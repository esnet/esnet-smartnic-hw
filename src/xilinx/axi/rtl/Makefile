# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../..

include $(COMPONENT_ROOT)/config.mk

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: along with explicitly-listed sources, all
#   source files from ./src are added automatically, and
#   .include is added as an include directory automatically.
# ----------------------------------------------------
SRC_FILES = \
    $(XILINX_VIVADO)/data/ip/xilinx/axi_infrastructure_v1_1/hdl/axi_infrastructure_v1_1_vl_rfs.v \
    $(XILINX_VIVADO)/data/ip/xilinx/axi_register_slice_v2_1/hdl/axi_register_slice_v2_1_vl_rfs.v

INC_DIRS = \
    $(XILINX_VIVADO)/data/ip/xilinx/axi_infrastructure_v1_1/hdl

SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
SUBCOMPONENTS = \
    axi3.rtl@common \
    axi4l.rtl@common \
    util.rtl@common

# Import IP core revision details from version-specific tool config
include $(CFG_ROOT)/vivado_ip.mk

EXT_LIBS = \
    unisims_ver \
    axi_register_slice_v$(IP_VER_AXI_REGISTER_SLICE)

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES = AXI_REGISTER_SLICE_MODULE_NAME=axi_register_slice_v$(IP_VER_AXI_REGISTER_SLICE)_axi_register_slice

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: compile synth

compile: _compile_sim
synth:   _compile_synth
info:    _compile_info
clean:   _compile_clean

.PHONY: all compile synth info clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
