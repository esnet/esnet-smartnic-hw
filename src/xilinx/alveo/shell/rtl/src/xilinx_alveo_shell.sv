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
    // Interfaces
    // =========================================================================
    axi4l_intf #() axil_top ();
    axi4l_intf #() axil_hw ();

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
        .axis_cmac_rx ( shell_if.axis_cmac_rx ),
        .axis_cmac_tx ( shell_if.axis_cmac_tx ),
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

