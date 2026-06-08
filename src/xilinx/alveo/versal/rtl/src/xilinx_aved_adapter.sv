module xilinx_aved_adapter (
    // Clocks and resets from AVED BD
    input  wire        clk_pl,
    input  wire        resetn_pl_periph,

    // PCIE0 H2C stream (BD master → user logic, terminated here)
    input  wire         dma0_m_axis_h2c_0_tvalid,
    input  wire [511:0] dma0_m_axis_h2c_0_tdata,
    input  wire         dma0_m_axis_h2c_0_tlast,
    output wire         dma0_m_axis_h2c_0_tready,
    input  wire [11:0]  dma0_m_axis_h2c_0_qid,
    input  wire [2:0]   dma0_m_axis_h2c_0_port_id,
    input  wire [31:0]  dma0_m_axis_h2c_0_mdata,
    input  wire [5:0]   dma0_m_axis_h2c_0_mty,
    input  wire [31:0]  dma0_m_axis_h2c_0_tcrc,
    input  wire         dma0_m_axis_h2c_0_err,
    input  wire         dma0_m_axis_h2c_0_zero_byte,

    // PCIE0 C2H stream (user logic → BD slave, terminated here)
    output wire         dma0_s_axis_c2h_0_tvalid,
    output wire [511:0] dma0_s_axis_c2h_0_tdata,
    output wire         dma0_s_axis_c2h_0_tlast,
    input  wire         dma0_s_axis_c2h_0_tready,
    output wire [11:0]  dma0_s_axis_c2h_0_ctrl_qid,
    output wire [15:0]  dma0_s_axis_c2h_0_ctrl_len,
    output wire [2:0]   dma0_s_axis_c2h_0_ctrl_port_id,
    output wire         dma0_s_axis_c2h_0_ctrl_has_cmpt,
    output wire         dma0_s_axis_c2h_0_ctrl_marker,
    output wire [5:0]   dma0_s_axis_c2h_0_mty,
    output wire [6:0]   dma0_s_axis_c2h_0_ecc,
    output wire [31:0]  dma0_s_axis_c2h_0_tcrc,

    // PCIE0 C2H completion write-back (user logic → BD slave, terminated here)
    output wire         dma0_s_axis_c2h_cmpt_0_tvalid,
    output wire [511:0] dma0_s_axis_c2h_cmpt_0_data,
    output wire [1:0]   dma0_s_axis_c2h_cmpt_0_size,
    output wire [11:0]  dma0_s_axis_c2h_cmpt_0_qid,
    output wire [2:0]   dma0_s_axis_c2h_cmpt_0_port_id,
    output wire [1:0]   dma0_s_axis_c2h_cmpt_0_cmpt_type,
    output wire [15:0]  dma0_s_axis_c2h_cmpt_0_wait_pld_pkt_id,
    output wire [15:0]  dma0_s_axis_c2h_cmpt_0_dpar,
    output wire [2:0]   dma0_s_axis_c2h_cmpt_0_col_idx,
    output wire [2:0]   dma0_s_axis_c2h_cmpt_0_err_idx,
    output wire         dma0_s_axis_c2h_cmpt_0_user_trig,
    output wire         dma0_s_axis_c2h_cmpt_0_marker,
    output wire         dma0_s_axis_c2h_cmpt_0_no_wrb_marker,
    input  wire         dma0_s_axis_c2h_cmpt_0_tready,

    // PCIE0 descriptor credit in (user logic → BD slave, terminated here)
    output wire [15:0]  dma0_dsc_crdt_in_0_crdt,
    output wire         dma0_dsc_crdt_in_0_dir,
    output wire         dma0_dsc_crdt_in_0_fence,
    output wire [11:0]  dma0_dsc_crdt_in_0_qid,
    output wire         dma0_dsc_crdt_in_0_valid,
    input  wire         dma0_dsc_crdt_in_0_rdy,

    // PCIE0 queue status output (BD → user logic, terminated here)
    input  wire [63:0]  dma0_qsts_out_0_data,
    input  wire [7:0]   dma0_qsts_out_0_op,
    input  wire [2:0]   dma0_qsts_out_0_port_id,
    input  wire [12:0]  dma0_qsts_out_0_qid,
    input  wire         dma0_qsts_out_0_vld,
    output wire         dma0_qsts_out_0_rdy,

    // PCIE0 traffic manager descriptor status (BD → user logic, terminated here)
    input  wire [15:0]  dma0_tm_dsc_sts_0_avl,
    input  wire         dma0_tm_dsc_sts_0_byp,
    input  wire         dma0_tm_dsc_sts_0_dir,
    input  wire         dma0_tm_dsc_sts_0_error,
    input  wire         dma0_tm_dsc_sts_0_irq_arm,
    input  wire         dma0_tm_dsc_sts_0_mm,
    input  wire [15:0]  dma0_tm_dsc_sts_0_pidx,
    input  wire [2:0]   dma0_tm_dsc_sts_0_port_id,
    input  wire         dma0_tm_dsc_sts_0_qen,
    input  wire [11:0]  dma0_tm_dsc_sts_0_qid,
    input  wire         dma0_tm_dsc_sts_0_qinv,
    output wire         dma0_tm_dsc_sts_0_rdy,
    input  wire         dma0_tm_dsc_sts_0_valid,

    // PCIE0 user interrupt (user logic → BD slave, terminated here)
    output wire [10:0]  dma0_usr_irq_0_vec,
    output wire [12:0]  dma0_usr_irq_0_fnc,
    output wire         dma0_usr_irq_0_valid,
    input  wire         dma0_usr_irq_0_ack,
    input  wire         dma0_usr_irq_0_fail,

    // PCIE0 function level reset notification (BD → user logic, terminated here)
    input  wire [12:0]  dma0_usr_flr_0_fnc,
    input  wire         dma0_usr_flr_0_set,
    output wire         dma0_usr_flr_0_clear,
    output wire [12:0]  dma0_usr_flr_0_done_fnc,
    output wire         dma0_usr_flr_0_done_vld,

    // Management AXI4-Lite (BD master -> adapter slave)
    input  wire [31:0] m_axi_usr_mgmt_awaddr,
    input  wire [2:0]  m_axi_usr_mgmt_awprot,
    input  wire        m_axi_usr_mgmt_awvalid,
    output wire        m_axi_usr_mgmt_awready,
    input  wire [31:0] m_axi_usr_mgmt_wdata,
    input  wire [3:0]  m_axi_usr_mgmt_wstrb,
    input  wire        m_axi_usr_mgmt_wvalid,
    output wire        m_axi_usr_mgmt_wready,
    output wire [1:0]  m_axi_usr_mgmt_bresp,
    output wire        m_axi_usr_mgmt_bvalid,
    input  wire        m_axi_usr_mgmt_bready,
    input  wire [31:0] m_axi_usr_mgmt_araddr,
    input  wire [2:0]  m_axi_usr_mgmt_arprot,
    input  wire        m_axi_usr_mgmt_arvalid,
    output wire        m_axi_usr_mgmt_arready,
    output wire [31:0] m_axi_usr_mgmt_rdata,
    output wire [1:0]  m_axi_usr_mgmt_rresp,
    output wire        m_axi_usr_mgmt_rvalid,
    input  wire        m_axi_usr_mgmt_rready,

    // AXI4-Lite controller output (carries clk/reset via aclk/aresetn)
    axi4l_intf.controller axil_if
);
    // Vivado SmartConnect delivers the absolute address (lower 32 bits) to
    // the slave port rather than the aperture-relative offset.  Strip the
    // base by masking to the M04 usr_mgmt aperture size (4 KB = 12 bits).
    localparam int USR_MGMT_APERTURE_BITS = 12;

    wire [31:0] awaddr_offset = {{(32-USR_MGMT_APERTURE_BITS){1'b0}},
                                  m_axi_usr_mgmt_awaddr[USR_MGMT_APERTURE_BITS-1:0]};
    wire [31:0] araddr_offset = {{(32-USR_MGMT_APERTURE_BITS){1'b0}},
                                  m_axi_usr_mgmt_araddr[USR_MGMT_APERTURE_BITS-1:0]};

    axi4l_intf_from_signals i_axi4l_intf_from_signals (
        .aclk     ( clk_pl                   ),
        .aresetn  ( resetn_pl_periph         ),
        .awvalid  ( m_axi_usr_mgmt_awvalid  ),
        .awready  ( m_axi_usr_mgmt_awready  ),
        .awaddr   ( awaddr_offset            ),
        .awprot   ( m_axi_usr_mgmt_awprot   ),
        .wvalid   ( m_axi_usr_mgmt_wvalid   ),
        .wready   ( m_axi_usr_mgmt_wready   ),
        .wdata    ( m_axi_usr_mgmt_wdata    ),
        .wstrb    ( m_axi_usr_mgmt_wstrb    ),
        .bvalid   ( m_axi_usr_mgmt_bvalid   ),
        .bready   ( m_axi_usr_mgmt_bready   ),
        .bresp    ( m_axi_usr_mgmt_bresp    ),
        .arvalid  ( m_axi_usr_mgmt_arvalid  ),
        .arready  ( m_axi_usr_mgmt_arready  ),
        .araddr   ( araddr_offset            ),
        .arprot   ( m_axi_usr_mgmt_arprot   ),
        .rvalid   ( m_axi_usr_mgmt_rvalid   ),
        .rready   ( m_axi_usr_mgmt_rready   ),
        .rdata    ( m_axi_usr_mgmt_rdata    ),
        .rresp    ( m_axi_usr_mgmt_rresp    ),
        .axi4l_if ( axil_if                 )
    );

    // =========================================================================
    // PCIE0 DMA interface termination
    //
    // Placeholder termination pending full QDMA subsystem implementation.
    // H2C is consumed (tready=1). C2H, completions, and control sidebands
    // are driven to safe idle values. FLR is immediately acknowledged.
    // =========================================================================

    assign dma0_m_axis_h2c_0_tready          = 1'b1;

    assign dma0_s_axis_c2h_0_tvalid          = 1'b0;
    assign dma0_s_axis_c2h_0_tdata           = '0;
    assign dma0_s_axis_c2h_0_tlast           = 1'b0;
    assign dma0_s_axis_c2h_0_ctrl_qid        = '0;
    assign dma0_s_axis_c2h_0_ctrl_len        = '0;
    assign dma0_s_axis_c2h_0_ctrl_port_id    = '0;
    assign dma0_s_axis_c2h_0_ctrl_has_cmpt   = 1'b0;
    assign dma0_s_axis_c2h_0_ctrl_marker     = 1'b0;
    assign dma0_s_axis_c2h_0_mty             = '0;
    assign dma0_s_axis_c2h_0_ecc             = '0;
    assign dma0_s_axis_c2h_0_tcrc            = '0;

    assign dma0_s_axis_c2h_cmpt_0_tvalid          = 1'b0;
    assign dma0_s_axis_c2h_cmpt_0_data            = '0;
    assign dma0_s_axis_c2h_cmpt_0_size            = '0;
    assign dma0_s_axis_c2h_cmpt_0_qid             = '0;
    assign dma0_s_axis_c2h_cmpt_0_port_id         = '0;
    assign dma0_s_axis_c2h_cmpt_0_cmpt_type       = '0;
    assign dma0_s_axis_c2h_cmpt_0_wait_pld_pkt_id = '0;
    assign dma0_s_axis_c2h_cmpt_0_dpar            = '0;
    assign dma0_s_axis_c2h_cmpt_0_col_idx         = '0;
    assign dma0_s_axis_c2h_cmpt_0_err_idx         = '0;
    assign dma0_s_axis_c2h_cmpt_0_user_trig       = 1'b0;
    assign dma0_s_axis_c2h_cmpt_0_marker          = 1'b0;
    assign dma0_s_axis_c2h_cmpt_0_no_wrb_marker   = 1'b0;

    assign dma0_dsc_crdt_in_0_crdt           = '0;
    assign dma0_dsc_crdt_in_0_dir            = 1'b0;
    assign dma0_dsc_crdt_in_0_fence          = 1'b0;
    assign dma0_dsc_crdt_in_0_qid            = '0;
    assign dma0_dsc_crdt_in_0_valid          = 1'b0;

    assign dma0_qsts_out_0_rdy               = 1'b1;
    assign dma0_tm_dsc_sts_0_rdy             = 1'b1;

    assign dma0_usr_irq_0_vec                = '0;
    assign dma0_usr_irq_0_fnc                = '0;
    assign dma0_usr_irq_0_valid              = 1'b0;

    assign dma0_usr_flr_0_clear              = dma0_usr_flr_0_set;
    assign dma0_usr_flr_0_done_fnc           = dma0_usr_flr_0_fnc;
    assign dma0_usr_flr_0_done_vld           = dma0_usr_flr_0_set;

endmodule : xilinx_aved_adapter
