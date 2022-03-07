# Create SDNet IP (sdnet_0)
set p4_file $env(P4_FILE)
create_ip -force -name vitis_net_p4 -vendor xilinx.com -library ip -version 1.0 -module_name sdnet_0 -dir .
set_property -dict [list CONFIG.P4_FILE $p4_file] [get_ips sdnet_0]
