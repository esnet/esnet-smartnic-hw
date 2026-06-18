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
# Adds to the BD boundary:
#
#   1. Clock / reset outputs — clk_pl and its resets
#   2. PCIE0 endpoint        — GT, AXI4, AXI4S streaming, and reset ports
#
# =============================================================================

# =========================================================================
# 1. Clock / reset outputs
#
# clk_pl (pl0_ref_clk, 100 MHz) and its resets are internal-only in the
# AMD base design.  BD ports are added and connected onto the existing
# internal nets.  No internal logic is added or modified.
# =========================================================================

# -- Clock ----------------------------------------------------------------
create_bd_port -dir O -type clk clk_pl

# FREQ_HZ is intentionally not set here — Vivado propagates the actual
# frequency from the CRP through the net, which is more accurate than
# any nominal value we could specify.

connect_bd_net [get_bd_ports clk_pl] \
    [get_bd_pins cips/pl0_ref_clk]

# -- Resets ---------------------------------------------------------------
# proc_sys_reset produces two flavours of active-low resetn:
#   ic     (interconnect_aresetn) — for AXI interconnects
#   periph (peripheral_aresetn)  — for peripheral IP

foreach {port_name pin_path} {
    resetn_pl_ic        clock_reset/resetn_pl_ic
    resetn_pl_periph    clock_reset/resetn_pl_periph
} {
    create_bd_port -dir O -from 0 -to 0 -type rst $port_name
    connect_bd_net [get_bd_ports $port_name] \
        [get_bd_pins $pin_path]
}

# =========================================================================
# 2. PCIE0 — user application endpoint (QDMA mode, X8)
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
# 2a. Enable PCIE0 on the CIPS
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
    CPM_PCIE0_EXT_PCIE_CFG_SPACE_ENABLED    None \
    CPM_PCIE0_CFG_EXT_IF                   0 \
    CPM_PCIE0_COPY_PF0_QDMA_ENABLED       1 \
    CPM_PCIE0_CFG_VEND_ID                  10ee \
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
    CPM_PCIE0_PF0_BAR0_QDMA_TYPE          DMA \
    CPM_PCIE0_PF0_BAR2_QDMA_ENABLED        1 \
    CPM_PCIE0_PF0_BAR2_QDMA_64BIT          1 \
    CPM_PCIE0_PF0_BAR2_QDMA_PREFETCHABLE   0 \
    CPM_PCIE0_PF0_BAR2_QDMA_SCALE         Megabytes \
    CPM_PCIE0_PF0_BAR2_QDMA_SIZE          8 \
    CPM_PCIE0_PF0_BAR2_QDMA_TYPE          AXI_Bridge_Master \
    CPM_PCIE0_PF0_PCIEBAR2AXIBAR_QDMA_2   0x0000020300000000 \
    CPM_PCIE0_DMA_INTF                     AXI4S \
    CPM_PCIE0_PF1_CFG_DEV_ID              9138 \
    CPM_PCIE0_SRIOV_CAP_ENABLE             1 \
    CPM_PCIE0_PF0_SRIOV_CAP_TOTAL_VF      4 \
    CPM_PCIE0_PF0_SRIOV_CAP_INITIAL_VF    4 \
    CPM_PCIE0_ALL_VFS                      4 \
    CPM_PCIE0_PF0_SRIOV_BAR0_ENABLED      1 \
    CPM_PCIE0_PF0_SRIOV_BAR0_64BIT        0 \
    CPM_PCIE0_PF0_SRIOV_BAR0_PREFETCHABLE 0 \
    CPM_PCIE0_PF0_SRIOV_BAR0_SCALE       Kilobytes \
    CPM_PCIE0_PF0_SRIOV_BAR0_SIZE        32 \
    CPM_PCIE0_PF0_SRIOV_BAR0_TYPE        DMA \
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
# 2b. PCIE0 physical GT interfaces
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
# 2c. PCIE0 interface clock and independent reset
#
# dma0_intrfc_clk is a CIPS input driven by pl2_ref_clk (250 MHz),
# matching the base design's treatment of dma1_intrfc_clk.
#
# Reset is kept fully independent from PCIE1.  Two raw reset sources are
# exported as BD outputs so that user RTL outside the BD can combine them
# (along with a VIO-driven GPIO reset) into a single synthesised reset:
#
#   aresetn_pl0        — cips/pl0_resetn (PS global reset, active-low)
#   aresetn_pcie0_link — cips/dma0_axi_aresetn (CPM5 PCIE0 link reset)
#
# The synthesised result is fed back in as resetn_pcie0 (active-low input)
# which drives dma0_intrfc_resetn.  This allows VIO/JTAG, link-down events,
# and PS global reset to be combined with arbitrary priority outside the BD.
# -------------------------------------------------------------------------
create_bd_port -dir O -type clk clk_pcie0

# Raw reset source exports (both active-low)
create_bd_port -dir O -from 0 -to 0 -type rst aresetn_pl0
set_property CONFIG.POLARITY {ACTIVE_LOW} [get_bd_ports aresetn_pl0]
create_bd_port -dir O -from 0 -to 0 -type rst aresetn_pcie0_link
set_property CONFIG.POLARITY {ACTIVE_LOW} [get_bd_ports aresetn_pcie0_link]

# Synthesised reset input from user logic
create_bd_port -dir I -from 0 -to 0 -type rst resetn_pcie0
set_property CONFIG.POLARITY {ACTIVE_LOW} [get_bd_ports resetn_pcie0]

connect_bd_net \
    [get_bd_pins cips/pl2_ref_clk] \
    [get_bd_pins cips/dma0_intrfc_clk] \
    [get_bd_ports clk_pcie0]
# Note: pl2_ref_clk is a 250 MHz PMC CRP clock (PMC_CRP_PL2_REF_CTRL_FREQMHZ),
# always-on and independent of PCIe link state.

connect_bd_net \
    [get_bd_pins cips/pl0_resetn] \
    [get_bd_ports aresetn_pl0]

connect_bd_net \
    [get_bd_pins cips/dma0_axi_aresetn] \
    [get_bd_ports aresetn_pcie0_link]

connect_bd_net \
    [get_bd_ports resetn_pcie0] \
    [get_bd_pins cips/dma0_intrfc_resetn]

# -------------------------------------------------------------------------
# 2d. PCIE0 AXI4 boundary port via axi_noc_cips
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

# Address assignment: route PCIE0 BAR2 (8 MB) window to M01_AXI from both
# CPM NoC initiator address spaces.  BAR0 is type DMA (QDMA internal) and
# never generates outbound NoC transactions, so only BAR2 is mapped here.
# Offset matches PCIEBAR2AXIBAR_QDMA_2 = 0x0000020300000000.
foreach addr_space {
    cips/CPM_PCIE_NOC_0
    cips/CPM_PCIE_NOC_1
} {
    assign_bd_address \
        -offset 0x020300000000 \
        -range  0x00800000 \
        -target_address_space [get_bd_addr_spaces $addr_space] \
        [get_bd_addr_segs m_axi_pcie0/Reg] \
        -force
}

# =========================================================================
# 3. PCIE0 AXI4S streaming and control interfaces
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
