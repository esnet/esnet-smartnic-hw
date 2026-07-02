// =============================================================================
// xilinx_alveo_shell
//
// Common platform module for Alveo cards (UltraScale+ and Versal).
// Instantiated once per top-level design to collect functionality that is
// shared across all Alveo platform variants.
// =============================================================================
module xilinx_alveo_shell
    import xilinx_alveo_pkg::*;
(
    input  wire logic sys_clk_100mhz,     // Free-running debug clock for VIO

    input  wire logic pci_rstn_in,        // Raw incoming reset (active-low)

    output wire logic pci_rstn_out,       // Reset output (active-low, JTAG-overridable)

    axi4l_intf.peripheral axil_top,  // AXI-L interface from PCIe core
    axi4l_intf.controller axil_hw,   // AXI-L interface to hardware (shell) components
    axi4l_intf.controller axil_core  // AXI-L interface to core
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

endmodule : xilinx_alveo_shell
