# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Board setup
# -----------------------------------------------
BOARD ?= au280 # Default of au280 can be overriden using make BOARD={au55c|au250}

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = esnet_shell

# -----------------------------------------------
# Build config
# -----------------------------------------------
BUILD_TIMESTAMP = $(shell date +"%s")
BUILD_ID ?= $(BUILD_TIMESTAMP)

DEFINES = BOARD=$(BOARD) __$(BOARD)__

CONSTRAINTS_XDC_USER = $(abspath $(wildcard $(BOARD)/*.xdc))

SHELL_COMPONENT = xilinx.alveo.shell.rtl@$(SMARTNIC_LIB_NAME)
CORE_COMPONENT = core.smartnic.build@$(SMARTNIC_LIB_NAME)
SMARTNIC_APP_COMPONENT = smartnic_app.build

SHELL_DCP = $(call get_lib_component_out_path_from_ref,$(SHELL_COMPONENT),$(LIB_OUTPUT_ROOT))/proj/proj.runs/impl_1/xilinx_alveo_shell.dcp
CORE_DCP = $(call get_lib_component_out_path_from_ref,$(CORE_COMPONENT),$(LIB_OUTPUT_ROOT))/proj/proj.runs/impl_1/core.dcp
SMARTNIC_APP_DCP = $(call get_lib_component_out_path_from_ref,$(SMARTNIC_APP_COMPONENT),$(LIB_OUTPUT_ROOT))/proj/proj.runs/impl_1/smartnic_app.dcp

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
SUBCOMPONENTS = \
    $(SMARTNIC_APP_COMPONENT) \
    $(CORE_COMPONENT) \
    $(SHELL_COMPONENT)

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build

build: route_opt bitstream flash

.PHONY: build

pre_synth: _pre_synth
	@echo "read_checkpoint -cell i_core $(CORE_DCP)" >> $(COMPONENT_OUT_SYNTH_PATH)/sources.tcl
	@echo "read_checkpoint -cell i_core.i_smartnic_wrapper.smartnic.smartnic_app $(SMARTNIC_APP_DCP)" >> $(COMPONENT_OUT_SYNTH_PATH)/sources.tcl
	#@echo "read_checkpoint -cell esnet_shell.i_xilinx_alveo_shell $(SHELL_DCP)" >> $(COMPONENT_OUT_SYNTH_PATH)/sources.tcl
synth:     _build_synth
opt:       _build_opt
place:     _build_place
place_opt: _build_place_opt
route:     _build_route
route_opt: _build_route_opt
bitstream: _build_bitstream
flash:     _build_flash
validate:  _build_validate
info:      _build_info
clean:     _build_clean

.PHONY: pre_synth synth opt place place_opt route route_opt bitstream flash validate info clean

# ----------------------------------------------------
# Project management targets
# ----------------------------------------------------
proj       : _proj
proj_clean : _proj_clean

.PHONY: proj proj_clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_top.mk
