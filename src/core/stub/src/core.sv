// Application core (stub version)
// (used for OOC simulation of shell)
module core
    import shell_pkg::*;
(
    shell_intf.core shell_if
);
    // Signals
    axi4l_intf axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_rx [NUM_PORTS] (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_tx [NUM_PORTS] (.aclk(shell_if.clk));

    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(shell_if.clk));
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(shell_if.clk));

    // Convert shell_intf to SV interfaces
    shell_adapter__core i_shell_adapter__core (
        .shell_if,
        .axil_if,
        .axis_port_rx,
        .axis_port_tx,
        .axis_h2c,
        .axis_c2h
    );

    // Terminate interfaces
    // -- AXI-L
    axi4l_intf_peripheral_term i_axi4l_intf_peripheral_term (.axi4l_if (axil_if));

    // -- Network ports
    // shell_adapter__core drives axis_port_rx (.tx) and receives axis_port_tx (.rx),
    // so the stub provides the complementary sides.
    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__port_rx (.from_tx (axis_port_rx[g_port]));
            axi4s_intf_tx_term i_axi4s_intf_tx_term__port_tx (.to_rx   (axis_port_tx[g_port]));
        end : g__port
    endgenerate

    // -- H2C/C2H
    // shell_adapter__core drives axis_h2c (.tx) and receives axis_c2h (.rx).
    axi4s_intf_rx_sink i_axi4s_intf_rx_sink__h2c (.from_tx (axis_h2c));
    axi4s_intf_tx_term i_axi4s_intf_tx_term__c2h (.to_rx   (axis_c2h));

endmodule : core
