// =========================================================================
// xilinx_qdma_st_adapter
//
// Common QDMA streaming interface adapter — converts flat QDMA H2C/C2H
// signals (as exported by the QDMA IP or the CPM5 block design) to/from
// standard interfaces.
//
// QID_WID covers the only width difference between the discrete QDMA IP
// (UltraScale+, 11 bits) and the CPM5 QDMA (Versal, 12 bits).
//
// Responsibilities:
//   H2C: flat QDMA signals → packet_intf
//   C2H: packet_intf → flat QDMA signals + completions + ECC, deriving the
//        packet length for c2h_ctrl_len (required for DPDK).
//        Descriptor credits kept at zero (simple mode).
//
// Both directions present packet_intf in the core clock domain. Each owns a
// packet_fifo (ASYNC=1) providing store-and-forward buffering and the clock
// domain crossing to or from the QDMA clock, so the caller needs no CDC of
// its own. mty maps natively in both directions and the QID travels in
// packet_intf.meta.
//
// A register-controlled loopback mode reflects H2C back to the host as C2H
// without involving the core, for testing the DMA path end to end. See the
// qdma_st_adapter register block.
//
// FLR, user interrupts, queue status, and TM descriptor status are
// PCIe function-level concerns and belong in the caller (e.g.
// xilinx_aved_adapter, xilinx_alveo_qdma_wrapper).
// =========================================================================
module xilinx_qdma_st_adapter
    import xilinx_qdma_pkg::*;
