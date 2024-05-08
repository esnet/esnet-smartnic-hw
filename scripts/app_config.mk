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
# else APP is P4 file only, set APP_ROOT to smartnic_app (to get common P4 application verilog) and P4 files.
ifneq ($(wildcard $(APP_DIR)/app_if/.),)
APP_TYPE := VERILOG
else
APP_TYPE := P4
endif

APP_PROJ_ROOT := $(APP_DIR)/.app

ifeq ($(APP_TYPE),P4)
APP_ROOT := $(APP_PROJ_ROOT)
else
APP_ROOT := $(APP_DIR)
endif

# App name
# ----------------------------------------------------
# Where APP_NAME is not set explicitly by parent (calling)
# Makefile, set APP_NAME to name of application root directory
APP_NAME_DEFAULT := $(notdir $(abspath $(APP_DIR)))
APP_NAME ?= $(shell echo $(APP_NAME_DEFAULT) | tr '[:upper:]' '[:lower:]')

# P4 files
# ----------------------------------------------------
# Full pathname of application p4 files
P4_FILE ?= $(APP_DIR)/p4/$(APP_NAME).p4
P4_IGR_FILE_DEFAULT := $(P4_FILE)
P4_EGR_FILE_DEFAULT :=

P4_IGR_FILE ?= $(P4_IGR_FILE_DEFAULT)
P4_EGR_FILE ?= $(P4_EGR_FILE_DEFAULT)


# P4 options
# ----------------------------------------------------
# Options to pass to p4 compiler
ifneq ($(P4_IGR_FILE),)
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
     echo "P4_IGR_FILE  : $(P4_IGR_FILE)"; \
     echo "P4_EGR_FILE  : $(P4_EGR_FILE)"; \
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
APP_CFG_FILE := $(APP_PROJ_ROOT)/config.mk

_configure_app_src_lib := \
	 mkdir -p $(APP_PROJ_ROOT)/src; \
	 cp $(SCRIPTS_ROOT)/Makefiles/templates/lib.mk $(APP_PROJ_ROOT)/src/Makefile; \
	 cp $(SCRIPTS_ROOT)/Makefiles/templates/lib_config.mk $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<path-to-proj-root>:$(APP_PROJ_ROOT):' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<library-name>:$(APP_NAME):' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<library-desc>:$(APP_NAME) SmartNIC application library:' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<libraries>:smartnic=$(SMARTNIC_ROOT)/src:' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:<common-lib-name>:common@smartnic:' $(APP_PROJ_ROOT)/src/config.mk; \
	 sed -i 's:.*<lib-env>.*:BOARD ?= au280\nLIB_ENV = \\\n\tBOARD=$$(BOARD) \\\n\tIP_OUT_SUBDIR=$$(BOARD):g' $(APP_PROJ_ROOT)/src/config.mk;

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
	 echo "export P4_IGR_FILE        := $(P4_IGR_FILE)"                     >> $(APP_CFG_FILE); \
	 echo "export P4_EGR_FILE        := $(P4_EGR_FILE)"                     >> $(APP_CFG_FILE); \
     echo "P4_OPTS        := $(P4_OPTS)"                     >> $(APP_CFG_FILE); \
     echo ""                                                 >> $(APP_CFG_FILE); \
	 echo "\# Standard application parameters"               >> $(APP_CFG_FILE); \
	 echo "include $(SMARTNIC_ROOT)/scripts/app_config_base.mk" >> $(APP_CFG_FILE); \
	 $(_configure_app_src_lib) \
	 $(_configure_app_out_dir)

_configure_app_verilog :=

