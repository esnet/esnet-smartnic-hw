set module_name xilinx_aved

set AVED_ROOT $env(AVED_ROOT)
set AVED_BASE_DESIGN $env(AVED_BASE_DESIGN)

# Limit Vivado's internal thread count to reduce peak memory during
# CIPS elaboration (PCIE0 + SR-IOV is very large on this platform).
set_param general.maxThreads 4

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

foreach {param value} {
    CPM_PCIE1_PF0_BAR0_QDMA_PREFETCHABLE 0
    CPM_PCIE1_PF1_BAR0_QDMA_PREFETCHABLE 0
} {
    set_property CONFIG.CPM_CONFIG \
        [concat [get_property CONFIG.CPM_CONFIG [get_bd_cells cips]] \
                [list $param $value]] \
        [get_bd_cells cips]
}

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

# =========================================================================
# 3. PCIE0 — user application endpoint (QDMA mode, X8)
#
# PCIE0 and PCIE1 are independent CPM5 controllers mapped to separate GT
# quads.  The AMD base design sets CPM_PCIE0_MODES {None}; this section
# enables it.  Host-side PCIe slot bifurcation is required so that both
# x8 segments link simultaneously.
#
# No connections are made to any existing AVED internal logic.  All PCIE0
# interfaces are routed directly to BD boundary ports for use by RTL outside
# the AVED BD.
#
# BAR0 base: 0x0000_0203_0000_0000 (distinct from PCIE1's 0x0000_0201_…).
# BAR0 non-prefetchable — same reason as the PCIE1 fix above.
# =========================================================================

# -------------------------------------------------------------------------
# 3a. Enable PCIE0 on the CIPS
#
# All PCIE0 parameters are appended to the existing CPM_CONFIG value in a
# single set_property call.  The per-iteration approach (one set_property
# per parameter) triggers a full CIPS re-validation on each call; with
# SR-IOV enabled this becomes prohibitively slow (~50 re-validations).
# -------------------------------------------------------------------------
set cips [get_bd_cells cips]

