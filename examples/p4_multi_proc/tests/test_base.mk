# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

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
# Top
#   Specify top module(s) for elaboration
# ----------------------------------------------------
TOP = $(SVUNIT_TOP) smartnic_app__p4_only__tb.tb

# ----------------------------------------------------
# Sources
#   List source files and include directories for test
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: SVUnit sources are automatically included
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES = $(SVUNIT_SRC_LIST_FILE)

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk for details)
# ----------------------------------------------------
SUBCOMPONENTS = \
    vitisnetp4_igr.rtl \
    vitisnetp4_igr.verif \
    smartnic_app.p4_only.rtl \
    smartnic_app.p4_only.verif \
    smartnic_app.p4_only.tb \
    axi4l.rtl@common@smartnic \
    axi4s.rtl@common@smartnic \
    axi4l.verif@common@smartnic \
    axi4s.verif@common@smartnic

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
ELAB_OPTS = --debug typical
SIM_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: p4bm build_test sim

p4bm:
	$(MAKE) sim-all P4BM_LOGFILE="-l log" -C $(COMPONENT_ROOT)/../p4/sim_igr

build_test: _build_test
sim:        _sim
info:       _sim_info
clean:      _clean_test _clean_sim

.PHONY: all p4bm build_test sim info clean

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
# Import VitisNetP4 IP simulation configuration
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/test_vitisnetp4.mk

# ----------------------------------------------------
# Import Vivado sim targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_sim.mk
