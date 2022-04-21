create_clock -period 8.000 -name aclk [get_ports axil_aclk]
create_clock -period 3.103 -name cmac_clk [get_ports cmac_clk*]

create_generated_clock -name core_clk [get_pins reset_inst/axi_to_core_clk/inst/plle4_adv_inst/CLKOUT0]
create_generated_clock -name clk_100mhz [get_pins reset_inst/axi_to_clk_100mhz/inst/plle4_adv_inst/CLKOUT0]

set_clock_groups -name cmac_clk__to_from__core_clk -asynchronous -group core_clk -group cmac_clk

