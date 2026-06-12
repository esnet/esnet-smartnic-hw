# shell_proj_config.mk
#
# Project-level configuration for shell builds.
#
# Creates a local build directory tree containing:
#   $(BUILD_DIR)/config.mk                         - project config
#   $(BUILD_DIR)/src/Makefile                      - library dispatch
#   $(BUILD_DIR)/src/config.mk                     - library config
#   $(BUILD_DIR)/src/esnet_smartnic/config.mk      - component config
#   $(BUILD_DIR)/src/esnet_smartnic/build/Makefile - component build Makefile
#
# BUILD_DIR defaults to build/$(BOARD) so multiple board targets can
# coexist as build/av80/, build/av90/, etc.
#
# Reconfiguration is triggered only when the recorded build parameters
# change (BOARD, CORE_BUILD_REF, SMARTNIC_ROOT, Vivado version).
# A stamp file is written to build/$(BOARD).config and compared
# using cmp -s before overwriting, matching the pattern used in
# vivado_compile.mk for sources.tcl.
#
# Required inputs (set before including this file):
#   SMARTNIC_ROOT  - absolute path to the esnet-smartnic-hw repo root
#
# Optional inputs:
#   BOARD          - target board (default: av80)
#   CORE_BUILD_REF - core component ref (default: core.stub.build)
#   BUILD_DIR      - build root (default: $(CURDIR)/build/$(BOARD))

# -----------------------------------------------
# Defaults
# -----------------------------------------------
BOARD          ?= av80
CORE_BUILD_REF ?= core.stub.build
BUILD_DIR      ?= $(CURDIR)/build/$(BOARD)

# -----------------------------------------------
# Paths (modelled on app_config_base.mk — no config.mk include)
# -----------------------------------------------
__SPC_SMARTNIC_ROOT  := $(abspath $(SMARTNIC_ROOT))
LIB_ROOT             := $(__SPC_SMARTNIC_ROOT)/esnet-fpga-library
include $(LIB_ROOT)/paths.mk
include $(__SPC_SMARTNIC_ROOT)/paths.mk
CFG_ROOT             := $(__SPC_SMARTNIC_ROOT)/cfg

XILINX_VIVADO__VERSION := $(firstword $(sort $(subst /, ,$(XILINX_VIVADO))))

__SPC_BUILD_SRC_DIR  := $(BUILD_DIR)/src
__SPC_BUILD_OUT_DIR  := $(BUILD_DIR)/out
__SPC_ESNET_DIR      := $(__SPC_BUILD_SRC_DIR)/esnet_smartnic
__SPC_COMP_DIR       := $(__SPC_ESNET_DIR)/build

# -----------------------------------------------
# Library name and qualifier
# -----------------------------------------------
SMARTNIC_LIB_NAME := smartnic
__SPC_LIB_SUFFIX  := @$(SMARTNIC_LIB_NAME)

# -----------------------------------------------
# Config stamp
#
# Records the parameters that affect the generated files.  The sentinel
# depends on this stamp; the stamp is only updated when its content
# changes, so an unmodified configuration does not trigger a reconfigure.
# -----------------------------------------------
__SPC_CONFIGURED := $(__SPC_COMP_DIR)/.configured

# Stamp and tmp file live beside BUILD_DIR (not inside it) so they survive
# a clean and are not disturbed when BUILD_DIR is backed up or recreated.
__SPC_STAMP     := $(CURDIR)/build/$(BOARD).config
__SPC_STAMP_TMP := $(CURDIR)/build/$(BOARD).config.tmp

# Define the stamp content: one key=value per line.
define __SPC_STAMP_CONTENT
SMARTNIC_ROOT=$(abspath $(SMARTNIC_ROOT))
CORE_BUILD_REF=$(CORE_BUILD_REF)
XILINX_VIVADO__VERSION=$(XILINX_VIVADO__VERSION)
endef
export __SPC_STAMP_CONTENT

# The stamp file is written (or left unchanged) before configure runs.
# Depends on the including Makefile as a normal prerequisite so that
# editing it (changing CORE_BUILD_REF, BOARD, etc.) always re-runs the
# stamp recipe; cmp -s then decides whether the content actually changed.
# If the content has changed and a stamp already exists, the current
# BUILD_DIR is saved as BUILD_DIR.bak (overwriting any previous backup)
# before a fresh configure proceeds.
__SPC_CALLER_MAKEFILE := $(firstword $(MAKEFILE_LIST))
$(__SPC_STAMP): $(__SPC_CALLER_MAKEFILE) | $(BUILD_DIR)
	@printf 'SMARTNIC_ROOT=%s\nCORE_BUILD_REF=%s\nXILINX_VIVADO__VERSION=%s\n' \
	    "$(abspath $(SMARTNIC_ROOT))" "$(CORE_BUILD_REF)" "$(XILINX_VIVADO__VERSION)" \
	    > $(__SPC_STAMP_TMP)
	@if ! cmp -s $(__SPC_STAMP_TMP) $@ 2>/dev/null; then \
	    if [ -e $@ ]; then \
	        echo ""; \
	        echo "Build configuration has changed."; \
	        echo "Saving $(BUILD_DIR) to $(CURDIR)/build/$(BOARD).bak ..."; \
	        rm -rf $(CURDIR)/build/$(BOARD).bak; \
	        mv $(BUILD_DIR) $(CURDIR)/build/$(BOARD).bak; \
	        cp -p $@ $(CURDIR)/build/$(BOARD).bak.config; \
	        mkdir -p $(BUILD_DIR); \
	        cp $(__SPC_STAMP_TMP) $@; \
	        rm -f $(__SPC_STAMP_TMP); \
	        echo "The previous build can be restored with: make restore"; \
	        echo ""; \
	        exit 1; \
	    fi; \
	    cp $(__SPC_STAMP_TMP) $@; \
	fi
	@rm -f $(__SPC_STAMP_TMP)

