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
export APP_ROOT ?= $(PROJ_ROOT)/src/p4_app
export OUTPUT_ROOT

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_322mhz

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: opt

cp_app_dec: $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml
	@cp $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml $(IP_ROOT)/regio

$(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml:
	@$(MAKE) -s -C $(APP_ROOT)/app_if

reg: cp_app_dec
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=axi4s.regio@common
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=fifo.regio@common
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=reg.endian.regio@common
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=reg.proxy.regio@common
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=xilinx.hbm.regio@common
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=smartnic_322mhz.regio

ip:
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=axi4s.xilinx_ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=fifo.xilinx_ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=xilinx.axi.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=xilinx.axis.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=smartnic_322mhz.xilinx_ip

.PHONY: reg ip

pre_synth: reg ip $(APP_ROOT)/app_if/smartnic_322mhz_app.dcp
synth:     _synth
opt:       _opt

$(APP_ROOT)/app_if/smartnic_322mhz_app.dcp:
	@$(MAKE) -s -C $(APP_ROOT)/app_if

.PHONY: pre_synth synth opt

clean: _clean_build

.PHONY: clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_core.mk
