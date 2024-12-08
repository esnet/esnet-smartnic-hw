# -----------------------------------------------
# Path setup
# -----------------------------------------------
APP_DIR = ..

include $(APP_DIR)/config.mk

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build package

build:
	@$(MAKE) -s -C $(SRC_ROOT) opt COMPONENT=smartnic_app.build BOARD=$(BOARD)

package: build_package reg_package p4_package driver_package

build_package:
	@cp $(OUTPUT_ROOT)/$(BOARD)/smartnic_app/build/proj/proj.runs/impl_1/smartnic_app_opt.dcp smartnic_app.dcp
	@cp $(SRC_ROOT)/smartnic_app/rtl/src/smartnic_app_pkg.sv smartnic_app_pkg.sv

reg_package:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=smartnic_app.regio BOARD=$(BOARD)
	@cp $(OUTPUT_ROOT)/$(BOARD)/smartnic_app/regio/ir/smartnic_app_decoder-ir.yaml smartnic_app_decoder.yaml

p4_package:
	@cp $(P4_IGR_FILE) smartnic_app_igr.p4
	@find $(dir $(P4_IGR_FILE)) -name \*.lua -exec cp {} ./ \;

driver_package:
	@$(MAKE) -s -C $(SRC_ROOT) driver COMPONENT=vitisnetp4.ip
	@tar -cf smartnic_app_igr_drv.tar -C $(OUTPUT_ROOT)/$(BOARD)/vitisnetp4/ip/vitisnetp4_igr/src/sw/drivers/install .

clean:
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=smartnic_app.build BOARD=$(BOARD)
	@rm -rf smartnic_app*
	@rm -rf *.lua

.PHONY: all build package build_package reg_package p4_package driver_package clean
