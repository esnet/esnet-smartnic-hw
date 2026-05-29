# -----------------------------------------------
# Path to root of SmartNIC repo
# (all other project paths are inferred)
# -----------------------------------------------
# APP_DIR is passed explicitly when building via the top-level Makefile
# (make -C <smartnic-root> build APP_DIR=$(CURDIR)).  When running tests
# directly from within the example tree, default to this file's directory.
APP_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

SMARTNIC_ROOT = $(abspath $(APP_DIR)/../..)

# -----------------------------------------------
# Application paths
# -----------------------------------------------
SRC_ROOT := $(abspath $(APP_DIR)/src)

P4_IGR_FILE = $(abspath $(APP_DIR)/p4/p4_and_verilog.p4)

# -----------------------------------------------
# Standard application config
# -----------------------------------------------
include $(SMARTNIC_ROOT)/scripts/app_config_base.mk
