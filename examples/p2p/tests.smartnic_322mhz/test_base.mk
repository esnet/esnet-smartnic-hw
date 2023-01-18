# -----------------------------------------------
# Path setup
# -----------------------------------------------
IP_ROOT := ..

# -----------------------------------------------
# IP config
# -----------------------------------------------
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
TOP = $(SVUNIT_TOP) smartnic_322mhz__tb.glbl smartnic_322mhz__tb.tb

# ----------------------------------------------------
# Sources
#   List source files and include directories for test
#   (see $(SCRIPTS_ROOT)/Makefiles/sources.mk)
#   NOTE: SVUnit sources are automatically included
# ----------------------------------------------------
SRC_FILES = $(PROJ_ROOT)/app_if/src/smartnic_322mhz_app.sv
INC_DIRS =
SRC_LIST_FILES = $(SVUNIT_SRC_LIST_FILE)

# ----------------------------------------------------
# Dependencies
#   List IP component and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/dependencies.mk for details)
# ----------------------------------------------------
COMPONENTS = rtl regio.verif \
             smartnic.common.std.verif \
             smartnic.common.axi4l.rtl \
             smartnic.common.axi4s.rtl \
             smartnic.common.axi4l.verif \
             smartnic.common.axi4s.verif \
             smartnic.smartnic_322mhz.rtl \
             smartnic.smartnic_322mhz.tb

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
ELAB_OPTS += --relax --debug typical
SIM_OPTS +=

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build_test pcap sim

pcap:
	cd $(SMARTNIC_ROOT)/src/smartnic_322mhz/tests/common/pcap; python3 gen_pcap.py;

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

