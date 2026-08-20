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
# Adds to the BD boundary:
#
#   1. Clock / reset outputs — clk_pl0_100mhz (pl0_ref_clk) and rstn_pl0_100mhz
#   2. PCIE0 endpoint        — GT, AXI4, AXI4S streaming, clock, and reset ports
#
# =============================================================================

# =========================================================================
# 1. Clock / reset outputs
#
# clk_pl0_100mhz (pl0_ref_clk) and rstn_pl0_100mhz (resetn_pl_periph) are
# internal-only in the AMD base design.  BD ports are added and connected
# onto the existing internal nets.  No internal logic is added or modified.
#
# FREQ_HZ is intentionally not set on the clock port — Vivado propagates
# the frequency from the CRP configuration through the net automatically,
# so the port annotation is redundant and could become stale if the
# CRP frequency is ever changed.
# =========================================================================

create_bd_port -dir O -type clk clk_pl0_100mhz

connect_bd_net [get_bd_ports clk_pl0_100mhz] \
    [get_bd_pins cips/pl0_ref_clk]

create_bd_port -dir O -from 0 -to 0 -type rst rstn_pl0_100mhz
set_property CONFIG.POLARITY {ACTIVE_LOW} [get_bd_ports rstn_pl0_100mhz]

connect_bd_net \
    [get_bd_pins clock_reset/resetn_pl_periph] \
    [get_bd_ports rstn_pl0_100mhz]

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
# BAR0 non-prefetchable to suppress speculative cache-line read-ahead.
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
# cell before sections 2b and 2c reference them.
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
# 2c. PCIE0 interface clock and reset
#
# m_axi_pcie0_aclk is pl2_ref_clk (250 MHz), a PMC CRP clock always-on and
# independent of PCIe link state.  It drives dma0_intrfc_clk and the
# axi_noc_cips M01_AXI clock (section 2d).
#
# m_axi_pcie0_aresetn (dma0_axi_aresetn) is the CPM5 PCIE0 link reset,
# already synchronous to m_axi_pcie0_aclk.  Exported for use by user RTL.
#
# dma0_intrfc_resetn mirrors dma1: driven from clock_reset/resetn_pcie_ic,
# which is pcie_psr/interconnect_aresetn — cascaded from pl_psr, rooted at
# pl0_resetn, synchronised first to pl0_ref_clk then to pl2_ref_clk.
# -------------------------------------------------------------------------
create_bd_port -dir O -type clk m_axi_pcie0_aclk

create_bd_port -dir O -from 0 -to 0 -type rst m_axi_pcie0_aresetn
set_property CONFIG.POLARITY {ACTIVE_LOW} [get_bd_ports m_axi_pcie0_aresetn]

connect_bd_net \
    [get_bd_pins cips/pl2_ref_clk] \
    [get_bd_pins cips/dma0_intrfc_clk] \
    [get_bd_ports m_axi_pcie0_aclk]

connect_bd_net \
    [get_bd_pins cips/dma0_axi_aresetn] \
    [get_bd_ports m_axi_pcie0_aresetn]

connect_bd_net \
    [get_bd_pins clock_reset/resetn_pcie_ic] \
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
# Joins the pl2_ref_clk net shared by dma0_intrfc_clk and m_axi_pcie0_aclk.
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

# Associate m_axi_pcie0 with m_axi_pcie0_aclk.
set_property CONFIG.ASSOCIATED_BUSIF {m_axi_pcie0} \
    [get_bd_ports m_axi_pcie0_aclk]

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
# 2e. PCIE0 AXI4S streaming and control interfaces
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

# Associate streaming interfaces with m_axi_pcie0_aclk.
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
set_property CONFIG.ASSOCIATED_BUSIF $assoc_busifs [get_bd_ports m_axi_pcie0_aclk]

save_bd_design
