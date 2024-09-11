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

    // Interfaces
    xilinx_aved_app_intf app_if ();
    shell_intf shell_if ();

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

    // Adapt AVED application interface to standard ESnet shell interface
    xilinx_aved_shell_adapter #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_aved_shell (
        .*
    );

    // Application core
    core #() i_core (
        .*
    );

endmodule : esnet_smartnic

