// AXI-Lite access to configuration flash through the IP's internal STARTUP.
// Both IP clocks use axil_if.aclk; SPI SCK is half that frequency.
module xilinx_qspi (
    axi4l_intf.peripheral axil_if,
    output logic          irq
);
    initial begin
        std_pkg::param_check(axil_if.DATA_WID, 32, "axil_if.DATA_WID");
        std_pkg::param_check_gt(axil_if.ADDR_WID, 6, "axil_if.ADDR_WID");
    end

    xilinx_axi_quad_spi i_xilinx_axi_quad_spi (
        .ext_spi_clk   ( axil_if.aclk      ),
        .s_axi_aclk    ( axil_if.aclk      ),
        .s_axi_aresetn ( axil_if.aresetn   ),
        .s_axi_awaddr  ( axil_if.awaddr[6:0] ),
        .s_axi_awvalid ( axil_if.awvalid   ),
        .s_axi_awready ( axil_if.awready   ),
        .s_axi_wdata   ( axil_if.wdata     ),
        .s_axi_wstrb   ( axil_if.wstrb     ),
        .s_axi_wvalid  ( axil_if.wvalid    ),
        .s_axi_wready  ( axil_if.wready    ),
        .s_axi_bresp   ( axil_if.bresp     ),
        .s_axi_bvalid  ( axil_if.bvalid    ),
        .s_axi_bready  ( axil_if.bready    ),
        .s_axi_araddr  ( axil_if.araddr[6:0] ),
        .s_axi_arvalid ( axil_if.arvalid   ),
        .s_axi_arready ( axil_if.arready   ),
        .s_axi_rdata   ( axil_if.rdata     ),
        .s_axi_rresp   ( axil_if.rresp     ),
        .s_axi_rvalid  ( axil_if.rvalid    ),
        .s_axi_rready  ( axil_if.rready    ),
        .ip2intc_irpt  ( irq               ),

        // Drive CCLK from SPI while leaving device-wide controls inactive.
        .gsr           ( 1'b0 ),
        .gts           ( 1'b0 ),
        .keyclearb     ( 1'b1 ),
        .usrcclkts     ( 1'b0 ),
        .usrdoneo      ( 1'b1 ),
        .usrdonets     ( 1'b1 ),
        .cfgclk        ( ),
        .cfgmclk       ( ),
        .eos           ( ),
        .preq          ( )
    );

endmodule : xilinx_qspi
