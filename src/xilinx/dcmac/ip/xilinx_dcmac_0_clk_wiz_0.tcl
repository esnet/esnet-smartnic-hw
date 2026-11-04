set module_name xilinx_dcmac_0_clk_wiz_0

create_ip -name clk_wizard -vendor xilinx.com -library ip -version 1.0 -module_name $module_name -dir . -force

# Input: 322.265625 MHz from BUFG_GT (IBUFDS_GTME5 ODIV2 of 322.265625 MHz GT refclk)
# Output clk_out1: ~781.25  MHz  (core_clk, DCMAC Tx/Rx core clock)
# Output clk_out2: ~390.625 MHz  (axis_clk, AXI-S interface clock)
# Output clk_out3: ~300.000 MHz  (ts_clk,   timestamp clock)
set_property -dict [list \
  CONFIG.PRIM_IN_FREQ                   {322.265625} \
  CONFIG.PRIM_SOURCE                    {Global_buffer} \
  CONFIG.USE_LOCKED                     {true} \
  CONFIG.USE_RESET                      {true} \
  CONFIG.CLKOUT_USED                    {true,true,true,false,false,false,false} \
  CONFIG.CLKOUT_PORT                    {clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
  CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {781.25,390.625,300.000,100.000,100.000,100.000,100.000} \
  CONFIG.CLKOUT_REQUESTED_PHASE         {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
  CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE    {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
  CONFIG.CLKOUT_DRIVES                  {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
] [get_ips $module_name]
