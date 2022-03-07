# -----------------------------------------------
# Path setup
# -----------------------------------------------
IP_ROOT := ../..

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
TOP = $(SVUNIT_TOP) p4_app_tb.glbl p4_app_tb.tb

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
COMPONENTS = rtl verif tb \
             axi4l_rtl=$(LIB_ROOT)/src/axi4l/rtl \
             axi4s_rtl=$(LIB_ROOT)/src/axi4s/rtl

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

ELAB_OPTS += --relax --debug typical --sv_lib vitisnetp4_drv_dpi --sv_root $(PROJ_ROOT)/src/p4_app/xilinx_ip/sdnet_0/bin

SIM_OPTS +=

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: p4bm build_test sim

p4bm:
	$(MAKE) sim-all-svh P4BM_LOGFILE="-l log" -C $(IP_ROOT)/p4/sim

build_test: _build_test

sim: _sim

clean: _clean_test _clean_sim

.PHONY: all p4bm build_test sim clean

# ----------------------------------------------------
# Test configuration
# ----------------------------------------------------
LIB_NAME = test
SRC_DIR = .
INC_DIR = .

# ----------------------------------------------------
# Import SVUNIT build targets/configuration
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/svunit.mk

# Export SVUNIT configuration
SVUNIT_TOP = $(LIB_NAME).$(SVUNIT_TOP_MODULE)
SVUNIT_SRC_LIST_FILE = $(SVUNIT_FILE_LIST)

# ----------------------------------------------------
# Import Vivado sim targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_sim.mk