set pcie0_params [list \
    CPM_PCIE0_MODES                         DMA \
    CPM_PCIE0_FUNCTIONAL_MODE               QDMA \
    CPM_PCIE0_MODE_SELECTION                Advanced \
    CPM_PCIE0_MAX_LINK_SPEED                32.0_GT/s \
    CPM_PCIE0_PL_LINK_CAP_MAX_LINK_WIDTH    X8 \
    CPM_PCIE0_TL_PF_ENABLE_REG             2 \
    CPM_PCIE0_MSI_X_OPTIONS                 MSI-X_Internal \
    CPM_PCIE0_EXT_PCIE_CFG_SPACE_ENABLED    Extended_Large \
    CPM_PCIE0_CFG_VEND_ID                   10ee \
    CPM_PCIE0_PF0_CFG_DEV_ID               9038 \
    CPM_PCIE0_PF0_CFG_SUBSYS_ID            0000 \
    CPM_PCIE0_PF0_BASE_CLASS_VALUE         02 \
    CPM_PCIE0_PF0_SUB_CLASS_VALUE          80 \
    CPM_PCIE0_ACS_CAP_ON                   1 \
    CPM_PCIE0_PF0_MSIX_ENABLED             1 \
    CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE      8 \
    CPM_PCIE0_PF0_MSIX_CAP_TABLE_OFFSET    40 \
    CPM_PCIE0_PF0_BAR0_QDMA_ENABLED        1 \
    CPM_PCIE0_PF0_BAR0_QDMA_64BIT          1 \
    CPM_PCIE0_PF0_BAR0_QDMA_PREFETCHABLE   0 \
    CPM_PCIE0_PF0_BAR0_QDMA_SCALE         Kilobytes \
    CPM_PCIE0_PF0_BAR0_QDMA_SIZE          512 \
    CPM_PCIE0_PF0_BAR0_QDMA_TYPE          AXI_Bridge_Master \
    CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_0   0x0000020300000000 \
    CPM_PCIE0_PF0_BAR2_QDMA_ENABLED        1 \
    CPM_PCIE0_PF0_BAR2_QDMA_64BIT          1 \
    CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE   0 \
    CPM_PCIE0_PF0_BAR2_QDMA_SCALE         Megabytes \
    CPM_PCIE0_PF0_BAR2_QDMA_SIZE          8 \
    CPM_PCIE0_PF0_BAR2_QDMA_TYPE          AXI_Bridge_Master \
    CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2   0x0000020300080000 \
    CPM_PCIE0_DMA_INTF                     AXI4S \
    CPM_PCIE0_PF1_CFG_DEV_ID              9039 \
    CPM_PCIE0_PF1_BASE_CLASS_VALUE        02 \
    CPM_PCIE0_PF1_SUB_CLASS_VALUE         80 \
    CPM_PCIE0_PF1_MSIX_ENABLED            1 \
    CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE     8 \
    CPM_PCIE0_PF1_MSIX_CAP_TABLE_OFFSET   40 \
    CPM_PCIE0_PF1_BAR0_QDMA_ENABLED       1 \
    CPM_PCIE0_PF1_BAR0_QDMA_64BIT         1 \
    CPM_PCIE0_PF1_BAR0_QDMA_PREFETCHABLE  0 \
    CPM_PCIE0_PF1_BAR0_QDMA_SCALE        Kilobytes \
    CPM_PCIE0_PF1_BAR0_QDMA_SIZE         512 \
    CPM_PCIE0_PF1_BAR0_QDMA_TYPE         AXI_Bridge_Master \
    CPM_PCIE0_PF1_BAR2_QDMA_ENABLED       1 \
    CPM_PCIE0_PF1_BAR2_QDMA_64BIT         1 \
    CPM_PCIE0_PF1_BAR2_QDMA_PREFETCHABLE  0 \
    CPM_PCIE0_PF1_BAR2_QDMA_SCALE        Megabytes \
    CPM_PCIE0_PF1_BAR2_QDMA_SIZE         8 \
    CPM_PCIE0_PF1_BAR2_QDMA_TYPE         AXI_Bridge_Master \
    CPM_PCIE0_SRIOV_CAP_ENABLE             1 \
    CPM_PCIE0_PF0_SRIOV_CAP_TOTAL_VF      4 \
    CPM_PCIE0_PF0_SRIOV_CAP_INITIAL_VF    4 \
    CPM_PCIE0_ALL_VFS                      4 \
    CPM_PCIE0_PF0_SRIOV_BAR0_ENABLED      1 \
    CPM_PCIE0_PF0_SRIOV_BAR0_64BIT        0 \
    CPM_PCIE0_PF0_SRIOV_BAR0_PREFETCHABLE 0 \
    CPM_PCIE0_PF0_SRIOV_BAR0_SCALE       Kilobytes \
    CPM_PCIE0_PF0_SRIOV_BAR0_SIZE        32 \
    CPM_PCIE0_PF0_SRIOV_BAR0_TYPE        Memory \
    CPM_PCIE0_PF0_SRIOV_BAR2_ENABLED      1 \
    CPM_PCIE0_PF0_SRIOV_BAR2_64BIT        1 \
    CPM_PCIE0_PF0_SRIOV_BAR2_PREFETCHABLE 0 \
    CPM_PCIE0_PF0_SRIOV_BAR2_SCALE       Megabytes \
    CPM_PCIE0_PF0_SRIOV_BAR2_SIZE        8 \
    CPM_PCIE0_PF0_SRIOV_BAR2_TYPE        Memory \
    CPM_PCIE0_MAILBOX_ENABLE               1 \
    CPM_PCIE0_PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE 1 \
]

set_property CONFIG.CPM_CONFIG \
    [concat [get_property CONFIG.CPM_CONFIG $cips] $pcie0_params] \
    $cips

# Validate after CPM_CONFIG changes so Vivado surfaces the new PCIE0 pins
# (PCIE0_GT, gt_refclk0, dma0_intrfc_clk, dma0_intrfc_resetn) on the CIPS
# cell before sections 3b and 3c reference them.
validate_bd_design -quiet

# -------------------------------------------------------------------------
# 3b. PCIE0 physical GT interfaces
#
# gt_pciea0 / gt_pcie0_refclk mirror the existing gt_pciea1 / gt_pcie_refclk
# ports created by the AMD base design for PCIE1.
# -------------------------------------------------------------------------
set gt_pciea0 [create_bd_intf_port \
    -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 gt_pciea0]
