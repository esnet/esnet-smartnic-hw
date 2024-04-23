#------- Variables -------
# Notes:
#  In typical usage, this Makefile will be invoked within the context
#  of a particular SmartNIC application. Direct invocation is also
#  supported.

# Configure project paths
PROJ_ROOT := $(CURDIR)
include $(PROJ_ROOT)/config.mk

# Configure default application if none is specified
APP_DIR ?= $(CURDIR)/src/smartnic_app/p4_only

# Include standard application configuration
include $(PROJ_ROOT)/scripts/app_config.mk

ARTIFACTS_BUILD_DIR := $(ARTIFACTS_DIR)/$(BUILD_NAME)

VALIDATE_WNS_MIN ?= 0
VALIDATE_TNS_MIN ?= 0

# Build options
max_pkt_len ?= 9100
jobs ?= 16

#------- Targets -------

build: bitfile package

# Include targets for config validation
# - checks Vivado version
# - checks that licenses are available for IP, where required
# - checks that required command-line utilities are available in path
include $(SCRIPTS_ROOT)/Makefiles/config.mk

config : $(APP_DIR)/.app/config.mk
	$(_print_app_config)

$(APP_DIR)/.app/config.mk: $(APP_DIR)/Makefile
	$(_configure_app)

proj_paths:
	$(_proj_print_paths)

example : config $(APP_DIR)/example
ifneq ($(wildcard $(EXAMPLE_TEST_DIR)/../user_externs/*.cpp),)
	@echo "Compiling extern .cpp model..."
	@$(MAKE) -s -C $(EXAMPLE_TEST_DIR)/../user_externs
endif
	@echo "Copying source files for example design generation into example/.src dir..."
	cp $(EXAMPLE_P4_FILE) $(APP_DIR)/example/.src
	cp $(EXAMPLE_TEST_DIR)/cli_commands.txt $(APP_DIR)/example/.src
	-cp $(EXAMPLE_TEST_DIR)/*_in.pcap $(EXAMPLE_TEST_DIR)/*_in.user $(EXAMPLE_TEST_DIR)/*_in.meta $(APP_DIR)/example/.src 2> /dev/null
	-cp $(EXAMPLE_TEST_DIR)/../user_externs/*.so $(APP_DIR)/example/.src 2> /dev/null
	@echo "Generating vitisnetp4 ip in example/ subdirectory, using application p4 file..."
	@$(MAKE) -s -C $(APP_DIR)/.app/src/vitisnetp4/ip   COMPONENT_OUT_PATH=$(APP_DIR)/example   P4_FILE=$(APP_DIR)/example/.src/$(notdir $(EXAMPLE_P4_FILE)) \
	         VITISNETP4_IP_NAME=$(EXAMPLE_VITISNETP4_IP_NAME)
	@echo "Cleaning up unused and unecessary files (vitisnetp4 design ip and log files)..."
	rm -rf $(APP_DIR)/example/ip_proj $(APP_DIR)/example/ip_user_files $(APP_DIR)/example/lib $(APP_DIR)/example/synth
	rm -rf $(APP_DIR)/example/.Xil $(APP_DIR)/example/.xci $(APP_DIR)/example/*.tcl $(APP_DIR)/example/vivado*.log
ifneq ($(wildcard $(APP_DIR)/src/$(EXAMPLE_VITISNETP4_IP_NAME)_extern),)
	@echo "Stitching extern into example design..."
	@$(MAKE) -s -C $(APP_DIR)/src/$(EXAMPLE_VITISNETP4_IP_NAME)_extern  VITISNETP4_IP_NAME=$(EXAMPLE_VITISNETP4_IP_NAME)
endif

$(APP_DIR)/example:
	@mkdir -p $@
	@mkdir -p $@/.src

bitfile : config config_check
	@echo "Starting bitfile build $(BUILD_NAME)..."
	@echo
	@echo "----------------------------------------------------------"
	@echo "Building application $(APP_NAME) for $(BOARD) ..."
	@echo
	@$(MAKE) -s -C $(APP_ROOT)/app_if BOARD=$(BOARD)
	@echo
	@echo "Done."
	@echo "----------------------------------------------------------"
	@echo "Preparing smartnic IP ..."
	@$(MAKE) -s -C $(PROJ_ROOT)/src/smartnic/build pre_synth APP_ROOT=$(APP_ROOT) BOARD=$(BOARD)
	@echo
	@echo "Done."
	@echo "----------------------------------------------------------"
	@echo "Preparing smartnic_250mhz IP ..."
	@$(MAKE) -s -C $(PROJ_ROOT)/src/smartnic_250mhz/build pre_synth BOARD=$(BOARD)
	@echo
	@echo "Done."
	@echo "----------------------------------------------------------"
	@echo "Building OpenNIC shell ..."
	@$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet bitfile \
		BOARD=$(BOARD) BUILD_NAME=$(BUILD_NAME) APP_ROOT=$(APP_ROOT) max_pkt_len=$(max_pkt_len) jobs=$(jobs) OUTPUT_ROOT=$(OUTPUT_ROOT)/smartnic
	@echo
	@echo "Done."

package : | $(ARTIFACTS_BUILD_DIR)
	@echo "----------------------------------------------------------"
	@echo "Packaging build $(BUILD_NAME) ..."
	@$(MAKE) -s -C $(PROJ_ROOT)/src/smartnic/regio reg APP_ROOT=$(APP_ROOT)
	@$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet package \
		BOARD=$(BOARD) BUILD_NAME=$(BUILD_NAME) APP_ROOT=$(APP_ROOT) ARTIFACTS_BUILD_DIR=$(ARTIFACTS_BUILD_DIR) OUTPUT_ROOT=$(OUTPUT_ROOT)/smartnic
	@echo
	@echo "Done."

validate: | $(ARTIFACTS_BUILD_DIR)
	@$(MAKE) -s -C $(PROJ_ROOT) -f makefile.esnet validate_build \
		BOARD=$(BOARD) BUILD_NAME=$(BUILD_NAME) APP_ROOT=$(APP_ROOT) ARTIFACTS_BUILD_DIR=$(ARTIFACTS_BUILD_DIR) \
		VALIDATE_WNS_MIN=$(VALIDATE_WNS_MIN) VALIDATE_TNS_MIN=$(VALIDATE_TNS_MIN)

clean_build :
ifneq ($(wildcard $(APP_DIR)/app_if),)
	@-$(MAKE) -s -C $(APP_DIR)/app_if clean
endif
	@-rm -rf $(APP_DIR)/.app
	-$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet clean_build BUILD_NAME=$(BUILD_NAME)

clean_artifacts :
	@-rm -rf $(ARTIFACTS_BUILD_DIR)

.PHONY : config example bitfile package clean_build clean_artifacts

$(ARTIFACTS_BUILD_DIR) : | $(ARTIFACTS_DIR)
	@mkdir $(ARTIFACTS_BUILD_DIR)

$(ARTIFACTS_DIR) :
	@mkdir $(ARTIFACTS_DIR)

build_smartnic :
	@$(MAKE) -s -C $(PROJ_ROOT)/src/smartnic/build all

