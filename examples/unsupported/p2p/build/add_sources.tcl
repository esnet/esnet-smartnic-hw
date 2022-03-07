set lib_root $env(LIB_ROOT)

# IP
read_ip $lib_root/src/axi4l/xilinx_ip/axi_clock_converter_0/axi_clock_converter_0.xci

# Packages
read_verilog -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -sv [glob src/*_pkg.sv]
read_verilog -sv [glob $lib_root/src/axi4l/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/axi4s/rtl/src/*_pkg.sv ]
read_verilog -sv [glob ../rtl/src/*_pkg.sv ]

# RTL
read_verilog -sv [glob $lib_root/src/util/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/reg/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/mem/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/sync/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/axi4l/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/axi4s/rtl/src/*.sv ]
read_verilog -sv [glob src/*.sv ]
read_verilog -sv [glob ../rtl/src/*.sv ]

# Application wrapper
read_verilog -sv ../app_if/src/smartnic_322mhz_app.sv

# Constraints
read_xdc -unmanaged -mode out_of_context constraints/timing_ooc.xdc
read_xdc -unmanaged -mode out_of_context constraints/place_ooc.xdc
