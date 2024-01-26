set smartnic_src_root $env(SMARTNIC_ROOT)/src
set lib_root $env(LIB_ROOT)
set src_root $env(SRC_ROOT)
set out_root $env(OUTPUT_ROOT)
set board    $env(BOARD)

# IP
read_ip -quiet $out_root/vitisnetp4/ip/$board/sdnet_0/sdnet_0.xci
read_ip $out_root/smartnic/common/fifo/ip/$board/fifo_xilinx_ila/fifo_xilinx_ila.xci

# Packages
read_verilog -quiet -sv [glob $out_root/smartnic/common/fifo/regio/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $out_root/smartnic/common/axi4s/regio/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $out_root/smartnic/p4_proc/regio/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $out_root/smartnic/p4_app/regio/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob $lib_root/src/std/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/sync/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/ram/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axi/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axis/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi3/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/arb/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob $smartnic_src_root/p4_proc/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $smartnic_src_root/p4_app/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob $out_root/vitisnetp4/ip/$board/sdnet_0/src/verilog/sdnet_0_pkg.sv ]

# RTL
read_verilog -quiet -sv [glob $out_root/smartnic/common/fifo/regio/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $out_root/smartnic/common/axi4s/regio/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $out_root/smartnic/p4_proc/regio/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $out_root/smartnic/p4_app/regio/rtl/src/*.sv ]

read_verilog -quiet -sv [glob $lib_root/src/sync/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/util/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/ram/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi3/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/arb/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*.sv ]

read_verilog -quiet -sv [glob $smartnic_src_root/p4_proc/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $smartnic_src_root/p4_app/rtl/src/*.sv ]

read_verilog -quiet -sv [glob $out_root/smartnic/common/fifo/regio/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $out_root/vitisnetp4/ip/$board/sdnet_0/sdnet_0_wrapper.sv ]

# Application extern
if {[file exists $src_root/p4_app/extern/rtl/smartnic_extern.sv]} {
    read_verilog -sv [glob $src_root/p4_app/extern/rtl/*.sv ]
}

# Application wrapper
read_verilog -sv ../app_if/src/smartnic_322mhz_app.sv

source $lib_root/src/xilinx/ram/build/constraints.tcl
source $lib_root/src/sync/build/constraints.tcl
