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

    // DMA streams from xilinx_aved_adapter (QDMA clock domain, ~250 MHz)
    axi4s_intf.rx           axis_h2c_dma, // H2C from CPM5 QDMA
    axi4s_intf.tx           axis_c2h_dma, // C2H to CPM5 QDMA

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
    xilinx_alveo_shell i_xilinx_alveo_shell (
        .sys_clk_100mhz  ( sys_clk_100mhz ),
        .pci_rstn_in     ( pci_rstn_in     ),
        .pci_rstn_out    ( pci_rstn        ),
        .axil_top,
        .axil_hw,
        .axil_core
    );

    // =========================================================================
    // Versal Alveo hw decoder
    // =========================================================================
    axi4l_intf #() axil_dcmac [2] ();

    xilinx_alveo_versal_decoder i_xilinx_alveo_versal_decoder (
        .axil_if        ( axil_hw       ),
        .dcmac0_axil_if ( axil_dcmac[0] ),
        .dcmac1_axil_if ( axil_dcmac[1] )
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
    // The CPM5 QDMA streams arrive in the QDMA clock domain (~250 MHz) via
    // axis_h2c_dma / axis_c2h_dma.  We:
    //   1. Cross to the management clock (axil_top.aclk, 100 MHz) using
    //      axi4s_pkt_fifo_async (store-and-forward, full-packet CDC).
    //   2. Adapt metadata (tid/tuser) from xilinx_qdma_pkg types to
    //      shell_pkg types using axi4s_intf_set_meta, matching the pattern
    //      used in xilinx_alveo_usplus_shell.
    // =========================================================================

    // Post-CDC interfaces: QDMA-typed, management clock domain
    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .TID_WID       ( AXIS_TID_WID       ),
        .TDEST_WID     ( AXIS_TDEST_WID     ),
        .TUSER_WID     ( AXIS_TUSER_WID     )
    ) axis_h2c_cdc (.aclk(axil_top.aclk));

    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .TID_WID       ( AXIS_TID_WID       ),
        .TDEST_WID     ( AXIS_TDEST_WID     ),
        .TUSER_WID     ( AXIS_TUSER_WID     )
    ) axis_c2h_cdc (.aclk(axil_top.aclk));

    // pci_rstn is the JTAG-overrideable form of m_axi_pcie0_aresetn; use it
    // as the active-high reset for the QDMA-domain side of both CDC FIFOs.
    logic dma_srst;
    assign dma_srst = ~pci_rstn;

    // Terminated AXI-L peripheral interfaces for the FIFO probes
    axi4l_intf #() axil_h2c_fifo_probe ();
    axi4l_intf #() axil_h2c_fifo_ovfl  ();
    axi4l_intf #() axil_h2c_fifo       ();
    axi4l_intf #() axil_c2h_fifo_probe ();
    axi4l_intf #() axil_c2h_fifo_ovfl  ();
    axi4l_intf #() axil_c2h_fifo       ();

    axi4l_intf_peripheral_term i_axil_term__h2c_probe (.axi4l_if(axil_h2c_fifo_probe));
    axi4l_intf_peripheral_term i_axil_term__h2c_ovfl  (.axi4l_if(axil_h2c_fifo_ovfl));
    axi4l_intf_peripheral_term i_axil_term__h2c_fifo  (.axi4l_if(axil_h2c_fifo));
    axi4l_intf_peripheral_term i_axil_term__c2h_probe (.axi4l_if(axil_c2h_fifo_probe));
    axi4l_intf_peripheral_term i_axil_term__c2h_ovfl  (.axi4l_if(axil_c2h_fifo_ovfl));
    axi4l_intf_peripheral_term i_axil_term__c2h_fifo  (.axi4l_if(axil_c2h_fifo));

    // H2C CDC: 250 MHz QDMA domain → 100 MHz management domain
    axi4s_pkt_fifo_async #(
        .FIFO_DEPTH ( 256 ),
        .MAX_PKT_LEN( 9100 )
    ) i_axi4s_pkt_fifo_async__h2c (
        .axi4s_in_srst  ( dma_srst              ),
        .axi4s_in       ( axis_h2c_dma          ),
        .axi4s_out_srst ( ~axil_top.aresetn     ),
        .axi4s_out      ( axis_h2c_cdc          ),
        .flow_ctl_thresh( '1 ),
        .flow_ctl       (    ),
        .axil_to_probe  ( axil_h2c_fifo_probe   ),
        .axil_to_ovfl   ( axil_h2c_fifo_ovfl    ),
        .axil_if        ( axil_h2c_fifo         )
    );

    // C2H CDC: 100 MHz management domain → 250 MHz QDMA domain
    axi4s_pkt_fifo_async #(
        .FIFO_DEPTH ( 256 ),
        .MAX_PKT_LEN( 9100 )
    ) i_axi4s_pkt_fifo_async__c2h (
        .axi4s_in_srst  ( ~axil_top.aresetn     ),
        .axi4s_in       ( axis_c2h_cdc          ),
        .axi4s_out_srst ( dma_srst              ),
        .axi4s_out      ( axis_c2h_dma          ),
        .flow_ctl_thresh( '1 ),
        .flow_ctl       (    ),
        .axil_to_probe  ( axil_c2h_fifo_probe   ),
        .axil_to_ovfl   ( axil_c2h_fifo_ovfl    ),
        .axil_if        ( axil_c2h_fifo         )
    );

    // Shell-domain interfaces: shell_pkg-typed, management clock
    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID           ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID         ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID         )
    ) axis_h2c (.aclk(axil_top.aclk));

    axi4s_intf #(
        .DATA_BYTE_WID ( shell_if.DMA_ST_DATA_BYTE_WID ),
        .TID_WID       ( DMA_ST_AXIS_TID_WID           ),
        .TDEST_WID     ( DMA_ST_AXIS_TDEST_WID         ),
        .TUSER_WID     ( DMA_ST_AXIS_TUSER_WID         )
    ) axis_c2h (.aclk(axil_top.aclk));

    // H2C metadata adaptation: QDMA types → shell_pkg types
    xilinx_qdma_pkg::axis_tid_t   __h2c_qdma_tid;
    xilinx_qdma_pkg::axis_tuser_t __h2c_qdma_tuser;
    shell_pkg::dma_st_axis_tid_t   h2c_shell_tid;
    shell_pkg::dma_st_axis_tdest_t h2c_shell_tdest;
    shell_pkg::dma_st_axis_tuser_t h2c_shell_tuser;

    assign __h2c_qdma_tid    = axis_h2c_cdc.tid;
    assign h2c_shell_tid.qid = __h2c_qdma_tid.qid;
    assign h2c_shell_tdest.unused = 1'b0;
    assign __h2c_qdma_tuser      = axis_h2c_cdc.tuser;
    assign h2c_shell_tuser.rss_enable  = 1'b0;
    assign h2c_shell_tuser.rss_entropy = '0;

    axi4s_intf_set_meta #(
        .TID_WID   ( DMA_ST_AXIS_TID_WID   ),
        .TDEST_WID ( DMA_ST_AXIS_TDEST_WID ),
        .TUSER_WID ( DMA_ST_AXIS_TUSER_WID )
    ) i_axi4s_intf_set_meta__h2c (
        .from_tx ( axis_h2c_cdc  ),
        .to_rx   ( axis_h2c      ),
        .tid     ( h2c_shell_tid  ),
        .tdest   ( h2c_shell_tdest ),
        .tuser   ( h2c_shell_tuser )
    );

    // C2H metadata adaptation: shell_pkg types → QDMA types
    shell_pkg::dma_st_axis_tid_t   c2h_shell_tid;
    xilinx_qdma_pkg::axis_tid_t   __c2h_qdma_tid;
    xilinx_qdma_pkg::axis_tdest_t __c2h_qdma_tdest;
    xilinx_qdma_pkg::axis_tuser_t __c2h_qdma_tuser;

    assign c2h_shell_tid        = axis_c2h.tid;
    assign __c2h_qdma_tid.qid  = c2h_shell_tid.qid;
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
