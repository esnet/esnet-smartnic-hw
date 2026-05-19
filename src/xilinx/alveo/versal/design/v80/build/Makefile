# -----------------------------------------------
# Board / component setup
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

# Custom IP repository containing AVED IPs
IP_REPO_PATHS = \
    $(abspath $(COMPONENT_ROOT)/aved/hw/$(AVED_BASE_DESIGN)/src/iprepo)

# Board-specific shell directory (provides impl constraints and hook TCL files)
SHELL_BOARD_DIR = $(SRC_ROOT)/xilinx/alveo/versal/shell/v80

# No synthesis XDC — timing constraints are carried in the shell OOC DCP context
CONSTRAINTS_XDC_USER =

# Implementation-only constraints from the shell board directory
CONSTRAINTS_XDC_IMPL = \
    $(abspath $(SHELL_BOARD_DIR)/impl.pins.xdc) \
    $(abspath $(SHELL_BOARD_DIR)/impl.xdc)

# TCL hook files attached to implementation run steps
IMPL_HOOK_TCL_FILES = $(abspath $(wildcard $(SHELL_BOARD_DIR)/*.tcl))

# Versal uses write_device_image instead of write_bitstream
BUILD_STAGES = synth opt place place_opt route route_opt device_image

# ----------------------------------------------------
# Sources
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   - Shell OOC DCP (provides esnet_smartnic with core as black_box)
#   - Core RTL (provides the real core implementation)
# ----------------------------------------------------
SUBCOMPONENTS = \
    xilinx.alveo.versal.shell.v80.build \
    core.$(CORE)

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build

build: route_opt bitstream flash

.PHONY: build

pre_synth: _pre_synth
synth:     _build_synth
opt:       _build_opt
place:     _build_place
place_opt: _build_place_opt
route:     _build_route
route_opt: _build_route_opt
bitstream: _build_bitstream
flash:     _build_flash
validate:  _build_validate
info:      _build_info
clean:     _build_clean

.PHONY: pre_synth synth opt place place_opt route route_opt bitstream flash validate info clean

# ----------------------------------------------------
# Project management targets
# ----------------------------------------------------
proj       : _proj
proj_clean : _proj_clean

.PHONY: proj proj_clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_top.mk
