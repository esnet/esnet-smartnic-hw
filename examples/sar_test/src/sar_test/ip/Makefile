# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

# ----------------------------------------------------
# IP listing
# ----------------------------------------------------
IP_LIST = \
    sar_test_clk_wiz

# ----------------------------------------------------
# Simulation sources
# ----------------------------------------------------
IP_SIM_SRC_FILES = \
    sar_test_clk_wiz/sar_test_clk_wiz.v \
    sar_test_clk_wiz/sar_test_clk_wiz_clk_wiz.v \

IP_SIM_INC_DIRS =

EXT_LIBS =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
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

# ----------------------------------------------------
# Import Vivado IP management targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_manage_ip.mk