_configure_app_p4 := \
	 cp -r $(SMARTNIC_ROOT)/src/vitisnetp4     $(APP_PROJ_ROOT)/src/; \
	 cp -r $(SMARTNIC_ROOT)/src/vitisnetp4_igr $(APP_PROJ_ROOT)/src/; \
	 cp -r $(SMARTNIC_ROOT)/src/vitisnetp4_egr $(APP_PROJ_ROOT)/src/; \
	 cp $(APP_DIR)/src/vitisnetp4_0_extern/rtl/src/*.sv   $(APP_PROJ_ROOT)/src/vitisnetp4/rtl/src/     2>/dev/null || \
            rm $(APP_PROJ_ROOT)/src/vitisnetp4/rtl/src/vitisnetp4_0_extern.sv; \
	 cp $(APP_DIR)/src/vitisnetp4_igr_extern/rtl/src/*.sv $(APP_PROJ_ROOT)/src/vitisnetp4_igr/rtl/src/ 2>/dev/null || \
            rm $(APP_PROJ_ROOT)/src/vitisnetp4_igr/rtl/src/vitisnetp4_igr_extern.sv; \
	 cp $(APP_DIR)/src/vitisnetp4_egr_extern/rtl/src/*.sv $(APP_PROJ_ROOT)/src/vitisnetp4_egr/rtl/src/ 2>/dev/null || \
            rm $(APP_PROJ_ROOT)/src/vitisnetp4_egr/rtl/src/vitisnetp4_egr_extern.sv; \
	 cp -r $(SMARTNIC_ROOT)/src/smartnic_app $(APP_PROJ_ROOT)/src/; \
	 cp $(APP_DIR)/src/smartnic_app*/rtl/src/* $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src 2>/dev/null; \
	 cp $(APP_DIR)/src/smartnic_app*/regio/*.yaml $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/regio 2>/dev/null; \
	 mv $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/app_if $(APP_PROJ_ROOT)/; \
	 sed -i 's:COMPONENT_ROOT.*=.*:COMPONENT_ROOT = \.\.:' $(APP_PROJ_ROOT)/app_if/Makefile; \
	 make -s -C $(APP_ROOT)/app_if clean;

_instantiate_p4_igr := \
         sed -i 's:localparam logic P4_PROC_IGR_MODE = 0:localparam logic P4_PROC_IGR_MODE = 1:' \
                $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src/smartnic_app.sv;

_instantiate_p4_egr := \
         sed -i 's:localparam logic P4_PROC_EGR_MODE = 0:localparam logic P4_PROC_EGR_MODE = 1:' \
                $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src/smartnic_app.sv;

_instantiate_p4_igr_passthru := \
         sed -i 's:localparam logic P4_PROC_IGR_MODE = 1:localparam logic P4_PROC_IGR_MODE = 0:' \
                $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src/smartnic_app.sv; \
         sed -i 's:vitisnetp4_igr\.rtl::' $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/Makefile;

_instantiate_p4_egr_passthru := \
         sed -i 's:localparam logic P4_PROC_EGR_MODE = 1:localparam logic P4_PROC_EGR_MODE = 0:' \
                $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src/smartnic_app.sv; \
         sed -i 's:vitisnetp4_egr\.rtl::' $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/Makefile;

_instantiate_smartnic_app_igr := \
         sed -i 's:localparam logic SMARTNIC_APP_IGR_MODE = 0:localparam logic SMARTNIC_APP_IGR_MODE = 1:' \
                $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src/smartnic_app.sv;

_instantiate_smartnic_app_egr := \
         sed -i 's:localparam logic SMARTNIC_APP_EGR_MODE = 0:localparam logic SMARTNIC_APP_EGR_MODE = 1:' \
                $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src/smartnic_app.sv;

_instantiate_smartnic_app_igr_passthru := \
         sed -i 's:localparam logic SMARTNIC_APP_IGR_MODE = 1:localparam logic SMARTNIC_APP_IGR_MODE = 0:' \
                $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src/smartnic_app.sv;

_instantiate_smartnic_app_egr_passthru := \
         sed -i 's:localparam logic SMARTNIC_APP_EGR_MODE = 1:localparam logic SMARTNIC_APP_EGR_MODE = 0:' \
                $(APP_PROJ_ROOT)/src/smartnic_app/p4_only/rtl/src/smartnic_app.sv;

ifeq ($(APP_TYPE),P4) # configure p4 app
_configure_app := $(_configure_app_common) $(_configure_app_p4)
ifneq ($(P4_IGR_FILE),)
_configure_app := $(_configure_app) $(_instantiate_p4_igr)
else
_configure_app := $(_configure_app) $(_instantiate_p4_igr_passthru)
endif
ifneq ($(P4_EGR_FILE),)
_configure_app := $(_configure_app) $(_instantiate_p4_egr)
else
_configure_app := $(_configure_app) $(_instantiate_p4_egr_passthru)
endif
ifneq ($(wildcard $(APP_DIR)/src/smartnic_app_igr/rtl/src/smartnic_app_igr.sv),)
_configure_app := $(_configure_app) $(_instantiate_smartnic_app_igr)
else
_configure_app := $(_configure_app) $(_instantiate_smartnic_app_igr_passthru)
endif
ifneq ($(wildcard $(APP_DIR)/src/smartnic_app_egr/rtl/src/smartnic_app_egr.sv),)
_configure_app := $(_configure_app) $(_instantiate_smartnic_app_egr)
else
_configure_app := $(_configure_app) $(_instantiate_smartnic_app_egr_passthru)
endif

else # configure verilog app
_configure_app := $(_configure_app_common) $(_configure_app_verilog)
endif
