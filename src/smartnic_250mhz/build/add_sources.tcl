set lib_root $env(LIB_ROOT)
set out_root $env(OUTPUT_ROOT)

# IP
read_ip $out_root/common/fifo/xilinx_ip/fifo_xilinx_ila/fifo_xilinx_ila.xci
read_ip $out_root/common/axi4l/xilinx_ip/axi_clock_converter_0/axi_clock_converter_0.xci
read_ip $out_root/common/axi4s/xilinx_ip/ila_axi4s/ila_axi4s.xci

# Register slice IP (not synthesized OOC but need to provide Xilinx libs)
read_verilog $out_root/common/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_infrastructure_v1_1_0.vh
read_verilog $out_root/common/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_infrastructure_v1_1_vl_rfs.v
read_verilog $out_root/common/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_register_slice_v1_1_vl_rfs.v
read_verilog $out_root/common/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_infrastructure_v1_1_0.vh
read_verilog $out_root/common/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_infrastructure_v1_1_vl_rfs.v
read_verilog $out_root/common/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_register_slice_v2_1_vl_rfs.v

# Packages
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axi/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axis/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob $out_root/smartnic_250mhz/build/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob ../rtl/src/*_pkg.sv ]

# RTL
read_verilog -quiet -sv [glob $lib_root/src/util/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/sync/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*.sv ]

read_verilog -quiet -sv [glob $out_root/smartnic_250mhz/build/rtl/src/*.sv ]

read_verilog -quiet -sv [glob ../rtl/src/*.sv ]

# Constraints
read_xdc -mode out_of_context constraints/timing_ooc.xdc
read_xdc -mode out_of_context constraints/place_ooc.xdc