#(
    parameter int QID_WID = 11,      // 11 for USPlus discrete QDMA, 12 for CPM5
    parameter int MAX_PKT_LEN = 9100 // Max packet length (bytes) for FIFO sizing
) (
    // QDMA clock and reset
    input  wire        aclk,
    input  wire        aresetn,

    // Core clock and synchronous reset. This is the domain of pkt_h2c/pkt_c2h,
    // the core side of both packet FIFOs, and the loopback switch.
    input  wire        core_clk,
    input  wire        core_srst,

    // -----------------------------------------------------------------------
    // Flat QDMA streaming signals
    // (connect directly to the QDMA IP ports or the AVED BD exports)
    // -----------------------------------------------------------------------

    // H2C stream (QDMA master → user)
    input  wire                   h2c_tvalid,
    input  wire [511:0]           h2c_tdata,
    input  wire                   h2c_tlast,
    output wire                   h2c_tready,
    input  wire [QID_WID-1:0]     h2c_qid,
    input  wire [2:0]             h2c_port_id,
    input  wire [31:0]            h2c_mdata,
    input  wire [5:0]             h2c_mty,
    input  wire [31:0]            h2c_tcrc,
    input  wire                   h2c_err,
    input  wire                   h2c_zero_byte,

    // C2H data (user → QDMA slave)
    output wire                   c2h_tvalid,
    output wire [511:0]           c2h_tdata,
    output wire                   c2h_tlast,
    input  wire                   c2h_tready,
    output wire [QID_WID-1:0]     c2h_ctrl_qid,
    output wire [15:0]            c2h_ctrl_len,
    output wire [2:0]             c2h_ctrl_port_id,
    output wire                   c2h_ctrl_has_cmpt,
    output wire                   c2h_ctrl_marker,
    output wire [5:0]             c2h_mty,
    output wire [6:0]             c2h_ecc,
    output wire [31:0]            c2h_tcrc,

    // C2H completion write-back (user → QDMA slave)
    output wire                   cmpt_tvalid,
    output wire [511:0]           cmpt_data,
    output wire [1:0]             cmpt_size,
    output wire [QID_WID-1:0]     cmpt_qid,
    output wire [2:0]             cmpt_port_id,
    output wire [1:0]             cmpt_cmpt_type,
    output wire [15:0]            cmpt_wait_pld_pkt_id,
    output wire [15:0]            cmpt_dpar,
    output wire [2:0]             cmpt_col_idx,
    output wire [2:0]             cmpt_err_idx,
    output wire                   cmpt_user_trig,
    output wire                   cmpt_marker,
    output wire                   cmpt_no_wrb_marker,
    input  wire                   cmpt_tready,

    // Descriptor credit in (user → QDMA, kept at zero — simple mode)
    output wire [15:0]            dsc_crdt_crdt,
    output wire                   dsc_crdt_dir,
    output wire                   dsc_crdt_fence,
    output wire [QID_WID-1:0]     dsc_crdt_qid,
    output wire                   dsc_crdt_valid,
    input  wire                   dsc_crdt_rdy,

    // -----------------------------------------------------------------------
    // Management AXI4-Lite — test and debug registers.
    // Its own clock domain; crossings to the core domain are made internally.
    // -----------------------------------------------------------------------
    axi4l_intf.peripheral axil_if,

    // -----------------------------------------------------------------------
    // Packet interfaces (core clock domain; CDC handled internally).
    // The QID travels in the metadata field in both directions.
    // -----------------------------------------------------------------------
    packet_intf.tx pkt_h2c,  // H2C: drives toward core
    packet_intf.rx pkt_c2h   // C2H: receives from core
);

    // =========================================================================
    // Packet FIFO sizing
    //
    // Both FIFOs are store-and-forward, so each must hold strictly more than
    // one maximum-length packet (packet_fifo_core checks DEPTH > MAX_PKT_WORDS).
    // 256 words of 64 bytes covers packets up to just under 16 kB, which
    // includes the 9100-byte jumbo default; beyond that, grow to the next power
    // of two that clears the check.
    // =========================================================================
    localparam int MAX_PKT_WORDS  = (MAX_PKT_LEN + AXIS_DATA_BYTE_WID - 1) / AXIS_DATA_BYTE_WID;
    localparam int MIN_FIFO_DEPTH = 2 ** $clog2(MAX_PKT_WORDS + 1);
    localparam int H2C_FIFO_DEPTH = MIN_FIFO_DEPTH > 256 ? MIN_FIFO_DEPTH : 256;
    localparam int C2H_FIFO_DEPTH = H2C_FIFO_DEPTH;

    // =========================================================================
    // Test and debug registers
    //
    // The register block runs on the management clock; the loopback enable and
    // its status cross to and from the core domain through level
    // synchronizers.  The enable changes rarely and packet_loopback applies it
    // only at a packet boundary, so the crossing needs no handshake.
    // =========================================================================
    qdma_st_adapter_reg_intf reg_if ();

    qdma_st_adapter_reg_blk i_qdma_st_adapter_reg_blk (
        .axil_if    ( axil_if ),
        .reg_blk_if ( reg_if  )
    );

    // Reserved registers pad the block out to a full 16-byte window; they hold
    // their init value and take no hardware update.
    assign reg_if.reserved_0_nxt_v = 1'b0;
    assign reg_if.reserved_0_nxt   = '0;
    assign reg_if.reserved_1_nxt_v = 1'b0;
    assign reg_if.reserved_1_nxt   = '0;

    logic core_loopback_en;
    logic core_loopback_en_mon;
    logic core_loopback_switching;

    sync_level #(.RST_VALUE(1'b0)) i_sync_level__loopback_en (
        .clk_in  ( axil_if.aclk                   ),
        .rst_in  ( 1'b0                           ),
        .rdy_in  (                                ),
        .lvl_in  ( reg_if.loopback_config.enable  ),
        .clk_out ( core_clk                       ),
        .rst_out ( 1'b0                           ),
        .lvl_out ( core_loopback_en               )
    );

    sync_level #(.RST_VALUE(1'b0)) i_sync_level__loopback_enabled (
        .clk_in  ( core_clk                       ),
        .rst_in  ( 1'b0                           ),
        .rdy_in  (                                ),
        .lvl_in  ( core_loopback_en_mon           ),
        .clk_out ( axil_if.aclk                   ),
        .rst_out ( 1'b0                           ),
        .lvl_out ( reg_if.loopback_status_nxt.enabled )
    );

    sync_level #(.RST_VALUE(1'b0)) i_sync_level__loopback_switching (
        .clk_in  ( core_clk                       ),
        .rst_in  ( 1'b0                           ),
        .rdy_in  (                                ),
        .lvl_in  ( core_loopback_switching        ),
        .clk_out ( axil_if.aclk                   ),
        .rst_out ( 1'b0                           ),
        .lvl_out ( reg_if.loopback_status_nxt.switching )
    );

    assign reg_if.loopback_status_nxt_v = 1'b1;

    // =========================================================================
    // H2C stream — flat signals → packet_fifo (ASYNC CDC + S&F) → packet_intf
    //
    // mty maps natively onto packet_intf, and the QID travels in the metadata
    // field. An internal packet_fifo with ASYNC=1 provides store-and-forward
    // buffering and the clock domain crossing from the QDMA clock down to the
    // core clock, so the caller receives H2C already in the core domain.
    //
    // zero_byte marks a transfer carrying no payload, which packet_intf cannot
    // represent (mty tops out one byte short of a full beat). Such packets are
    // marked errored so DROP_ERRORED discards them and the FIFO's event
    // interface counts them, rather than passing a beat of undefined payload on
    // to the core.
    // =========================================================================

    // FIFO input interface (QDMA clock domain)
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c_in (.clk(aclk));

    assign pkt_h2c_in.vld  = h2c_tvalid;
    assign pkt_h2c_in.data = {<<8{h2c_tdata}};  // little-endian → big-endian
    assign pkt_h2c_in.eop  = h2c_tlast;
    assign pkt_h2c_in.mty  = h2c_tlast ? h2c_mty : '0;
    assign pkt_h2c_in.err  = h2c_err || h2c_zero_byte;
    assign pkt_h2c_in.meta = h2c_qid;
    assign h2c_tready      = pkt_h2c_in.rdy;

    // FIFO output interface (core clock domain), routed via packet_loopback
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c_core (.clk(core_clk));

    packet_fifo #(
        .ASYNC           ( 1              ),
        .DEPTH           ( H2C_FIFO_DEPTH ),
        .MAX_PKT_SIZE    ( MAX_PKT_LEN    ),
        .MAX_DESCRIPTORS ( 32             ),
        .DROP_ERRORED    ( 1              )
    ) i_packet_fifo_h2c (
        .srst_in       ( ~aresetn     ),
        .packet_in_if  ( pkt_h2c_in   ),
        .srst_out      ( core_srst    ),
        .packet_out_if ( pkt_h2c_core ),
        .pkt_size      (              )
    );

    // =========================================================================
    // C2H stream — packet_intf → packet_fifo (ASYNC CDC + S&F) → flat signals
    //
    // The C2H input arrives on packet_intf in the core clock domain.  An
    // internal packet_fifo with ASYNC=1 provides:
    //   - Clock domain crossing (core → QDMA)
    //   - Store-and-forward buffering
    //   - Packet length computation (pkt_size output)
    //
    // The FIFO output drives flat QDMA C2H signals directly.  mty maps
    // natively; the QID is carried in packet_intf.meta and extracted for
    // ctrl_qid and completions.
    // =========================================================================

    // FIFO output interface (QDMA clock domain)
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h_out (.clk(aclk));

    // Packet length from packet_fifo (held for current output packet).
    // packet_pkg::size_t is 16 bits — the same width as the QDMA ctrl_len and
    // completion len fields, so no resizing is needed below.
    packet_pkg::size_t c2h_pkt_size;

    // FIFO input interface (core clock domain), sourced via packet_loopback
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h_core (.clk(core_clk));

    packet_fifo #(
        .ASYNC           ( 1              ),
        .DEPTH           ( C2H_FIFO_DEPTH ),
        .MAX_PKT_SIZE    ( MAX_PKT_LEN    ),
        .MAX_DESCRIPTORS ( 32             ),
        .DROP_ERRORED    ( 0              )
    ) i_packet_fifo_c2h (
        .srst_in       ( core_srst    ),
        .packet_in_if  ( pkt_c2h_core ),
        .srst_out      ( ~aresetn     ),
        .packet_out_if ( pkt_c2h_out  ),
        .pkt_size      ( c2h_pkt_size )
    );

    // =========================================================================
    // Loopback switch (core clock domain)
    //
    // tx/rx are named from the host's point of view, which matches the DMA
    // directions: H2C is the host transmitting, C2H the host receiving.  With
    // loopback enabled, H2C is reflected straight into the C2H FIFO, the core
    // sees no H2C traffic, and C2H traffic from the core is discarded.
    // =========================================================================
    packet_loopback i_packet_loopback (
        .srst          ( core_srst               ),
        .packet_tx_in  ( pkt_h2c_core            ),
        .packet_tx_out ( pkt_h2c                 ),
        .packet_rx_in  ( pkt_c2h                 ),
        .packet_rx_out ( pkt_c2h_core            ),
        .en            ( core_loopback_en        ),
        .en_mon        ( core_loopback_en_mon    ),
        .switching     ( core_loopback_switching )
    );

    // --- Flat C2H data outputs (QDMA clock domain) ---
    assign c2h_tvalid        = pkt_c2h_out.vld;
    assign c2h_tdata         = {<<8{pkt_c2h_out.data}};  // big-endian → little-endian
    assign c2h_tlast         = pkt_c2h_out.eop;
    assign c2h_ctrl_qid      = pkt_c2h_out.meta[QID_WID-1:0];
    assign c2h_ctrl_len      = c2h_pkt_size;
    assign c2h_ctrl_port_id  = '0;
    assign c2h_ctrl_has_cmpt = 1'b1;
    assign c2h_ctrl_marker   = 1'b0;
    assign c2h_mty           = pkt_c2h_out.eop ? pkt_c2h_out.mty : '0;
    assign c2h_tcrc          = '0;

    // ECC over C2H ctrl bus (PG302: input order LSB-first as listed below)
    logic [56:0] ecc_data_in;
    assign ecc_data_in = {24'h0, c2h_ctrl_has_cmpt, c2h_ctrl_marker,
                          c2h_ctrl_port_id, 1'b0,
                          11'(c2h_ctrl_qid),    // PG302 ECC covers 11-bit qid field
                          c2h_ctrl_len};

    xilinx_qdma_ecc i_xilinx_qdma_ecc (
        .ecc_data_in     ( ecc_data_in ),
        .ecc_data_out    (             ),
        .ecc_chkbits_out ( c2h_ecc     ),
        .ecc_clk         ( aclk        ),
        .ecc_clken       ( 1'b1        ),
        .ecc_reset       ( !aresetn    )
    );

    // Packet ID counter for completion write-back
    pkt_id_t c2h_pkt_id;
    always_ff @(posedge aclk) begin
        if (!aresetn) c2h_pkt_id <= '0;
        else if (pkt_c2h_out.vld && pkt_c2h_out.rdy && pkt_c2h_out.eop)
            c2h_pkt_id <= c2h_pkt_id + 1'b1;
    end

    // Completion: one per EOP
    c2h_cmpt_data_t cmpt_data_packed;
    assign cmpt_data_packed.len    = c2h_pkt_size;
    assign cmpt_data_packed.pkt_id = c2h_pkt_id;
    assign cmpt_data_packed.qid    = pkt_c2h_out.meta[QID_WID-1:0];

    assign cmpt_tvalid          = pkt_c2h_out.vld && pkt_c2h_out.rdy && pkt_c2h_out.eop;
    assign cmpt_data            = cmpt_data_packed;
    assign cmpt_size            = 2'b00;   // 8-byte completion
    assign cmpt_qid             = pkt_c2h_out.meta[QID_WID-1:0];
    assign cmpt_port_id         = '0;
    assign cmpt_cmpt_type       = 2'b11;   // HAS_PLD
    assign cmpt_wait_pld_pkt_id = c2h_pkt_id;
    assign cmpt_dpar            = '0;
    assign cmpt_col_idx         = '0;
    assign cmpt_err_idx         = '0;
    assign cmpt_user_trig       = 1'b0;
    assign cmpt_marker          = 1'b0;
    assign cmpt_no_wrb_marker   = 1'b0;

    // tready: accepted when both data and completion paths are ready
    assign pkt_c2h_out.rdy = c2h_tready && cmpt_tready;

    // =========================================================================
    // Descriptor credits — kept at zero (simple mode)
    // =========================================================================
    assign dsc_crdt_crdt  = '0;
    assign dsc_crdt_dir   = 1'b0;
    assign dsc_crdt_fence = 1'b0;
    assign dsc_crdt_qid   = '0;
    assign dsc_crdt_valid = 1'b0;

endmodule : xilinx_qdma_st_adapter
