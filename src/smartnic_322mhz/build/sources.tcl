set lib_root $env(LIB_ROOT)
set app_root $env(APP_ROOT)
set out_root $env(OUTPUT_ROOT)

# IP
read_ip $out_root/common/fifo/ip/fifo_xilinx_ila/fifo_xilinx_ila.xci
read_ip $out_root/common/axi4s/ip/ila_axi4s/ila_axi4s.xci
read_ip $out_root/smartnic_322mhz/xilinx_ip/axis_switch_egress/axis_switch_egress.xci
read_ip $out_root/smartnic_322mhz/xilinx_ip/axis_switch_ingress/axis_switch_ingress.xci
read_ip $out_root/smartnic_322mhz/xilinx_ip/clk_wiz_0/clk_wiz_0.xci
read_ip $out_root/smartnic_322mhz/xilinx_ip/clk_wiz_1/clk_wiz_1.xci

# Register slice IP (not synthesized OOC but need to provide Xilinx libs)
read_verilog $out_root/common/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_infrastructure_v1_1_1.vh
read_verilog $out_root/common/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_infrastructure_v1_1_vl_rfs.v
read_verilog $out_root/common/xilinx/axis/ip/xilinx_axis_reg_slice/hdl/axis_register_slice_v1_1_vl_rfs.v
read_verilog $out_root/common/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_infrastructure_v1_1_0.vh
read_verilog $out_root/common/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_infrastructure_v1_1_vl_rfs.v
read_verilog $out_root/common/xilinx/axi/ip/xilinx_axi_reg_slice/hdl/axi_register_slice_v2_1_vl_rfs.v

# Application package
read_verilog -sv [glob $app_root/app_if/smartnic_322mhz_app_pkg.sv]

# Reg packages
read_verilog -quiet -sv [glob $out_root/common/axi4s/regio/rtl/src/*_pkg.sv]
read_verilog -quiet -sv [glob $out_root/common/fifo/regio/rtl/src/*_pkg.sv]
read_verilog -quiet -sv [glob $out_root/common/reg/endian/regio/rtl/src/*_pkg.sv]
read_verilog -quiet -sv [glob $out_root/common/reg/proxy/regio/rtl/src/*_pkg.sv]
read_verilog -quiet -sv [glob $out_root/smartnic_322mhz/regio/rtl/src/*_pkg.sv]

# Packages
read_verilog -quiet -sv [glob $lib_root/src/std/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/ram/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/sync/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/apb/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/arb/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi3/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axi/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axis/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob ../rtl/src/*_pkg.sv ]

# Reg RTL
read_verilog -quiet -sv [glob $out_root/common/axi4s/regio/rtl/src/*.sv]
read_verilog -quiet -sv [glob $out_root/common/fifo/regio/rtl/src/*.sv]
read_verilog -quiet -sv [glob $out_root/common/reg/endian/regio/rtl/src/*.sv]
read_verilog -quiet -sv [glob $out_root/common/reg/proxy/regio/rtl/src/*.sv]
read_verilog -quiet -sv [glob $out_root/smartnic_322mhz/regio/rtl/src/*.sv]

# RTL
read_verilog -quiet -sv [glob $lib_root/src/util/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/endian/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/proxy/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/ram/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/sync/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/apb/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi3/rtl/src/*.sv ]

# HBM RTL and pkg sources, unless BOARD does NOT support HBM (i.e. au250).
if { [info exists env(BOARD)] } {
  if { [string trim $env(BOARD)] != "au250" } {
    read_ip $out_root/smartnic_322mhz/xilinx_ip/hbm_4g_left/hbm_4g_left.xci
    read_ip $out_root/smartnic_322mhz/xilinx_ip/hbm_4g_right/hbm_4g_right.xci

    read_verilog -quiet -sv [glob $lib_root/src/xilinx/hbm/rtl/src/*_pkg.sv ]
    read_verilog -quiet -sv [glob $lib_root/src/xilinx/hbm/rtl/src/*.sv ]
  }
}

read_verilog -quiet -sv [glob ../rtl/src/*.sv ]

source $lib_root/src/xilinx/ram/build/constraints.tcl
source $lib_root/src/sync/build/constraints.tcl
