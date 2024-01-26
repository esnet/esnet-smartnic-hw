# -----------------------------------------------
# (Global) Path setup
# -----------------------------------------------
IP_ROOT := ..

# -----------------------------------------------
# IP config
# -----------------------------------------------
include $(IP_ROOT)/config.mk

# Export path variables for use in build (Tcl) scripts
export LIB_ROOT
export OUTPUT_ROOT
export BOARD

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_250mhz

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: opt
pre_synth: reg ip
synth:     _synth
opt:       _opt

.PHONY: pre_synth synth opt

reg:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=fifo.regio@common
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=smartnic_250mhz.regio

ip:
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=xilinx.axi.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=xilinx.axis.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=axi4s.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=fifo.ip@common

ip_clean:
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=xilinx.axi.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=xilinx.axis.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=axi4s.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=fifo.ip@common

.PHONY: reg ip ip_clean

clean: clean_build ip_clean

.PHONY: clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_core.mk
