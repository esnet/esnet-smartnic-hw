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
export BOARD

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_322mhz_app

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: opt

reg:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=fifo.regio@common@smartnic
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=p4_and_verilog.regio

ip:
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=fifo.ip@common@smartnic
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=vitisnetp4.ip
.PHONY: ip

pre_synth: reg ip
synth:     _synth
opt:       _opt
.PHONY: pre_synth synth opt

clean: _clean_build
.PHONY: clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_core.mk
