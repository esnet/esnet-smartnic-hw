// =========================================================================
// xilinx_alveo_versal_shell
//
// Versal-specific Alveo shell layer.  Sits between the AVED block design
// (via xilinx_aved_adapter) and the platform-agnostic ESnet shell-core
// boundary (shell_intf).
//
// Responsibilities:
//   - Instantiate xilinx_alveo_shell for common Alveo platform functionality:
//     JTAG VIO PCIe reset override and top-level hw/core AXI-L decoder.
//   - Terminate the hw AXI-L sub-space (no Versal hw registers yet).
//   - Pass the core AXI-L sub-space to the shell-core boundary (shell_intf).
//   - Terminate network port and DMA streaming interfaces pending
//     DCMAC and QDMA subsystem implementation.
// =========================================================================
module xilinx_alveo_versal_shell
    import shell_pkg::*;
    import xilinx_qdma_pkg::*;
#(
    parameter bit [31:0] BUILD_TIMESTAMP = 32'h0
) (
    // -------------------------------------------------------------------------
    // From/to Versal hardware layer
    // -------------------------------------------------------------------------
    // System clock — sourced from the PMC crystal oscillator via the CRP.
    // Independent of PCIe, HBM, and PS state; available immediately after
    // device power-on.
    input  wire logic       sys_clk_100mhz,

    // PCIe reset (JTAG VIO overrride interface)
    input  wire logic       pci_rstn_in, // Incoming hardware PCI reset (e.g. PERST#)
    output wire logic       pci_rstn,    // Outgoing PCI reset (includes JTAG override)

    // Management AXI4-Lite
    axi4l_intf.peripheral   axil_top,    // AXI-L interface from PCIe core

    // Core clock.  The common Alveo shell crosses the DMA streams into this
    // domain and hands them to the core.
    input  wire logic       core_clk,

    // DMA streams to/from xilinx_aved_adapter, in the PCIE0 (QDMA) clock
    // domain.  The crossing to core_clk happens in xilinx_alveo_shell.
    input  wire logic       dma_aclk,
    input  wire logic       dma_aresetn,
    packet_intf.rx          pkt_h2c_dma,  // H2C from CPM5 QDMA
    packet_intf.tx          pkt_c2h_dma,  // C2H to CPM5 QDMA
    output packet_pkg::size_t pkt_c2h_dma_size,

    // -------------------------------------------------------------------------
    // To/from application core — standard ESnet shell-core boundary
    // -------------------------------------------------------------------------
    shell_intf.shell        shell_if
);

    // =========================================================================
    // Interfaces for the hw/core AXI-L decoder outputs
    // =========================================================================
    axi4l_intf #() axil_hw   ();
    axi4l_intf #() axil_core ();

    // =========================================================================
    // DMA streaming interfaces
    //
    // xilinx_alveo_qdma_st, inside the common Alveo shell, crosses both
    // directions from the QDMA clock into the core clock domain and presents
    // them already converted to shell-typed axi4s, so they pass straight to
    // shell_adapter__shell below.
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( shell_if.DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID         ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID         )
    ) axis_h2c (.aclk(core_clk));

    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( shell_if.DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID         ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID         )
    ) axis_c2h (.aclk(core_clk));

    // =========================================================================
    // Common Alveo shell — JTAG reset control and top-level hw/core decoder
    // =========================================================================
    // DMA streaming registers, decoded from the hw sub-space below.
    axi4l_intf #() axil_qdma_st ();

    xilinx_alveo_shell #(
        .QID_WID ( QID_WID )
    ) i_xilinx_alveo_shell (
        .sys_clk_100mhz  ( sys_clk_100mhz ),
        .pci_rstn_in     ( pci_rstn_in     ),
        .pci_rstn_out    ( pci_rstn        ),
        .core_clk,
        .dma_aclk,
        .dma_aresetn,
        .axil_top,
        .axil_hw,
        .axil_core,
        .axil_qdma_st     ( axil_qdma_st ),
        .pkt_h2c_dma,
        .pkt_c2h_dma,
        .pkt_c2h_dma_size,
        .axis_h2c,
        .axis_c2h
    );

    // =========================================================================
    // Versal Alveo hw decoder
    // =========================================================================
    axi4l_intf #() axil_dcmac [2] ();

    xilinx_alveo_versal_decoder i_xilinx_alveo_versal_decoder (
        .axil_if        ( axil_hw       ),
        .dcmac0_axil_if ( axil_dcmac[0] ),
        .dcmac1_axil_if ( axil_dcmac[1] ),
        .qdma_axil_if   ( axil_qdma_st  )
    );

    // Terminate DCMAC AXI-L interfaces — pending DCMAC register map
    generate
        for (genvar g = 0; g < 2; g++) begin : g__dcmac
            axi4l_intf_peripheral_term i_axi4l_term__dcmac (.axi4l_if (axil_dcmac[g]));
        end : g__dcmac
    endgenerate

    // =========================================================================
    // Network port interfaces (CMAC) — terminated pending DCMAC wiring
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.PORT_DATA_BYTE_WID ),
        .TID_WID       ( PORT_AXIS_TID_WID           ),
        .TDEST_WID     ( PORT_AXIS_TDEST_WID          ),
        .TUSER_WID     ( PORT_AXIS_TUSER_WID          )
    ) axis_port_rx [shell_if.NUM_PORTS] (.aclk(axil_top.aclk));

    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.PORT_DATA_BYTE_WID ),
        .TID_WID       ( PORT_AXIS_TID_WID           ),
        .TDEST_WID     ( PORT_AXIS_TDEST_WID          ),
        .TUSER_WID     ( PORT_AXIS_TUSER_WID          )
    ) axis_port_tx [shell_if.NUM_PORTS] (.aclk(axil_top.aclk));

    generate
        for (genvar g_port = 0; g_port < shell_if.NUM_PORTS; g_port++) begin : g__port
            axi4s_intf_tx_term i_axi4s_intf_tx_term__port_rx (
                .to_rx ( axis_port_rx[g_port] )
            );
            axi4s_intf_rx_sink i_axi4s_intf_rx_sink__port_tx (
                .from_tx ( axis_port_tx[g_port] )
            );
        end : g__port
    endgenerate

    // =========================================================================
    // Convert SV interfaces to flat shell_intf representation.
    // Clock/reset are derived from axil_core which carries the management
    // clock/reset from the AXI4-L path (same aclk/aresetn as axil_if).
    // port_clk/port_srst use the same clock pending per-port clock support.
    // =========================================================================
    shell_adapter__shell i_shell_adapter__shell (
        .shell_if,
        .clk        ( axil_core.aclk    ),
        .srst       ( ~axil_core.aresetn ),
        .mgmt_clk   ( axil_core.aclk    ),
        .mgmt_srst  ( ~axil_core.aresetn ),
        .clk_100mhz ( sys_clk_100mhz ),
        .port_clk   ( '{default: axil_core.aclk}    ),
        .port_srst  ( '{default: ~axil_core.aresetn} ),
        .axil_if    ( axil_core ),
        .axis_port_rx,
        .axis_port_tx,
        .axis_h2c,
        .axis_c2h
    );

endmodule : xilinx_alveo_versal_shell
