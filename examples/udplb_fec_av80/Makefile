# udplb_fec example build

.DEFAULT_GOAL := pdi

SMARTNIC_ROOT  := $(abspath ../..)
BOARD          ?= av80
CORE_BUILD_REF ?= smartnic.core.build
APP_BUILD_REF  ?= smartnic_app.build
APP_REGIO_REF  ?= smartnic_app.regio
APP_SRC_DIR    ?= $(CURDIR)/src
P4_IGR_FILE    ?= $(CURDIR)/p4/p4_multi_proc_igr.p4
P4_EGR_FILE    ?= $(CURDIR)/p4/p4_multi_proc_egr.p4

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
