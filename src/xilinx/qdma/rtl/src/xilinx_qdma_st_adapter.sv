// =========================================================================
// xilinx_qdma_st_adapter
//
// Common QDMA streaming interface adapter — converts flat QDMA H2C/C2H
// signals (as exported by the QDMA IP or the CPM5 block design) to/from
// axi4s_intf.
//
// QID_WID covers the only width difference between the discrete QDMA IP
// (UltraScale+, 11 bits) and the CPM5 QDMA (Versal, 12 bits).
//
// Responsibilities:
//   H2C: mty → tkeep (last beat), qid → tid.qid, err → tuser.err
//   C2H: tid.qid → ctrl_qid, tkeep → mty, auto-generate completions + ECC
//        descriptor credits kept at zero (simple mode)
//
// FLR, user interrupts, queue status, and TM descriptor status are
// PCIe function-level concerns and belong in the caller (e.g.
// xilinx_aved_adapter, xilinx_alveo_qdma_wrapper).
//
// The module operates entirely in the QDMA clock domain.  The caller is
// responsible for any CDC needed before connecting axis_h2c / axis_c2h to
// a downstream clock domain.
// =========================================================================
module xilinx_qdma_st_adapter
    import xilinx_qdma_pkg::*;
#(
    parameter int QID_WID = 11  // 11 for USPlus discrete QDMA, 12 for CPM5
) (
    // QDMA clock and reset
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
    // AXI4-S interfaces (QDMA clock domain)
    // -----------------------------------------------------------------------
    axi4s_intf.tx axis_h2c,  // H2C: drives toward core
    axi4s_intf.rx axis_c2h   // C2H: receives from core
);

    // =========================================================================
    // H2C stream — flat signals → axi4s_intf
    //
    // mty[5:0] = number of empty bytes in the last beat (MSB end).
    // Convert to tkeep by masking those bytes off.
    // qid may be wider than QID_WID in xilinx_qdma_pkg (11); truncate.
    // =========================================================================
    logic [AXIS_DATA_BYTE_WID-1:0] h2c_tkeep;
    always_comb begin
        if (h2c_tlast && !h2c_zero_byte) begin
            for (int b = 0; b < AXIS_DATA_BYTE_WID; b++)
                h2c_tkeep[b] = (b < (AXIS_DATA_BYTE_WID - h2c_mty)) ? 1'b1 : 1'b0;
        end else begin
            h2c_tkeep = '1;
        end
    end

    axis_tid_t   h2c_tid;
    axis_tdest_t h2c_tdest;
    axis_tuser_t h2c_tuser;

    assign h2c_tid.qid      = h2c_qid; // auto-truncates to qid_t (11 bits) when QID_WID=12
    assign h2c_tdest.unused = 1'b0;
    assign h2c_tuser.err    = h2c_err;

    assign axis_h2c.tvalid = h2c_tvalid;
    assign axis_h2c.tdata  = h2c_tdata;
    assign axis_h2c.tkeep  = h2c_tkeep;
    assign axis_h2c.tlast  = h2c_tlast;
    assign axis_h2c.tid    = h2c_tid;
    assign axis_h2c.tdest  = h2c_tdest;
    assign axis_h2c.tuser  = h2c_tuser;
    assign h2c_tready      = axis_h2c.tready;

    // =========================================================================
    // C2H stream — axi4s_intf → flat signals + completions
    // =========================================================================
    axis_tid_t   c2h_tid;
    axis_tdest_t c2h_tdest;
    axis_tuser_t c2h_tuser;

    assign c2h_tid   = axis_c2h.tid;
    assign c2h_tdest = axis_c2h.tdest;
    assign c2h_tuser = axis_c2h.tuser;

    // tkeep → mty: count contiguous trailing zero keeps on the last beat
    logic [5:0] c2h_mty_comb;
    always_comb begin
        c2h_mty_comb = '0;
        for (int b = AXIS_DATA_BYTE_WID-1; b >= 0; b--) begin
            if (!axis_c2h.tkeep[b] && (c2h_mty_comb == (AXIS_DATA_BYTE_WID-1-b)))
                c2h_mty_comb = c2h_mty_comb + 1'b1;
        end
    end

    assign c2h_tvalid        = axis_c2h.tvalid;
    assign c2h_tdata         = axis_c2h.tdata;
    assign c2h_tlast         = axis_c2h.tlast;
    assign c2h_ctrl_qid      = c2h_tid.qid[QID_WID-1:0];
    assign c2h_ctrl_len      = '0;
    assign c2h_ctrl_port_id  = '0;
    assign c2h_ctrl_has_cmpt = 1'b1;
    assign c2h_ctrl_marker   = 1'b0;
    assign c2h_mty           = axis_c2h.tlast ? c2h_mty_comb : '0;
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
        else if (axis_c2h.tvalid && axis_c2h.tready && axis_c2h.tlast)
            c2h_pkt_id <= c2h_pkt_id + 1'b1;
    end

    // Completion: one per EOP
    c2h_cmpt_data_t cmpt_data_packed;
    assign cmpt_data_packed.len    = '0;
    assign cmpt_data_packed.pkt_id = c2h_pkt_id;
    assign cmpt_data_packed.qid    = c2h_tid.qid;

    assign cmpt_tvalid          = axis_c2h.tvalid && axis_c2h.tready && axis_c2h.tlast;
    assign cmpt_data            = cmpt_data_packed;
    assign cmpt_size            = 2'b00;   // 8-byte completion
    assign cmpt_qid             = c2h_tid.qid[QID_WID-1:0];
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
    assign axis_c2h.tready = c2h_tready && cmpt_tready;

    // =========================================================================
    // Descriptor credits — kept at zero (simple mode)
    // =========================================================================
    assign dsc_crdt_crdt  = '0;
    assign dsc_crdt_dir   = 1'b0;
    assign dsc_crdt_fence = 1'b0;
    assign dsc_crdt_qid   = '0;
    assign dsc_crdt_valid = 1'b0;

endmodule : xilinx_qdma_st_adapter
