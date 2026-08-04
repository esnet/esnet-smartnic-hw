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
# P4 source files
# ----------------------------------------------------
P4_IGR_FILE := $(abspath $(COMPONENT_ROOT)/../../p4/p4_multi_proc_igr.p4)
P4_EGR_FILE := $(abspath $(COMPONENT_ROOT)/../../p4/p4_multi_proc_egr.p4)

# ----------------------------------------------------
# Sources
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
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
    smartnic_app.igr.rtl \
    smartnic_app.egr.rtl \
    smartnic_app.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)

# ----------------------------------------------------
# Build config
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
