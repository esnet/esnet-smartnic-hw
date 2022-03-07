# -----------------------------------------------
# Path setup
# -----------------------------------------------
# Set relative to IP directory
# Note: IP_ROOT is configured in calling (parent) Makefile
export PROJ_ROOT ?= $(abspath $(IP_ROOT)/../../..)

# All other project paths can be derived
include $(PROJ_ROOT)/paths.mk

# -----------------------------------------------
# Custom IP config
# -----------------------------------------------
# IP library name - if unset, defaults to IP_ROOT directory name (with ".HDL" suffix stripped, when present)
IP_NAME =

REGIO_YAML_INC_DIR = $(IP_ROOT)

#export P4_FILE ?= $(abspath $(IP_ROOT)/p4/$(IP_NAME).p4)

# -----------------------------------------------
# Import base IP config
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/ip_base.mk
