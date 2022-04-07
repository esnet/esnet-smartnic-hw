# -----------------------------------------------
# Project path setup
# -----------------------------------------------
# Set relative to PROJ_ROOT (current) directory
# Note: PROJ_ROOT is configured in calling (parent) Makefile
CFG_ROOT        := $(abspath $(PROJ_ROOT)/cfg)
export LIB_ROOT ?= $(abspath $(PROJ_ROOT)/esnet-fpga-library)
SCRIPTS_ROOT    := $(abspath $(LIB_ROOT)/scripts)
REGIO_ROOT      := $(abspath $(LIB_ROOT)/tools/regio)
SVUNIT_ROOT     := $(abspath $(LIB_ROOT)/tools/svunit)
export ONS_ROOT ?= $(abspath $(PROJ_ROOT)/open-nic-shell)
