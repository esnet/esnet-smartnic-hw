# ----------------------------------------------------
# Paths
# ----------------------------------------------------
COMPONENT_ROOT = ../..

include $(COMPONENT_ROOT)/config.mk

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build package

build:
	@$(MAKE) -s -C $(SRC_ROOT) opt COMPONENT=smartnic_app.stub.build BOARD=$(BOARD)

package: build_package reg_package p4_package driver_package

build_package:
	@cp $(OUTPUT_ROOT)/$(BOARD)/smartnic_app/stub/build/proj/proj.runs/opt_1/smartnic_app_opt.dcp smartnic_app.dcp

reg_package:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=smartnic_app.stub.regio
	@cp $(OUTPUT_ROOT)/$(BOARD)/smartnic_app/stub/regio/ir/smartnic_app_decoder-ir.yaml smartnic_app_decoder.yaml

p4_package:

driver_package:

clean:
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=smartnic_app.stub.build BOARD=$(BOARD)
	@rm -rf smartnic_app*
	@rm -rf *.lua

.PHONY: all build package build_package reg_package p4_package driver_package clean

