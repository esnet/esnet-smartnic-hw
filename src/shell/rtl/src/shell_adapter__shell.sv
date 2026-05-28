module shell_adapter__shell
    import shell_pkg::*;
#(
    parameter int NUM_PORTS = 2
) (
    shell_intf.shell shell_if,

    axi4l_intf.peripheral axil_if,

    axi4s_intf.rx axis_port_rx [NUM_PORTS],
    axi4s_intf.tx axis_port_tx [NUM_PORTS],

    axi4s_intf.rx axis_h2c,
    axi4s_intf.tx axis_c2h
);
    // AXI-L
    axi4l_intf_to_signals #(
        .ADDR_WID ( shell_if.AXIL_ADDR_WID )
    ) i_axi4l_intf_to_signals (
        .aclk    (),
        .aresetn (),
        .awvalid ( shell_if.axil_awvalid ),
        .awready ( shell_if.axil_awready ),
        .awaddr  ( shell_if.axil_awaddr  ),
        .awprot  ( shell_if.axil_awprot  ),
        .wvalid  ( shell_if.axil_wvalid  ),
        .wready  ( shell_if.axil_wready  ),
        .wdata   ( shell_if.axil_wdata   ),
        .wstrb   ( shell_if.axil_wstrb   ),
        .bvalid  ( shell_if.axil_bvalid  ),
        .bready  ( shell_if.axil_bready  ),
        .bresp   ( shell_if.axil_bresp   ),
        .arvalid ( shell_if.axil_arvalid ),
        .arready ( shell_if.axil_arready ),
        .araddr  ( shell_if.axil_araddr  ),
        .arprot  ( shell_if.axil_arprot  ),
        .rvalid  ( shell_if.axil_rvalid  ),
        .rready  ( shell_if.axil_rready  ),
        .rdata   ( shell_if.axil_rdata   ),
        .rresp   ( shell_if.axil_rresp   ),
        .axi4l_if( axil_if )
    );

    // Network ports
    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            axi4s_intf_to_signals #(
                .DATA_BYTE_WID ( shell_if.PORT_DATA_BYTE_WID ),
                .TID_WID       ( PORT_AXIS_TID_WID  ),
                .TDEST_WID     ( PORT_AXIS_TDEST_WID ),
                .TUSER_WID     ( PORT_AXIS_TUSER_WID )
            ) i_axi4s_intf_to_signals__port_rx (
                .tvalid   ( shell_if.port_rx_tvalid[g_port] ),
                .tready   ( shell_if.port_rx_tready[g_port] ),
                .tdata    ( shell_if.port_rx_tdata [g_port] ),
                .tkeep    ( shell_if.port_rx_tkeep [g_port] ),
                .tlast    ( shell_if.port_rx_tlast [g_port] ),
                .tid      ( shell_if.port_rx_tid   [g_port] ),
                .tdest    ( shell_if.port_rx_tdest [g_port] ),
                .tuser    ( shell_if.port_rx_tuser [g_port] ),
                .axi4s_if ( axis_port_rx[g_port] )
            );

            axi4s_intf_from_signals #(
                .DATA_BYTE_WID ( shell_if.PORT_DATA_BYTE_WID ),
                .TID_WID       ( PORT_AXIS_TID_WID  ),
                .TDEST_WID     ( PORT_AXIS_TDEST_WID ),
                .TUSER_WID     ( PORT_AXIS_TUSER_WID )
            ) i_axi4s_intf_from_signals__port_tx (
                .tvalid   ( shell_if.port_tx_tvalid[g_port] ),
                .tready   ( shell_if.port_tx_tready[g_port] ),
                .tdata    ( shell_if.port_tx_tdata [g_port] ),
                .tkeep    ( shell_if.port_tx_tkeep [g_port] ),
                .tlast    ( shell_if.port_tx_tlast [g_port] ),
                .tid      ( shell_if.port_tx_tid   [g_port] ),
                .tdest    ( shell_if.port_tx_tdest [g_port] ),
                .tuser    ( shell_if.port_tx_tuser [g_port] ),
                .axi4s_if ( axis_port_tx[g_port] )
            );
        end
    endgenerate

    // H2C
    axi4s_intf_to_signals #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_intf_to_signals__h2c (
        .tvalid   ( shell_if.h2c_tvalid ),
        .tready   ( shell_if.h2c_tready ),
        .tdata    ( shell_if.h2c_tdata  ),
        .tkeep    ( shell_if.h2c_tkeep  ),
        .tlast    ( shell_if.h2c_tlast  ),
        .tid      ( shell_if.h2c_tid    ),
        .tdest    ( shell_if.h2c_tdest  ),
        .tuser    ( shell_if.h2c_tuser  ),
        .axi4s_if ( axis_h2c )
    );

    // C2H
    axi4s_intf_from_signals #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_intf_from_signals__c2h (
        .tvalid   ( shell_if.c2h_tvalid ),
        .tready   ( shell_if.c2h_tready ),
        .tdata    ( shell_if.c2h_tdata  ),
        .tkeep    ( shell_if.c2h_tkeep  ),
        .tlast    ( shell_if.c2h_tlast  ),
        .tid      ( shell_if.c2h_tid    ),
        .tdest    ( shell_if.c2h_tdest  ),
        .tuser    ( shell_if.c2h_tuser  ),
        .axi4s_if ( axis_c2h )
    );

endmodule : shell_adapter__shell
