// =============================================================================
// xilinx_alveo
//
// Common platform module for Alveo cards (UltraScale+ and Versal).
// Instantiated once per top-level design to collect functionality that is
// shared across all Alveo platform variants.
// =============================================================================
module xilinx_alveo
    import xilinx_alveo_pkg::*;
(
    input  wire logic sys_clk_100mhz,  // Free-running debug clock for VIO

    input  wire logic pci_clk,         // PCIe interface clock (target domain)
    input  wire logic pci_rstn_in,     // Raw incoming reset (active-low)

    output wire logic pci_rstn_out     // Retimed reset output (active-low)
);

    // =========================================================================
    // PCIe reset control
    //
    // Retimes pci_rstn_in to pci_clk and exposes a JTAG VIO (on sys_clk_100mhz)
    // that allows the reset to be independently asserted or released per endpoint
    // without a board power cycle.
    // VIO probes: in0=raw reset, in1=retimed reset, in2=ready;
    //             out0=jtag_reset (active-high override).
    // =========================================================================
    xilinx_jtag_reset_ctrl i_xilinx_jtag_reset_ctrl (
        .debug_clk ( sys_clk_100mhz ),
        .ready     ( 1'b1           ), // Placeholder: tie to real init-done when available
        .rstn_clk  ( pci_clk        ),
        .rstn_in   ( pci_rstn_in    ),
        .rstn_out  ( pci_rstn_out   )
    );

endmodule : xilinx_alveo