connect_bd_intf_net \
    [get_bd_intf_pins cips/PCIE0_GT] \
    [get_bd_intf_ports gt_pciea0]

set gt_pcie0_refclk [create_bd_intf_port \
    -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_pcie0_refclk]
set_property CONFIG.FREQ_HZ {100000000} $gt_pcie0_refclk
connect_bd_intf_net \
    [get_bd_intf_ports gt_pcie0_refclk] \
    [get_bd_intf_pins cips/gt_refclk0]

# -------------------------------------------------------------------------
# 3c. PCIE0 interface clock and reset exports
#
# dma0_intrfc_clk is an INPUT to the CIPS, not an output.  It must be
# driven by a PL reference clock, exactly as the AMD base design drives
# dma1_intrfc_clk from pl2_ref_clk (250 MHz) for PCIE1.  We extend that
# same net to also drive dma0_intrfc_clk, axi_noc_cips/aclk5, and the
# clk_pcie0 BD output port — all at 250 MHz, no new clock resource needed.
#
# dma0_intrfc_resetn is a CIPS output and is the source for resetn_pcie0.
# -------------------------------------------------------------------------
create_bd_port -dir O -type clk clk_pcie0
create_bd_port -dir O -type rst resetn_pcie0
set_property CONFIG.POLARITY {ACTIVE_LOW} [get_bd_ports resetn_pcie0]

connect_bd_net \
    [get_bd_pins cips/pl2_ref_clk] \
    [get_bd_pins cips/dma0_intrfc_clk] \
    [get_bd_ports clk_pcie0]

connect_bd_net [get_bd_ports resetn_pcie0] \
    [get_bd_pins cips/dma0_intrfc_resetn]

# -------------------------------------------------------------------------
# 3d. PCIE0 AXI4 boundary port via axi_noc_cips
#
# The CPM5 exposes a single shared pair of NoC initiator ports
# (CPM_PCIE_NOC_0 / CPM_PCIE_NOC_1) that carry traffic from both PCIE0
# and PCIE1 — there are no separate CPM_PCIE0_NOC_* pins.  Address-based
# routing inside axi_noc_cips demultiplexes the two endpoints:
#
#   M00_AXI  →  base_logic (PCIE1 management, existing, unchanged)
#   M01_AXI  →  m_axi_pcie0 (new BD boundary port, PCIE0 data path)
#
# axi_noc_cips is expanded from 1 to 2 MI ports.  The existing M00_AXI
# connection and all SI/clock associations are untouched.
#
# The CONNECTIONS map on S00_AXI / S01_AXI in the AMD base design already
# lists M00_AXI; we append M01_AXI to each.  Bandwidth parameters mirror
# the existing M00_AXI entry (5 Gbps read + write).
# -------------------------------------------------------------------------
set noc_cips [get_bd_cells axi_noc_cips]

# Expand to 2 MI ports (was 1), then validate so Vivado surfaces the new
# M01_AXI interface pin and aclk5 clock pin before they are referenced below.
set_property CONFIG.NUM_MI   {2} $noc_cips
set_property CONFIG.NUM_CLKS {6} $noc_cips
validate_bd_design -quiet

# Append M01_AXI to the CONNECTIONS map for both CPM NoC slave ports.
# The base design sets these as separate set_property calls per port;
# we read the current value and append rather than overwrite.
foreach {si_port} {S00_AXI S01_AXI} {
    set pin [get_bd_intf_pins axi_noc_cips/$si_port]
    set cur [get_property CONFIG.CONNECTIONS $pin]
    set_property CONFIG.CONNECTIONS \
        "$cur M01_AXI {read_bw {5} write_bw {5} read_avg_burst {64} write_avg_burst {64}}" \
        $pin
}

# M01_AXI clock: aclk5 (slot 6, added via NUM_CLKS above).
# Joins the pl2_ref_clk net shared by dma0_intrfc_clk and clk_pcie0.
set_property CONFIG.ASSOCIATED_BUSIF {M01_AXI} \
    [get_bd_pins axi_noc_cips/aclk5]
