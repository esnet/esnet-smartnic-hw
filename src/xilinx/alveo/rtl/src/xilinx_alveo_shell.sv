// =============================================================================
// xilinx_alveo_shell
//
// Common platform module for Alveo cards (UltraScale+ and Versal).
// Instantiated once per top-level design to collect functionality that is
// shared across all Alveo platform variants.
// =============================================================================
module xilinx_alveo_shell
#(
    parameter int QID_WID = 11,      // 11 for USPlus discrete QDMA, 12 for CPM5
    parameter int MAX_PKT_LEN = 9100 // Max packet length (bytes) for DMA FIFO sizing
) (
    input  wire logic sys_clk_100mhz,     // Free-running debug clock for VIO

    input  wire logic pci_rstn_in,        // Raw incoming reset (active-low)

    output wire logic pci_rstn_out,       // Reset output (active-low, JTAG-overridable)

    // Core clock. The DMA streams are handed to the core in this domain; the
    // crossing from the QDMA clock happens here, in xilinx_alveo_qdma_st.
    input  wire logic core_clk,

    // QDMA clock and reset — the domain of the dma_* packet interfaces below.
    // Passed explicitly rather than taken from packet_intf.clk so the domain
    // is visible in the port list.
    input  wire logic dma_aclk,
    input  wire logic dma_aresetn,

    axi4l_intf.peripheral axil_top,     // AXI-L interface from PCIe core
    axi4l_intf.controller axil_hw,      // AXI-L interface to hardware (shell) components
    axi4l_intf.controller axil_core,    // AXI-L interface to core
    axi4l_intf.peripheral axil_qdma_st, // DMA streaming registers, decoded per platform

    // -----------------------------------------------------------------------
    // DMA streams, QDMA clock domain — toward the platform's QDMA adapter
    // -----------------------------------------------------------------------
    packet_intf.rx pkt_h2c_dma,  // H2C: from the adapter
    packet_intf.tx pkt_c2h_dma,  // C2H: to the adapter

    // Length of the packet on pkt_c2h_dma, for the adapter's ctrl_len
    output packet_pkg::size_t pkt_c2h_dma_size,

    // -----------------------------------------------------------------------
    // DMA streams, core clock domain — toward the platform shell datapath
    // -----------------------------------------------------------------------
    packet_intf.tx pkt_h2c_core,  // H2C: drives toward core
    packet_intf.rx pkt_c2h_core   // C2H: receives from core
);

    // =========================================================================
    // PCIe reset control
    //
    // Exposes a JTAG VIO (on sys_clk_100mhz) that allows the reset to be
    // independently asserted or released per endpoint without a board power
    // cycle.  rstn_out is combinatorial: rstn_in & !jtag_reset.
    // VIO probes: in0=raw reset, in1=output reset, in2=ready;
    //             out0=jtag_reset (active-high override).
    // =========================================================================
    xilinx_jtag_reset_ctrl i_xilinx_jtag_reset_ctrl (
        .debug_clk ( sys_clk_100mhz ),
        .ready     ( 1'b1           ), // Placeholder: tie to real init-done when available
        .rstn_in   ( pci_rstn_in    ),
        .rstn_out  ( pci_rstn_out   )
    );

    // =========================================================================
    // Top-level decoder
    //
    // Splits the incoming AXI-L interface into shell_cfg, hw, and core
    // sub-spaces.  The address map is defined in
    // src/shell/regio/shell_decoder.yaml.
    // =========================================================================
    axi4l_intf #() axil_shell_cfg ();

    shell_decoder i_shell_decoder (
        .axil_if           ( axil_top       ),
        .shell_cfg_axil_if ( axil_shell_cfg ),
        .hw_axil_if        ( axil_hw        ),
        .core_axil_if      ( axil_core      )
    );

    // =========================================================================
    // Shell config register block
    //
    // id is a fixed RO constant; tie off update inputs so it holds INIT_VALUE.
    // =========================================================================
    shell_cfg_reg_intf shell_cfg_reg_if ();

    assign shell_cfg_reg_if.id_nxt_v = 1'b0;
    assign shell_cfg_reg_if.id_nxt   = '0;

    shell_cfg_reg_blk i_shell_cfg_reg_blk (
        .axil_if     ( axil_shell_cfg  ),
        .reg_blk_if  ( shell_cfg_reg_if )
    );

    // =========================================================================
    // DMA streaming datapath
    //
    // Owns the QDMA-clock to core-clock crossing, the loopback switch and the
    // DMA counters.  Placing it here keeps the clock domain boundary in the
    // shell: the platform adapter below stays entirely in the QDMA domain, and
    // the platform shell above receives the streams already in the core domain.
    //
    // core_srst is derived here rather than taken as a port, so the shell owns
    // the core reset and stays correct if core_clk later diverges from the
    // management clock.
    // =========================================================================
    wire core_srst;

    sync_reset i_sync_reset__core (
        .clk_in  ( axil_top.aclk    ),
        .rst_in  ( axil_top.aresetn ),
        .clk_out ( core_clk         ),
        .rst_out ( core_srst        )
    );

    xilinx_alveo_qdma_st #(
        .QID_WID     ( QID_WID     ),
        .MAX_PKT_LEN ( MAX_PKT_LEN )
    ) i_xilinx_alveo_qdma_st (
        .aclk             ( dma_aclk         ),
        .aresetn          ( dma_aresetn      ),
        .core_clk         ( core_clk         ),
        .core_srst        ( core_srst        ),
        .axil_if          ( axil_qdma_st     ),
        .pkt_h2c_dma      ( pkt_h2c_dma      ),
        .pkt_c2h_dma      ( pkt_c2h_dma      ),
        .pkt_c2h_dma_size ( pkt_c2h_dma_size ),
        .pkt_h2c_core     ( pkt_h2c_core     ),
        .pkt_c2h_core     ( pkt_c2h_core     )
    );

endmodule : xilinx_alveo_shell
