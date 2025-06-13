set curdir [pwd]
cd ../smartnic/build/

set __XILINX_VERSION [regexp -inline {[0-9]{4}\.[0-9]} $env(XILINX_VIVADO)]

# read design sources
source ../../../.out/${board}/${__XILINX_VERSION}/smartnic/build/synth/sources.tcl
read_checkpoint -cell box_322mhz_inst/smartnic/smartnic_app $env(APP_ROOT)/app_if/smartnic_app.dcp

# read constraints
source ../../../.out/${board}/${__XILINX_VERSION}/smartnic/build/synth/constraints.tcl

read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
