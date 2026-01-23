module xilinx_cms_sn_fetch_fsm (
  input logic              cms_clk,
  input logic              cms_srst,
  // From controller
  axi4l_intf.peripheral    axil_from_controller,
  // To CMS
  axi4l_intf.controller    axil_to_cms,
  // Card Serial Number Info
  output logic             card_sn_vld,
  output logic [0:15][7:0] card_sn,
  output logic [7:0]       card_sn_len,
  // Error status
  output logic             error_boot_timeout,
  output logic             error_bad_axil_transaction,
  output logic             error_card_info_length,
  output logic             error_bad_info_parse
);

  localparam int CMS_ADDR_WID = $clog2(256*1024); // 256kB

  logic [CMS_ADDR_WID-1:0] m_awaddr;
  logic [CMS_ADDR_WID-1:0] m_araddr;

  cms_sn_fetch_fsm      i_cms_sn_fetch_fsm (
    .aclk               ( cms_clk ),
    .aresetn            ( !cms_srst ),
    .s_axi_ctrl_AWVALID ( axil_from_controller.awvalid ),
    .s_axi_ctrl_AWREADY ( axil_from_controller.awready ),
    .s_axi_ctrl_AWADDR  ( axil_from_controller.awaddr[CMS_ADDR_WID-1:0] ),
    .s_axi_ctrl_AWPROT  ( axil_from_controller.awprot ),
    .s_axi_ctrl_WVALID  ( axil_from_controller.wvalid ),
    .s_axi_ctrl_WREADY  ( axil_from_controller.wready ),
    .s_axi_ctrl_WDATA   ( axil_from_controller.wdata ),
    .s_axi_ctrl_WSTRB   ( axil_from_controller.wstrb ),
    .s_axi_ctrl_BVALID  ( axil_from_controller.bvalid ),
    .s_axi_ctrl_BREADY  ( axil_from_controller.bready ),
    .s_axi_ctrl_BRESP   ( axil_from_controller.bresp ),
    .s_axi_ctrl_ARVALID ( axil_from_controller.arvalid ),
    .s_axi_ctrl_ARREADY ( axil_from_controller.arready ),
    .s_axi_ctrl_ARADDR  ( axil_from_controller.araddr[CMS_ADDR_WID-1:0] ),
    .s_axi_ctrl_ARPROT  ( axil_from_controller.arprot ),
    .s_axi_ctrl_RVALID  ( axil_from_controller.rvalid ),
    .s_axi_ctrl_RREADY  ( axil_from_controller.rready ),
    .s_axi_ctrl_RDATA   ( axil_from_controller.rdata ),
    .s_axi_ctrl_RRESP   ( axil_from_controller.rresp ),
    .m_axi_ctrl_AWVALID ( axil_to_cms.awvalid ),
    .m_axi_ctrl_AWREADY ( axil_to_cms.awready ),
    .m_axi_ctrl_AWADDR  ( m_awaddr ),
    .m_axi_ctrl_AWPROT  ( axil_to_cms.awprot ),
    .m_axi_ctrl_WVALID  ( axil_to_cms.wvalid ),
    .m_axi_ctrl_WREADY  ( axil_to_cms.wready ),
    .m_axi_ctrl_WDATA   ( axil_to_cms.wdata ),
    .m_axi_ctrl_WSTRB   ( axil_to_cms.wstrb ),
    .m_axi_ctrl_BVALID  ( axil_to_cms.bvalid ),
    .m_axi_ctrl_BREADY  ( axil_to_cms.bready ),
    .m_axi_ctrl_BRESP   ( axil_to_cms.bresp ),
    .m_axi_ctrl_ARVALID ( axil_to_cms.arvalid ),
    .m_axi_ctrl_ARREADY ( axil_to_cms.arready ),
    .m_axi_ctrl_ARADDR  ( m_araddr ),
    .m_axi_ctrl_ARPROT  ( axil_to_cms.arprot ),
    .m_axi_ctrl_RVALID  ( axil_to_cms.rvalid ),
    .m_axi_ctrl_RREADY  ( axil_to_cms.rready ),
    .m_axi_ctrl_RDATA   ( axil_to_cms.rdata ),
    .m_axi_ctrl_RRESP   ( axil_to_cms.rresp ),
    .*
  );

  assign axil_to_cms.awaddr = {'0, m_awaddr};
  assign axil_to_cms.araddr = {'0, m_araddr};

  assign axil_to_cms.aclk = axil_from_controller.aclk;
  assign axil_to_cms.aresetn = axil_from_controller.aresetn;

endmodule :  xilinx_cms_sn_fetch_fsm