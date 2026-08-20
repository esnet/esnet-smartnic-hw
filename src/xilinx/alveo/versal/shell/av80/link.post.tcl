# ======================================================
# Default timing constraints
#
# Includes per-reference constraints for sync (synchronizer)
# and xilinx.ram (RAM) modules with clock domain crossing
# (CDC) paths.
# =====================================================

set _lib_root $::env(LIB_ROOT)

# Synchronizer constraints
# ------------------------
read_xdc -quiet -unmanaged -ref sync_meta     $_lib_root/src/sync/build/sync_meta/synth.xdc
read_xdc -quiet -unmanaged -ref sync_areset   $_lib_root/src/sync/build/sync_areset/synth.xdc
read_xdc -quiet -unmanaged -ref sync_bus      $_lib_root/src/sync/build/sync_bus/synth.xdc

# RAM constraints
# ---------------
read_xdc -quiet -unmanaged -ref xilinx_ram_sdp_lutram  $_lib_root/src/xilinx/ram/build/xilinx_ram_sdp_lutram/synth.xdc

# SLR crossing constraints
#-------------------------
read_xdc -quiet -unmanaged -ref bus_pipe_slr  $_lib_root/src/bus/build/bus_pipe_slr/synth.xdc
