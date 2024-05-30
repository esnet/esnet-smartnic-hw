set module_name xilinx_alveo_clk

create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name $module_name -dir . -force

set_property -dict {
  CONFIG.PRIMITIVE {Auto}
  CONFIG.PRIM_SOURCE {Global_buffer}
  CONFIG.PRIM_IN_FREQ {250}
  CONFIG.NUM_OUT_CLKS {2}
  CONFIG.CLKOUT2_USED {true}
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000}
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {333.33333}
} [get_ips $module_name]
