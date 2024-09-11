# -----------------------------------------------
# Board setup
# -----------------------------------------------
BOARD ?= av80

# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Path setup
# -----------------------------------------------
# Export environment variables required by Tcl scripts
export AVED_ROOT = $(abspath $(COMPONENT_ROOT)/aved/hw)
export AVED_BASE_DESIGN = amd_v80_gen5x8_23.2_exdes_2

IP_REPO_PATHS = \
	$(AVED_ROOT)/hw/$(AVED_BASE_DESIGN)/src/iprepo

# ----------------------------------------------------
# BD listing
#
#   Each BD core in the source component needs to be
#   explicitly listed here. Each core must have a
#   corresponding Tcl stub describing BD creation
#   (Vivado `create_bd_design` command invocation) and
#   configuration in the current directory.
#
#   e.g.:
#
#   BD_LIST = bd1 bd2
#
#   Assumes ./bd1.tcl and ./bd2.tcl exist
#
#   Note: ./bd3.tcl and ./bd4.tcl could also exist, but
#   will be ignored by this makefile since they are
#   not explicitly listed.
# ----------------------------------------------------
BD_LIST = \
    xilinx_aved

# ----------------------------------------------------
# Simulation sources
#
#   List source files and include directories for compiling
#   the BD core (or a model of the component) for simulation.
#
#   NOTE: The paths to the sources should be specified
#         relative to the directory into which the BD output
#         products are generated. For example, to include the
#         verilog source file describing the simulation model
#         for BD core `foo`, the following could be used:
#
#         BD_SIM_SRC_FILES = foo/sim/foo.v
#
#         and NOT:
#
#         BD_SIM_SRC_FILES = <path-to-out-dir>/foo/sim/foo.v
#
#         (The <path-to-out-dir> is prepended automatically)
# ----------------------------------------------------
#  List simulation source files and include directories
#  (see $SCRIPTS_ROOT/Makefiles/templates/sources.mk)
BD_SIM_SRC_FILES =
BD_SIM_INC_DIRS =

#   List external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
EXT_LIBS =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: ip compile synth

ip:      _bd
compile: _bd_compile
synth:   _bd_synth
info:    _bd_info
status:  _bd_status
upgrade: _bd_upgrade
clean:   _bd_clean

.PHONY: all ip compile synth info status upgrade clean

# ----------------------------------------------------
# BD project management targets
#
#   These targets are used for managing block designs,
#   i.e. creating new BDs, or modifying existing BDs.
# ----------------------------------------------------
proj:       _bd_proj
proj_clean: _bd_proj_clean

.PHONY: proj proj_clean

# ----------------------------------------------------
# Import Vivado IP management targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_manage_bd.mk
