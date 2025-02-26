# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Board setup
# -----------------------------------------------
BOARD ?= au280 # Default of au280 can be overriden using make BOARD={au55c|au250}

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = esnet_shell

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
    xilinx.alveo.pkg \
    xilinx.alveo.rtl \
    xilinx.alveo.shell.rtl \
    core.blackbox

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
