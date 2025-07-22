# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Configuration
# Note: these parameters can also be provided
#       at the command line, e.g.:
#       make REGRESSION=1
#       make waves=ON
#       make SEED=29 waves=ON
# -----------------------------------------------
REGRESSION ?= 0
SEED ?= 0
waves ?= OFF

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk for details)
# ----------------------------------------------------
SUBCOMPONENTS = \
    smartnic.pkg \
    smartnic.rtl \
    smartnic.tb \
    smartnic_app.rtl \
    smartnic_app.regio.verif \
    smartnic_app.igr_p4.vf_loopback.rtl \
    smartnic_app.egr_p4.vf_loopback.rtl \
    smartnic_app.igr.demux.rtl \
    smartnic_app.igr.demux.regio.verif \
    smartnic_app.egr.mux.rtl \
    xilinx.hbm.verif \
    std.verif@common \
    axi4l.rtl@common \
    axi4l.verif@common \
    axi4s.rtl@common \
    axi4s.verif@common \
    axi4s.regio.verif@common

EXT_LIBS =

# ----------------------------------------------------
# Defines
#   List macro definitions.
#   Macros listed here will add to any defines set at
#   command line, as e.g.:
#     make DEFINES="DEBUG FAST=TRUE"
# ----------------------------------------------------
override DEFINES +=

# ----------------------------------------------------
# Run-time arguments
#   List runtime arguments passed to simulator as
#   plusarg (+ARG) references.
#   Arguments listed here will add to any arguments
#   set at the command line, as e.g.:
#   make PLUSARGS="FAST_SIM MODE=1"
# ----------------------------------------------------
override PLUSARGS +=

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =
ELAB_OPTS = --relax --debug typical
SIM_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build_test sim

build_test: _build_test
sim:        _sim
info:       _sim_info
clean:      _clean_test _clean_sim

.PHONY: all build_test sim info clean

# ----------------------------------------------------
# Import SVUNIT build targets/configuration
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/svunit.mk

# Add testbench as top module (in addition to SVUnit testrunner)
TOP += smartnic__tb.tb

# ----------------------------------------------------
# Import Vivado sim targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_sim.mk
