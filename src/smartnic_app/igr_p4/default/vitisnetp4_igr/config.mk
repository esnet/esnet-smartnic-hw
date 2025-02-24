# -----------------------------------------------
# Path setup
# -----------------------------------------------
COMPONENT_ROOT := $(abspath $(VITISNETP4_COMPONENT_ROOT)/../../..)

# All other project paths can be derived
include $(COMPONENT_ROOT)/config.mk

# VitisNetP4 config
P4_FILE := $(SMARTNIC_ROOT)/src/vitisnetp4/p4/p4_app.p4
VITISNETP4_IP_NAME := vitisnetp4_igr
