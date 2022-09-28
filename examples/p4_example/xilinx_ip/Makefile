# -----------------------------------------------
# Path setup
# -----------------------------------------------
IP_ROOT := ..

# -----------------------------------------------
# IP config
# -----------------------------------------------
include $(IP_ROOT)/config.mk

# -----------------------------------------------
# VitisNetP4 IP config
# -----------------------------------------------
VITISNETP4_IP_NAME = sdnet_0
VITISNETP4_IP_DIR = .

P4_FILE = $(abspath $(IP_ROOT)/p4/p4_and_verilog.p4)
P4_OPTS = {CONFIG.PKT_RATE 150}

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
    $(VITISNETP4_IP_NAME)/src/verilog/$(VITISNETP4_IP_NAME).sv 

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

compile: _ip _vitisnetp4_drv_dpi _compile

synth: _ip_synth

clean: _clean_compile vitisnetp4_clean

.PHONY: all compile synth clean

vitisnetp4_clean: _ip_proj_clean
	@rm -rf $(VITISNETP4_IP_NAME)

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk

# ----------------------------------------------------
# Import Vivado IP management targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_vitisnetp4.mk



