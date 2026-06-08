set module_name clk_wiz_1

create_ip -name clk_wizard -vendor xilinx.com -library ip -module_name $module_name -dir . -force

set_property -dict [list \
    CONFIG.PRIM_SOURCE                    {No_buffer} \
    CONFIG.PRIM_IN_FREQ                   {125.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {100.000} \
    CONFIG.CLKOUT_USED                    {true} \
    CONFIG.CLKOUT_DRIVES                  {Buffer} \
    CONFIG.USE_LOCKED                     {false} \
    CONFIG.USE_RESET                      {false} \
] [get_ips $module_name]
