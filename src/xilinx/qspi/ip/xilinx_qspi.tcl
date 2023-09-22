set module_name xilinx_qspi
create_ip -name axi_quad_spi -vendor xilinx.com -library ip -version 3.2 -module_name $module_name -dir . -force
set_property -dict {
    CONFIG.C_SPI_MEMORY {2} 
    CONFIG.C_USE_STARTUP {1} 
    CONFIG.C_USE_STARTUP_INT {1} 
    CONFIG.C_SPI_MODE {2} 
    CONFIG.C_SCK_RATIO {2} 
    CONFIG.C_FIFO_DEPTH {256}
}   [get_ips $module_name]
