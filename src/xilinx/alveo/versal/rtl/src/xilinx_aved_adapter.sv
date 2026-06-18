module xilinx_aved_adapter (
    // Clocks and resets from AVED BD
    input  wire        clk_pl0_100mhz,
    input  wire        m_axi_pcie0_aclk,
    input  wire        rstn_pl0_100mhz,
    input  wire        m_axi_pcie0_aresetn,

    // Shell-facing signals (functional naming for xilinx_alveo_versal_shell)
    output wire        sys_clk,     // system/debug clock → shell
    output wire        pcie_clk,    // PCIe interface clock → shell
    output wire        pci_rstn_in, // pre-JTAG reset → shell (m_axi_pcie0_aresetn proxy for perst#)
    input  wire        pci_rstn,    // post-JTAG reset ← shell (not yet wired to CPM5)

    // PCIE0 BAR2 — 512-bit AXI4 master from NoC (→ AXI4-L → axil_if)
    input  wire [63:0]  m_axi_pcie0_awaddr,
    input  wire [1:0]   m_axi_pcie0_awid,
    input  wire [7:0]   m_axi_pcie0_awlen,
    input  wire [2:0]   m_axi_pcie0_awsize,
    input  wire [1:0]   m_axi_pcie0_awburst,
    input  wire         m_axi_pcie0_awlock,
    input  wire [3:0]   m_axi_pcie0_awcache,
    input  wire [2:0]   m_axi_pcie0_awprot,
    input  wire [3:0]   m_axi_pcie0_awqos,
    input  wire [3:0]   m_axi_pcie0_awregion,
    input  wire [17:0]  m_axi_pcie0_awuser,
    input  wire         m_axi_pcie0_awvalid,
    output wire         m_axi_pcie0_awready,
    input  wire [511:0] m_axi_pcie0_wdata,
    input  wire [63:0]  m_axi_pcie0_wstrb,
    input  wire         m_axi_pcie0_wlast,
    input  wire         m_axi_pcie0_wvalid,
    output wire         m_axi_pcie0_wready,
    output wire [1:0]   m_axi_pcie0_bid,
    output wire [1:0]   m_axi_pcie0_bresp,
    output wire         m_axi_pcie0_bvalid,
    input  wire         m_axi_pcie0_bready,
    input  wire [63:0]  m_axi_pcie0_araddr,
    input  wire [1:0]   m_axi_pcie0_arid,
    input  wire [7:0]   m_axi_pcie0_arlen,
    input  wire [2:0]   m_axi_pcie0_arsize,
    input  wire [1:0]   m_axi_pcie0_arburst,
    input  wire         m_axi_pcie0_arlock,
    input  wire [3:0]   m_axi_pcie0_arcache,
    input  wire [2:0]   m_axi_pcie0_arprot,
    input  wire [3:0]   m_axi_pcie0_arqos,
    input  wire [3:0]   m_axi_pcie0_arregion,
    input  wire [17:0]  m_axi_pcie0_aruser,
    input  wire         m_axi_pcie0_arvalid,
    output wire         m_axi_pcie0_arready,
    output wire [511:0] m_axi_pcie0_rdata,
    output wire [1:0]   m_axi_pcie0_rid,
    output wire [1:0]   m_axi_pcie0_rresp,
    output wire         m_axi_pcie0_rlast,
    output wire         m_axi_pcie0_rvalid,
    input  wire         m_axi_pcie0_rready,

    // PCIE0 H2C stream (BD master → terminated here)
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

    // PCIE0 C2H completion write-back (terminated here)
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

    // PCIE0 descriptor credit in (terminated here)
    output wire [15:0]  dma0_dsc_crdt_in_0_crdt,
    output wire         dma0_dsc_crdt_in_0_dir,
    output wire         dma0_dsc_crdt_in_0_fence,
    output wire [11:0]  dma0_dsc_crdt_in_0_qid,
    output wire         dma0_dsc_crdt_in_0_valid,
    input  wire         dma0_dsc_crdt_in_0_rdy,

    // PCIE0 queue status output (terminated here)
    input  wire [63:0]  dma0_qsts_out_0_data,
    input  wire [7:0]   dma0_qsts_out_0_op,
    input  wire [2:0]   dma0_qsts_out_0_port_id,
    input  wire [12:0]  dma0_qsts_out_0_qid,
    input  wire         dma0_qsts_out_0_vld,
    output wire         dma0_qsts_out_0_rdy,

    // PCIE0 traffic manager descriptor status (terminated here)
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

    // PCIE0 user interrupt (terminated here)
    output wire [10:0]  dma0_usr_irq_0_vec,
    output wire [12:0]  dma0_usr_irq_0_fnc,
    output wire         dma0_usr_irq_0_valid,
    input  wire         dma0_usr_irq_0_ack,
    input  wire         dma0_usr_irq_0_fail,

    // PCIE0 function level reset (terminated here)
    input  wire [12:0]  dma0_usr_flr_0_fnc,
    input  wire         dma0_usr_flr_0_set,
    output wire         dma0_usr_flr_0_clear,
    output wire [12:0]  dma0_usr_flr_0_done_fnc,
    output wire         dma0_usr_flr_0_done_vld,

    // AXI4-L controller output — driven from PCIE0 BAR2
    // (axil_if.aclk is driven from clk_pl0_100mhz)
    axi4l_intf.controller axil_if
);

    // =========================================================================
    // PCIE0 BAR2 — AXI4 (512-bit) → AXI4-L → axil_if
    //
    // The NoC delivers PCIE0 BAR2 transactions as wide AXI4.  The byte lane
    // within the 512-bit beat is selected by AxADDR[5:2] (AxSIZE signals the
    // actual transfer width).  axi4l_from_axi4_adapter extracts the active
    // 32-bit word and drives the downstream AXI4-L register fabric.
    // =========================================================================
    axi4l_intf axil_if__m_axi_pcie0_aclk ();

    axi4_intf #(
        .DATA_BYTE_WID ( 64 ),
        .ADDR_WID      ( 64 ),
        .ID_WID        ( 2  ),
        .USER_WID      ( 18 )
    ) pcie0_axi4_if (.aclk(m_axi_pcie0_aclk));

    axi4_intf_from_signals #(
        .DATA_BYTE_WID ( 64 ),
        .ADDR_WID      ( 64 ),
        .ID_WID        ( 2  ),
        .USER_WID      ( 18 )
    ) i_pcie0_from_signals (
        .aclk     ( m_axi_pcie0_aclk      ),
        .awid     ( m_axi_pcie0_awid      ),
        .awaddr   ( m_axi_pcie0_awaddr    ),
        .awlen    ( m_axi_pcie0_awlen     ),
        .awsize   ( m_axi_pcie0_awsize    ),
        .awburst  ( m_axi_pcie0_awburst   ),
        .awlock   ( m_axi_pcie0_awlock    ),
        .awcache  ( m_axi_pcie0_awcache   ),
        .awprot   ( m_axi_pcie0_awprot    ),
        .awqos    ( m_axi_pcie0_awqos     ),
        .awregion ( m_axi_pcie0_awregion  ),
        .awuser   ( m_axi_pcie0_awuser    ),
        .awvalid  ( m_axi_pcie0_awvalid   ),
        .awready  ( m_axi_pcie0_awready   ),
        .wdata    ( m_axi_pcie0_wdata     ),
        .wstrb    ( m_axi_pcie0_wstrb     ),
        .wlast    ( m_axi_pcie0_wlast     ),
        .wuser    ( '0                    ),
        .wvalid   ( m_axi_pcie0_wvalid    ),
        .wready   ( m_axi_pcie0_wready    ),
        .bid      ( m_axi_pcie0_bid       ),
        .bresp    ( m_axi_pcie0_bresp     ),
        .buser    (                       ),
        .bvalid   ( m_axi_pcie0_bvalid    ),
        .bready   ( m_axi_pcie0_bready    ),
        .arid     ( m_axi_pcie0_arid      ),
        .araddr   ( m_axi_pcie0_araddr    ),
        .arlen    ( m_axi_pcie0_arlen     ),
        .arsize   ( m_axi_pcie0_arsize    ),
        .arburst  ( m_axi_pcie0_arburst   ),
        .arlock   ( m_axi_pcie0_arlock    ),
        .arcache  ( m_axi_pcie0_arcache   ),
        .arprot   ( m_axi_pcie0_arprot    ),
        .arqos    ( m_axi_pcie0_arqos     ),
        .arregion ( m_axi_pcie0_arregion  ),
        .aruser   ( m_axi_pcie0_aruser    ),
        .arvalid  ( m_axi_pcie0_arvalid   ),
        .arready  ( m_axi_pcie0_arready   ),
        .rid      ( m_axi_pcie0_rid       ),
        .rdata    ( m_axi_pcie0_rdata     ),
        .rresp    ( m_axi_pcie0_rresp     ),
        .rlast    ( m_axi_pcie0_rlast     ),
        .ruser    (                       ),
        .rvalid   ( m_axi_pcie0_rvalid    ),
        .rready   ( m_axi_pcie0_rready    ),
        .axi4_if  ( pcie0_axi4_if         )
    );

    axi4l_from_axi4_adapter #(
        .DATA_BYTE_WID ( 64 ),
        .ADDR_WID      ( 64 ),
        .ID_WID        ( 2  ),
        .USER_WID      ( 18 )
    ) i_pcie0_axi4l_from_axi4 (
        .aclk    ( m_axi_pcie0_aclk ),
        .aresetn ( m_axi_pcie0_aresetn ),
        .axi4_if ( pcie0_axi4_if ),
        .axi4l_if( axil_if__m_axi_pcie0_aclk )
    );

    axi4l_intf_cdc i_axi4l_intf_cdc (
        .axi4l_if_from_controller ( axil_if__m_axi_pcie0_aclk ),
        .clk_to_peripheral        ( clk_pl0_100mhz ),
        .axi4l_if_to_peripheral   ( axil_if )
    );

    // =========================================================================
    // PCIE0 DMA interface termination
    //
    // H2C is consumed (tready=1). C2H, completions, and all control sidebands
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

    // Signal naming adaptation — AVED-specific names → functional shell names
    assign sys_clk     = clk_pl0_100mhz;
    assign pcie_clk    = m_axi_pcie0_aclk;
    assign pci_rstn_in = m_axi_pcie0_aresetn;

endmodule : xilinx_aved_adapter
