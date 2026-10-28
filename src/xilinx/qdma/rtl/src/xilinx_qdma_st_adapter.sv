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
//        meta carries pkt_h2c_meta_t {tcrc, qid}; xilinx_alveo_qdma_st
//        uses tcrc as crc_in for the inline H2C CRC checker.
//   C2H: packet_intf → flat QDMA signals + completions + ECC
//        meta carries pkt_c2h_meta_t {size, tcrc, qid}; all three fields
//        are unpacked here, eliminating the separate pkt_c2h_size port.
//        Descriptor credits kept at zero (simple mode).
//
// Everything here is in the QDMA clock domain and is a direct signal
// mapping.  Buffering, the clock-domain crossing, the CRC check/generate,
// the loopback switch and the register space live upstream in
// xilinx_alveo_qdma_st.
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
    // meta carries pkt_h2c_meta_t / pkt_c2h_meta_t — see xilinx_qdma_pkg.
    // -----------------------------------------------------------------------
    packet_intf.tx pkt_h2c,  // H2C: drives upstream; META_WID = PKT_H2C_META_WID
    packet_intf.rx pkt_c2h   // C2H: receives from upstream; META_WID = PKT_C2H_META_WID
);

    // =========================================================================
    // H2C stream — flat QDMA signals → packet_intf (pkt_h2c_meta_t)
    //
    // Packs {h2c_tcrc, h2c_qid} into meta.  The tcrc is valid at EOP only when
    // the QDMA IP's data protection (parity) setting is enabled in the
    // platform wrapper; with protection disabled it reads 0.
    // xilinx_alveo_qdma_st extracts it as crc_in for packet_crc_rx.
    //
    // zero_byte marks a transfer with no payload (packet_intf cannot represent
    // mty == DATA_BYTE_WID); it is marked errored so the upstream
    // store-and-forward FIFO (DROP_ERRORED=1) discards and counts it.
    // =========================================================================
    pkt_h2c_meta_t h2c_meta;
    assign h2c_meta.tcrc = h2c_tcrc;
    assign h2c_meta.qid  = QID_WID'(h2c_qid);

    assign pkt_h2c.vld  = h2c_tvalid;
    assign pkt_h2c.data = {<<8{h2c_tdata}};  // little-endian → big-endian
    assign pkt_h2c.eop  = h2c_tlast;
    assign pkt_h2c.mty  = h2c_tlast ? h2c_mty : '0;
    assign pkt_h2c.err  = h2c_err || h2c_zero_byte;
    assign pkt_h2c.meta = PKT_H2C_META_WID'(h2c_meta);
    assign h2c_tready   = pkt_h2c.rdy;

    // =========================================================================
    // C2H stream — packet_intf (pkt_c2h_meta_t) → flat QDMA signals
    //
    // Unpacks meta into size (→ ctrl_len, cmpt.len), tcrc (→ c2h_tcrc) and
    // qid (→ ctrl_qid, completions).  size is the store-and-forward packet
    // length packed upstream at the FIFO output, available from the first beat.
    // =========================================================================
    pkt_c2h_meta_t c2h_meta;
    assign c2h_meta = pkt_c2h.meta;

    assign c2h_tvalid        = pkt_c2h.vld;
    assign c2h_tdata         = {<<8{pkt_c2h.data}};  // big-endian → little-endian
    assign c2h_tlast         = pkt_c2h.eop;
    assign c2h_ctrl_qid      = QID_WID'(c2h_meta.qid);
    assign c2h_ctrl_len      = c2h_meta.size;
    assign c2h_ctrl_port_id  = '0;
    assign c2h_ctrl_has_cmpt = 1'b1;
    assign c2h_ctrl_marker   = 1'b0;
    assign c2h_mty           = pkt_c2h.eop ? pkt_c2h.mty : '0;
    assign c2h_tcrc          = c2h_meta.tcrc;

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
        .ecc_chkbits_out ( c2h_ecc     )
    );

    // Payload packet ID counter for completion write-back.  QDMA's internal
    // payload packet ID is 1-based, so the completion carries the count
    // including the packet being presented.
    pkt_id_t c2h_pkt_id;
    always_ff @(posedge aclk) begin
        if (!aresetn) c2h_pkt_id <= '0;
        else if (pkt_c2h.vld && pkt_c2h.rdy && pkt_c2h.eop)
            c2h_pkt_id <= c2h_pkt_id + 1'b1;
    end

    pkt_id_t c2h_pld_pkt_id;
    assign c2h_pld_pkt_id = c2h_pkt_id + 1'b1;

    // Completion: one per EOP
    c2h_cmpt_data_t cmpt_data_packed;
    assign cmpt_data_packed.dma_rsv  = '0;
    assign cmpt_data_packed.desc_used = 1'b1;
    assign cmpt_data_packed.user_rsv = '0;
    assign cmpt_data_packed.len    = c2h_meta.size;
    assign cmpt_data_packed.pkt_id = c2h_pld_pkt_id;
    assign cmpt_data_packed.qid    = 12'(c2h_meta.qid);

    assign cmpt_tvalid          = pkt_c2h.vld && pkt_c2h.rdy && pkt_c2h.eop;
    assign cmpt_data            = cmpt_data_packed;
    assign cmpt_size            = 2'b00;   // 8-byte completion
    assign cmpt_qid             = QID_WID'(c2h_meta.qid);
    assign cmpt_port_id         = '0;
    assign cmpt_cmpt_type       = 2'b11;   // HAS_PLD
    assign cmpt_wait_pld_pkt_id = c2h_pld_pkt_id;
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
