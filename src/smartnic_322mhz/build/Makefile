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

# -----------------------------------------------
# Regmap YAML definitions
# -----------------------------------------------
REG_BLOCK_YAML = $(IP_ROOT)/regio/smartnic_322mhz.yaml \
                 $(LIB_ROOT)/src/axi4s/regio/axi4s_probe.yaml \
                 $(LIB_ROOT)/src/axi4s/regio/axi4s_split_join.yaml \
                 $(LIB_ROOT)/src/fifo/regio/fifo_ctrl_info.yaml \
                 $(LIB_ROOT)/src/fifo/regio/fifo_ctrl_wr_mon.yaml \
                 $(LIB_ROOT)/src/fifo/regio/fifo_ctrl_rd_mon.yaml \
                 $(LIB_ROOT)/src/fifo/regio/fifo_core.yaml \
                 $(LIB_ROOT)/src/reg/endian/regio/reg_endian_check.yaml \
                 $(LIB_ROOT)/src/reg/proxy/regio/reg_proxy.yaml \
                 $(LIB_ROOT)/src/xilinx/hbm/regio/xilinx_hbm.yaml

REG_DECODER_YAML := $(IP_ROOT)/regio/smartnic_322mhz_decoder.yaml \
                    $(IP_ROOT)/regio/smartnic_322mhz_app_sdnet_decoder.yaml \
                    $(LIB_ROOT)/src/fifo/regio/fifo_ctrl_decoder.yaml \
                    $(LIB_ROOT)/src/fifo/regio/fifo_core_decoder.yaml \
                    $(LIB_ROOT)/src/axi4s/regio/axi4s_split_join_decoder.yaml \
                    $(LIB_ROOT)/src/xilinx/hbm/regio/xilinx_hbm_decoder.yaml

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

reg_rtl: cp_app_dec _reg_rtl

cp_app_dec: $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml
	@cp $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml $(IP_ROOT)/regio

$(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml:
	@$(MAKE) -s -C $(APP_ROOT)/app_if

.PHONY: reg_rtl 

ip:
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=axi4s.xilinx_ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=fifo.xilinx_ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=xilinx.axi.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=xilinx.axis.ip@common
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=smartnic_322mhz.xilinx_ip
.PHONY: ip


pre_synth: reg_rtl ip $(APP_ROOT)/app_if/smartnic_322mhz_app.dcp
synth:     _synth
opt:       _opt
place:     _place
phys_opt:  _phys_opt
route:     _route

$(APP_ROOT)/app_if/smartnic_322mhz_app.dcp:
	@$(MAKE) -s -C $(APP_ROOT)/app_if

.PHONY: pre_synth synth opt place phys_opt route


reg_package: cp_app_dec | $(REGIO_YAML_DIR)
	$(REGIO_ROOT)/regio-flatten -i $(REGIO_YAML_INC_DIR) -o $(REGIO_YAML_DIR)/box1_322mhz_decoder.yaml \
        $(IP_ROOT)/regio/smartnic_322mhz_decoder.yaml

$(REGIO_YAML_DIR):
	@mkdir $(REGIO_YAML_DIR)


clean: _clean_reg _clean_build
	@rm -f smartnic_322mhz_app_decoder.yaml
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
