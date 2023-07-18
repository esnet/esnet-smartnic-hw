create_generated_clock -name core_clk [get_pins box_322mhz_inst/smartnic_322mhz/reset_inst/axi_to_core_clk/inst/plle4_adv_inst/CLKOUT0]
create_generated_clock -name clk_100mhz [get_pins box_322mhz_inst/smartnic_322mhz/reset_inst/axi_to_clk_100mhz/inst/plle4_adv_inst/CLKOUT0]
create_generated_clock -name axil_aclk [get_pins qdma_if*.qdma_subsystem_inst/qdma_wrapper_inst/clk_div_inst/inst/mmcme4_adv_inst/CLKOUT0]

connect_debug_port dbg_hub/clk [get_nets -hierarchical clk_100mhz_clk_wiz_1]
