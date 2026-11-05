# OOC boundary clocks for xilinx_alveo_qdma_st_wrapper.
#
# aclk:      250 MHz QDMA clock domain (pkt_h2c_dma/pkt_c2h_dma, CPM5 NoC rate)
# core_clk:  350 MHz core clock domain (axis_h2c/axis_c2h, matches av80
#            xilinx_versal_core_clk)
# axil_clk:  100 MHz management clock domain (axil_if)
create_clock -period 4.000 -name aclk     [get_ports aclk]
create_clock -period 2.857 -name core_clk [get_ports core_clk]
create_clock -period 8.000 -name axil_clk [get_ports axil_aclk]

set_clock_groups -asynchronous \
    -group [get_clocks aclk] \
    -group [get_clocks core_clk] \
    -group [get_clocks axil_clk]
