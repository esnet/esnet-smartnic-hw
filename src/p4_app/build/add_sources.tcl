set lib_root $env(LIB_ROOT)
set app_name $env(APP_NAME)

# IP
read_ip ../xilinx_ip/$app_name/sdnet_0/sdnet_0.xci

# Packages
read_verilog -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -sv [glob src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/axi3/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/axi4l/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/axi4s/rtl/src/*_pkg.sv ]
read_verilog -sv [glob ../xilinx_ip/$app_name/sdnet_0/src/verilog/sdnet_0_pkg.sv ]
read_verilog -sv [glob ../rtl/src/*_pkg.sv ]

# RTL
read_verilog -sv [glob $lib_root/src/sync/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/util/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/reg/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/mem/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/axi3/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/axi4l/rtl/src/*.sv ]
read_verilog -sv [glob $lib_root/src/axi4s/rtl/src/*.sv ]
read_verilog -sv [glob src/*.sv ]
read_verilog -sv [glob ../xilinx_ip/$app_name/sdnet_0/sdnet_0_wrapper.sv]
read_verilog -sv [glob ../rtl/src/*.sv ]

# Application wrapper
read_verilog -sv ../app_if/src/smartnic_322mhz_app.sv

# Constraints
read_xdc -unmanaged -mode out_of_context -quiet $lib_root/src/sync/build/sync.xdc
read_xdc -unmanaged -mode out_of_context constraints/timing_ooc.xdc
read_xdc -unmanaged -mode out_of_context constraints/place_ooc.xdc
