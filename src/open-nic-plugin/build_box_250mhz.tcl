set curdir [pwd]
cd ../smartnic_250mhz/build/

# read design sources
source ../../../.out/smartnic_250mhz/build/${board}/synth/sources.tcl

# read constraints
source ../../../.out/smartnic_250mhz/build/${board}/synth/constraints.tcl

read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
