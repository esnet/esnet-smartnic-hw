set module_name xilinx_jtag_reset_vio

# Select IP variant based on board:
#   UltraScale+ (au*): vio
#   Versal      (av*): axis_vio
set board $env(BOARD)
if {[string match "au*" $board]} {
    set ip_name vio
} else {
    set ip_name axis_vio
}

create_ip -name $ip_name -vendor xilinx.com -library ip -module_name $module_name -dir . -force

set_property -dict {
    CONFIG.C_NUM_PROBE_IN  {3}
    CONFIG.C_NUM_PROBE_OUT {1}
    CONFIG.C_PROBE_IN0_WIDTH {1}
    CONFIG.C_PROBE_IN1_WIDTH {1}
    CONFIG.C_PROBE_IN2_WIDTH {1}
    CONFIG.C_PROBE_OUT0_WIDTH {1}
    CONFIG.C_PROBE_OUT0_INIT_VAL {0x1}
} [get_ips $module_name]
