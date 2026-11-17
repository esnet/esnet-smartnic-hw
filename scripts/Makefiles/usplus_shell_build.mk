# UltraScale+ shell/core checkpoint assembly and programming artifacts.
# Include from a configured component, through shell_build.mk.

ifeq ($(filter $(BOARD),au55c au250 au280),)
$(error usplus_shell_build.mk: unsupported BOARD '$(BOARD)')
endif

__USB_LIB_SUFFIX := $(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),)
SHELL_BUILD_REF := xilinx.alveo.usplus.shell.build$(__USB_LIB_SUFFIX)

# The US+ shell RTL and synthesized checkpoint use this top-level name.
TOP := esnet_shell
BUILD_STAGES := link opt place place_opt route route_opt bitstream
SHELL_REGIO_TOP_YAML := $(SMARTNIC_ROOT)/src/xilinx/alveo/usplus/shell/regio/esnet-smartnic-top.yaml

__USB_BOARD_CONSTRAINTS := $(SMARTNIC_ROOT)/src/xilinx/alveo/usplus/shell/build/$(BOARD)
CONSTRAINTS_XDC_IMPL += $(addprefix $(__USB_BOARD_CONSTRAINTS)/,general.xdc pins.xdc)
CONSTRAINTS_XDC_IMPL += $(SMARTNIC_ROOT)/src/xilinx/alveo/usplus/shell/build/qspi.xdc

__USB_EXPORT_DIR := $(SMARTNIC_ROOT)/scripts/usplus
__USB_EXPORT_HOOK := $(__USB_EXPORT_DIR)/write_bitstream.post.tcl
__USB_PROBE_NAMES_SCRIPT := $(__USB_EXPORT_DIR)/rename_pcie_reset_probes.py
IMPL_HOOK_TCL_FILES += $(__USB_EXPORT_HOOK)

include $(SMARTNIC_ROOT)/scripts/Makefiles/shell_build_base.mk

$(COMPONENT_OUT_PATH)/.done/link: $(CONSTRAINTS_XDC_IMPL)
$(COMPONENT_OUT_PATH)/.done/bitstream: $(__USB_EXPORT_HOOK) $(__USB_PROBE_NAMES_SCRIPT)

__USB_BITSTREAM := $(COMPONENT_OUT_PATH)/$(TOP).bit
__USB_BIN := $(COMPONENT_OUT_PATH)/$(TOP).bin
__USB_LTX := $(COMPONENT_OUT_PATH)/$(TOP).ltx

.shell_build_bitstream: _np_bitstream
.PHONY: .shell_build_bitstream

.shell_build_info: .usplus_shell_build_info
.usplus_shell_build_info:
	@echo "US+ programming artifacts: $(__USB_BITSTREAM) $(__USB_BIN) $(__USB_LTX)"
.PHONY: .usplus_shell_build_info

.shell_build_hwapi: .usplus_shell_build_hwapi
.usplus_shell_build_hwapi: | $(SHELL_HWAPI_DIRS)
	@zstd -f9 $(__USB_BITSTREAM) -o $(SHELL_HWAPI_FW_DIR)/esnet-smartnic.bit.zst
	@zstd -f9 $(__USB_BIN) -o $(SHELL_HWAPI_FW_DIR)/esnet-smartnic.bin.zst
	@cp $(__USB_LTX) $(SHELL_HWAPI_FW_DIR)/esnet-smartnic.ltx
.PHONY: .usplus_shell_build_hwapi
