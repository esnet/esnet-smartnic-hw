set lib_root $env(LIB_ROOT)
set app_root $env(APP_ROOT)

# IP
read_ip $lib_root/src/fifo/xilinx_ip/fifo_xilinx_ila/fifo_xilinx_ila.xci
read_ip $lib_root/src/axi4l/xilinx_ip/axi_clock_converter_0/axi_clock_converter_0.xci
read_ip $lib_root/src/axi4s/xilinx_ip/ila_axi4s/ila_axi4s.xci
read_ip $lib_root/src/axi4s/xilinx_ip/axis_data_fifo/axis_data_fifo.xci
read_ip ../xilinx_ip/axis_switch_egress/axis_switch_egress.xci
read_ip ../xilinx_ip/axis_switch_ingress/axis_switch_ingress.xci
read_ip ../xilinx_ip/clk_wiz_0/clk_wiz_0.xci
read_ip ../xilinx_ip/clk_wiz_1/clk_wiz_1.xci
read_ip ../xilinx_ip/hbm_4g_left/hbm_4g_left.xci
read_ip ../xilinx_ip/hbm_4g_right/hbm_4g_right.xci

# Register slice IP (not synthesized OOC but need to provide Xilinx libs)
read_verilog $lib_root/src/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_infrastructure_v1_1_0.vh
read_verilog $lib_root/src/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_infrastructure_v1_1_vl_rfs.v
read_verilog $lib_root/src/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_register_slice_v1_1_vl_rfs.v
read_verilog $lib_root/src/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_infrastructure_v1_1_0.vh
read_verilog $lib_root/src/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_infrastructure_v1_1_vl_rfs.v
read_verilog $lib_root/src/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_register_slice_v2_1_vl_rfs.v

# Application package
read_verilog -sv [glob $app_root/app_if/smartnic_322mhz_app_pkg.sv]

# Packages
read_verilog -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -sv [glob src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/fifo/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/apb/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/axi4l/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/axi4s/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/axi3/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/xilinx/hbm/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/xilinx/axi/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/xilinx/axis/rtl/src/*_pkg.sv ]
read_verilog -sv [glob ../rtl/src/*_pkg.sv ]

# RTL
read_verilog -sv [glob $lib_root/src/util/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/reg/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/mem/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/sync/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/fifo/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/apb/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/axi4l/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/axi4s/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/axi3/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/xilinx/hbm/rtl/src/*.sv ]
read_verilog -sv [glob src/*.sv ]
read_verilog -sv [glob ../rtl/src/*.sv ]

# Application wrapper
read_checkpoint -cell smartnic_322mhz_app $app_root/app_if/smartnic_322mhz_app.dcp

# Constraints
read_xdc -mode out_of_context constraints/timing_ooc.xdc
read_xdc -mode out_of_context constraints/place_ooc.xdc
