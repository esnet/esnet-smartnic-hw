set curdir [pwd]
cd ../smartnic_322mhz/build/

# read design sources
source ../../../.out/smartnic_322mhz/build/${board}/synth/sources.tcl
source ../../../.out/smartnic_322mhz/build/${board}/synth/app_sources.tcl

# read constraints
source ../../../.out/smartnic_322mhz/build/${board}/synth/constraints.tcl

read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
