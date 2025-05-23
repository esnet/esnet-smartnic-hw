# -----------------------------------------------
# Path to root of SmartNIC repo
# (all other project paths are inferred)
# -----------------------------------------------
SMARTNIC_ROOT = $(abspath $(APP_DIR)/../..)

# -----------------------------------------------
# Application paths
# -----------------------------------------------
SRC_ROOT := $(abspath $(APP_DIR)/src)

P4_IGR_FILE = $(abspath $(APP_DIR)/p4/p4_multi_proc_igr.p4)
P4_EGR_FILE = $(abspath $(APP_DIR)/p4/p4_multi_proc_egr.p4)

# -----------------------------------------------
# Standard application config
# -----------------------------------------------
include $(SMARTNIC_ROOT)/scripts/app_config_base.mk
