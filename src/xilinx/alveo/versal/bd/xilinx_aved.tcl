set module_name xilinx_aved

set AVED_ROOT $env(AVED_ROOT)
set AVED_BASE_DESIGN $env(AVED_BASE_DESIGN)

# Create BD
create_bd_design ${module_name} -dir .
current_bd_design ${module_name}

source "${AVED_ROOT}/hw/${AVED_BASE_DESIGN}/src/bd/create_bd_design.tcl"
create_root_design ""

# =============================================================================
# ESnet AVED BD patch
#
# Applied after create_root_design from the unmodified AMD AVED base design.
# The AMD-owned file (create_bd_design.tcl) is never modified.
#
# Adds two groups of ports to the BD boundary:
#
#   1. Clock / reset outputs  — clk_pl, clk_usr_{0,1} and their resets
#   2. Management AXI4-Lite   — m_axi_usr_mgmt (from pcie_slr0_mgmt_sc M04)
#
# Address map (PCIe BAR0-relative, BAR0 base = 0x0000_0201_0000_0000):
#
#   Existing (AMD-owned, unchanged):
#     0x0000_0100_0000  (4 KB)   hw_discovery
#     0x0000_0100_1000  (4 KB)   uuid_rom
#     0x0000_0101_0000  (4 KB)   gcq_m2r
#     0x0000_0104_0000  (4 KB)   pcie_mgmt_pdi_reset_gpio
#
#   Added here:
#     0x0000_0105_0000  (4 KB)   m_axi_usr_mgmt  (user register space root)
#
# Note: Vivado requires the offset to be naturally aligned to the range size.
# 0x050000 is 4 KB-aligned, satisfying the alignment requirement.
#
# =============================================================================

# =========================================================================
# 0. BAR0 prefetchable override
#
# The AMD base design marks BAR0 as prefetchable for both PF0 and PF1
# (CPM_PCIE1_PF{0,1}_BAR0_QDMA_PREFETCHABLE = 1).  A prefetchable BAR
# tells the CPU/IOMMU it is safe to read ahead speculatively: a single
# 4-byte MMIO read can trigger a full cache-line (64-byte) PCIe read,
# generating AXI-L transactions to addresses beyond the one the driver
# actually requested.
#
# The usr_mgmt aperture is only 4 KB with 8 bytes of valid registers (id
# and scratchpad at offsets 0x0 and 0x4).  A cache-line read starting at
# offset 0x0 issues transactions at 0x0, 0x4, 0x8, 0xC; the decoder
# returns SLVERR/0xDEADBEEF for 0x8 and 0xC (unmapped), which propagates
# as a PCIe completion error and poisons the entire read — the driver sees
# all-F's even for the valid registers.
#
# Marking BAR0 non-prefetchable suppresses the speculative read-ahead and
# ensures transactions are issued only for the addresses the driver requests.
# =========================================================================

set_property CONFIG.CPM_PCIE1_PF0_BAR0_QDMA_PREFETCHABLE {0} [get_bd_cells cips]
set_property CONFIG.CPM_PCIE1_PF1_BAR0_QDMA_PREFETCHABLE {0} [get_bd_cells cips]

# =========================================================================
# 1. Clock / reset outputs
#
# clk_usr_{0,1} and their resets are generated inside the clock_reset
# hierarchy but not exported at the BD boundary by the AMD base design.
# clk_pl (pl0_ref_clk, 100 MHz) is likewise internal-only.
#
# BD ports are added and connected onto the existing internal nets.
# No internal logic is added or modified.
# =========================================================================

# -- Clocks ---------------------------------------------------------------
create_bd_port -dir O -type clk clk_pl
create_bd_port -dir O -type clk clk_usr_0
create_bd_port -dir O -type clk clk_usr_1

# FREQ_HZ is intentionally not set here — Vivado propagates the actual
# PLL output frequency from the clock wizard through the net, which is
# more accurate than any nominal value we could specify.

# clk_pl is pl0_ref_clk; tap the existing net driven by cips.
connect_bd_net [get_bd_ports clk_pl] \
    [get_bd_pins cips/pl0_ref_clk]

connect_bd_net [get_bd_ports clk_usr_0] \
    [get_bd_pins clock_reset/clk_usr_0]

connect_bd_net [get_bd_ports clk_usr_1] \
    [get_bd_pins clock_reset/clk_usr_1]

# -- Resets ---------------------------------------------------------------
# Each proc_sys_reset produces two flavours of active-low resetn:
#   ic     (interconnect_aresetn) — for AXI interconnects
#   periph (peripheral_aresetn)  — for peripheral IP
#
# The pl_* resets are already consumed internally by base_logic; exporting
# them too lets the platform RTL build its own peripheral reset trees
# synchronised to clk_pl without needing a second proc_sys_reset.

