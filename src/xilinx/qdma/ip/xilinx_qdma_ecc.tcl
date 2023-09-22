set module_name xilinx_qdma_ecc
create_ip -name ecc -vendor xilinx.com -library ip -module_name $module_name -dir . -force
set_property -dict { 
    CONFIG.C_USE_CLK_ENABLE {true}
    CONFIG.C_REG_OUTPUT {true}
    CONFIG.C_REG_INPUT {false}
    CONFIG.C_CHK_BIT_WIDTH {7}
    CONFIG.C_DATA_WIDTH {57}
    CONFIG.C_ECC_MODE {Encoder}
} [get_ips $module_name]
