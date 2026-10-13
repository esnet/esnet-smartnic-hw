set module_name xilinx_dcmac_0

create_ip -name dcmac -vendor xilinx.com -library ip -version 3.0 -module_name $module_name -dir . -force

set_property -dict [list \
  CONFIG.DCMAC_DATA_PATH_INTERFACE_C0 {391MHz Upto 6 Ports} \
  CONFIG.MAC_PORT0_CONFIG_C0 {200GAUI-4} \
  CONFIG.MAC_PORT1_ENABLE_C0 {0} \
  CONFIG.MAC_PORT2_CONFIG_C0 {200GAUI-4} \
  CONFIG.MAC_PORT3_ENABLE_C0 {0} \
  CONFIG.MAC_PORT4_ENABLE_C0 {0} \
  CONFIG.MAC_PORT5_ENABLE_C0 {0} \
  CONFIG.IS_GT_WIZ_OLD {0} \
  CONFIG.GT_REF_CLK_FREQ_C0 {322.265625} \
  CONFIG.MAC_PORT0_RX_STRIP_C0 {1} \
  CONFIG.MAC_PORT2_RX_STRIP_C0 {1} \
] [get_ips $module_name]
