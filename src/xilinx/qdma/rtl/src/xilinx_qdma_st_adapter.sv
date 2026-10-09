// =========================================================================
// xilinx_qdma_st_adapter
//
// Common QDMA streaming interface adapter — converts flat QDMA H2C/C2H
// signals (as exported by the QDMA IP or the CPM5 block design) to/from
// packet_intf.
//
// QID_WID covers the only width difference between the discrete QDMA IP
// (UltraScale+, 11 bits) and the CPM5 QDMA (Versal, 12 bits).
//
// Responsibilities:
//   H2C: flat QDMA signals → packet_intf
//   C2H: packet_intf → flat QDMA signals + completions + ECC
//        Descriptor credits kept at zero (simple mode).
//
// Everything here is in the QDMA clock domain and is a direct signal mapping:
// mty maps natively in both directions and the QID travels in
// packet_intf.meta.  Buffering, the crossing to the core clock domain, the
// loopback switch and the register space live upstream in
// xilinx_alveo_qdma_st.
//
// c2h_ctrl_len and the completion length come from pkt_c2h_size rather than
// being derived here: QDMA needs the length at the first beat, which only the
// store-and-forward FIFO upstream knows.
//
// FLR, user interrupts, queue status, and TM descriptor status are
// PCIe function-level concerns and belong in the caller (e.g.
// xilinx_aved_adapter, xilinx_alveo_qdma_wrapper).
// =========================================================================
module xilinx_qdma_st_adapter
    import xilinx_qdma_pkg::*;
#(
    parameter int QID_WID = 11  // 11 for USPlus discrete QDMA, 12 for CPM5
) (
    // QDMA clock and reset — the domain of everything in this module
    input  wire        aclk,
    input  wire        aresetn,

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
    // Packet interfaces (QDMA clock domain).
    // The QID travels in the metadata field in both directions.
    // -----------------------------------------------------------------------
    packet_intf.tx pkt_h2c,  // H2C: drives upstream
    packet_intf.rx pkt_c2h,  // C2H: receives from upstream

    // Length of the packet currently presented on pkt_c2h, held for its
    // duration.  packet_pkg::size_t is 16 bits — the same width as the QDMA
    // ctrl_len and completion len fields, so no resizing is needed below.
    input  packet_pkg::size_t pkt_c2h_size
);


    // =========================================================================
    // H2C stream — flat QDMA signals → packet_intf
    //
    // mty maps natively onto packet_intf and the QID travels in the metadata
    // field.
    //
    // zero_byte marks a transfer carrying no payload, which packet_intf cannot
    // represent (mty tops out one byte short of a full beat). Such packets are
    // marked errored so the store-and-forward FIFO upstream discards them and
    // counts them, rather than passing a beat of undefined payload onward.
    // =========================================================================
    assign pkt_h2c.vld  = h2c_tvalid;
    assign pkt_h2c.data = {<<8{h2c_tdata}};  // little-endian → big-endian
    assign pkt_h2c.eop  = h2c_tlast;
    assign pkt_h2c.mty  = h2c_tlast ? h2c_mty : '0;
    assign pkt_h2c.err  = h2c_err || h2c_zero_byte;
    assign pkt_h2c.meta = h2c_qid;
    assign h2c_tready   = pkt_h2c.rdy;

    // =========================================================================
    // C2H stream — packet_intf → flat QDMA signals
    //
    // mty maps natively; the QID is carried in packet_intf.meta and extracted
    // for ctrl_qid and completions.  The length arrives on pkt_c2h_size.
    // =========================================================================

    // --- Flat C2H data outputs (QDMA clock domain) ---
    assign c2h_tvalid        = pkt_c2h.vld;
    assign c2h_tdata         = {<<8{pkt_c2h.data}};  // big-endian → little-endian
    assign c2h_tlast         = pkt_c2h.eop;
    assign c2h_ctrl_qid      = pkt_c2h.meta[QID_WID-1:0];
    assign c2h_ctrl_len      = pkt_c2h_size;
    assign c2h_ctrl_port_id  = '0;
    assign c2h_ctrl_has_cmpt = 1'b1;
    assign c2h_ctrl_marker   = 1'b0;
    assign c2h_mty           = pkt_c2h.eop ? pkt_c2h.mty : '0;
    assign c2h_tcrc          = '0;

    // ECC over the C2H ctrl bus.  Field order and widths per PG347:
    //   {24'h0, has_cmpt, marker, port_id[2:0], qid[11:0], len[15:0]} = 57 bits
    // The qid field is 12 bits on both targets; the 11-bit USPlus qid
    // zero-extends into it.
    logic [56:0] ecc_data_in;
    assign ecc_data_in = {24'h0, c2h_ctrl_has_cmpt, c2h_ctrl_marker,
                          c2h_ctrl_port_id,
                          12'(c2h_ctrl_qid),
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
        else if (pkt_c2h.vld && pkt_c2h.rdy && pkt_c2h.eop)
            c2h_pkt_id <= c2h_pkt_id + 1'b1;
    end

    // Completion: one per EOP
    c2h_cmpt_data_t cmpt_data_packed;
    assign cmpt_data_packed.dma_rsv  = '0;
    assign cmpt_data_packed.user_rsv = '0;
    assign cmpt_data_packed.len    = pkt_c2h_size;
    assign cmpt_data_packed.pkt_id = c2h_pkt_id;
    assign cmpt_data_packed.qid    = pkt_c2h.meta[QID_WID-1:0];

    assign cmpt_tvalid          = pkt_c2h.vld && pkt_c2h.rdy && pkt_c2h.eop;
    assign cmpt_data            = cmpt_data_packed;
    assign cmpt_size            = 2'b00;   // 8-byte completion
    assign cmpt_qid             = pkt_c2h.meta[QID_WID-1:0];
    assign cmpt_port_id         = '0;
    assign cmpt_cmpt_type       = 2'b11;   // HAS_PLD
    assign cmpt_wait_pld_pkt_id = c2h_pkt_id;
    // Odd parity: one bit per 32-bit word of the 512-bit completion bus.
    generate
        for (genvar i = 0; i < 16; i++) begin : g_cmpt_dpar
            assign cmpt_dpar[i] = ~(^cmpt_data[i*32 +: 32]);
        end
    endgenerate
    assign cmpt_col_idx         = '0;
    assign cmpt_err_idx         = '0;
    assign cmpt_user_trig       = 1'b0;
    assign cmpt_marker          = 1'b0;
    assign cmpt_no_wrb_marker   = 1'b0;

    // tready: accepted when both data and completion paths are ready
    assign pkt_c2h.rdy = c2h_tready && cmpt_tready;

    // =========================================================================
    // Descriptor credits — kept at zero (simple mode)
    // =========================================================================
    assign dsc_crdt_crdt  = '0;
    assign dsc_crdt_dir   = 1'b0;
    assign dsc_crdt_fence = 1'b0;
    assign dsc_crdt_qid   = '0;
    assign dsc_crdt_valid = 1'b0;

endmodule : xilinx_qdma_st_adapter
