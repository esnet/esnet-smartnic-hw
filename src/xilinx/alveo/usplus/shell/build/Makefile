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
BUILD_TIMESTAMP ?= $(shell date +"%s")
BUILD_ID ?= $(BUILD_TIMESTAMP)

DEFINES = BOARD=$(BOARD) __$(BOARD)__

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: along with explicitly-listed sources, all
#   source files from ./src are added automatically, and
#   .include is added as an include directory automatically.
# ----------------------------------------------------
SRC_FILES =
INC_DIRS = ../../rtl/include $(COMPONENT_OUT_PATH)/include
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
CONSTRAINTS_XDC_SYNTH = $(abspath $(BOARD)/timing.xdc)
BUILD_STAGES = synth
VPD_BUILD_INFO := $(COMPONENT_OUT_PATH)/include/shell_build_info.svh
VPD_BUILD_INFO_SCRIPT := $(SMARTNIC_ROOT)/scripts/generate_shell_build_info.py
export SHELL_VPD_BUILD_ID = $(BUILD_ID)
export SHELL_VPD_BUILD_TIMESTAMP ?= $(if $(filter command line environment,$(origin BUILD_TIMESTAMP)),$(BUILD_TIMESTAMP),)
export SHELL_VPD_APPLICATION_ID ?= $(or $(SN_HW_APP_NAME),shell)
export SHELL_VPD_BUILD_GIT_REPO ?= $(CI_PROJECT_NAME)
export SHELL_VPD_BUILD_GIT_HASH ?= $(CI_COMMIT_SHORT_SHA)
STAGE_DEPS = $(COMPONENT_OUT_PATH)/synth/sources.tcl $(CONSTRAINTS_XDC_SYNTH) $(VPD_BUILD_INFO)

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

# Declare the generated header explicitly: wildcard discovery runs before it
# exists on a clean build. Keep metadata stable when build identity is unchanged.
SV_HDR_FILES := $(sort $(SV_HDR_FILES) $(VPD_BUILD_INFO))
$(SYNTH_SOURCES_OBJ): $(VPD_BUILD_INFO)
$(VPD_BUILD_INFO): FORCE
	@python3 $(VPD_BUILD_INFO_SCRIPT) --output $@ --repo $(SMARTNIC_ROOT)