connect_bd_net [get_bd_pins cips/pl2_ref_clk] \
    [get_bd_pins axi_noc_cips/aclk5]

# BD boundary port — raw AXI4, 512-bit wide (CPM5 QDMA native width).
# User RTL outside the AVED BD instantiates its own slave and, when needed,
# drives a separate user-instantiated NoC toward DCMAC or other endpoints.
set port_pcie0_axi [create_bd_intf_port \
    -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_pcie0]
set_property -dict [list \
    CONFIG.ADDR_WIDTH {64}  \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.PROTOCOL   {AXI4} \
] $port_pcie0_axi
connect_bd_intf_net \
    [get_bd_intf_pins axi_noc_cips/M01_AXI] \
    [get_bd_intf_ports m_axi_pcie0]

# Associate m_axi_pcie0 with clk_pcie0.
set_property CONFIG.ASSOCIATED_BUSIF {m_axi_pcie0} \
    [get_bd_ports clk_pcie0]

# Address assignment: route PCIE0 BAR0 (256 MB) and BAR2 (8 MB) windows
# to M01_AXI from both CPM NoC initiator address spaces.
# Offsets match PCIEBAR2AXIBAR_QDMA_0 and _2 respectively.
# BAR2 is placed immediately after BAR0: 0x020300080000 = 0x020300000000 + 512 KB.
foreach addr_space {
    cips/CPM_PCIE_NOC_0
    cips/CPM_PCIE_NOC_1
} {
    assign_bd_address \
        -offset 0x020300000000 \
        -range  0x00080000 \
        -target_address_space [get_bd_addr_spaces $addr_space] \
        [get_bd_addr_segs m_axi_pcie0/Reg] \
        -force
    assign_bd_address \
        -offset 0x020300080000 \
        -range  0x00800000 \
        -target_address_space [get_bd_addr_spaces $addr_space] \
        [get_bd_addr_segs m_axi_pcie0/Reg] \
        -force
}

# =========================================================================
# 4. PCIE0 AXI4S streaming and control interfaces
#
# The QDMA H2C/C2H streams and associated control sidebands connect
# directly as CIPS pins — they do not pass through the NoC.
#
# Exported as BD interface ports using Vivado's interface types so that
# downstream RTL can connect cleanly without per-signal wiring.
#
# Interfaces exported:
#   dma0_m_axis_h2c      — H2C data stream (CIPS master → user slave)
#   dma0_s_axis_c2h      — C2H data stream (user master → CIPS slave)
#   dma0_s_axis_c2h_cmpt — C2H completion write-back (user → CIPS)
#   dma0_usr_irq         — user interrupt request (user → CIPS)
#   dma0_tm_dsc_sts      — traffic manager descriptor status (CIPS → user)
#   dma0_dsc_crdt_in     — descriptor credit in (user → CIPS)
#   dma0_qsts_out        — queue status output (CIPS → user)
#   dma0_usr_flr         — function level reset notification (CIPS → user)
# =========================================================================

# make_bd_intf_pins_external infers the port VLNV from the pin itself, avoiding
# the need to specify display_eqdma VLNVs which have no registered abstraction.
foreach pin_name {
    dma0_m_axis_h2c
    dma0_s_axis_c2h
    dma0_s_axis_c2h_cmpt
    dma0_usr_irq
    dma0_tm_dsc_sts
    dma0_dsc_crdt_in
    dma0_qsts_out
    dma0_usr_flr
} {
    make_bd_intf_pins_external [get_bd_intf_pins cips/$pin_name]
}

# Associate streaming interfaces with clk_pcie0.
# make_bd_intf_pins_external appends _0 to the pin name for the port name.
set assoc_busifs [join {
    dma0_m_axis_h2c_0
    dma0_s_axis_c2h_0
    dma0_s_axis_c2h_cmpt_0
    dma0_usr_irq_0
    dma0_tm_dsc_sts_0
    dma0_dsc_crdt_in_0
    dma0_qsts_out_0
    dma0_usr_flr_0
    m_axi_pcie0
} :]
set_property CONFIG.ASSOCIATED_BUSIF $assoc_busifs [get_bd_ports clk_pcie0]

save_bd_design
