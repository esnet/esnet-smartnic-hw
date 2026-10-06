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
    // Common Alveo shell — JTAG reset control and top-level hw/core decoder
    // =========================================================================
    // DMA streaming registers, decoded from the hw sub-space below.
    axi4l_intf #() axil_qdma_st ();

    // Core-domain DMA streams, produced by the common shell and consumed by
    // the axi4s conversion below.
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c_core (.clk(core_clk));

    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h_core (.clk(core_clk));

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
        .pkt_h2c_core,
        .pkt_c2h_core
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
    // DMA streaming interfaces
    //
    // Both DMA directions meet xilinx_qdma_st_adapter as packet_intf in the
    // management clock domain (axil_top.aclk, 100 MHz); the crossing to and
    // from the QDMA clock happens in that module's packet FIFOs, so no CDC is
    // needed here.
    //
    // H2C converts straight to axi4s_intf, taking the QID from the packet
    // metadata and supplying the shell_pkg tid/tdest/tuser in the same step.
    // C2H adapts the metadata to xilinx_qdma_pkg types and then converts to
    // packet_intf.
    // =========================================================================

    // QDMA-typed C2H interface, management clock domain
    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .TID_WID       ( AXIS_TID_WID       ),
        .TDEST_WID     ( AXIS_TDEST_WID     ),
        .TUSER_WID     ( AXIS_TUSER_WID     )
    ) axis_c2h_cdc (.aclk(axil_top.aclk));

    // Shell-domain interfaces: shell_pkg-typed, management clock
    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( shell_if.DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID         ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID         )
    ) axis_h2c (.aclk(axil_top.aclk));

    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( shell_if.DMA_ST_AXIS_TID_WID  ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID         ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID         )
    ) axis_c2h (.aclk(axil_top.aclk));

    // H2C: packet_intf → axi4s_intf. The QID arrives in the packet metadata
    // and becomes tid; tdest and tuser have no H2C source and are tied off.
    logic [shell_if.DMA_ST_AXIS_TID_WID-1:0] h2c_shell_tid;
    shell_pkg::dma_st_axis_tdest_t h2c_shell_tdest;
    shell_pkg::dma_st_axis_tuser_t h2c_shell_tuser;

    assign h2c_shell_tid               = pkt_h2c_core.meta;
    assign h2c_shell_tdest.unused      = 1'b0;
    assign h2c_shell_tuser.rss_enable  = 1'b0;
    assign h2c_shell_tuser.rss_entropy = '0;

    axi4s_from_packet_adapter #(
        .TID_WID   ( shell_if.DMA_ST_AXIS_TID_WID ),
        .TDEST_WID ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID ( DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_from_packet_adapter__h2c (
        .srst      ( ~axil_top.aresetn ),
        .packet_if ( pkt_h2c_core    ),
        .axis_if   ( axis_h2c        ),
        .tid       ( h2c_shell_tid   ),
        .tdest     ( h2c_shell_tdest ),
        .tuser     ( h2c_shell_tuser )
    );

    // C2H metadata adaptation: shell_pkg types → QDMA types
    logic [shell_if.DMA_ST_AXIS_TID_WID-1:0] c2h_shell_tid;
    xilinx_qdma_pkg::axis_tid_t   __c2h_qdma_tid;
    xilinx_qdma_pkg::axis_tdest_t __c2h_qdma_tdest;
    xilinx_qdma_pkg::axis_tuser_t __c2h_qdma_tuser;

    assign c2h_shell_tid        = axis_c2h.tid;
    assign __c2h_qdma_tid.qid  = c2h_shell_tid;
    assign __c2h_qdma_tdest.unused = 1'b0;
    assign __c2h_qdma_tuser.err    = 1'b0;

    axi4s_intf_set_meta #(
        .TID_WID   ( AXIS_TID_WID   ),
        .TDEST_WID ( AXIS_TDEST_WID ),
        .TUSER_WID ( AXIS_TUSER_WID )
    ) i_axi4s_intf_set_meta__c2h (
        .from_tx ( axis_c2h      ),
        .to_rx   ( axis_c2h_cdc  ),
        .tid     ( __c2h_qdma_tid  ),
        .tdest   ( __c2h_qdma_tdest ),
        .tuser   ( __c2h_qdma_tuser )
    );

    // C2H axi4s_intf → packet_intf.  The QID moves from tid into the packet
    // metadata field, where xilinx_qdma_st_adapter picks it up for ctrl_qid
    // and the completion.
    axi4s_to_packet_adapter #(
        .META_WID ( xilinx_qdma_pkg::QID_WID )
    ) i_axi4s_to_packet_adapter__c2h (
        .srst      ( ~axil_top.aresetn  ),
        .axis_if   ( axis_c2h_cdc       ),
        .packet_if ( pkt_c2h_core       ),
        .meta      ( __c2h_qdma_tid.qid ),
        .err       ( 1'b0               )
    );

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
