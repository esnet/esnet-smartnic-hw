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
#   core.stub.rtl transitively includes shell.pkg, shell.rtl,
#   axi4l.rtl@common, axi4s.rtl@common via its own Makefile.
# ----------------------------------------------------
SUBCOMPONENTS = \
    core.stub.rtl

OOC = 1

CONSTRAINTS_XDC_SYNTH = $(abspath timing_ooc.xdc)

BUILD_STAGES = synth

# Re-synthesize when sources change (sources.tcl is a real file target, rebuilt when deps change)
STAGE_DEPS = $(COMPONENT_OUT_PATH)/synth/sources.tcl

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: synth

pre_synth: _pre_synth
synth: _np_synth
	@$(MAKE) -s _build_np_synth_lib
info:  _build_info
clean: _build_clean

.PHONY: pre_synth synth info clean

# -----------------------------------------------
# Include non-project build definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_non_proj.mk
