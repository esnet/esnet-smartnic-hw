# -----------------------------------------------
# Path setup
# -----------------------------------------------
# Set relative to component root directory
# Note: COMPONENT_ROOT is configured in calling (parent) Makefile
SRC_ROOT = $(abspath $(COMPONENT_ROOT)/../src)

# All other project paths can be derived
include $(SRC_ROOT)/config.mk

# -----------------------------------------------
# Import default component config
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/component_config_base.mk
