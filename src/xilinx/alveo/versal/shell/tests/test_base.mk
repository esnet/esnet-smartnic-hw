# -----------------------------------------------
# Board selection
# -----------------------------------------------
BOARD ?= av80

# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../../../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Configuration
# -----------------------------------------------
REGRESSION ?= 0
SEED ?= 0
waves ?= OFF
SIM ?= xsim

# ----------------------------------------------------
# Dependencies
# ----------------------------------------------------
SUBCOMPONENTS ?= \
    xilinx.alveo.versal.shell.rtl \
    core.stub.rtl

EXT_LIBS =

# ----------------------------------------------------
# Defines
# ----------------------------------------------------
override DEFINES +=

# ----------------------------------------------------
# Run-time arguments
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

# ----------------------------------------------------
# Import sim targets (backend selected by SIM variable)
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/sim.mk
