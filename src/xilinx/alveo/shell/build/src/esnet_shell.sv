module esnet_shell
`ifdef __au280__
    import xilinx_alveo_au280_pkg::*;
`elsif __au250__
    import xilinx_alveo_au250_pkg::*;
`elsif __au55c__
    import xilinx_alveo_au55c_pkg::*;
`endif
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
`ifdef __au280__
    `include "xilinx_alveo_au280_io.svh"
`elsif __au250__
    `include "xilinx_alveo_au250_io.svh"
`elsif __au55c__
    `include "xilinx_alveo_au55c_io.svh"
`endif
);
    // Interfaces
    xilinx_alveo_hw_intf #(.NUM_QSFP(NUM_QSFP), .PCIE_LINK_WID(PCIE_LINK_WID)) alveo_hw_if ();

    // Signals
    wire logic clk;
    wire logic srst;
    wire logic mgmt_clk;
    wire logic mgmt_srst;
    wire logic clk_100mhz;

    wire shell_pkg::shell_to_core_t shell_to_core;
    wire shell_pkg::core_to_shell_t core_to_shell;

    // Physical (hardware) layer
`ifdef __au280__
    xilinx_alveo_au280 i_xilinx_au280 (
`elsif __au250__
    xilinx_alveo_au250 i_xilinx_au250 (
`elsif __au55c__
    xilinx_alveo_au55c i_xilinx_au55c (
`endif
        .*
    );

    // (Common) shell layer
    xilinx_alveo_shell #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo_shell (
        .*
    );

    // Application core
    core i_core (.*);

endmodule : esnet_shell

