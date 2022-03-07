# -----------------------------------------------
# (Global) Path setup
# -----------------------------------------------
IP_ROOT := ..

# -----------------------------------------------
# IP config
# -----------------------------------------------
include $(IP_ROOT)/config.mk

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build package

build:
	$(MAKE) -C ../build

package: build_package reg_package p4_package driver_package
.PHONY: package

build_package:
	cp ../build/out/smartnic_322mhz_app.opt.dcp smartnic_322mhz_app.dcp

reg_package:
	$(REGIO_ROOT)/regio-flatten -i $(REGIO_YAML_INC_DIR) -o smartnic_322mhz_app_decoder.yaml src/smartnic_322mhz_app_decoder.yaml

p4_package:
	@cp $(P4_FILE) smartnic_322mhz_app.p4
	@find ../p4 -name \*.lua -exec cp {} ./ \;

driver_package:
	$(MAKE) -C ../xilinx_ip/sdnet_0/src/sw/drivers && \
	tar -cf smartnic_322mhz_app_drv.tar -C ../xilinx_ip/sdnet_0/src/sw/drivers/install .

clean:
	$(MAKE) -C ../build clean
	@rm -rf smartnic_322mhz_app*
	@rm -rf *.lua

# -----------------------------------------------
# Include regio targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/regio.mk

