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
	@echo "RTL-only application (no P4)."

driver_package:
	@echo "RTL-only application (no driver)."

clean:
	$(MAKE) -C ../build clean
	@rm -rf smartnic_322mhz_app*
	@rm -rf *.lua

# -----------------------------------------------
# Include regio targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/regio.mk

