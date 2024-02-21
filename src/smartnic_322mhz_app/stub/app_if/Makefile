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
	@$(MAKE) -s -C $(SRC_ROOT) opt COMPONENT=smartnic_322mhz_app.stub.build BOARD=$(BOARD)

package: build_package reg_package p4_package driver_package

build_package:
	@cp $(OUTPUT_ROOT)/smartnic_322mhz_app/stub/build/$(BOARD)/proj/proj.runs/opt_1/smartnic_322mhz_app_opt.dcp smartnic_322mhz_app.dcp
	@cp $(SRC_ROOT)/smartnic_322mhz_app/stub/rtl/src/smartnic_322mhz_app_pkg.sv smartnic_322mhz_app_pkg.sv

reg_package:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=smartnic_322mhz_app.stub.regio
	@cp $(OUTPUT_ROOT)/smartnic_322mhz_app/stub/regio/ir/smartnic_322mhz_app_decoder-ir.yaml smartnic_322mhz_app_decoder.yaml

p4_package:

driver_package:

clean:
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=smartnic_322mhz_app.stub.build BOARD=$(BOARD)
	@rm -rf smartnic_322mhz_app*
	@rm -rf *.lua

.PHONY: all build package build_package reg_package p4_package driver_package clean

