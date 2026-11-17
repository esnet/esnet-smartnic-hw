set module_name xilinx_usplus_cms_subsystem
create_ip -name cms_subsystem -vendor xilinx.com -library ip -version 4.0 -module_name $module_name -dir . -force
