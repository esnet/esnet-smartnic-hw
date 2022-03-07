set lib_root $env(LIB_ROOT)
set reg_src_dir $env(SRC_DIR)

# Packages
read_verilog -sv [glob $lib_root/src/reg/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $lib_root/src/mem/rtl/src/*_pkg.sv ]
read_verilog -sv [glob $reg_src_dir/*_pkg.sv]

# RTL
read_verilog -sv [glob $reg_src_dir/*.sv]
