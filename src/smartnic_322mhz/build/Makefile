# -----------------------------------------------
# (Global) Path setup
# -----------------------------------------------
IP_ROOT := ..

# -----------------------------------------------
# IP config
# -----------------------------------------------
include $(IP_ROOT)/config.mk

# Export path variables for use in build (Tcl) scripts
export APP_ROOT ?= $(PROJ_ROOT)/src/p4_app

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_322mhz

# -----------------------------------------------
# (Local) Paths
# -----------------------------------------------
OUT_DIR=out

# -----------------------------------------------
# Regmap YAML definitions
# -----------------------------------------------
REG_BLOCK_YAML = $(IP_ROOT)/reg/smartnic_322mhz.yaml \
                 $(LIB_ROOT)/src/axi4s/reg/axi4s_probe.yaml \
                 $(LIB_ROOT)/src/fifo/reg/fifo_ctrl_info.yaml \
                 $(LIB_ROOT)/src/fifo/reg/fifo_ctrl_wr_mon.yaml \
                 $(LIB_ROOT)/src/fifo/reg/fifo_ctrl_rd_mon.yaml \
                 $(LIB_ROOT)/src/fifo/reg/fifo_core.yaml \
                 $(LIB_ROOT)/src/reg/reg/reg_endian_check.yaml \
                 $(LIB_ROOT)/src/xilinx/hbm/reg/xilinx_hbm.yaml
                 

REG_DECODER_YAML := $(IP_ROOT)/reg/smartnic_322mhz_decoder.yaml \
                    $(IP_ROOT)/reg/smartnic_322mhz_app_sdnet_decoder.yaml \
                    $(LIB_ROOT)/src/fifo/reg/fifo_ctrl_decoder.yaml \
                    $(LIB_ROOT)/src/fifo/reg/fifo_core_decoder.yaml \
                    $(LIB_ROOT)/src/xilinx/hbm/reg/xilinx_hbm_decoder.yaml

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

reg_src: cp_app_dec _reg_src

cp_app_dec: $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml
	@cp $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml $(IP_ROOT)/reg

$(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml:
	$(MAKE) -C $(APP_ROOT)/app_if

.PHONY: reg_src 


ip:
	$(MAKE) -C $(LIB_ROOT)/src/axi4s/xilinx_ip synth
	$(MAKE) -C $(LIB_ROOT)/src/axi4l/xilinx_ip synth
	$(MAKE) -C $(LIB_ROOT)/src/fifo/xilinx_ip synth
	$(MAKE) -C $(IP_ROOT)/xilinx_ip synth


pre_synth: reg_src ip $(APP_ROOT)/app_if/smartnic_322mhz_app.dcp
synth:     _synth
opt:       _opt
place:     _place
phys_opt:  _phys_opt
route:     _route

$(APP_ROOT)/app_if/smartnic_322mhz_app.dcp:
	$(MAKE) -C $(APP_ROOT)/app_if

.PHONY: pre_synth synth opt place phys_opt route


reg_package: cp_app_dec | $(REGIO_YAML_DIR)
	$(REGIO_ROOT)/regio-flatten -i $(REGIO_YAML_INC_DIR) -o $(REGIO_YAML_DIR)/box1_322mhz_decoder.yaml \
        $(IP_ROOT)/reg/smartnic_322mhz_decoder.yaml

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

