# -----------------------------------------------
# Path setup
# -----------------------------------------------
COMPONENT_ROOT := $(VITISNETP4_COMPONENT_ROOT)

# Set relative to component root directory
# Note: COMPONENT_ROOT is configured in calling (parent) Makefile
SRC_ROOT := $(abspath $(COMPONENT_ROOT)/..)

# All other project paths can be derived
include $(SRC_ROOT)/config.mk

# VitisNetP4 config
P4_FILE := $(SMARTNIC_ROOT)/src/vitisnetp4/p4/p4_app.p4
VITISNETP4_IP_NAME := vitisnetp4

# -----------------------------------------------
# Import default component config
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/component_config_base.mk
