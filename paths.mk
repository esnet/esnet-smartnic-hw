# -----------------------------------------------
# Project path setup
# -----------------------------------------------
# Set relative to PROJ_ROOT (current) directory
# Note: PROJ_ROOT is configured in calling (parent) Makefile
CFG_ROOT     := $(abspath $(PROJ_ROOT)/cfg)
ONS_ROOT     := $(abspath $(PROJ_ROOT)/open-nic-shell)
LIB_ROOT     := $(abspath $(PROJ_ROOT)/esnet-fpga-library)

# Configure paths to tools/resources provided by library
include $(LIB_ROOT)/paths.mk
