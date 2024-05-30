set module_name xilinx_alveo_axil_ila

create_ip -name ila -vendor xilinx.com -library ip -module_name $module_name -dir . -force

set_property -dict {
    CONFIG.C_ADV_TRIGGER {true} \
    CONFIG.C_EN_STRG_QUAL {1} \
    CONFIG.C_MONITOR_TYPE {AXI} \
    CONFIG.C_SLOT_0_AXI_PROTOCOL {AXI4LITE} \
} [get_ips $module_name]
