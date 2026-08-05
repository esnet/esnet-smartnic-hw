# ----------------------------------------------------
# Path setup
# - specify paths in terms of SRC_ROOT
#   (defined in parent Makefile)
# ----------------------------------------------------
APP_DIR = $(abspath $(SRC_ROOT)/..)

include $(APP_DIR)/config.mk

# ----------------------------------------------------
# Library setup
# ----------------------------------------------------
LIB_NAME := "SAR test SmartNIC application"
LIB_DESC := "RTL and verification for SAR test SmartNIC application"

# ----------------------------------------------------
# Sub-library config
# ----------------------------------------------------
LIBRARIES = smartnic=$(SMARTNIC_ROOT)/src

# Specify name of 'common' library (for autogenerating register infrastructure from regio specifications)
COMMON_LIB_NAME = common@smartnic

# Specify name of 'SmartNIC' source library (for compatibility with standard component build scripts)
SMARTNIC_LIB_NAME = smartnic

# ----------------------------------------------------
# Environment setup
# ----------------------------------------------------
BOARD ?= au55c

# Maintain separate output products per board and Vivado version
OUTPUT_SUBDIR = $(BOARD)/$(XILINX_VIVADO__VERSION)

LIB_ENV = \
    BOARD=$(BOARD)

# ----------------------------------------------------
# Import base library config
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/lib_config_base.mk
