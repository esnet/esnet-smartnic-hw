# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Board setup
# -----------------------------------------------
BOARD ?= au55c # Default of au55c can be overriden using make BOARD={au280|au250}

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = esnet_shell

# -----------------------------------------------
# Source directory (board-specific top-level)
# -----------------------------------------------
SRC_DIR = $(BOARD)/src

# -----------------------------------------------
# Build config
# -----------------------------------------------
BUILD_TIMESTAMP = $(shell date +"%s")
BUILD_ID ?= $(BUILD_TIMESTAMP)

DEFINES = BOARD=$(BOARD) __$(BOARD)__

CONSTRAINTS_XDC_USER = $(abspath $(wildcard $(BOARD)/*.xdc))

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: along with explicitly-listed sources, all
#   source files from ./src are added automatically, and
#   .include is added as an include directory automatically.
# ----------------------------------------------------
SRC_FILES =
INC_DIRS = ../../rtl/include
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
SUBCOMPONENTS = \
    shell.pkg \
    xilinx.alveo.usplus.pkg \
    xilinx.alveo.usplus.rtl \
    xilinx.alveo.usplus.shell.rtl \
    core.blackbox

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
# Shell synthesis leaves i_core as a black box. The project assembly flow
# inserts the selected core DCP and owns implementation and bitstream output.
OOC = 0
CONSTRAINTS_XDC_SYNTH = $(CONSTRAINTS_XDC_USER)
BUILD_STAGES = synth
STAGE_DEPS = $(COMPONENT_OUT_PATH)/synth/sources.tcl

all: synth

pre_synth: _pre_synth
synth: _np_synth
	@$(MAKE) -s _build_np_synth_lib
info: _build_info
clean: _build_clean

.PHONY: all pre_synth synth info clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_non_proj.mk
