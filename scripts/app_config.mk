# ----------------------------------------------------
# App configuration defaults
# ----------------------------------------------------
# Intended to be included by 'parent' Makefile, with
# following variables defined:
#
# APP_DIR - absolute path to application directory
# SMARTNIC_DIR - absolute path to smartnic root directory

# Application Verilog source root directory
# ----------------------------------------------------
# if APP_DIR contains app_if/ subdir i.e. APP contains P4 + verilog, set APP_ROOT to APP_DIR,
# else APP is P4 file only, set APP_ROOT to p4_app (to get common P4 core verilog) and P4_FILE.
ifneq ($(wildcard $(APP_DIR)/app_if/.),)
APP_TYPE := VERILOG
else
APP_TYPE := P4
endif

ifeq ($(APP_TYPE),P4)
APP_ROOT := $(APP_DIR)/.app/src/p4_app
else
APP_ROOT := $(APP_DIR)
endif

# App name
# ----------------------------------------------------
# Where APP_NAME is not set explicitly by parent (calling)
# Makefile, set APP_NAME to name of application root directory
APP_NAME_DEFAULT := $(notdir $(abspath $(APP_DIR)))
APP_NAME ?= $(shell echo $(APP_NAME_DEFAULT) | tr '[:upper:]' '[:lower:]')

# P4 file
# ----------------------------------------------------
# Full pathname of application p4 file
ifeq ($(APP_TYPE),P4)
P4_FILE_DEFAULT := $(APP_DIR)/p4/$(APP_NAME).p4 
else
P4_FILE_DEFAULT :=
endif
P4_FILE ?= $(P4_FILE_DEFAULT)


# P4 options
# ----------------------------------------------------
# Options to pass to p4 compiler
ifneq ($(P4_FILE),)
P4_OPTS_DEFAULT := CONFIG.PKT_RATE {150} \
                   CONFIG.OUTPUT_METADATA_FOR_DROPPED_PKTS {true}
else
P4_OPTS_DEFAULT :=
endif
P4_OPTS ?= $(P4_OPTS_DEFAULT)


# Board specification
# ----------------------------------------------------
# Specifies name of AMD (Xilinx) Alveo board used for application.
# Supports 'au280', 'au250' and 'au55c'.
BOARD_DEFAULT := au280
BOARD ?= $(BOARD_DEFAULT)

# Build name
# ----------------------------------------------------
# Specify name of build and build artifacts
BUILD_NAME_DEFAULT := $(APP_NAME)
BUILD_NAME ?= $(BUILD_NAME_DEFAULT)

# (Build) artifacts
# ----------------------------------------------------
# Set path for build artifacts (output) directory
ARTIFACTS_DIR_DEFAULT := $(APP_DIR)/artifacts
ARTIFACTS_DIR ?= $(ARTIFACTS_DIR_DEFAULT)

# Import standard application config
# ----------------------------------------------------
include $(SMARTNIC_ROOT)/scripts/app_config_base.mk

# Print parameters
# - convenience function for implementing targets that
#   echo the application parameters for reporting or
#   debug purposes
# ----------------------------------------------------
ifeq ($(APP_TYPE),P4)
_print_app_config := \
    @echo "=============================================="; \
	 echo "Configuring P4 application '$(APP_NAME)':"; \
     echo "=============================================="; \
     echo "APP_DIR      : $(APP_DIR)"; \
     echo "APP_NAME     : $(APP_NAME)"; \
     echo "APP_ROOT     : $(APP_ROOT)"; \
     echo "BOARD        : $(BOARD)"; \
     echo "BUILD_NAME   : $(BUILD_NAME)"; \
     echo "ARTIFACTS_DIR: $(ARTIFACTS_DIR)"; \
     echo "P4_FILE      : $(P4_FILE)"; \
     echo "P4_OPTS      : $(P4_OPTS)";
else
_print_app_config := \
    @echo "=============================================="; \
	 echo "Configuring Verilog application '$(APP_NAME)':"; \
     echo "=============================================="; \
     echo "APP_DIR      : $(APP_DIR)"; \
     echo "APP_NAME     : $(APP_NAME)"; \
     echo "APP_ROOT     : $(APP_ROOT)"; \
     echo "BOARD        : $(BOARD)"; \
     echo "BUILD_NAME   : $(BUILD_NAME)"; \
     echo "ARTIFACTS_DIR: $(ARTIFACTS_DIR)";
endif