$(BUILD_DIR):
	@mkdir -p $@

# -----------------------------------------------
# Configure target
#
# Depends on the stamp file so it only runs when the stamp changes
# (i.e. when BOARD, CORE_BUILD_REF, SMARTNIC_ROOT, or Vivado version
# change).  The generated files are written unconditionally when
# reconfiguration does occur.
# -----------------------------------------------
$(__SPC_CONFIGURED): $(__SPC_STAMP) | $(__SPC_COMP_DIR)
	@echo "Configuring shell build at $(BUILD_DIR) ..."
	@# --- build/config.mk ---
	@echo "# Autogenerated by shell_proj_config.mk — do not edit"            >  $(BUILD_DIR)/config.mk
	@echo "SMARTNIC_ROOT := $(__SPC_SMARTNIC_ROOT)"                          >> $(BUILD_DIR)/config.mk
	@echo "LIB_ROOT      := $(__SPC_SMARTNIC_ROOT)/esnet-fpga-library"      >> $(BUILD_DIR)/config.mk
	@echo "include \$$(LIB_ROOT)/paths.mk"                                   >> $(BUILD_DIR)/config.mk
	@echo "include $(__SPC_SMARTNIC_ROOT)/paths.mk"                          >> $(BUILD_DIR)/config.mk
	@echo "CFG_ROOT      := $(__SPC_SMARTNIC_ROOT)/cfg"                     >> $(BUILD_DIR)/config.mk
	@echo "OUTPUT_ROOT   := $(abspath $(__SPC_BUILD_OUT_DIR))"              >> $(BUILD_DIR)/config.mk
	@echo "include \$$(SCRIPTS_ROOT)/Makefiles/proj_config_base.mk"          >> $(BUILD_DIR)/config.mk
	@# --- build/src/Makefile ---
	@cp $(SCRIPTS_ROOT)/Makefiles/templates/lib.mk $(__SPC_BUILD_SRC_DIR)/Makefile
	@# --- build/src/config.mk ---
	@cp $(SCRIPTS_ROOT)/Makefiles/templates/lib_config.mk $(__SPC_BUILD_SRC_DIR)/config.mk
	@sed -i 's|<path-to-proj-root>|$(abspath $(BUILD_DIR))|'                $(__SPC_BUILD_SRC_DIR)/config.mk
	@sed -i 's|<library-name>|ESnet SmartNIC Shell Build|'                  $(__SPC_BUILD_SRC_DIR)/config.mk
	@sed -i 's|<library-desc>|Shell build library|'                         $(__SPC_BUILD_SRC_DIR)/config.mk
	@sed -i 's|<libraries>|$(SMARTNIC_LIB_NAME)=$(__SPC_SMARTNIC_ROOT)/src|' $(__SPC_BUILD_SRC_DIR)/config.mk
	@sed -i 's|<common-lib-name>|common@$(SMARTNIC_LIB_NAME)|'              $(__SPC_BUILD_SRC_DIR)/config.mk
	@sed -i 's|<custom-env-setup>|BOARD ?= $(BOARD)|'                       $(__SPC_BUILD_SRC_DIR)/config.mk
	@sed -i 's|<output-subdir>||'                                           $(__SPC_BUILD_SRC_DIR)/config.mk
	@sed -i 's|<lib-env>|\\\n\tBOARD=$$(BOARD)|g'                          $(__SPC_BUILD_SRC_DIR)/config.mk
	@# --- build/src/esnet_smartnic/config.mk ---
	@cp $(SCRIPTS_ROOT)/Makefiles/templates/component_config.mk $(__SPC_ESNET_DIR)/config.mk
	@# --- build/src/esnet_smartnic/build/Makefile ---
	@echo "# Autogenerated by shell_proj_config.mk — do not edit"                >  $(__SPC_COMP_DIR)/Makefile
	@echo "all: build"                                                           >> $(__SPC_COMP_DIR)/Makefile
	@echo ".PHONY: all"                                                          >> $(__SPC_COMP_DIR)/Makefile
	@echo ""                                                                     >> $(__SPC_COMP_DIR)/Makefile
	@echo "COMPONENT_ROOT := .."                                                 >> $(__SPC_COMP_DIR)/Makefile
	@echo "include \$$(COMPONENT_ROOT)/config.mk"                               >> $(__SPC_COMP_DIR)/Makefile
	@echo ""                                                                     >> $(__SPC_COMP_DIR)/Makefile
	@echo "TOP            := esnet_smartnic"                                     >> $(__SPC_COMP_DIR)/Makefile
	@echo "SMARTNIC_ROOT  := $(__SPC_SMARTNIC_ROOT)"                            >> $(__SPC_COMP_DIR)/Makefile
	@echo "BOARD          := $(BOARD)"                                           >> $(__SPC_COMP_DIR)/Makefile
	@echo "CORE_BUILD_REF := $(CORE_BUILD_REF)$(__SPC_LIB_SUFFIX)"             >> $(__SPC_COMP_DIR)/Makefile
	@echo "SMARTNIC_LIB_NAME := $(SMARTNIC_LIB_NAME)"                          >> $(__SPC_COMP_DIR)/Makefile
	@echo ""                                                                     >> $(__SPC_COMP_DIR)/Makefile
	@echo "include $(__SPC_SMARTNIC_ROOT)/scripts/Makefiles/shell_build.mk"     >> $(__SPC_COMP_DIR)/Makefile
	@echo ""                                                                     >> $(__SPC_COMP_DIR)/Makefile
	@echo "build:       .shell_build"                                            >> $(__SPC_COMP_DIR)/Makefile
	@echo "build_clean: .shell_build_clean"                                      >> $(__SPC_COMP_DIR)/Makefile
	@echo "pdi:         .versal_shell_build_pdi"                                 >> $(__SPC_COMP_DIR)/Makefile
	@echo "info:        .shell_build_info"                                       >> $(__SPC_COMP_DIR)/Makefile
	@echo ".PHONY: build build_clean pdi info"                                   >> $(__SPC_COMP_DIR)/Makefile
	@touch $@
	@echo "Done."

