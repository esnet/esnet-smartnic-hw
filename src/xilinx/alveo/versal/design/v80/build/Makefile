# -----------------------------------------------
# Component setup
# -----------------------------------------------
export BOARD = av80

COMPONENT_ROOT := ../../../../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = esnet_smartnic

# -----------------------------------------------
# Build config
# -----------------------------------------------
BUILD_TIMESTAMP = $(shell date +"%s")
BUILD_ID ?= $(BUILD_TIMESTAMP)
CORE ?= stub

AVED_BASE_DESIGN = amd_v80_gen5x8_25.1

# Board-specific shell directory (provides impl constraints and hook TCL files)
SHELL_BOARD_DIR = $(SRC_ROOT)/xilinx/alveo/versal/shell/v80

# Shell synth DCP: produced by xilinx.alveo.versal.shell.v80.build (non-project flow)
SHELL_SUBCOMPONENT_REF = xilinx.alveo.versal.shell.v80.build
SHELL_DCP_FILE = $(call get_lib_component_out_path_from_ref,$(SHELL_SUBCOMPONENT_REF),$(LIB_OUTPUT_ROOT))/$(TOP).synth.dcp

# Core OOC DCP: produced by core.<CORE>.build.v80 (non-project flow)
CORE_SUBCOMPONENT_REF = core.$(CORE).build.v80
CORE_DCP_FILE = $(call get_lib_component_out_path_from_ref,$(CORE_SUBCOMPONENT_REF),$(LIB_OUTPUT_ROOT))/core.synth.dcp

# Map to the generic assembly interface (shell=top-level, core fills i_core cell)
TOP_DCP_FILE = $(SHELL_DCP_FILE)
CELL_DCPS    = i_core:$(CORE_DCP_FILE)

# Re-run from link if either input DCP changes
STAGE_DEPS = $(SHELL_DCP_FILE) $(CORE_DCP_FILE)

# Implementation-only constraints from the shell board directory
CONSTRAINTS_XDC_IMPL = \
    $(abspath $(SHELL_BOARD_DIR)/impl.pins.xdc) \
    $(abspath $(SHELL_BOARD_DIR)/impl.xdc)

# TCL hook files attached to implementation run steps
IMPL_HOOK_TCL_FILES = $(abspath $(wildcard $(SHELL_BOARD_DIR)/*.tcl))

# AVED IP repository — needed by Vivado link_design to resolve the CIPS
# partition context during full-device implementation.
IP_REPO_PATHS = $(abspath $(SRC_ROOT)/xilinx/aved/hw/$(AVED_BASE_DESIGN)/src/iprepo)

# Link + implementation stages (no synth here — shell and core synthesize separately)
BUILD_STAGES = link opt place place_opt route route_opt device_image xsa

# ----------------------------------------------------
# Sources (none — pre-synthesized DCPs only)
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   Both OOC builds are invoked as subcomponents so that
#   their DCP caching guards run before assembly starts.
# ----------------------------------------------------
SUBCOMPONENTS = \
    $(SHELL_SUBCOMPONENT_REF) \
    $(CORE_SUBCOMPONENT_REF)

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build

build: _np_xsa

.PHONY: build

pre_synth:    _pre_synth
link:         _np_link
opt:          _np_opt
place:        _np_place
place_opt:    _np_place_opt
route:        _np_route
route_opt:    _np_route_opt
device_image: _np_device_image
xsa:          _np_xsa
info:         _build_info
clean:        _build_clean

.PHONY: pre_synth link opt place place_opt route route_opt device_image xsa info clean

# -----------------------------------------------
# Include non-project build definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_non_proj.mk
