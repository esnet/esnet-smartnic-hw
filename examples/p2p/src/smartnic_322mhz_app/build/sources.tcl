set lib_root $env(LIB_ROOT)
set src_root $env(SRC_ROOT)
set out_root $env(OUTPUT_ROOT)

# IP
read_ip $out_root/smartnic/common/fifo/xilinx_ip/fifo_xilinx_ila/fifo_xilinx_ila.xci

# Packages
read_verilog -quiet -sv [glob $lib_root/src/std/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/ram/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/sync/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axi/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axis/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi3/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob $out_root/smartnic_322mhz_app/build/rtl/src/*_pkg.sv]

read_verilog -quiet -sv [glob $src_root/p2p/rtl/src/*_pkg.sv ]

# RTL
read_verilog -quiet -sv [glob $lib_root/src/util/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/ram/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/sync/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi3/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*.sv ]

read_verilog -quiet -sv [glob $out_root/smartnic_322mhz_app/build/rtl/src/*.sv]

read_verilog -quiet -sv [glob $src_root/p2p/rtl/src/*.sv ]

# Application wrapper
read_verilog -sv ../../../app_if/src/smartnic_322mhz_app.sv

source $lib_root/src/xilinx/ram/build/constraints.tcl
source $lib_root/src/sync/build/constraints.tcl