$(__SPC_COMP_DIR): | $(__SPC_BUILD_SRC_DIR) $(__SPC_ESNET_DIR)
	@mkdir -p $@

$(__SPC_BUILD_SRC_DIR) $(__SPC_ESNET_DIR):
	@mkdir -p $@

.configure: $(__SPC_CONFIGURED)
.PHONY: .configure

# -----------------------------------------------
# Convenience: forward targets through the library dispatch.
# -----------------------------------------------
SMARTNIC_BUILD_CMD = $(MAKE) -s -C $(__SPC_BUILD_SRC_DIR) \
    COMPONENT=esnet_smartnic.build BOARD=$(BOARD) BUILD_ID=$(BUILD_ID)

# pdi is not in lib_base.mk's LIB_OPS, so bypass the lib layer and invoke
# the generated component Makefile directly (TODO: add pdi to LIB_OPS in
# esnet-fpga-library so this can use SMARTNIC_BUILD_CMD like the others).
SMARTNIC_COMP_CMD = $(MAKE) -s -C $(__SPC_COMP_DIR) \
    BOARD=$(BOARD) BUILD_ID=$(BUILD_ID)

.shell_proj_build: $(__SPC_CONFIGURED)
	@$(SMARTNIC_BUILD_CMD) build
.PHONY: .shell_proj_build

.shell_proj_build_clean: $(__SPC_CONFIGURED)
	@$(SMARTNIC_BUILD_CMD) build_clean
.PHONY: .shell_proj_build_clean

.shell_proj_pdi: $(__SPC_CONFIGURED)
	@$(SMARTNIC_COMP_CMD) pdi
.PHONY: .shell_proj_pdi

.shell_proj_info: $(__SPC_CONFIGURED)
	@$(SMARTNIC_BUILD_CMD) info
.PHONY: .shell_proj_info

# -----------------------------------------------
# Clean
# -----------------------------------------------
.shell_proj_clean:
	@echo "Cleaning shell build at $(BUILD_DIR) ..."
	@rm -rf $(BUILD_DIR)
	@rm -f $(__SPC_STAMP) $(__SPC_STAMP_TMP)
	@echo "Done."
.PHONY: .shell_proj_clean

.shell_proj_restore:
	@if [ ! -d $(CURDIR)/build/$(BOARD).bak ]; then \
	    echo "Error: no backup found at $(CURDIR)/build/$(BOARD).bak"; exit 1; \
	fi
	@echo "Restoring $(CURDIR)/build/$(BOARD).bak to $(BUILD_DIR) ..."
	@rm -rf $(BUILD_DIR)
	@mv $(CURDIR)/build/$(BOARD).bak $(BUILD_DIR)
	@[ -f $(CURDIR)/build/$(BOARD).bak.config ] && mv $(CURDIR)/build/$(BOARD).bak.config $(__SPC_STAMP) || true
	@touch $(__SPC_CONFIGURED)
	@echo "Done."
.PHONY: .shell_proj_restore

.shell_proj_clean_all:
	@echo "Cleaning all shell build directories under $(CURDIR)/build ..."
	@rm -rf $(CURDIR)/build
	@echo "Done."
.PHONY: .shell_proj_clean_all
