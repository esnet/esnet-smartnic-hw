// Application core (stub version)
// (used for OOC simulation of shell)
module core 
    import shell_pkg::*;
(
    // Clock/reset
    input  wire logic clk,
    input  wire logic srst,

    input  wire logic mgmt_clk,
    input  wire logic mgmt_srst,

    input  wire logic clk_100mhz,

    // Shell interface
    input  wire logic [SHELL_TO_CORE_WID-1:0] shell_to_core,
    output wire logic [CORE_TO_SHELL_WID-1:0] core_to_shell
);
    // Signals
    axi4l_intf axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_WID(CMAC_AXIS_TID_WID), .TDEST_WID(CMAC_AXIS_TDEST_WID), .TUSER_WID(CMAC_AXIS_TUSER_WID)) axis_cmac_rx [NUM_CMAC] (.aclk(clk), .aresetn(!srst));
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TID_WID(CMAC_AXIS_TID_WID), .TDEST_WID(CMAC_AXIS_TDEST_WID), .TUSER_WID(CMAC_AXIS_TUSER_WID)) axis_cmac_tx [NUM_CMAC] (.aclk(clk), .aresetn(!srst));

    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_h2c (.aclk(clk), .aresetn(!srst));
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_WID(DMA_ST_AXIS_TID_WID), .TDEST_WID(DMA_ST_AXIS_TDEST_WID), .TUSER_WID(DMA_ST_AXIS_TUSER_WID)) axis_c2h (.aclk(clk), .aresetn(!srst));

    // Convert flat signal representation to interfaces
    shell_adapter__core i_shell_adapter__core (.*);

    // Terminate interfaces
    // -- AXI-L
    axi4l_intf_peripheral_term i_axi4l_intf_peripheral_term (.axi4l_if (axil_if));

    // -- CMAC
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            axi4s_intf_tx_term i_axi4s_intf_tx_term__cmac_rx (.to_rx   (axis_cmac_rx[g_cmac]));
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__cmac_tx (.from_tx (axis_cmac_tx[g_cmac]));
        end : g__cmac
    endgenerate

    // -- H2C
    axi4s_intf_tx_term i_axi4s_intf_tx_term__h2c (.to_rx   (axis_h2c));
    axi4s_intf_rx_term i_axi4s_intf_rx_sink__c2h (.from_rx (axis_c2h));

endmodule : core
