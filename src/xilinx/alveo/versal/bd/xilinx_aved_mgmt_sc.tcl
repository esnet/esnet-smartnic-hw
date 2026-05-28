# =============================================================================
# Simulation-only BD: xilinx_aved_mgmt_sc
#
# Mirrors the management SmartConnect configuration from pcie_slr0_mgmt_sc
# after applying xilinx_aved.tcl.  Used to verify that PCIe management
# transactions are routed to the correct slave port.
#
# Topology:
#   axi_vip_m (MASTER) --> mgmt_sc (1S/5M SmartConnect) --> axi_vip_s{0..4}
#
# Address map (matches xilinx_aved.tcl exactly):
#   M00 (hw_discovery)             0x020101000000  4 KB
#   M01 (uuid_rom)                 0x020101001000  4 KB
#   M02 (gcq_m2r)                  0x020101010000  4 KB
#   M03 (pcie_mgmt_pdi_reset_gpio) 0x020101040000  4 KB
#   M04 (usr_mgmt)                 0x020101800000  8 MB
# =============================================================================

set module_name xilinx_aved_mgmt_sc

create_bd_design ${module_name} -dir .
current_bd_design ${module_name}

# -----------------------------------------------------------------------------
# Clock / reset ports
# -----------------------------------------------------------------------------
create_bd_port -dir I -type clk  aclk
create_bd_port -dir I -type rst  aresetn
set_property CONFIG.POLARITY {ACTIVE_LOW} [get_bd_ports aresetn]
set_property CONFIG.ASSOCIATED_RESET {aresetn} [get_bd_ports aclk]

# -----------------------------------------------------------------------------
# AXI VIP master  — simulates the PCIe host issuing management transactions
# -----------------------------------------------------------------------------
set vip_m [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_m]
set_property -dict [list \
    CONFIG.INTERFACE_MODE {MASTER}   \
    CONFIG.PROTOCOL       {AXI4LITE} \
    CONFIG.ADDR_WIDTH     {64}       \
    CONFIG.DATA_WIDTH     {32}       \
    CONFIG.HAS_BRESP      {1}        \
    CONFIG.HAS_RRESP      {1}        \
] $vip_m

# -----------------------------------------------------------------------------
# Management SmartConnect  — 1 slave, 5 masters (matches pcie_slr0_mgmt_sc)
# -----------------------------------------------------------------------------
set mgmt_sc [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 mgmt_sc]
set_property -dict [list \
    CONFIG.NUM_SI {1} \
    CONFIG.NUM_MI {5} \
] $mgmt_sc

# -----------------------------------------------------------------------------
# AXI VIP slaves  — one per master port, auto-respond in simulation
# -----------------------------------------------------------------------------
foreach idx {0 1 2 3 4} {
    set vip_s [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_s${idx}]
    set_property -dict [list \
        CONFIG.INTERFACE_MODE {SLAVE}    \
        CONFIG.PROTOCOL       {AXI4LITE} \
        CONFIG.ADDR_WIDTH     {32}       \
        CONFIG.DATA_WIDTH     {32}       \
        CONFIG.HAS_BRESP      {1}        \
        CONFIG.HAS_RRESP      {1}        \
    ] $vip_s
}

# -----------------------------------------------------------------------------
# Clocks and resets
# -----------------------------------------------------------------------------
connect_bd_net [get_bd_ports aclk]    [get_bd_pins axi_vip_m/aclk]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins axi_vip_m/aresetn]

connect_bd_net [get_bd_ports aclk]    [get_bd_pins mgmt_sc/aclk]
connect_bd_net [get_bd_ports aresetn] [get_bd_pins mgmt_sc/aresetn]

foreach idx {0 1 2 3 4} {
    connect_bd_net [get_bd_ports aclk]    [get_bd_pins axi_vip_s${idx}/aclk]
    connect_bd_net [get_bd_ports aresetn] [get_bd_pins axi_vip_s${idx}/aresetn]
}

# -----------------------------------------------------------------------------
# AXI connections
# -----------------------------------------------------------------------------
connect_bd_intf_net [get_bd_intf_pins axi_vip_m/M_AXI] \
                    [get_bd_intf_pins mgmt_sc/S00_AXI]

foreach idx {0 1 2 3 4} {
    connect_bd_intf_net \
        [get_bd_intf_pins mgmt_sc/M0${idx}_AXI] \
        [get_bd_intf_pins axi_vip_s${idx}/S_AXI]
}

# -----------------------------------------------------------------------------
# Address assignments  — mirror xilinx_aved.tcl exactly
# -----------------------------------------------------------------------------
set master_space [get_bd_addr_spaces axi_vip_m/Master_AXI]

assign_bd_address \
    -offset 0x020101000000 -range 0x001000 \
    -target_address_space $master_space \
    [get_bd_addr_segs axi_vip_s0/S_AXI/Reg] -force

assign_bd_address \
    -offset 0x020101001000 -range 0x001000 \
    -target_address_space $master_space \
    [get_bd_addr_segs axi_vip_s1/S_AXI/Reg] -force

assign_bd_address \
    -offset 0x020101010000 -range 0x001000 \
    -target_address_space $master_space \
    [get_bd_addr_segs axi_vip_s2/S_AXI/Reg] -force

assign_bd_address \
    -offset 0x020101040000 -range 0x001000 \
    -target_address_space $master_space \
    [get_bd_addr_segs axi_vip_s3/S_AXI/Reg] -force

assign_bd_address \
    -offset 0x020101800000 -range 0x800000 \
    -target_address_space $master_space \
    [get_bd_addr_segs axi_vip_s4/S_AXI/Reg] -force

save_bd_design
