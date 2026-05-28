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
    axi4l_intf axil_if ();

    shell_intf shell_if ();

    // AVED top-level
    // NOTE: for compatibility with AVED constraints, this instance must
    //       be at the first level of hierarchy and be named `top_i`
    xilinx_aved top_i (
        .*
    );

    // SMBus tristate: bridge BD i/o/t split signals to physical inout pins
    assign smbus_0_scl_i  = smbus_0_scl_io;
    assign smbus_0_scl_io = smbus_0_scl_t ? 1'bz : smbus_0_scl_o;
    assign smbus_0_sda_i  = smbus_0_sda_io;
    assign smbus_0_sda_io = smbus_0_sda_t ? 1'bz : smbus_0_sda_o;

    // Convert AVED application interface signals to interfaces
    xilinx_aved_adapter i_xilinx_aved_adapter (
        .*
    );

    // Adapt AVED management AXI4-Lite to standard ESnet shell-core boundary
    xilinx_aved_shell_adapter #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_aved_shell_adapter (
        .axil_if,
        .shell_if
    );

    // Application core
    core i_core (
        .shell_if
    );

endmodule : esnet_smartnic
