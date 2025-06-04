# ----------------------------------------------------
# Path setup
# ----------------------------------------------------
PROJ_ROOT = ..

include $(PROJ_ROOT)/config.mk

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
help: _help
check: _check
info:  _info

.PHONY: check info

# ----------------------------------------------------
# Configure device properties for project
# ----------------------------------------------------
# Usage:
#   make config [PART=<part>] [BOARD_PART=<board_part>] [BOARD_REPO=<path_to_board_files>]
config: _config

.PHONY: config

# Include part configuration targets
include $(SCRIPTS_ROOT)/Makefiles/config_part.mk

# ----------------------------------------------------
# Include base Makefile
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/cfg_base.mk
