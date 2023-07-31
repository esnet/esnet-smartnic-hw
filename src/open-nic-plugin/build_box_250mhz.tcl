set curdir [pwd]
cd ../smartnic_250mhz/build/

# read design sources
source sources.tcl

# read constraints
read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
