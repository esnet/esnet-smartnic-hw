// Card management at 50 MHz. Firmware startup is controlled through AXI-Lite.
module xilinx_alveo_usplus_cms (
    axi4l_intf.peripheral axil_if,
    input  logic         satellite_uart_rxd,
    output logic         satellite_uart_txd,
    input  logic [3:0]   satellite_gpio,
    input  logic [6:0]   hbm_temp_1,
    input  logic [6:0]   hbm_temp_2,
    input  logic         hbm_cattrip,
    input  logic [1:0]   qsfp_modprsl,
    input  logic [1:0]   qsfp_intl,
    output logic [1:0]   qsfp_resetl,
    output logic [1:0]   qsfp_lpmode,
    output logic [1:0]   qsfp_modsell,
    output logic         irq
);
    initial begin
        std_pkg::param_check(axil_if.DATA_WID, 32, "axil_if.DATA_WID");
        std_pkg::param_check_gt(axil_if.ADDR_WID, 17, "axil_if.ADDR_WID");
    end

    xilinx_usplus_cms_subsystem i_xilinx_usplus_cms_subsystem (
        .aclk_ctrl          ( axil_if.aclk ),
        .aresetn_ctrl       ( axil_if.aresetn ),
        .s_axi_ctrl_awaddr  ( {14'b0, axil_if.awaddr[17:0]} ),
        .s_axi_ctrl_awprot  ( axil_if.awprot ),
        .s_axi_ctrl_awvalid ( axil_if.awvalid ),
        .s_axi_ctrl_awready ( axil_if.awready ),
        .s_axi_ctrl_wdata   ( axil_if.wdata ),
        .s_axi_ctrl_wstrb   ( axil_if.wstrb ),
        .s_axi_ctrl_wvalid  ( axil_if.wvalid ),
        .s_axi_ctrl_wready  ( axil_if.wready ),
        .s_axi_ctrl_bresp   ( axil_if.bresp ),
        .s_axi_ctrl_bvalid  ( axil_if.bvalid ),
        .s_axi_ctrl_bready  ( axil_if.bready ),
        .s_axi_ctrl_araddr  ( {14'b0, axil_if.araddr[17:0]} ),
        .s_axi_ctrl_arprot  ( axil_if.arprot ),
        .s_axi_ctrl_arvalid ( axil_if.arvalid ),
        .s_axi_ctrl_arready ( axil_if.arready ),
        .s_axi_ctrl_rdata   ( axil_if.rdata ),
        .s_axi_ctrl_rresp   ( axil_if.rresp ),
        .s_axi_ctrl_rvalid  ( axil_if.rvalid ),
        .s_axi_ctrl_rready  ( axil_if.rready ),
        .satellite_uart_rxd ( satellite_uart_rxd ),
        .satellite_uart_txd ( satellite_uart_txd ),
        .satellite_gpio     ( satellite_gpio ),
        .interrupt_host     ( irq ),
`ifdef XILINX_USPLUS_CMS_QSFP_IO
        .qsfp0_modprs_l ( qsfp_modprsl[0] ),
        .qsfp1_modprs_l ( qsfp_modprsl[1] ),
        .qsfp0_int_l    ( qsfp_intl[0] ),
        .qsfp1_int_l    ( qsfp_intl[1] ),
        .qsfp0_lpmode   ( qsfp_lpmode[0] ),
        .qsfp1_lpmode   ( qsfp_lpmode[1] ),
        .qsfp0_modsel_l ( qsfp_modsell[0] ),
        .qsfp1_modsel_l ( qsfp_modsell[1] ),
        .qsfp0_reset_l  ( qsfp_resetl[0] ),
        .qsfp1_reset_l  ( qsfp_resetl[1] )
`else
        .hbm_temp_1            ( hbm_temp_1 ),
        .hbm_temp_2            ( hbm_temp_2 ),
        .interrupt_hbm_cattrip ( hbm_cattrip )
`endif
    );

`ifndef XILINX_USPLUS_CMS_QSFP_IO
    assign qsfp_resetl = '1;
    assign qsfp_lpmode = '0;
    assign qsfp_modsell = '1;
`endif

endmodule : xilinx_alveo_usplus_cms
