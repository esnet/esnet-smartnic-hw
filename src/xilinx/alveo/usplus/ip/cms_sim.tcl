# Export a self-contained CMS functional model from its synthesized checkpoint.
open_checkpoint [lindex $argv 0]
write_verilog -force -mode funcsim [lindex $argv 1]
