// Application core (stub version)
// (used for OOC simulation of shell)
module core
    import shell_pkg::*;
(
    shell_intf.core shell_if
);
    // Signals
    logic clk;
    logic srst;
    logic mgmt_clk;
    logic mgmt_srst;
    logic clk_100mhz;
    logic port_clk  [shell_if.NUM_PORTS];
    logic port_srst [shell_if.NUM_PORTS];

    // Interfaces
    axi4l_intf axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(shell_if.PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_rx [shell_if.NUM_PORTS] (.aclk(clk));
    axi4s_intf #(.DATA_BYTE_WID(shell_if.PORT_DATA_BYTE_WID), .TID_WID(PORT_AXIS_TID_WID), .TDEST_WID(PORT_AXIS_TDEST_WID), .TUSER_WID(PORT_AXIS_TUSER_WID)) axis_port_tx [shell_if.NUM_PORTS] (.aclk(clk));

    axi4s_intf #(.DATA_BYTE_WID(shell_if.DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(clk));
    axi4s_intf #(.DATA_BYTE_WID(shell_if.DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(clk));

    // Convert shell_intf to SV interfaces
    shell_adapter__core i_shell_adapter__core (
        .shell_if,
        .clk,
        .srst,
        .mgmt_clk,
        .mgmt_srst,
        .clk_100mhz,
        .port_clk,
        .port_srst,
        .axil_if,
        .axis_port_rx,
        .axis_port_tx,
        .axis_h2c,
        .axis_c2h
    );

    // Register map
    core_reg_intf regs ();

    core_reg_blk i_core_reg_blk (
        .axil_if    (axil_if),
        .reg_blk_if (regs)
    );

    // id: read-only constant — holds INIT value, no hardware update
    assign regs.id_nxt_v = 1'b0;
    assign regs.id_nxt   = '0;

    // -- Network ports
    // shell_adapter__core drives axis_port_rx (.tx) and receives axis_port_tx (.rx),
    // so the stub provides the complementary sides.
    generate
        for (genvar g_port = 0; g_port < shell_if.NUM_PORTS; g_port++) begin : g__port
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__port_rx (.from_tx (axis_port_rx[g_port]));
            axi4s_intf_tx_term i_axi4s_intf_tx_term__port_tx (.to_rx   (axis_port_tx[g_port]));
        end : g__port
    endgenerate

    // -- H2C/C2H
    // shell_adapter__core drives axis_h2c (.tx) and receives axis_c2h (.rx).
    axi4s_intf_rx_sink i_axi4s_intf_rx_sink__h2c (.from_tx (axis_h2c));
    axi4s_intf_tx_term i_axi4s_intf_tx_term__c2h (.to_rx   (axis_c2h));

endmodule : core
