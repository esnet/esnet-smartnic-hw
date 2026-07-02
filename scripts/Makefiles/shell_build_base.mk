# shell_build.mk
#
# Generic shell+core assembly include.
#
# Assembles a top-level design from a pre-synthesized shell DCP and a
# pre-synthesized core DCP, then runs implementation through route_opt.
# Device-specific output (bitfile, device image, PDI, XSA) is NOT generated
# here — that is left to the including component's Makefile.
#
# This file is intended to be included within a component build Makefile
# (e.g. esnet_smartnic/build/Makefile) after the component's config chain
# has been loaded.  TOP, COMPONENT_OUT_PATH, COMPONENT_OUT_SYNTH_PATH,
# COMPONENT_OUT_SRCS_PATH, COMPONENT_REF, LIB_OUTPUT_ROOT, and part
# configuration are all inherited from the component context.
#
# Required inputs from the including component Makefile:
#   SHELL_BUILD_REF  - component ref for the shell build
#                      e.g. xilinx.alveo.versal.shell.av80.build
#   CORE_BUILD_REF   - component ref for the core build
#                      e.g. core.stub.build
#
# Optional inputs:
#   BUILD_STAGES          - implementation stages (default: link opt place
#                           place_opt route route_opt); set before including
#                           to extend (e.g. += device_image xsa)
#   CONSTRAINTS_XDC_IMPL  - implementation-only XDC constraint files
#   IMPL_HOOK_TCL_FILES   - TCL hook files for implementation steps
#   IP_REPO_PATHS         - Vivado IP repository paths
#
# Targets provided (dot-prefixed so they are skipped by Make when selecting
# the default goal; expose with public names in the including Makefile):
#   .shell_build        - build through the last BUILD_STAGES entry
#   .shell_build_clean  - clean via _build_clean
#   .shell_build_info   - print shell build configuration

# -----------------------------------------------
# Default implementation stages
# The calling component can override before including this file.
# -----------------------------------------------
BUILD_STAGES ?= link opt place place_opt route route_opt

# -----------------------------------------------
# Regio IR packaging configuration
#
# SHELL_REGIO_TOP_YAML must be set by the platform-specific include
# (e.g. versal_shell_build.mk) to the path of the top-level regio YAML
# for elaboration into a final esnet-smartnic-top-ir.yaml artifact.
#
# The core regio component ref is derived from CORE_BUILD_REF by stripping
# the trailing .build (and optional @lib qualifier) and appending .regio,
# so the same @lib qualifier is preserved:
#   core.stub.build@smartnic  →  core.stub.regio@smartnic
# -----------------------------------------------
SHELL_REGIO_TOP_YAML ?=

# -----------------------------------------------
# DCP paths
#
# Computed from the component refs using the same function used by
# the existing design/build/Makefile.  LIB_OUTPUT_ROOT is inherited
# from the component context.
# -----------------------------------------------
__SB_SHELL_OUT := $(call get_lib_component_out_path_from_ref,$(SHELL_BUILD_REF),$(LIB_OUTPUT_ROOT))
__SB_CORE_OUT  := $(call get_lib_component_out_path_from_ref,$(CORE_BUILD_REF),$(LIB_OUTPUT_ROOT))

TOP_DCP_FILE := $(__SB_SHELL_OUT)/$(TOP).synth.dcp
CELL_DCPS    := i_core:$(__SB_CORE_OUT)/core.synth.dcp

# Re-run from link if either input DCP changes; wildcard avoids Make errors
# on first run before the DCPs exist.
STAGE_DEPS := $(wildcard $(TOP_DCP_FILE) $(__SB_CORE_OUT)/core.synth.dcp)

# -----------------------------------------------
# Subcomponents
#
# Listing both build refs as SUBCOMPONENTS causes compile_base.mk /
# vivado_compile.mk to invoke their synth targets via the library dispatch
# as part of _pre_synth → _compile_synth.
# -----------------------------------------------
SUBCOMPONENTS := \
    $(SHELL_BUILD_REF) \
    $(CORE_BUILD_REF)

# Assembly only — no RTL sources in this layer
SRC_FILES      :=
INC_DIRS       :=
SRC_LIST_FILES :=

# -----------------------------------------------
# Non-project build infrastructure
# Defines _np_link, _np_opt, ..., _pre_synth, _build_clean, etc.
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_non_proj.mk

# -----------------------------------------------
# Targets (dot-prefixed to avoid becoming Make's default goal)
# Including Makefile exposes these with public names, e.g.:
#   build: .shell_build
#   clean: .shell_build_clean
# -----------------------------------------------
.shell_build: _np_$(lastword $(BUILD_STAGES))
.PHONY: .shell_build

.shell_build_clean: _build_clean
.PHONY: .shell_build_clean

