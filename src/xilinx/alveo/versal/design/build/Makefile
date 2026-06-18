BOARD ?= av80

# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../../..

include $(COMPONENT_ROOT)/config.mk

export LIB_ROOT

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = esnet_smartnic

# -----------------------------------------------
# Build config
# -----------------------------------------------
BUILD_TIMESTAMP = $(shell date +"%s")
BUILD_ID ?= $(BUILD_TIMESTAMP)
CORE ?= core.stub

AVED_BASE_DESIGN = amd_v80_gen5x8_25.1

# Board-specific shell directory (provides impl constraints and hook TCL files)
SHELL_BOARD_DIR = $(SRC_ROOT)/xilinx/alveo/versal/shell/$(BOARD)

# Shell synth DCP: produced by xilinx.alveo.versal.shell.<BOARD>.build (non-project flow)
SHELL_SUBCOMPONENT_REF = xilinx.alveo.versal.shell.$(BOARD).build
SHELL_DCP_FILE = $(call get_lib_component_out_path_from_ref,$(SHELL_SUBCOMPONENT_REF),$(LIB_OUTPUT_ROOT))/$(TOP).synth.dcp

# Core OOC DCP: produced by <CORE>.build (non-project flow)
CORE_SUBCOMPONENT_REF = $(CORE).build
CORE_DCP_FILE = $(call get_lib_component_out_path_from_ref,$(CORE_SUBCOMPONENT_REF),$(LIB_OUTPUT_ROOT))/core.synth.dcp

# App DCP: produced by smartnic_app.build in the application repo
APP_SUBCOMPONENT_REF = smartnic_app.build
APP_DCP_FILE = $(call get_lib_component_out_path_from_ref,$(APP_SUBCOMPONENT_REF),$(LIB_OUTPUT_ROOT))/proj/proj.runs/synth_1/smartnic_app.dcp

# VitisNetP4 DCPs: optional — only present for apps that include P4.
VITISNETP4_IGR_DCP_FILE = $(call get_lib_component_out_path_from_ref,vitisnetp4_igr.ip,$(LIB_OUTPUT_ROOT))/vitisnetp4_igr/vitisnetp4_igr.dcp
VITISNETP4_EGR_DCP_FILE = $(call get_lib_component_out_path_from_ref,vitisnetp4_egr.ip,$(LIB_OUTPUT_ROOT))/vitisnetp4_egr/vitisnetp4_egr.dcp

# Map to the generic assembly interface (shell=top-level, core fills i_core cell)
TOP_DCP_FILE = $(SHELL_DCP_FILE)
CELL_DCPS    = i_core:$(CORE_DCP_FILE) \
               i_core/i_smartnic_wrapper/smartnic/smartnic_app:$(APP_DCP_FILE) \
               $(if $(wildcard $(VITISNETP4_IGR_DCP_FILE)),i_core/i_smartnic_wrapper/smartnic/smartnic_app/smartnic_app_igr_p4_inst/vitisnetp4_igr_wrapper_inst/i_vitisnetp4_igr:$(VITISNETP4_IGR_DCP_FILE)) \
               $(if $(wildcard $(VITISNETP4_EGR_DCP_FILE)),i_core/i_smartnic_wrapper/smartnic/smartnic_app/smartnic_app_egr_p4_inst/vitisnetp4_egr_wrapper_inst/i_vitisnetp4_egr:$(VITISNETP4_EGR_DCP_FILE))

# Implementation-only constraints from the shell board directory
CONSTRAINTS_XDC_IMPL = \
    $(abspath $(SHELL_BOARD_DIR)/impl.pins.xdc) \
    $(abspath $(SHELL_BOARD_DIR)/impl.xdc) \
    $(abspath $(SHELL_BOARD_DIR)/timing.xdc)

# TCL hook files attached to implementation run steps
IMPL_HOOK_TCL_FILES = $(abspath $(wildcard $(SHELL_BOARD_DIR)/*.tcl))

# Re-run from link if any input DCP, XDC or TCL changes.
# $(wildcard ...) omits missing files at parse time so Make doesn't demand
# a rule to build them on first run; freshness tracking still works once
# the files exist (subcomponent builds via _pre_synth create them).
STAGE_DEPS = $(wildcard $(SHELL_DCP_FILE) $(CORE_DCP_FILE) $(APP_DCP_FILE) \
                        $(VITISNETP4_IGR_DCP_FILE) $(VITISNETP4_EGR_DCP_FILE) \
                        $(CONSTRAINTS_XDC_IMPL) $(IMPL_HOOK_TCL_FILES) )

# AVED IP repository — needed by Vivado link_design to resolve the CIPS
# partition context during full-device implementation.
IP_REPO_PATHS = $(abspath $(SRC_ROOT)/xilinx/aved/hw/$(AVED_BASE_DESIGN)/src/iprepo)

# Link + implementation stages (no synth here — shell and core synthesize separately)
BUILD_STAGES = link opt place place_opt route route_opt device_image xsa

# ----------------------------------------------------
# Sources (none — pre-synthesized DCPs only)
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   Both OOC builds are invoked as subcomponents so that
#   their DCP caching guards run before assembly starts.
# ----------------------------------------------------
SUBCOMPONENTS = \
    $(SHELL_SUBCOMPONENT_REF) \
    $(CORE_SUBCOMPONENT_REF)

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build

build: _np_xsa

.PHONY: build

pre_synth:    _pre_synth
link:         _np_link
opt:          _np_opt
place:        _np_place
place_opt:    _np_place_opt
route:        _np_route
route_opt:    _np_route_opt
device_image: _np_device_image
xsa:          _np_xsa
info:         _build_info
clean:        _build_clean

.PHONY: pre_synth link opt place place_opt route route_opt device_image xsa info clean

# -----------------------------------------------
# Firmware build + PDI generation
# -----------------------------------------------
BUILD_PDI_SCRIPT = $(SMARTNIC_ROOT)/scripts/versal/build_pdi.sh

PDI_HW_FILE  = $(COMPONENT_OUT_PATH)/$(TOP).pdi
XSA_FILE     = $(COMPONENT_OUT_PATH)/$(TOP).xsa
PDI_APP_FILE = $(COMPONENT_OUT_PATH)/$(TOP)_app.pdi

$(PDI_APP_FILE): $(PDI_HW_FILE) $(XSA_FILE)
	@$(BUILD_PDI_SCRIPT) \
	    -p $(abspath $(PROJ_ROOT)) \
	    -o $(COMPONENT_OUT_PATH) \
	    -d $(AVED_BASE_DESIGN) \
	    -t $(TOP)

pdi: _np_xsa $(PDI_APP_FILE)

.PHONY: pdi

# -----------------------------------------------
# Include non-project build definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_non_proj.mk
