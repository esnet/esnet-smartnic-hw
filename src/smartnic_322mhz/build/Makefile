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
export IP_ROOT

# -----------------------------------------------
# (Local) Paths
# -----------------------------------------------
# Export path variables for use in build (Tcl) scripts
export OUT_DIR=out
export SRC_DIR=src
export XILINX_IP_DIR=../xilinx_ip

AXI4S_XILINX_IP_DIR=$(LIB_ROOT)/src/axi4s/xilinx_ip
AXI4L_XILINX_IP_DIR=$(LIB_ROOT)/src/axi4l/xilinx_ip
FIFO_XILINX_IP_DIR=$(LIB_ROOT)/src/fifo/xilinx_ip

REGIO_YAML_DIR=regio-yaml

# -----------------------------------------------
# Regmap YAML definitions
# -----------------------------------------------
REG_BLOCK_YAML = $(IP_ROOT)/reg/smartnic_322mhz.yaml \
	$(LIB_ROOT)/src/axi4s/reg/axi4s_probe.yaml \
	$(LIB_ROOT)/src/fifo/reg/fifo_ctrl_info.yaml \
	$(LIB_ROOT)/src/fifo/reg/fifo_ctrl_wr_mon.yaml \
	$(LIB_ROOT)/src/fifo/reg/fifo_ctrl_rd_mon.yaml \
	$(LIB_ROOT)/src/fifo/reg/fifo_core.yaml \
	$(LIB_ROOT)/src/reg/reg/reg_endian_check.yaml

REG_DECODER_YAML := \
	$(IP_ROOT)/reg/smartnic_322mhz_decoder.yaml \
	$(IP_ROOT)/reg/smartnic_322mhz_app_sdnet_decoder.yaml \
	$(LIB_ROOT)/src/fifo/reg/fifo_ctrl_decoder.yaml \
	$(LIB_ROOT)/src/fifo/reg/fifo_core_decoder.yaml

# -----------------------------------------------
# regio options
# -----------------------------------------------
REGIO_ELABORATE_OPTS :=
REGIO_GENERATE_OPTS :=

REGIO_SRC_OUTPUT_DIR := $(SRC_DIR)

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: reg_package build_core

build_ip:
	$(MAKE) -C $(AXI4L_XILINX_IP_DIR) synth
	$(MAKE) -C $(AXI4S_XILINX_IP_DIR) synth
	$(MAKE) -C $(FIFO_XILINX_IP_DIR) synth
	$(MAKE) -C $(XILINX_IP_DIR) synth

build_app:
	$(MAKE) -C $(APP_ROOT)/app_if

build_core: reg_src build_ip $(APP_ROOT)/app_if/smartnic_322mhz_app.dcp | $(OUT_DIR)
	vivado -mode tcl -source build.tcl

clean: _clean_reg
	@rm -rf $(OUT_DIR)
	@rm -rf $(SRC_DIR)
	@rm -rf $(REGIO_YAML_DIR)
	@rm -rf $(IP_ROOT)/reg/smartnic_322mhz_app_decoder.yaml
	@rm -rf *.hw
	@rm -f *.jou
	@rm -f *.log
	@rm -f *.dcp
	@rm -f *.rpt

reg_src: cp_app_dec _reg_src
.PHONY: reg_src

cp_app_dec: $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml
	@cp $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml $(IP_ROOT)/reg

reg_package: cp_app_dec | $(REGIO_YAML_DIR)
	$(REGIO_ROOT)/regio-flatten -i $(REGIO_YAML_INC_DIR) -o $(REGIO_YAML_DIR)/box1_322mhz_decoder.yaml $(IP_ROOT)/reg/smartnic_322mhz_decoder.yaml

$(OUT_DIR):
	@mkdir $(OUT_DIR)

$(REGIO_YAML_DIR):
	@mkdir $(REGIO_YAML_DIR)

$(APP_ROOT)/app_if/smartnic_322mhz_app.dcp:
	$(MAKE) -C $(APP_ROOT)/app_if

$(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml:
	$(MAKE) -C $(APP_ROOT)/app_if

# -----------------------------------------------
# Include regio targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/regio.mk

