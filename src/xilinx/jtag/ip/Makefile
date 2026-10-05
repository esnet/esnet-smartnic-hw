# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../..

include $(COMPONENT_ROOT)/config.mk

# Export BOARD so the Tcl script can select the correct VIO IP variant:
#   UltraScale+ (au*): vio
#   Versal      (av*): axis_vio
export BOARD

# Import IP core revision details from version-specific tool config
include $(CFG_ROOT)/vivado_ip.mk

IP_LIST = \
    xilinx_jtag_reset_vio

IP_SIM_SRC_FILES = \
    xilinx_jtag_reset_vio/sim/xilinx_jtag_reset_vio.v

IP_SIM_INC_DIRS =

#   The axis_vio core revision moves with each Vivado release, so take it from
#   the per-version IP config in $(CFG_ROOT). The axis_dbg_* sub-cores ship
#   with it but have held at 1_0_1 across releases.
EXT_LIBS = \
    xpm \
    axis_vio_v$(IP_VER_AXIS_VIO) \
    axis_dbg_stub_v1_0_1 \
    axis_dbg_sync_v1_0_1

COMPILE_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: ip compile synth

ip:      _ip
compile: _ip_compile
synth:   _ip_synth
info:    _ip_info
status:  _ip_status
upgrade: _ip_upgrade
clean:   _ip_clean

.PHONY: all ip compile synth info status upgrade clean

proj:       _ip_proj
proj_clean: _ip_proj_clean

.PHONY: proj proj_clean

include $(SCRIPTS_ROOT)/Makefiles/vivado_manage_ip.mk
