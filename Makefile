#------- Variables -------
# Notes:
#  APP_DIR and SMARTNIC_DIR are configured in the parent Makefile.
#  ALL other variables are derived from APP_DIR and SMARTNIC_DIR.

export PROJ_ROOT := $(abspath $(SMARTNIC_DIR))
export LIB_ROOT  := $(PROJ_ROOT)/esnet-fpga-library


# APP_ROOT is conditionally set below.
# if APP_DIR contains app_if/ subdir i.e. APP contains P4 + verilog, set APP_ROOT to APP_DIR,
# else APP is P4 file only, set APP_ROOT to p4_app (to get common P4 core verilog) and P4_FILE.

ifneq ($(wildcard $(APP_DIR)/app_if/.),)
  export APP_ROOT := $(APP_DIR)
else
  export APP_ROOT := $(PROJ_ROOT)/src/p4_app
  export P4_FILE  ?= $(APP_DIR)/p4/$(APP_NAME).p4
endif


# Other variable assignments (optionally configured in the parent Makefile).

APP_NAME ?= $(shell basename $(APP_DIR) )

export BUILD_NAME   ?= esnet-smartnic-$(APP_NAME)

ARTIFACTS_DIR       ?= $(APP_DIR)/artifacts
ARTIFACTS_BUILD_DIR := $(ARTIFACTS_DIR)/$(BUILD_NAME)

jobs ?= 16


#------- Targets -------

all: build artifacts

echo_vars:
	@echo "           APP_NAME: $(APP_NAME)"
	@echo "          PROJ_ROOT: $(PROJ_ROOT)"
	@echo "           APP_ROOT: $(APP_ROOT)"
	@echo "            P4_FILE: $(P4_FILE)"
	@echo "         BUILD_NAME: $(BUILD_NAME)"
	@echo "ARTIFACTS_BUILD_DIR: $(ARTIFACTS_BUILD_DIR)"

build: bitfile package

bitfile : echo_vars
	@echo "Starting bitfile build $(BUILD_NAME)..."
	@echo "Generating smartnic platform IP..."
	$(MAKE) -C $(APP_ROOT)/app_if
	$(MAKE) -C $(PROJ_ROOT)/src/smartnic_322mhz/build
	@echo "Generating smartnic bitfile..."
	$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet bitfile BUILD_NAME=$(BUILD_NAME) jobs=$(jobs)

package : echo_vars
	@echo "Packaging build $(BUILD_NAME)..."
	$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet package BUILD_NAME=$(BUILD_NAME)

artifacts : echo_vars | $(ARTIFACTS_BUILD_DIR)
	$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet export_hwapi BUILD_NAME=$(BUILD_NAME)
	@cp -r $(PROJ_ROOT)/open-nic-shell/build/au280_$(BUILD_NAME)/artifacts.esnet-smartnic-hw.export_hwapi.manual.zip $(ARTIFACTS_BUILD_DIR)

clean_build :
	$(MAKE) -C $(APP_ROOT)/app_if clean
	$(MAKE) -C $(PROJ_ROOT)/src/smartnic_322mhz/build clean
	$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet clean_build build_name=$(BUILD_NAME)

clean_artifacts :
	@rm -rf $(ARTIFACTS_BUILD_DIR)

.PHONY : echo_vars clean_build



$(ARTIFACTS_BUILD_DIR) : | $(ARTIFACTS_DIR)
	@mkdir $(ARTIFACTS_BUILD_DIR)

$(ARTIFACTS_DIR) :
	@mkdir $(ARTIFACTS_DIR)

build_smartnic_322mhz : echo_vars
	$(MAKE) -C $(PROJ_ROOT)/src/smartnic_322mhz/build all



compile: compile_rtl regression

compile_%:
	$(MAKE) -C $* compile

regression:
	cd tests/regression && make

clean:
	$(MAKE) -C rtl clean