.shell_build_info: _build_info
	@echo "------------------------------------------------------"
	@echo "Shell build configuration"
	@echo "------------------------------------------------------"
	@echo "SHELL_BUILD_REF  : $(SHELL_BUILD_REF)"
	@echo "CORE_BUILD_REF   : $(CORE_BUILD_REF)"
	@echo "TOP_DCP_FILE     : $(TOP_DCP_FILE)"
	@echo "CELL_DCPS        : $(CELL_DCPS)"
.PHONY: .shell_build_info

# -----------------------------------------------
# Regio IR packaging
#
# .shell_build_regio: generates the top-level register map IR YAML
# that can be handed off to firmware and software.
#
# The output is: $(COMPONENT_OUT_PATH)/regio/ir/esnet-smartnic-top-ir.yaml
#
# Derivation of the core regio component ref from CORE_BUILD_REF:
#   1. Strip the @lib suffix (if any), save it for re-attachment
#   2. Strip the trailing .build segment
#   3. Append .regio and restore the @lib suffix
# Example: core.stub.build@smartnic → core.stub.regio@smartnic
# -----------------------------------------------
__SB_CORE_BUILD_BASE := $(subst @$(lastword $(subst @, ,$(CORE_BUILD_REF))),,$(CORE_BUILD_REF))
__SB_LIB_SUFFIX := $(if $(findstring @,$(CORE_BUILD_REF)),@$(lastword $(subst @, ,$(CORE_BUILD_REF))),)
__SB_CORE_REGIO_REF := $(patsubst %.build,%.regio,$(if $(__SB_LIB_SUFFIX),$(__SB_CORE_BUILD_BASE),$(CORE_BUILD_REF)))$(__SB_LIB_SUFFIX)

__SB_REGIO_IR_DIR := $(COMPONENT_OUT_PATH)/regio/ir
__SB_CORE_REGIO_OUT := $(call get_lib_component_out_path_from_ref,$(__SB_CORE_REGIO_REF),$(LIB_OUTPUT_ROOT))
__SB_REGIO_ELABORATE_CMD := $(REGIO_ROOT)/regio-elaborate -i $(LIB_ROOT) -i $(__SB_REGIO_IR_DIR)
__SB_SMARTNIC_SRC_ROOT := $(SMARTNIC_ROOT)/src

# The top-level IR artifact
SHELL_REGIO_ARTIFACT := $(__SB_REGIO_IR_DIR)/esnet-smartnic-top-ir.yaml

.shell_build_regio: $(SHELL_REGIO_ARTIFACT)
.PHONY: .shell_build_regio

$(SHELL_REGIO_ARTIFACT): $(__SB_REGIO_IR_DIR)/core_decoder-ir.yaml
	@if [ -z "$(SHELL_REGIO_TOP_YAML)" ]; then \
	    echo "Error: SHELL_REGIO_TOP_YAML is not set."; \
	    echo "Set it in the platform-specific include (e.g. versal_shell_build.mk)."; \
	    exit 1; \
	fi
	@echo "Elaborating top-level regio IR: $@"
	@$(__SB_REGIO_ELABORATE_CMD) -f top -o $@ $(SHELL_REGIO_TOP_YAML)
.PHONY: $(SHELL_REGIO_ARTIFACT)

$(__SB_REGIO_IR_DIR)/core_decoder-ir.yaml:
	@echo "Building core regio for $(__SB_CORE_REGIO_REF) ..."
	@$(MAKE) -s -C $(__SB_SMARTNIC_SRC_ROOT) reg \
	    COMPONENT=$(__SB_CORE_REGIO_REF) \
	    BOARD=$(BOARD) \
	    BUILD_ID=$(BUILD_ID) \
	    OUTPUT_ROOT=$(OUTPUT_ROOT) \
	    $(if $(SMARTNIC_LIB_NAME),SMARTNIC_LIB_NAME=$(SMARTNIC_LIB_NAME),)
	@mkdir -p $(__SB_REGIO_IR_DIR)
	@cp $(__SB_CORE_REGIO_OUT)/ir/core_decoder-ir.yaml $@
.PHONY: $(__SB_REGIO_IR_DIR)/core_decoder-ir.yaml

.shell_build_regio_info:
	@echo "------------------------------------------------------"
	@echo "Regio packaging configuration"
	@echo "------------------------------------------------------"
	@echo "CORE_BUILD_REF        : $(CORE_BUILD_REF)"
	@echo "Core regio ref        : $(__SB_CORE_REGIO_REF)"
	@echo "Core regio output     : $(__SB_CORE_REGIO_OUT)"
	@echo "Regio IR output dir   : $(__SB_REGIO_IR_DIR)"
	@echo "SHELL_REGIO_TOP_YAML  : $(SHELL_REGIO_TOP_YAML)"
	@echo "SHELL_REGIO_ARTIFACT  : $(SHELL_REGIO_ARTIFACT)"
.PHONY: .shell_build_regio_info

.shell_build_info: .shell_build_regio_info
