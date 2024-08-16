set curdir [pwd]
cd ../smartnic/build/

# read design sources
source ../../../.out/${board}/smartnic/build/synth/sources.tcl
source ../../../.out/${board}/smartnic/build/synth/app_sources.tcl

# read constraints
source ../../../.out/${board}/smartnic/build/synth/constraints.tcl

read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