foreach {port_name pin_path} {
    resetn_pl_ic        clock_reset/resetn_pl_ic
    resetn_pl_periph    clock_reset/resetn_pl_periph
    resetn_usr_0_ic     clock_reset/resetn_usr_0_ic
    resetn_usr_0_periph clock_reset/resetn_usr_0_periph
    resetn_usr_1_ic     clock_reset/resetn_usr_1_ic
    resetn_usr_1_periph clock_reset/resetn_usr_1_periph
} {
    create_bd_port -dir O -from 0 -to 0 -type rst $port_name
    connect_bd_net [get_bd_ports $port_name] \
        [get_bd_pins $pin_path]
}

# =========================================================================
# 2. Management AXI4-Lite master (m_axi_usr_mgmt)
#
# Expands pcie_slr0_mgmt_sc from 4 to 5 master ports and routes M04 out
# as a BD port.  This is the root of the user register tree; all address
# decode below this point is done in platform RTL, not in the BD.
#
# A hw_discovery endpoint table entry is added so the PCIe host can
# enumerate the user register window.
# =========================================================================

# -- Expand management SmartConnect ---------------------------------------
set mgmt_sc [get_bd_cells base_logic/pcie_slr0_mgmt_sc]
set_property CONFIG.NUM_MI {5} $mgmt_sc

# -- Create BD interface port ---------------------------------------------
set port_m_axi [create_bd_intf_port \
    -mode Master \
    -vlnv xilinx.com:interface:aximm_rtl:1.0 \
    m_axi_usr_mgmt]

set_property -dict [list \
    CONFIG.ADDR_WIDTH {32} \
    CONFIG.DATA_WIDTH {32} \
    CONFIG.PROTOCOL   {AXI4LITE} \
] $port_m_axi

# Associate with clk_pl so the SmartConnect synthesizes the correct clock
# domain for M04_AXI.  Without this, BD 41-2559 fires and the port does not
# work in hardware.
set_property CONFIG.ASSOCIATED_BUSIF {m_axi_usr_mgmt} [get_bd_ports clk_pl]

# Guard: verify Vivado accepted the association.  Catches regressions early
# (during 'make ip') rather than after a full implementation run.
set _assoc [get_property CONFIG.ASSOCIATED_BUSIF [get_bd_ports clk_pl]]
if {[lsearch -exact [split $_assoc {:}] m_axi_usr_mgmt] < 0} {
    error "BD guard: m_axi_usr_mgmt not associated with clk_pl (got: '$_assoc'); BD 41-2559 would fire"
}

# -- Wire M04_AXI to the port ---------------------------------------------
connect_bd_intf_net \
    [get_bd_intf_pins base_logic/pcie_slr0_mgmt_sc/M04_AXI] \
    [get_bd_intf_ports m_axi_usr_mgmt]

# -- Update hw_discovery endpoint table -----------------------------------
# Adds a fourth slot at BAR0 + 0x105_0000.
# Type 0x42 is vendor-specific; update to the correct Xilinx endpoint
# class code once confirmed (e.g. 0x50 = XRT mgmt, 0x54 = XRT user).
set hw_disc [get_bd_cells base_logic/hw_discovery]
set_property -dict [list \
    CONFIG.C_PF0_NUM_SLOTS_BAR_LAYOUT_TABLE {4} \
    CONFIG.C_PF0_ENTRY_ADDR_3              {0x000001050000} \
    CONFIG.C_PF0_ENTRY_BAR_3              {0} \
    CONFIG.C_PF0_ENTRY_TYPE_3             {0x42} \
    CONFIG.C_PF0_ENTRY_VERSION_TYPE_3     {0x01} \
    CONFIG.C_PF0_ENTRY_MAJOR_VERSION_3    {1} \
    CONFIG.C_PF0_ENTRY_MINOR_VERSION_3    {0} \
    CONFIG.C_PF0_ENTRY_RSVD0_3           {0x0} \
] $hw_disc

# -- Assign address segments ----------------------------------------------
# Maps 4 KB of the NoC aperture to M04.
# 0x020101050000 = BAR0 base (0x020100000000) + 0x1050000.
# Assigned from both CPM PCIe NOC master spaces.

foreach addr_space {
    cips/CPM_PCIE_NOC_0
    cips/CPM_PCIE_NOC_1
} {
    assign_bd_address \
        -offset 0x020101050000 \
        -range  0x00001000 \
        -target_address_space [get_bd_addr_spaces $addr_space] \
        [get_bd_addr_segs m_axi_usr_mgmt/Reg] \
        -force
}

save_bd_design
