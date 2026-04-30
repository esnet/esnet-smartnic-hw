module esnet_shell
    import xilinx_alveo_au250_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    `include "xilinx_alveo_au250_io.svh"
);
    xilinx_alveo_hw_intf #(.NUM_QSFP(NUM_QSFP), .PCIE_LINK_WID(PCIE_LINK_WID)) alveo_hw_if ();

    wire logic clk;
    wire logic srst;
    wire logic mgmt_clk;
    wire logic mgmt_srst;
    wire logic clk_100mhz;

    wire shell_pkg::shell_to_core_t shell_to_core;
    wire shell_pkg::core_to_shell_t core_to_shell;

    xilinx_alveo_au250 i_xilinx_au250 (.*);

    xilinx_alveo_shell #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo_shell (.*);

    core i_core (.*);

endmodule : esnet_shell
