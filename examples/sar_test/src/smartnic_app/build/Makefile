# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_app

# ----------------------------------------------------
# Sources
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
# ----------------------------------------------------
SUBCOMPONENTS = \
    vitisnetp4_igr.rtl \
    smartnic_app.igr_p4.rtl@smartnic \
    smartnic_app.igr.rtl \
    smartnic_app.egr_p4.passthru.rtl@smartnic \
    smartnic_app.egr.passthru.rtl@smartnic \
    smartnic_app.rtl@smartnic

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
