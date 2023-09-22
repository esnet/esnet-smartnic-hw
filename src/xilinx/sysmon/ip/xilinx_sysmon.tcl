set module_name xilinx_sysmon
create_ip -name system_management_wiz -vendor xilinx.com -library ip -module_name $module_name -dir . -force
set_property -dict {
    CONFIG.INTERFACE_SELECTION {Enable_AXI}
    CONFIG.ENABLE_RESET {false}
    CONFIG.OT_ALARM {false} 
    CONFIG.USER_TEMP_ALARM {false} 
    CONFIG.VCCINT_ALARM {false} 
    CONFIG.VCCAUX_ALARM {false} 
    CONFIG.ENABLE_VBRAM_ALARM {false} 
    CONFIG.CHANNEL_ENABLE_VP_VN {true} 
    CONFIG.AVERAGE_ENABLE_VBRAM {true} 
    CONFIG.AVERAGE_ENABLE_TEMPERATURE {true} 
    CONFIG.AVERAGE_ENABLE_VCCINT {true} 
    CONFIG.AVERAGE_ENABLE_VCCAUX {true} 
    CONFIG.AVERAGE_ENABLE_TEMPERATURE_SLAVE0_SSIT {true} 
    CONFIG.AVERAGE_ENABLE_TEMPERATURE_SLAVE1_SSIT {true} 
    CONFIG.CHANNEL_ENABLE_VUSER0_SLAVE0_SSIT {true} 
    CONFIG.AVERAGE_ENABLE_VUSER0_SLAVE0_SSIT {true} 
    CONFIG.CHANNEL_ENABLE_VUSER0_SLAVE1_SSIT {true} 
    CONFIG.AVERAGE_ENABLE_VUSER0_SLAVE1_SSIT {true} 
    CONFIG.Enable_Slave0 {true} 
    CONFIG.Enable_Slave1 {true}
} [get_ips $module_name]
