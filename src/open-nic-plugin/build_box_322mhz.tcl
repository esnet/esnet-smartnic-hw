set curdir [pwd]
cd ../smartnic/build/

# read design sources
source ../../../.out/smartnic/build/${board}/synth/sources.tcl
source ../../../.out/smartnic/build/${board}/synth/app_sources.tcl

# read constraints
source ../../../.out/smartnic/build/${board}/synth/constraints.tcl

read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
