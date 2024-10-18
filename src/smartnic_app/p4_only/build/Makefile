# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_app

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: along with explicitly-listed sources, all
#   source files from ./src are added automatically, and
#   .include is added as an include directory automatically.
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
SUBCOMPONENTS = \
    vitisnetp4_igr.rtl \
    smartnic_app.igr.passthru.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    smartnic_app.egr.passthru.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    smartnic_app.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)


# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: opt validate

pre_synth: _pre_synth
synth:     _build_core_synth
opt:       _build_core_opt
place:     _build_core_place
validate:  _build_core_validate
info:      _build_core_info
clean:     _build_clean

.PHONY: pre_synth synth opt validate info clean

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
