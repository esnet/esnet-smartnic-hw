# ----------------------------------------------------
# Application config
# ----------------------------------------------------
APP_DIR ?= ..
include $(APP_DIR)/.app_config.mk

# -----------------------------------------------
# IP config (for compilation library setup)
# -----------------------------------------------
IP_ROOT = ..
include $(IP_ROOT)/config.mk

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build package

build:
	$(MAKE) -C ../build

package: build_package reg_package p4_package driver_package

build_package:
	cp ../build/out/smartnic_322mhz_app.opt.dcp smartnic_322mhz_app.dcp
	cp src/smartnic_322mhz_app_pkg.sv smartnic_322mhz_app_pkg.sv

reg_package:
	$(REGIO_ROOT)/regio-flatten -i $(REGIO_YAML_INC_DIR) -o smartnic_322mhz_app_decoder.yaml src/smartnic_322mhz_app_decoder.yaml

p4_package:
	@cp $(P4_FILE) smartnic_322mhz_app.p4
	@find ../p4 -name \*.lua -exec cp {} ./ \;

driver_package:
	# Start: Hack to fix missing files in libvitisnetp4.a and libvitisnetp4.so in Vivado 2022.1.1
	-cp ${XILINX_VIVADO}/data/ip/xilinx/cam_v2_3/sw/cam_src/inc/bf.h ../xilinx_ip/sdnet_0/src/sw/drivers/cam_obf/inc
	-cp ${XILINX_VIVADO}/data/ip/xilinx/cam_v2_3/sw/cam_src/src/bf.c ../xilinx_ip/sdnet_0/src/sw/drivers/cam_obf/src
	# End: Hack to fix missing files in libvitisnetp4.a and libvitisnetp4.so in Vivado 2022.1.1
	$(MAKE) -C ../xilinx_ip/sdnet_0/src/sw/drivers && \
	tar -cf smartnic_322mhz_app_drv.tar -C ../xilinx_ip/sdnet_0/src/sw/drivers/install .

clean:
	$(MAKE) -C ../build clean
	@rm -rf smartnic_322mhz_app*
	@rm -rf *.lua

.PHONY: all build package build_package reg_package p4_package driver_package clean

# -----------------------------------------------
# Application config target
# -----------------------------------------------
$(APP_DIR)/.app_config.mk: $(APP_DIR)/Makefile
	$(MAKE) -C $(APP_DIR) config

# -----------------------------------------------
# Include regio targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/regio.mk

