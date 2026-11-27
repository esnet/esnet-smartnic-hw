module esnet_shell
    import xilinx_alveo_usplus_au280_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    `include "xilinx_alveo_usplus_au280_io.svh"
);
    `include "shell_build_info.svh"

    xilinx_alveo_usplus_hw_intf #(.NUM_QSFP(NUM_QSFP), .PCIE_LINK_WID(PCIE_LINK_WID)) alveo_hw_if ();

    shell_intf shell_if ();

    xilinx_alveo_usplus_au280 i_xilinx_alveo_usplus_au280 (.*);

    xilinx_alveo_usplus_shell #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP == 0 ? VPD_BUILD_TIMESTAMP : BUILD_TIMESTAMP ),
        .PRODUCT_ID(VPD_PRODUCT_ID), .APPLICATION_ID(VPD_APPLICATION_ID),
        .BUILD_ID(VPD_BUILD_ID), .BUILD_GIT_REPO(VPD_BUILD_GIT_REPO),
        .BUILD_GIT_HASH(VPD_BUILD_GIT_HASH), .BUILD_TIMESTAMP_STR(VPD_BUILD_TIMESTAMP_STR)
    ) i_xilinx_alveo_usplus_shell (
        .alveo_hw_if,
        .shell_if
    );

    core i_core (
        .shell_if
    );

endmodule : esnet_shell
