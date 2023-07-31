set curdir [pwd]
cd ../smartnic_322mhz/build/

# read design sources
source sources.tcl
read_checkpoint -cell box_322mhz_inst/smartnic_322mhz/smartnic_322mhz_app $app_root/app_if/smartnic_322mhz_app.dcp

# read constraints
read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
