# ----------------------------------------------------
# Application config
# ----------------------------------------------------
APP_DIR ?= ../..
include $(APP_DIR)/.app_config.mk

# -----------------------------------------------
# IP config (for compilation library setup)
# -----------------------------------------------
IP_ROOT = ../..
include $(IP_ROOT)/config.mk

# -----------------------------------------------
# Library setup
# -----------------------------------------------
LIB_NAME = p4_app_xilinx_ip

# -----------------------------------------------
# VitisNetP4 IP config
# -----------------------------------------------
VITISNETP4_IP_NAME = sdnet_0
VITISNETP4_IP_DIR = .

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/sources.mk)
#   Note: if no sources are explicitly listed, all
#   source files from ./src are added automatically,
#   with include directory ./include
# ----------------------------------------------------
IP_LIST = $(VITISNETP4_IP_NAME)
SRC_FILES = \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_top_pkg.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_pkg.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_sync_fifos.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_header_sequence_identifier.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_header_field_extractor.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_error_check_module.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_parser_engine.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_deparser_engine.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_action_engine.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_lookup_engine.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_axi4lite_interconnect.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_statistics_registers.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_match_action_engine.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME)_top.sv \
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME).sv \
	$(VITISNETP4_IP_NAME)/$(VITISNETP4_IP_NAME)_wrapper.sv

INC_DIRS = \
    $(VITISNETP4_IP_NAME)/src/hw/include

SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List IP component and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/dependencies.mk)
# ----------------------------------------------------
COMPONENTS =
EXT_LIBS = cam_v2_3_0 \
           vitis_net_p4_v1_1_0

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS=
ELAB_OPTS=--debug typical
SIM_OPTS=

# ----------------------------------------------------
# Compile Targets
# ----------------------------------------------------
all: compile

compile: ip _vitisnetp4_drv_dpi _compile

synth: ip _ip_synth

ip: _ip vitisnetp4_wrapper

clean: _clean_compile vitisnetp4_clean

.PHONY: all compile synth ip clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk

# ----------------------------------------------------
# Import Vivado IP management targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_vitisnetp4.mk

vitisnetp4_wrapper: $(VITISNETP4_XCI_DIR)/$(VITISNETP4_IP_NAME)_wrapper.sv
.PHONY: vitisnetp4_wrapper

$(VITISNETP4_XCI_DIR)/$(VITISNETP4_IP_NAME)_wrapper.sv: $(VITISNETP4_XCI_FILE)
	../gen_vitisnetp4_wrapper.py $(VITISNETP4_XCI_FILE) --out_dir $(VITISNETP4_XCI_DIR) --template-dir $(abspath ..)

vitisnetp4_clean: _ip_proj_clean
	@rm -rf $(VITISNETP4_IP_NAME)

.PHONY: vitisnetp4_clean
