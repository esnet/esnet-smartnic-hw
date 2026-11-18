# Export the native SYSMON model, including its configured primitive attributes.
open_checkpoint [lindex $argv 0]
write_verilog -force -mode funcsim [lindex $argv 1]
