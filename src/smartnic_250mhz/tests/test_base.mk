# -----------------------------------------------
# IP config (for compilation library setup)
# -----------------------------------------------
IP_ROOT = ../..
include $(IP_ROOT)/config.mk

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
# Top
#   Specify top module(s) for elaboration
# ----------------------------------------------------
TOP = $(SVUNIT_TOP) smartnic_250mhz__tb.tb

# ----------------------------------------------------
# Sources
#   List source files and include directories for test
#   (see $(SCRIPTS_ROOT)/Makefiles/sources.mk)
#   NOTE: SVUnit sources are automatically included
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES = $(SVUNIT_SRC_LIST_FILE)

# ----------------------------------------------------
# Dependencies
#   List IP component and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/dependencies.mk for details)
# ----------------------------------------------------
COMPONENTS = smartnic_250mhz.rtl \
			 smartnic_250mhz.tb \
             std.verif@common \
             packet.verif@common \
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
override DEFINES += SIMULATION

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS +=
ELAB_OPTS += --debug typical
SIM_OPTS +=

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build_test sim

build_test: _build_test

sim: _sim

clean: _clean_test _clean_sim

.PHONY: all build_test sim clean

# ----------------------------------------------------
# Test configuration
# ----------------------------------------------------
SRC_DIR = .
INC_DIR = .

# ----------------------------------------------------
# Import SVUNIT build targets/configuration
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/svunit.mk

# Export SVUNIT configuration
SVUNIT_TOP = $(COMPONENT_NAME).$(SVUNIT_TOP_MODULE)
SVUNIT_SRC_LIST_FILE = $(SVUNIT_FILE_LIST)

# ----------------------------------------------------
# Import Vivado sim targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_sim.mk
