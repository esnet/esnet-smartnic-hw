# Component setup
BOARD ?= av80
COMPONENT_ROOT := ../../..
include $(COMPONENT_ROOT)/config.mk

TOP = xilinx_alveo_vpd_wrapper
SRC_FILES = ../../rtl/src/xilinx_alveo_vpd.sv
SUBCOMPONENTS = xilinx.pci.rtl

all: opt validate
pre_synth: _pre_synth
synth: _build_core_synth
opt: _build_core_opt
validate: _build_core_validate
info: _build_core_info
clean: _build_clean
.PHONY: all pre_synth synth opt validate info clean

include $(SCRIPTS_ROOT)/Makefiles/vivado_build_core.mk
