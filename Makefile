#------- Variables -------
# Notes:
#  In typical usage, this Makefile will be invoked within the context
#  of a particular SmartNIC application. Direct invocation is also
#  supported.

# Configure project paths
PROJ_ROOT := $(CURDIR)
include $(PROJ_ROOT)/paths.mk

# Configure default application if none is specified
APP_DIR ?= $(CURDIR)/src/p4_app

# Include standard application configuration
include $(PROJ_ROOT)/scripts/app_config.mk

ARTIFACTS_BUILD_DIR := $(ARTIFACTS_DIR)/$(BUILD_NAME)

# Build options
max_pkt_len ?= 1518
jobs ?= 16

#------- Targets -------

build: config bitfile package

config :
	$(_print_app_config)
	$(_write_app_config)

bitfile :
	@echo "Starting bitfile build $(BUILD_NAME)..."
	@echo "Generating smartnic platform IP..."
	$(MAKE) -C $(APP_ROOT)/app_if APP_DIR=$(APP_DIR)
	$(MAKE) -C $(PROJ_ROOT)/src/smartnic_322mhz/build APP_ROOT=$(APP_ROOT)
	@echo "Generating smartnic bitfile..."
	$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet bitfile \
		BUILD_NAME=$(BUILD_NAME) APP_ROOT=$(APP_ROOT) max_pkt_len=$(max_pkt_len) jobs=$(jobs)

package : | $(ARTIFACTS_BUILD_DIR)
	@echo "Packaging build $(BUILD_NAME)..."
	$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet package \
		BUILD_NAME=$(BUILD_NAME) APP_ROOT=$(APP_ROOT) ARTIFACTS_BUILD_DIR=$(ARTIFACTS_BUILD_DIR)

clean_build :
	$(MAKE) -C $(APP_ROOT)/app_if clean
	$(MAKE) -C $(PROJ_ROOT)/src/smartnic_322mhz/src/p4_app/xilinx_ip clean
	$(MAKE) -C $(PROJ_ROOT)/src/smartnic_322mhz/build clean
	$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet clean_build BUILD_NAME=$(BUILD_NAME)

clean_artifacts :
	@rm -rf $(ARTIFACTS_BUILD_DIR)

.PHONY : config bitfile package clean_build clean_artifacts


$(ARTIFACTS_BUILD_DIR) : | $(ARTIFACTS_DIR)
	@mkdir $(ARTIFACTS_BUILD_DIR)

$(ARTIFACTS_DIR) :
	@mkdir $(ARTIFACTS_DIR)

build_smartnic_322mhz :
	$(MAKE) -C $(PROJ_ROOT)/src/smartnic_322mhz/build all

