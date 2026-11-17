set module_name xilinx_axi_quad_spi
create_ip -name axi_quad_spi -vendor xilinx.com -library ip -version 3.2 -module_name $module_name -dir . -force

# AXI-Lite register access and SPI logic share one reference clock.
# Quad-mode Micron command support, one flash, and an internal STARTUP primitive.
set_property -dict {
    CONFIG.C_TYPE_OF_AXI4_INTERFACE {0}
    CONFIG.C_XIP_MODE {0}
    CONFIG.Async_Clk {0}
    CONFIG.C_NUM_SS_BITS {1}
    CONFIG.C_SPI_MEMORY {2} 
    CONFIG.C_USE_STARTUP {1} 
    CONFIG.C_USE_STARTUP_INT {1} 
    CONFIG.C_SPI_MODE {2} 
    CONFIG.C_SCK_RATIO {2} 
    CONFIG.C_FIFO_DEPTH {256}
}   [get_ips $module_name]
