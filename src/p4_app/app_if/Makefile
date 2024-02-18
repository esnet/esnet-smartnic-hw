# ----------------------------------------------------
# Paths
# ----------------------------------------------------
COMPONENT_ROOT = ..

include $(COMPONENT_ROOT)/config.mk

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build package

build:
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=smartnic_322mhz_app.build BOARD=$(BOARD)

package: build_package reg_package p4_package driver_package

build_package:
	@cp $(OUTPUT_ROOT)/smartnic_322mhz_app/build/$(BOARD)/proj/proj.runs/synth_1/smartnic_322mhz_app.dcp smartnic_322mhz_app.dcp
	@cp $(OUTPUT_ROOT)/vitisnetp4/rtl/sdnet_0_app_pkg.sv smartnic_322mhz_app_pkg.sv
	@sed -i 's/sdnet_0/smartnic_322mhz/g' smartnic_322mhz_app_pkg.sv

reg_package:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=smartnic_322mhz_app.regio
	@cp $(OUTPUT_ROOT)/smartnic_322mhz_app/regio/ir/smartnic_322mhz_app_decoder-ir.yaml smartnic_322mhz_app_decoder.yaml

p4_package:
	@cp $(P4_FILE) smartnic_322mhz_app.p4
	@find $(dir $(P4_FILE)) -name \*.lua -exec cp {} ./ \;

driver_package:
	@$(MAKE) -s -C $(SRC_ROOT) driver COMPONENT=vitisnetp4.ip
	@tar -cf smartnic_322mhz_app_drv.tar -C $(OUTPUT_ROOT)/vitisnetp4/ip/$(BOARD)/sdnet_0/src/sw/drivers/install .

clean:
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=smartnic_322mhz_app.build BOARD=$(BOARD)
	@rm -rf smartnic_322mhz_app*
	@rm -rf *.lua

.PHONY: all build package build_package reg_package p4_package driver_package clean

