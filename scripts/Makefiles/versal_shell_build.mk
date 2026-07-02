# versal_shell_build.mk
#
# Versal-specific extension of shell_build.mk.
#
# Fills in the shell component reference for the Versal av80 shell and adds
# the device_image, xsa, and PDI firmware generation stages on top of the
# generic shell+core assembly provided by shell_build.mk.
#
# Intended to be included within a component build Makefile after the
# component's config chain has been loaded (same context requirement as
# shell_build.mk).
#
# Required inputs from the including component Makefile:
#   CORE_BUILD_REF     - component ref for the core build, e.g. core.stub.build
#   SMARTNIC_ROOT      - path to the esnet-smartnic-hw repo root
#
# Optional inputs:
#   BOARD              - target board (default: av80)
#   SMARTNIC_LIB_NAME  - library qualifier appended as @$(SMARTNIC_LIB_NAME)
#                        when set; omitted when building directly within the
#                        smartnic repo (same pattern as src/ component Makefiles)
#   AVED_BASE_DESIGN   - AVED reference design name
#                        (default: amd_v80_gen5x8_25.1)
#   CONSTRAINTS_XDC_IMPL  - additional implementation XDC files
#   IMPL_HOOK_TCL_FILES   - additional TCL hook files
#   IP_REPO_PATHS         - additional IP repository paths
#
# Targets provided (dot-prefixed; expose with public names in the including
# Makefile, e.g. build: .shell_build  pdi: .versal_shell_build_pdi):
#   .shell_build              - from shell_build_base.mk: link through xsa
#   .shell_build_clean        - from shell_build_base.mk: clean assembly output
#   .shell_build_info         - from shell_build_base.mk + Versal-specific info
#   .versal_shell_build_pdi   - firmware PDI generation (requires .shell_build)

# -----------------------------------------------
# Defaults
# -----------------------------------------------
BOARD             ?= av80
AVED_BASE_DESIGN  ?= amd_v80_gen5x8_25.1

# -----------------------------------------------
# Library qualifier
#
# Appends @$(SMARTNIC_LIB_NAME) when the variable is set, matching the
# pattern used throughout src/ component Makefiles:
#   foo.bar.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)
# -----------------------------------------------
__VSB_LIB_SUFFIX := $(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)

# -----------------------------------------------
# Shell component reference
# -----------------------------------------------
SHELL_BUILD_REF := xilinx.alveo.versal.shell.$(BOARD).build$(__VSB_LIB_SUFFIX)

# -----------------------------------------------
# Versal-specific board directory (constraints + hooks)
# -----------------------------------------------
__VSB_SHELL_BOARD_DIR := $(SMARTNIC_ROOT)/src/xilinx/alveo/versal/shell/$(BOARD)

CONSTRAINTS_XDC_IMPL += \
    $(abspath $(__VSB_SHELL_BOARD_DIR)/impl.pins.xdc) \
    $(abspath $(__VSB_SHELL_BOARD_DIR)/impl.xdc)

IMPL_HOOK_TCL_FILES += $(abspath $(wildcard $(__VSB_SHELL_BOARD_DIR)/*.tcl))

IP_REPO_PATHS += \
    $(abspath $(SMARTNIC_ROOT)/src/xilinx/aved/hw/$(AVED_BASE_DESIGN)/src/iprepo)

# -----------------------------------------------
# Extend build stages with Versal device output
# -----------------------------------------------
BUILD_STAGES := link opt place place_opt route route_opt device_image xsa

# -----------------------------------------------
# Versal-specific regio top YAML
#
# Points to the Versal platform's top-level register map specification.
# Used by shell_build_base.mk to elaborate the final IR artifact.
# -----------------------------------------------
SHELL_REGIO_TOP_YAML := $(SMARTNIC_ROOT)/src/xilinx/alveo/versal/regio/esnet-smartnic-top.yaml

# -----------------------------------------------
# Include generic shell+core assembly
# -----------------------------------------------
include $(SMARTNIC_ROOT)/scripts/Makefiles/shell_build_base.mk

# -----------------------------------------------
# PDI firmware generation
# -----------------------------------------------
__VSB_BUILD_PDI_SCRIPT := $(SMARTNIC_ROOT)/scripts/versal/build_pdi.sh
__VSB_PDI_HW_FILE      := $(COMPONENT_OUT_PATH)/$(TOP).pdi
__VSB_XSA_FILE         := $(COMPONENT_OUT_PATH)/$(TOP).xsa
__VSB_PDI_APP_FILE     := $(COMPONENT_OUT_PATH)/$(TOP)_app.pdi

$(__VSB_PDI_APP_FILE): $(__VSB_PDI_HW_FILE) $(__VSB_XSA_FILE)
	@$(__VSB_BUILD_PDI_SCRIPT) \
	    -p $(abspath $(SMARTNIC_ROOT)) \
	    -o $(COMPONENT_OUT_PATH) \
	    -d $(AVED_BASE_DESIGN) \
	    -t $(TOP)

.versal_shell_build_pdi: _np_xsa $(__VSB_PDI_APP_FILE)
.PHONY: .versal_shell_build_pdi

# -----------------------------------------------
# Regio alias
# -----------------------------------------------
.versal_shell_build_regio: .shell_build_regio
.PHONY: .versal_shell_build_regio

# -----------------------------------------------
# Info
# -----------------------------------------------
.shell_build_info: .versal_shell_build_info
.versal_shell_build_info:
	@echo "------------------------------------------------------"
	@echo "Versal shell build configuration"
	@echo "------------------------------------------------------"
	@echo "BOARD            : $(BOARD)"
	@echo "AVED_BASE_DESIGN : $(AVED_BASE_DESIGN)"
	@echo "CONSTRAINTS_XDC_IMPL :"
	@for f in $(CONSTRAINTS_XDC_IMPL); do echo "\t$$f"; done
	@echo "IMPL_HOOK_TCL_FILES :"
	@for f in $(IMPL_HOOK_TCL_FILES); do echo "\t$$f"; done
	@echo "IP_REPO_PATHS    :"
	@for f in $(IP_REPO_PATHS); do echo "\t$$f"; done
	@echo "PDI_APP_FILE     : $(__VSB_PDI_APP_FILE)"
.PHONY: .versal_shell_build_info
