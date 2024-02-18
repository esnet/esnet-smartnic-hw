# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

APP_ROOT ?= $(PROJ_ROOT)/src/smartnic_322mhz

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_322mhz

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: along with explictly-listed sources, all
#   source files from ./src are added automatically, and
#   .include is added as an include directory automatically.
# ----------------------------------------------------
SRC_FILES = \
    $(APP_ROOT)/app_if/smartnic_322mhz_app_pkg.sv

INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
SUBCOMPONENTS = \
    smartnic_322mhz.rtl

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: opt validate

reg: cp_app_dec
pre_synth: reg _pre_synth
	@cp $(COMPONENT_OUT_SYNTH_PATH)/sources.tcl ./

synth:     _build_core_synth
opt:       _build_core_opt
place:     _build_core_place
validate:  _build_core_validate
info:      _build_core_info _app_info
clean:     _build_clean

.PHONY: pre_synth synth opt validate info clean

cp_app_dec: $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml
	@cp $(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml $(COMPONENT_ROOT)/regio/

$(APP_ROOT)/app_if/smartnic_322mhz_app_decoder.yaml:
	$(error smartnic_322mhz_app_decoder.yaml not present in $(APP_ROOT)/app_if. Build application before executing SmartNIC build)

$(APP_ROOT)/app_if/smartnic_322mhz_app_pkg.sv:
	$(error smartnic_322mhz_app_pkg.sv not present in $(APP_ROOT)/app_if. Build application before executing SmartNIC build)

_app_info:
	@echo "------------------------------------------------------"
	@echo "Application configuration"
	@echo "------------------------------------------------------"
	@echo "APP_ROOT           : $(APP_ROOT)"
# ----------------------------------------------------
# Project management targets
# ----------------------------------------------------
proj       : _proj
proj_clean : _proj_clean

.PHONY: proj proj_clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_core.mk
