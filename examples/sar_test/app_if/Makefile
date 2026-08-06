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

package: build_package reg_package

build_package:
	@cp $(__OUTPUT_DIR)/smartnic_app/build/proj/proj.runs/impl_1/smartnic_app_opt.dcp smartnic_app.dcp

reg_package:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=smartnic_app.regio BOARD=$(BOARD)
	@cp $(__OUTPUT_DIR)/smartnic_app/regio/ir/smartnic_app_decoder-ir.yaml smartnic_app_decoder.yaml

clean:
	@$(MAKE) -s -C $(SRC_ROOT) clean COMPONENT=smartnic_app.build BOARD=$(BOARD)
	@rm -rf smartnic_app*

.PHONY: all build package build_package reg_package clean
