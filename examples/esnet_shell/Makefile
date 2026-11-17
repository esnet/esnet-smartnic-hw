# ESnet shell example build

SMARTNIC_ROOT  := $(abspath ../..)
BOARD          ?= av80
CORE_BUILD_REF ?= core.stub.build

# The platform build flow is selected by BOARD in shell_build.mk.
.DEFAULT_GOAL := $(if $(filter av%,$(BOARD)),pdi,bitstream)

include $(SMARTNIC_ROOT)/scripts/Makefiles/shell_proj_config.mk

config:      .configure
build:       .shell_proj_build
pdi:         .shell_proj_pdi
bitstream:   .shell_proj_bitstream
reg_package: .shell_proj_regio
info:        .shell_proj_info
hwapi:       .shell_proj_hwapi
package:     .shell_proj_package
p4_driver:   .shell_proj_p4_driver
build_clean: .shell_proj_build_clean
clean:       .shell_proj_clean
clean_all:   .shell_proj_clean_all
restore:     .shell_proj_restore

.PHONY: config build pdi bitstream reg_package info hwapi package p4_driver build_clean clean clean_all restore
