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
ifneq ($(P4_IGR_FILE),)
IGR_P4_DEPENDENCIES = \
    vitisnetp4_igr.rtl \
	smartnic_app.igr_p4.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)
else
IGR_P4_DEPENDENCIES = \
	smartnic_app.igr_p4.passthru.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)
endif
ifneq ($(P4_EGR_FILE),)
EGR_P4_DEPENDENCIES = \
    vitisnetp4_egr.rtl \
	smartnic_app.egr_p4.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)
else
EGR_P4_DEPENDENCIES = \
	smartnic_app.egr_p4.passthru.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)
endif

SUBCOMPONENTS = \
    $(IGR_P4_DEPENDENCIES) \
    $(EGR_P4_DEPENDENCIES) \
    smartnic_app.igr.demux.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    smartnic_app.egr.mux.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    smartnic_app.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)


# ====================================================
ifeq ($(filter av%,$(BOARD)),$(BOARD))
# ----------------------------------------------------
# Build config (Versal / non-project flow)
# ----------------------------------------------------
OOC = 1
CONSTRAINTS_XDC_SYNTH =  # $(abspath timing_ooc.xdc)
BUILD_STAGES = synth
STAGE_DEPS = $(COMPONENT_OUT_PATH)/synth/sources.tcl

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: synth

pre_synth: _pre_synth
synth:     _np_synth
	@$(MAKE) -s _build_np_synth_lib
info:      _build_info
clean:     _build_clean

.PHONY: pre_synth synth info clean

# -----------------------------------------------
# Include non-project build definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_non_proj.mk


# ====================================================
else
# ----------------------------------------------------
# Targets (UltraScale+ / project flow)
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
endif
# ====================================================
