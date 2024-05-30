set module_name xilinx_alveo_clk_axil

create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name $module_name -dir . -force

set_property -dict {
  CONFIG.PRIMITIVE {Auto}
  CONFIG.PRIM_SOURCE {Global_buffer}
  CONFIG.PRIM_IN_FREQ {250}
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125.000}
} [get_ips $module_name]
