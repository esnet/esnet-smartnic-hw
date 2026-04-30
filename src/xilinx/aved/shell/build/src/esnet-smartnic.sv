module esnet_smartnic
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    `include "xilinx_aved_io.svh"
);
    // Imports
    import shell_pkg::*;

    // Signals
    `include "xilinx_aved_app.svh"

    wire logic clk;
    wire logic srst;
    wire logic mgmt_clk;
    wire logic mgmt_srst;
    wire logic clk_100mhz;

    wire shell_pkg::shell_to_core_t shell_to_core;
    wire shell_pkg::core_to_shell_t core_to_shell;

    // Interfaces
    xilinx_aved_app_intf app_if ();

    // AVED top-level
    // NOTE: for compatibility with AVED constraints, this instance must
    //       be at the first level of hierarchy and be named `top_i`
    xilinx_aved top_i (
        .*
    );

    // Convert AVED application interface signals to interfaces
    xilinx_aved_adapter i_xilinx_aved_adapter (
        .*
    );

    // Adapt AVED application interface to standard ESnet shell-core boundary
    xilinx_aved_shell_adapter #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_aved_shell_adapter (
        .*
    );

    // Application core
    core i_core (
        .*
    );

endmodule : esnet_smartnic

