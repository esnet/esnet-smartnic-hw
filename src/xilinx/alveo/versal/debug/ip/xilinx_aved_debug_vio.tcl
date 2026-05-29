set module_name xilinx_aved_debug_vio

create_ip -name axis_vio -vendor xilinx.com -library ip -module_name $module_name -dir . -force

# Probe layout (all inputs — read-only diagnostic view):
#   in0  [0]    aresetn         — current reset state (active-low)
#   in1  [0]    clk_toggle      — free-running toggle on clk; confirms clock is live
#   in2  [31:0] rd_count        — AR transactions received
#   in3  [31:0] wr_count        — AW transactions received
#   in4  [31:0] rd_resp_count   — R responses sent (RVALID && RREADY)
#   in5  [31:0] wr_resp_count   — B responses sent (BVALID && BREADY)
#   in6  [31:0] rd_last_addr    — araddr of most recent AR transaction
#   in7  [31:0] wr_last_addr    — awaddr of most recent AW transaction
#   in8  [31:0] rd_last_data    — rdata of most recent R response
#   in9  [31:0] wr_last_data    — wdata of most recent W transaction
#   in10 [1:0]  rd_last_resp    — rresp of most recent R response
#   in11 [1:0]  wr_last_resp    — bresp of most recent B response
set_property -dict {
    CONFIG.C_NUM_PROBE_IN  {12}
    CONFIG.C_NUM_PROBE_OUT {0}
    CONFIG.C_PROBE_IN0_WIDTH  {1}
    CONFIG.C_PROBE_IN1_WIDTH  {1}
    CONFIG.C_PROBE_IN2_WIDTH  {32}
    CONFIG.C_PROBE_IN3_WIDTH  {32}
    CONFIG.C_PROBE_IN4_WIDTH  {32}
    CONFIG.C_PROBE_IN5_WIDTH  {32}
    CONFIG.C_PROBE_IN6_WIDTH  {32}
    CONFIG.C_PROBE_IN7_WIDTH  {32}
    CONFIG.C_PROBE_IN8_WIDTH  {32}
    CONFIG.C_PROBE_IN9_WIDTH  {32}
    CONFIG.C_PROBE_IN10_WIDTH {2}
    CONFIG.C_PROBE_IN11_WIDTH {2}
} [get_ips $module_name]
