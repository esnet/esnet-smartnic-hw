set proj_root $env(PROJ_ROOT)
set lib_root $env(LIB_ROOT)
set app_root $env(APP_ROOT)

read_xdc $proj_root/src/smartnic_322mhz/build/constraints/timing.xdc
read_xdc $proj_root/src/smartnic_322mhz/build/constraints/place.xdc

read_xdc -unmanaged $lib_root/src/sync/build/sync.xdc

if { [file exists $app_root/app_if/timing.xdc ] } {read_xdc $app_root/app_if/timing.xdc }
if { [file exists $app_root/app_if/place.xdc  ] } {read_xdc $app_root/app_if/place.xdc  }
