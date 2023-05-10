set smartnic_src_root $env(SMARTNIC_ROOT)/src
set lib_root $env(LIB_ROOT)
set out_root $env(OUTPUT_ROOT)

# IP
read_ip -quiet $out_root/vitisnetp4/xilinx_ip/sdnet_0/sdnet_0.xci
read_ip $out_root/smartnic/common/fifo/xilinx_ip/fifo_xilinx_ila/fifo_xilinx_ila.xci

# Packages
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axi/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/xilinx/axis/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi3/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob $smartnic_src_root/p4_app/rtl/src/*_pkg.sv ]

read_verilog -quiet -sv [glob $out_root/p4_app/build/rtl/src/*_pkg.sv ]
read_verilog -quiet -sv [glob $out_root/vitisnetp4/xilinx_ip/sdnet_0/src/verilog/sdnet_0_pkg.sv ]

# RTL
read_verilog -quiet -sv [glob $lib_root/src/sync/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/util/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/reg/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/mem/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi3/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4l/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/axi4s/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $lib_root/src/fifo/rtl/src/*.sv ]

read_verilog -quiet -sv [glob $smartnic_src_root/p4_app/rtl/src/*.sv ]

read_verilog -quiet -sv [glob $out_root/p4_app/build/rtl/src/*.sv ]
read_verilog -quiet -sv [glob $out_root/vitisnetp4/xilinx_ip/sdnet_0/sdnet_0_wrapper.sv ]

# Application wrapper
read_verilog -sv ../app_if/src/smartnic_322mhz_app.sv

# Constraints
read_xdc -unmanaged -mode out_of_context -quiet $lib_root/src/sync/build/sync.xdc
read_xdc -unmanaged -mode out_of_context constraints/timing_ooc.xdc
read_xdc -unmanaged -mode out_of_context constraints/place_ooc.xdc
