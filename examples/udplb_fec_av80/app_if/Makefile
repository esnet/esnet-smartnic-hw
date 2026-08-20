# -----------------------------------------------
# Path setup
# -----------------------------------------------
APP_DIR = ..

include $(APP_DIR)/config.mk

# Output products are arranged by board and Vivado version
# (e.g. .app/out/au280/2024.2/...)
ifdef XILINX_VIVADO
__OUTPUT_DIR = $(OUTPUT_ROOT)/$(BOARD)/$(XILINX_VIVADO__VERSION)
else
$(error Vivado not configured.)
endif

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build package

build:
	@$(MAKE) -s -C $(SRC_ROOT) opt COMPONENT=smartnic_app.build BOARD=$(BOARD)

package: build_package reg_package p4_package driver_package

build_package:
	@cp $(__OUTPUT_DIR)/smartnic_app/build/proj/proj.runs/impl_1/smartnic_app_opt.dcp smartnic_app.dcp

reg_package:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=smartnic_app.regio BOARD=$(BOARD)
	@cp $(__OUTPUT_DIR)/smartnic_app/regio/ir/smartnic_app_decoder-ir.yaml smartnic_app_decoder.yaml

p4_package:
	@if [ ! -z "$(strip $(P4_IGR_FILE))" ]; then \
		cp $(P4_IGR_FILE) smartnic_app_igr.p4; \
		if [ -e "$(P4_IGR_METADATA)" ]; then \
		    cp $(P4_IGR_METADATA) smartnic_app_igr-metadata.yaml; \
		fi; \
		find $(dir $(P4_IGR_FILE)) -name \*.lua -exec cp {} ./ \; ; \
	fi
	@if [ ! -z "$(strip $(P4_EGR_FILE))" ]; then \
		cp $(P4_EGR_FILE) smartnic_app_egr.p4; \
		if [ -e "$(P4_EGR_METADATA)" ]; then \
		    cp $(P4_EGR_METADATA) smartnic_app_egr-metadata.yaml; \
		fi; \
		find $(dir $(P4_EGR_FILE)) -name \*.lua -exec cp {} ./ \; ; \
	fi

driver_package:
	@if [ ! -z "$(strip $(P4_IGR_FILE))" ]; then \
		$(MAKE) -s -C $(SRC_ROOT) driver COMPONENT=vitisnetp4_igr.ip; \
		tar -cf smartnic_app_igr_drv.tar -C $(__OUTPUT_DIR)/vitisnetp4_igr/ip/vitisnetp4_igr/src/sw/drivers/install . ; \
	fi
	@if [ ! -z "$(strip $(P4_EGR_FILE))" ]; then \
		$(MAKE) -s -C $(SRC_ROOT) driver COMPONENT=vitisnetp4_egr.ip; \
		tar -cf smartnic_app_egr_drv.tar -C $(__OUTPUT_DIR)/vitisnetp4_egr/ip/vitisnetp4_egr/src/sw/drivers/install . ; \
	fi

clean:
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=smartnic_app.build BOARD=$(BOARD)
	@rm -rf smartnic_app*
	@rm -rf *.lua

.PHONY: all build package build_package reg_package p4_package driver_package clean
