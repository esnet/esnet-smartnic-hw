module esnet_shell
    import xilinx_alveo_au250_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    `include "xilinx_alveo_au250_io.svh"
);
    xilinx_alveo_hw_intf #(.NUM_QSFP(NUM_QSFP), .PCIE_LINK_WID(PCIE_LINK_WID)) alveo_hw_if ();

    shell_intf shell_if ();

    xilinx_alveo_au250 i_xilinx_au250 (.*);

    xilinx_alveo_usplus_shell #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo_usplus_shell (
        .alveo_hw_if,
        .shell_if
    );

    core i_core (
        .shell_if
    );

endmodule : esnet_shell
