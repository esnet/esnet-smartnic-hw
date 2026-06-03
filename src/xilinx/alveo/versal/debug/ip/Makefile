# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../../..

include $(COMPONENT_ROOT)/config.mk

IP_LIST = \
    xilinx_aved_axil_ila \
    xilinx_aved_debug_vio

IP_SIM_SRC_FILES = \
    xilinx_aved_axil_ila/sim/xilinx_aved_axil_ila.v \
    xilinx_aved_debug_vio/sim/xilinx_aved_debug_vio.v

IP_SIM_INC_DIRS =

EXT_LIBS =

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
