read_xdc constraints/timing.xdc
read_xdc constraints/place.xdc

set lib_root $env(LIB_ROOT)
read_xdc $lib_root/src/sync/build/sync.xdc
