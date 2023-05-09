set curdir [pwd]
cd ../../smartnic_250mhz/build/

# read design sources
source add_sources.tcl

# read constraints
read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc
set lib_root $env(LIB_ROOT)
read_xdc $lib_root/src/sync/build/sync.xdc

cd $curdir
