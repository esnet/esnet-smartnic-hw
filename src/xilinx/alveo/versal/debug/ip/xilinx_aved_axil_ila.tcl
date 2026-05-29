set module_name xilinx_aved_axil_ila

create_ip -name axis_ila -vendor xilinx.com -library ip -module_name $module_name -dir . -force

# Probe layout (AXI4-Lite channel signals):
#   probe0  [31:0]  araddr
#   probe1  [2:0]   arprot
#   probe2  [0]     arvalid
#   probe3  [0]     arready
#   probe4  [31:0]  awaddr
#   probe5  [2:0]   awprot
#   probe6  [0]     awvalid
#   probe7  [0]     awready
#   probe8  [31:0]  wdata
#   probe9  [3:0]   wstrb
#   probe10 [0]     wvalid
#   probe11 [0]     wready
#   probe12 [31:0]  rdata
#   probe13 [1:0]   rresp
#   probe14 [0]     rvalid
#   probe15 [0]     rready
#   probe16 [1:0]   bresp
#   probe17 [0]     bvalid
#   probe18 [0]     bready
set_property -dict {
    CONFIG.C_NUM_OF_PROBES  {19}
    CONFIG.C_DATA_DEPTH     {4096}
    CONFIG.C_PROBE0_WIDTH   {32}
    CONFIG.C_PROBE1_WIDTH   {3}
    CONFIG.C_PROBE4_WIDTH   {32}
    CONFIG.C_PROBE5_WIDTH   {3}
    CONFIG.C_PROBE8_WIDTH   {32}
    CONFIG.C_PROBE9_WIDTH   {4}
    CONFIG.C_PROBE12_WIDTH  {32}
    CONFIG.C_PROBE13_WIDTH  {2}
    CONFIG.C_PROBE16_WIDTH  {2}
} [get_ips $module_name]
