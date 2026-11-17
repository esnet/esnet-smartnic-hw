# ESnet shell example build

SMARTNIC_ROOT  := $(abspath ../..)
BOARD          ?= av80
CORE_BUILD_REF ?= core.stub.build

# The platform build flow is selected by BOARD in shell_build.mk.
.DEFAULT_GOAL := image

include $(SMARTNIC_ROOT)/scripts/Makefiles/shell_proj_config.mk

config:      .configure
build:       .shell_proj_build
image:       .shell_proj_image
reg_package: .shell_proj_regio
info:        .shell_proj_info
hwapi:       .shell_proj_hwapi
package:     .shell_proj_package
p4_driver:   .shell_proj_p4_driver
build_clean: .shell_proj_build_clean
clean:       .shell_proj_clean
clean_all:   .shell_proj_clean_all
restore:     .shell_proj_restore

.PHONY: config build image reg_package info hwapi package p4_driver build_clean clean clean_all restore
