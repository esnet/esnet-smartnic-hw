# Create IP
set module_name xilinx_qdma

create_ip -name qdma -vendor xilinx.com -library ip -module_name $module_name -dir . -force

# Base QDMA IP spec
set_property -dict {
    CONFIG.mode_selection {Advanced}
    CONFIG.en_transceiver_status_ports {false}
    CONFIG.dsc_byp_mode {Descriptor_bypass_and_internal}
    CONFIG.testname {st}
    CONFIG.pf1_pciebar2axibar_2 {0x0000000000000000}
    CONFIG.pf2_pciebar2axibar_2 {0x0000000000000000}
    CONFIG.pf3_pciebar2axibar_2 {0x0000000000000000}
    CONFIG.dma_reset_source_sel {Phy_Ready}
    CONFIG.pf0_bar2_scale_qdma {Megabytes}
    CONFIG.pf0_bar2_size_qdma {4}
    CONFIG.pf1_bar2_scale_qdma {Megabytes}
    CONFIG.pf1_bar2_size_qdma {4}
    CONFIG.pf2_bar2_scale_qdma {Megabytes}
    CONFIG.pf2_bar2_size_qdma {4}
    CONFIG.pf3_bar2_scale_qdma {Megabytes}
    CONFIG.pf3_bar2_size_qdma {4}
    CONFIG.PF0_MSIX_CAP_TABLE_SIZE_qdma {009}
    CONFIG.PF1_MSIX_CAP_TABLE_SIZE_qdma {008}
    CONFIG.PF2_MSIX_CAP_TABLE_SIZE_qdma {008}
    CONFIG.PF3_MSIX_CAP_TABLE_SIZE_qdma {008}
    CONFIG.pfch_cache_depth {64}
    CONFIG.wrb_coal_max_buf {32}
    CONFIG.dma_intf_sel_qdma {AXI_Stream_with_Completion}
    CONFIG.en_axi_mm_qdma {false}
    CONFIG.pf0_base_class_menu_qdma {Network_controller}
    CONFIG.pf0_class_code_base_qdma {02}
    CONFIG.pf0_class_code_sub_qdma {80}
    CONFIG.pf0_sub_class_interface_menu_qdma {Other_network_controller}
    CONFIG.pf0_class_code_qdma {028000}
    CONFIG.pf1_base_class_menu_qdma {Network_controller}
    CONFIG.pf1_class_code_base_qdma {02}
    CONFIG.pf1_class_code_sub_qdma {80}
    CONFIG.pf1_sub_class_interface_menu_qdma {Other_network_controller}
    CONFIG.pf1_class_code_qdma {028000}
    CONFIG.tl_pf_enable_reg {2}
    CONFIG.num_queues {512}
} [get_ips $module_name]

# Customize for board/application
switch $env(BOARD) {
    au55c {
        set_property -dict {
            CONFIG.pl_link_cap_max_link_width {X16}
            CONFIG.pl_link_cap_max_link_speed {8.0_GT/s}
            CONFIG.SYS_RST_N_BOARD_INTERFACE {pcie_perstn}
            CONFIG.PCIE_BOARD_INTERFACE {pci_express_x16}
            CONFIG.xlnx_ref_board {AU55C}
        } [get_ips $module_name]
    }
    au250 {
        set_property -dict {
            CONFIG.pl_link_cap_max_link_width {X16}
            CONFIG.pl_link_cap_max_link_speed {8.0_GT/s}
            CONFIG.SYS_RST_N_BOARD_INTERFACE {pcie_perstn}
            CONFIG.PCIE_BOARD_INTERFACE {pci_express_x16}
            CONFIG.xlnx_ref_board {AU250}
        } [get_ips $module_name]
    }
    au280 -
    default {
        set_property -dict {
            CONFIG.pl_link_cap_max_link_width {X16}
            CONFIG.pl_link_cap_max_link_speed {8.0_GT/s}
            CONFIG.SYS_RST_N_BOARD_INTERFACE {pcie_perstn}
            CONFIG.PCIE_BOARD_INTERFACE {pci_express_x16}
            CONFIG.xlnx_ref_board {AU280}
        } [get_ips $module_name]
    }
}
