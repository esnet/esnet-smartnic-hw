// =========================================================================
// Xilinx Alveo shell
//
//   Implements ESnet standard shell on Xilinx Alveo architecture.
//
//   Supports a variety of hardware implementations (Alveo boards) using
//   abstract xilinx_alveo_hw_intf connection to physical layer.
//
//   Supports a variety of 'core' implementations (applications) using
//   abstract shell_intf connection to user logic.
//
// =========================================================================
module xilinx_alveo_shell
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // To/from physical layer (hardware)
    xilinx_alveo_hw_intf.alveo alveo_hw_if,
    // To/from core (application)
    shell_intf.shell           shell_if
);
    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_alveo_pkg::*;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() axil_top ();
    axi4l_intf #() axil_hw ();

    axi4s_intf #(.DATA_BYTE_WID (CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) __axis_cmac_rx [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID (CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) __axis_cmac_tx [NUM_CMAC] ();

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
    // Common Alveo core
    // =========================================================================
    
    xilinx_alveo #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo  (
        .alveo_hw_if,
        .clk          ( shell_if.clk ),
        .srst         ( shell_if.srst ),
        .clk_100mhz   ( shell_if.clk_100mhz ),
        .clk_125mhz   ( ),
        .clk_250mhz   ( ),
        .clk_333mhz   ( ),
        .axis_cmac_rx ( __axis_cmac_rx ),
        .axis_cmac_tx ( __axis_cmac_tx ),
        .axis_h2c     ( shell_if.axis_h2c ),
        .axis_c2h     ( shell_if.axis_c2h ),
        .axil_top,
        .axil_hw
    );

    // =========================================================================
    // Shell top-level decoder
    // =========================================================================
    shell_decoder i_shell_decoder (
        .axil_if      ( axil_top ),
        .hw_axil_if   ( axil_hw ),
        .core_axil_if ( shell_if.axil_if )
    );

endmodule : xilinx_alveo_shell

