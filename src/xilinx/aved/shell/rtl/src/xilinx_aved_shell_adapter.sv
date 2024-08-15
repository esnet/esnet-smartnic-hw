// =========================================================================
// Xilinx Alveo shell
//
//   Implements ESnet standard shell on Xilinx AVED architecture.
//
//   Supports a variety of 'core' implementations (applications) using
//   abstract shell_intf connection to user logic.
//
// =========================================================================
module xilinx_aved_shell_adapter
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // To/from hardware top-level (AVED)
    xilinx_aved_app_intf.app app_if,
    
    // To/from core (application)
    shell_intf.shell         shell_if
);
    // =========================================================================
    // Imports
    // =========================================================================
    import shell_pkg::*;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4s_intf #(.DATA_BYTE_WID (CMAC_DATA_BYTE_WID), .TUSER_T(cmac_rx_axis_tuser_t)) __axis_cmac_rx [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID (CMAC_DATA_BYTE_WID), .TUSER_T(cmac_tx_axis_tuser_t)) __axis_cmac_tx [NUM_CMAC] ();

    // Pack CMAC AXI-S interfaces into arrays
    axi4s_intf_connector i_axi4s_intf_connector_rx_0 (
        .axi4s_from_tx ( shell_if.axis_cmac0_rx ),
        .axi4s_to_rx   ( __axis_cmac_rx[0] )
    );
    axi4s_intf_connector i_axi4s_intf_connector_tx_0 (
        .axi4s_from_tx ( __axis_cmac_tx[0] ),
        .axi4s_to_rx   ( shell_if.axis_cmac0_tx )
    );
    axi4s_intf_connector i_axi4s_intf_connector_rx_1 (
        .axi4s_from_tx ( shell_if.axis_cmac1_rx ),
        .axi4s_to_rx   ( __axis_cmac_rx[1] )
    );
    axi4s_intf_connector i_axi4s_intf_connector_tx_1 (
        .axi4s_from_tx ( __axis_cmac_tx[1] ),
        .axi4s_to_rx   ( shell_if.axis_cmac1_tx )
    );

    // =========================================================================
    // Connect AVED interfaces to shell interface
    // =========================================================================
    axi4l_intf_connector (.axil_if_from_controller(app_if.axil_if), .axil_if_to_peripheral(shell_if.axil_if));

    // TEMP: terminate unused signals/interfaces
    assign shell_if.clk = app_if.clk;
    assign shell_if.srst = 1'b1;
    assign shell_if.clk_100mhz = 1'b0;

    generate
        for (genvar g_cmac_if = 0; g_cmac_if < shell_pkg::NUM_CMAC; g_cmac_if++) begin : g__cmac
            axi4s_intf_tx_term i_axi4s_intf_tx_term (.axi4s_if(__axis_cmac_rx[g_cmac_if]));
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink (.axi4s_if(__axis_cmac_tx[g_cmac_if]));
        end : g__cmac
        axi4s_intf_tx_term i_axi4s_intf_tx_term__h2c (.axi4s_if(shell_if.axis_h2c));
        axi4s_intf_rx_term i_axi4s_intf_rx_term__c2h (.axi4s_if(shell_if.axis_c2h));
    endgenerate

endmodule : xilinx_aved_shell_adapter

