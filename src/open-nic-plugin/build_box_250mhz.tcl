set curdir [pwd]
cd ../smartnic_250mhz/build/

# read design sources
source ../../../.out/${board}/smartnic_250mhz/build/synth/sources.tcl

# read constraints
source ../../../.out/${board}/smartnic_250mhz/build/synth/constraints.tcl

read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
