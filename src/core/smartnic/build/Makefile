# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = core

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
    core.smartnic.rtl \
    smartnic.rtl \
    smartnic_app.blackbox.rtl

OOC = 1

CONSTRAINTS_XDC_SYNTH = $(abspath timing_ooc.xdc)

BUILD_STAGES = synth

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: synth

pre_synth: _pre_synth
synth:
	@if [ -f "$(SYNTH_DCP_FILE)" ]; then \
		echo "Core OOC DCP already built — refreshing manifest only."; \
	else \
		$(MAKE) -s _np_synth; \
	fi
	@$(MAKE) -s _build_np_synth_lib
info:  _build_info
clean: _build_clean

.PHONY: pre_synth synth info clean

# -----------------------------------------------
# Include non-project build definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_non_proj.mk
