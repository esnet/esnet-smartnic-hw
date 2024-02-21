# -----------------------------------------------
# Path setup
# -----------------------------------------------
# Set relative to component root directory
# Note: COMPONENT_ROOT is configured in calling (parent) Makefile
APP_DIR = $(abspath $(COMPONENT_ROOT)/..)

# All other project paths can be derived
include $(APP_DIR)/config.mk

# -----------------------------------------------
# Import default component config
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/component_config_base.mk
