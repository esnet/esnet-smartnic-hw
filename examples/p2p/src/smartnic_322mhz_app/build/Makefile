# -----------------------------------------------
# (Global) Path setup
# -----------------------------------------------
IP_ROOT := ..

include $(IP_ROOT)/config.mk

# -----------------------------------------------
# Export parameters used in add_sources.tcl
# -----------------------------------------------
export LIB_ROOT
export SRC_ROOT
export OUTPUT_ROOT

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_322mhz_app

# -----------------------------------------------
# Regmap YAML definitions
# -----------------------------------------------
REG_BLOCK_YAML =
REG_DECODER_YAML := \
    $(APP_DIR)/app_if/src/smartnic_322mhz_app_decoder.yaml \
    $(LIB_ROOT)/src/fifo/regio/fifo_core_decoder.yaml


# -----------------------------------------------
# regio options
# -----------------------------------------------
REGIO_ELABORATE_OPTS :=
REGIO_GENERATE_OPTS := --recursive

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: opt

ip:
	@$(MAKE) -s -C $(SRC_ROOT) synth BOARD=$(BOARD) COMPONENT=fifo.xilinx_ip@common@smartnic
	@$(MAKE) -s -C $(SRC_ROOT) synth BOARD=$(BOARD) COMPONENT=axi4s.xilinx_ip@common@smartnic
.PHONY: ip

pre_synth: _reg_rtl ip
synth:     _synth
opt:       _opt
place:     _place
phys_opt:  _phys_opt
route:     _route
.PHONY: pre_synth synth opt place phys_opt route

clean: _reg_clean _clean_build
.PHONY: clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_core.mk

# -----------------------------------------------
# Include regio targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/regio.mk

