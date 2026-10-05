module esnet_smartnic
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    `include "xilinx_aved_io.svh"
);
    // Imports
    import shell_pkg::*;
    import xilinx_qdma_pkg::*;

    // Signals from AVED BD wrapper and adapter
    `include "xilinx_aved_app.svh"

    // Signals between xilinx_aved_adapter and xilinx_alveo_versal_shell
    wire        sys_clk_100mhz;
    wire        pci_rstn_in;
    wire        pci_rstn;

    // Interfaces
    axi4l_intf axil_if ();
    axi4l_intf axil_debug_if ();

    // QDMA streaming adapter registers: decoded in the shell, consumed by the
    // adapter, so the sub-space runs back down into xilinx_aved_adapter.
    axi4l_intf axil_qdma ();

    // CPM5 carries a 12-bit queue ID; sizing the boundary from the platform
    // package keeps the core's qid field matched to what the hardware addresses.
    shell_intf #(
        .DMA_ST_QUEUES ( xilinx_alveo_versal_pkg::DMA_ST_QUEUES )
    ) shell_if ();

    // Core clock. The 100 MHz management clock stands in until a 322 MHz source
    // arrives with DCMAC; the shell likewise drives the core at this rate.
    wire core_clk = clk_pl0_100mhz;

    // DMA interfaces between adapter and shell, in the core clock domain; the
    // adapter's packet FIFOs cross them to and from the QDMA clock.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c_dma (.clk(core_clk));

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h_dma (.clk(core_clk));

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
        .*,
        .core_clk  ( core_clk     ),
        .core_srst ( ~axil_if.aresetn ),
        .axil_qdma ( axil_qdma    ),
        .pkt_h2c   ( pkt_h2c_dma  ),
        .pkt_c2h   ( pkt_c2h_dma  )
    );

    // AXI-L debug core: ILA + VIO between adapter and shell adapter
    xilinx_aved_debug i_xilinx_aved_debug (
        .axil_if_from_adapter ( axil_if       ),
        .axil_if_to_shell     ( axil_debug_if )
    );

    // Versal Alveo shell — PCIe reset control and shell-core boundary
    xilinx_alveo_versal_shell #(
        .BUILD_TIMESTAMP ( BUILD_TIMESTAMP )
    ) i_xilinx_alveo_versal_shell (
        .sys_clk_100mhz ( sys_clk_100mhz ),
        .pci_rstn_in    ( pci_rstn_in ),
        .pci_rstn       ( pci_rstn    ),
        .axil_top       ( axil_debug_if ),
        .pkt_h2c_dma    ( pkt_h2c_dma  ),
        .pkt_c2h_dma    ( pkt_c2h_dma  ),
        .axil_qdma      ( axil_qdma    ),
        .shell_if
    );

    // Application core
    core i_core (
        .shell_if
    );

endmodule : esnet_smartnic
