set curdir [pwd]
cd ../smartnic_250mhz/build/

set __XILINX_VERSION [regexp -inline {[0-9]{4}\.[0-9]} $env(XILINX_VIVADO)]

# read design sources
source ../../../.out/${board}/${__XILINX_VERSION}/smartnic_250mhz/build/synth/sources.tcl

# read constraints
source ../../../.out/${board}/${__XILINX_VERSION}/smartnic_250mhz/build/synth/constraints.tcl

read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
