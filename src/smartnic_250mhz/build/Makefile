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

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_250mhz

# -----------------------------------------------
# Regmap YAML definitions
# -----------------------------------------------
REG_BLOCK_YAML = $(IP_ROOT)/regio/smartnic_250mhz.yaml \
                 $(LIB_ROOT)/src/fifo/regio/fifo_ctrl_info.yaml \
                 $(LIB_ROOT)/src/fifo/regio/fifo_ctrl_wr_mon.yaml \
                 $(LIB_ROOT)/src/fifo/regio/fifo_ctrl_rd_mon.yaml \
                 $(LIB_ROOT)/src/fifo/regio/fifo_core.yaml

REG_DECODER_YAML := $(IP_ROOT)/regio/smartnic_250mhz_decoder.yaml \
                    $(LIB_ROOT)/src/fifo/regio/fifo_ctrl_decoder.yaml \
                    $(LIB_ROOT)/src/fifo/regio/fifo_core_decoder.yaml

# -----------------------------------------------
# regio options
# -----------------------------------------------
REGIO_ELABORATE_OPTS :=
REGIO_GENERATE_OPTS := 
REGIO_YAML_DIR=regio-yaml

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: reg_package opt
pre_synth: _reg_rtl ip
synth:     _synth
opt:       _opt
place:     _place
phys_opt:  _phys_opt
route:     _route

.PHONY: pre_synth synth opt place phys_opt route

ip:
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=xilinx.axi.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=xilinx.axis.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=axi4l.xilinx_ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=axi4s.xilinx_ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=fifo.xilinx_ip@common

ip_clean:
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=xilinx.axi.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=xilinx.axis.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=axi4l.xilinx_ip@common
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=axi4s.xilinx_ip@common
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=fifo.xilinx_ip@common

.PHONY: ip ip_clean

reg_package: $(REGIO_YAML_DIR)
	$(REGIO_ROOT)/regio-flatten -i $(REGIO_YAML_INC_DIR) -o $(REGIO_YAML_DIR)/box0_250mhz_decoder.yaml \
        $(IP_ROOT)/regio/smartnic_250mhz_decoder.yaml

$(REGIO_YAML_DIR):
	@mkdir $(REGIO_YAML_DIR)


clean: _reg_clean _clean_build ip_clean
	@rm -rf $(REGIO_YAML_DIR)

.PHONY: clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_core.mk

# -----------------------------------------------
# Include regio targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/regio.mk
