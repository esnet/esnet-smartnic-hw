# Versal shell example build

.DEFAULT_GOAL := pdi

SMARTNIC_ROOT  := $(abspath ../..)
BOARD          ?= av80
CORE_BUILD_REF ?= core.stub.build

include $(SMARTNIC_ROOT)/scripts/Makefiles/shell_proj_config.mk

build:       .shell_proj_build
pdi:         .shell_proj_pdi
reg_package: .shell_proj_regio
info:        .shell_proj_info
build_clean: .shell_proj_build_clean
clean:       .shell_proj_clean
clean_all:   .shell_proj_clean_all
restore:     .shell_proj_restore

.PHONY: build pdi reg_package info build_clean clean clean_all restore
