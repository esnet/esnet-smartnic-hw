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

AVED_BASE_DESIGN = amd_v80_gen5x8_25.1

# Custom IP repository containing AVED IPs (smbus, cmd_queue, etc.) — must be
# configured before loading the BD so Vivado can resolve locked BD sub-IPs.
IP_REPO_PATHS = \
    $(abspath $(COMPONENT_ROOT)/aved/hw/$(AVED_BASE_DESIGN)/src/iprepo)

# No synthesis XDC — OOC boundary clocks are defined in timing_ooc.xdc.
CONSTRAINTS_XDC_USER = $(abspath timing_ooc.xdc)

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: along with explicitly-listed sources, all
#   source files from ./src are added automatically, and
#   .include is added as an include directory automatically.
# ----------------------------------------------------
SRC_FILES =
INC_DIRS = ../../../rtl/include
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
SUBCOMPONENTS = \
    shell.pkg \
    shell.rtl \
    xilinx.alveo.versal.bd \
    xilinx.alveo.versal.shell.rtl \
    core.blackbox

# Full-device synthesis (no OOC) — core is a black_box stub.
# OOC_per_BD is applied to BD files inside build_non_proj.tcl so the
# CIPS/NOC partition context is correctly embedded in the shell DCP.
OOC = 0

CONSTRAINTS_XDC_SYNTH = $(abspath timing_ooc.xdc)

BUILD_STAGES = synth

# Re-synthesize when sources change (sources.tcl is a real file target, rebuilt when deps change)
STAGE_DEPS = $(COMPONENT_OUT_PATH)/synth/sources.tcl

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: synth

pre_synth: _pre_synth
synth: _np_synth
	@$(MAKE) -s _build_np_synth_lib
info:  _build_info
clean: _build_clean

.PHONY: pre_synth synth info clean

# -----------------------------------------------
# Include non-project build definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_non_proj.mk
