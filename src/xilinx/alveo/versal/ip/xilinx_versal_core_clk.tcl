set module_name xilinx_versal_core_clk

create_ip -name clk_wizard -vendor xilinx.com -library ip -module_name $module_name -dir . -force

# Core clock generator: 100 MHz CIPS PL0 reference -> 350 MHz core clock.
#
# NOT YET INSTANTIATED.  Raising core_clk is a shell change, not a top-level one:
# the shell drives shell_if.clk from axil_core.aclk and processes pkt_h2c_dma /
# pkt_c2h_dma on axil_top.aclk, so handing a faster clock to xilinx_aved_adapter
# alone leaves the core at 100 MHz and puts an unsynchronised crossing on the DMA
# interfaces.  See "Clocking (av80)" in CLAUDE.md.
#
# 350 MHz matches the UltraScale+ core clock (src/smartnic/ip/usplus/clk_wiz_0.tcl,
# instantiated as axi_to_core_clk in smartnic_reset.sv).  The core domain is
# deliberately faster than the 322.265625 MHz MAC clock so that a single common
# domain can absorb both MAC streams without backpressure.
#
# PRIM_SOURCE is No_buffer because clk_in1 is driven from an internal net
# (the CIPS pl0_ref_clk output), not a clock-capable pin.  The output takes a
# BUFG so the core clock reaches general fabric.
set_property -dict {
    CONFIG.PRIM_IN_FREQ                   {100.000}
    CONFIG.PRIM_SOURCE                    {No_buffer}
    CONFIG.CLKOUT_USED                    {true,false,false,false,false,false,false}
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {350.000}
    CONFIG.CLKOUT_DRIVES                  {BUFG}
    CONFIG.USE_LOCKED                     {true}
    CONFIG.USE_RESET                      {false}
} [get_ips $module_name]
