# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Configuration
# Note: these parameters can also be provided
#       at the command line, e.g.:
#       make REGRESSION=1
#       make waves=ON
#       make SEED=29 waves=ON
#       make SIM=verilator
# -----------------------------------------------
REGRESSION ?= 0
SEED ?= 0
waves ?= OFF
SIM ?= xsim

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk for details)
# ----------------------------------------------------
SUBCOMPONENTS = \
    smartnic_250mhz.rtl \
    smartnic_250mhz.tb \
    std.verif@common \
    axi4l.rtl@common \
    axi4l.verif@common \
    axi4s.rtl@common \
    axi4s.verif@common

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
ifeq ($(SIM),xsim)
ELAB_OPTS = --debug typical
endif
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

# Attach the shared testbench to the simulator's root hierarchy.
ifeq ($(SIM),verilator)
SRC_FILES += ../common/verilator_bind.sv
else
TOP += smartnic_250mhz__tb.tb
endif

# ----------------------------------------------------
# Import sim targets (backend selected by SIM variable)
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/sim.mk