# Write config to file
# - write application configuration to a file
# ----------------------------------------------------
APP_PROJ_ROOT := $(APP_DIR)/.app
APP_CFG_FILE := $(APP_PROJ_ROOT)/config.mk

_configure_app_src_lib := \
	 mkdir -p $(APP_PROJ_ROOT)/src; \
	 cp $(SCRIPTS_ROOT)/Makefiles/templates/lib.mk $(APP_PROJ_ROOT)/src/Makefile; \
	 cp $(SCRIPTS_ROOT)/Makefiles/templates/lib_config.mk $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<path-to-proj-root>:$(APP_PROJ_ROOT):' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<library-name>:$(APP_NAME):' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<library-desc>:$(APP_NAME) SmartNIC application library:' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<libraries>:smartnic=$(SMARTNIC_ROOT)/src:' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<common-lib-name>:common@smartnic:' $(APP_PROJ_ROOT)/src/config.mk;

_configure_app_out_dir := \
	 mkdir -p $(APP_PROJ_ROOT)/out; \
	 echo "This directory contains output products from IP generation, simulation, synthesis, etc." >> $(APP_PROJ_ROOT)/out/.README;

_configure_app_common := \
     @mkdir -p $(APP_PROJ_ROOT); \
	 echo "\#==============================================" >  $(APP_CFG_FILE); \
     echo "\# Application configuration"                     >> $(APP_CFG_FILE); \
     echo "\#"                                               >> $(APP_CFG_FILE); \
     echo "\# NOTE: This file is autogenerated."             >> $(APP_CFG_FILE); \
     echo "\#==============================================" >> $(APP_CFG_FILE); \
	 echo "\# Project paths"                                 >> $(APP_CFG_FILE); \
	 echo "SMARTNIC_ROOT  := $(SMARTNIC_ROOT)"               >> $(APP_CFG_FILE); \
	 echo "include $(SMARTNIC_ROOT)/paths.mk"                >> $(APP_CFG_FILE); \
     echo ""                                                 >> $(APP_CFG_FILE); \
     echo "\# Application-specific parameters"               >> $(APP_CFG_FILE); \
     echo "export APP_DIR := $(APP_DIR)"                     >> $(APP_CFG_FILE); \
     echo "APP_NAME       := $(APP_NAME)"                    >> $(APP_CFG_FILE); \
	 echo "APP_TYPE       := $(APP_TYPE)"                    >> $(APP_CFG_FILE); \
     echo "APP_ROOT       := $(APP_ROOT)"                    >> $(APP_CFG_FILE); \
     echo "BOARD          := $(BOARD)"                       >> $(APP_CFG_FILE); \
     echo "BUILD_NAME     := $(BUILD_NAME)"                  >> $(APP_CFG_FILE); \
     echo "ARTIFACTS_DIR  := $(ARTIFACTS_DIR)"               >> $(APP_CFG_FILE); \
	 echo "P4_FILE        := $(P4_FILE)"                     >> $(APP_CFG_FILE); \
     echo "P4_OPTS        := $(P4_OPTS)"                     >> $(APP_CFG_FILE); \
     echo ""                                                 >> $(APP_CFG_FILE); \
	 echo "\# Standard application parameters"               >> $(APP_CFG_FILE); \
	 echo "include $(SMARTNIC_ROOT)/scripts/app_config_base.mk" >> $(APP_CFG_FILE); \
	 $(_configure_app_src_lib) \
	 $(_configure_app_out_dir)

_configure_app_p4 := \
	 cp -r $(SMARTNIC_ROOT)/src/vitisnetp4 $(APP_PROJ_ROOT)/src/; \
	 mkdir -p $(APP_PROJ_ROOT)/src/p4_app; \
	 cp $(SCRIPTS_ROOT)/Makefiles/templates/ip_config.mk $(APP_PROJ_ROOT)/src/p4_app/config.mk; \
	 cp -r $(SMARTNIC_ROOT)/src/p4_app/app_if $(APP_PROJ_ROOT)/src/p4_app/; \
	 cp -r $(SMARTNIC_ROOT)/src/p4_app/build $(APP_PROJ_ROOT)/src/p4_app/; \
	 cp -r $(APP_DIR)/extern $(APP_PROJ_ROOT)/src/p4_app/ 2>/dev/null; \
	 make -s -C $(APP_ROOT)/app_if clean;

_configure_app_verilog :=

ifeq ($(APP_TYPE),P4)
_configure_app := $(_configure_app_common) $(_configure_app_p4)
else
_configure_app := $(_configure_app_common) $(_configure_app_verilog)
endif
