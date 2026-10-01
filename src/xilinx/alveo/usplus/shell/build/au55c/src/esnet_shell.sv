module esnet_shell
    import xilinx_alveo_au55c_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    `include "xilinx_alveo_au55c_io.svh"
);
    xilinx_alveo_hw_intf #(.NUM_QSFP(NUM_QSFP), .PCIE_LINK_WID(PCIE_LINK_WID)) alveo_hw_if ();

    // UltraScale+ QDMA carries an 11-bit queue ID; sizing the boundary from the
    // platform package keeps the core's qid field matched to the hardware.
    shell_intf #(
        .DMA_ST_QUEUES ( xilinx_alveo_usplus_pkg::DMA_ST_QUEUES )
    ) shell_if ();

    xilinx_alveo_au55c i_xilinx_au55c (.*);

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
