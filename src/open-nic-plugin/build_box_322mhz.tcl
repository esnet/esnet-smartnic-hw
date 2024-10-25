set curdir [pwd]
cd ../smartnic/build/

# read design sources
source ../../../.out/${board}/smartnic/build/synth/sources.tcl
read_checkpoint -cell box_322mhz_inst/smartnic/smartnic_app $env(APP_ROOT)/app_if/smartnic_app.dcp

# read constraints
source ../../../.out/${board}/smartnic/build/synth/constraints.tcl

read_xdc constraints/${board}/timing.xdc
read_xdc constraints/${board}/place.xdc

cd $curdir
