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
ifneq ($(wildcard $(EXAMPLE_P4_METADATA)),)
	cp $(EXAMPLE_P4_METADATA) $(APP_DIR)/example/.src
endif
	cp $(EXAMPLE_TEST_DIR)/cli_commands.txt $(APP_DIR)/example/.src
	-cp $(EXAMPLE_TEST_DIR)/*_in.pcap $(EXAMPLE_TEST_DIR)/*_in.user $(EXAMPLE_TEST_DIR)/*_in.meta $(APP_DIR)/example/.src 2> /dev/null
	-cp $(EXAMPLE_TEST_DIR)/../user_externs/*.so $(APP_DIR)/example/.src 2> /dev/null
	@echo "Generating vitisnetp4 ip in example/ subdirectory, using application p4 file..."
	@$(MAKE) -s -C $(APP_ROOT)/src/$(EXAMPLE_VITISNETP4_IP_NAME)/ip  COMPONENT_OUT_PATH=$(APP_DIR)/example \
	         P4_FILE=$(APP_DIR)/example/.src/$(notdir $(EXAMPLE_P4_FILE)) \
ifneq ($(wildcard $(EXAMPLE_P4_METADATA)),)
	         P4_METADATA=$(APP_DIR)/example/.src/$(notdir $(EXAMPLE_P4_METADATA)) \
endif
	         VITISNETP4_IP_NAME=$(EXAMPLE_VITISNETP4_IP_NAME)
	@echo "Cleaning up unused and unecessary files (vitisnetp4 design ip and log files)..."
	rm -rf $(APP_DIR)/example/ip_proj $(APP_DIR)/example/ip_user_files $(APP_DIR)/example/lib $(APP_DIR)/example/synth
	rm -rf $(APP_DIR)/example/.Xil $(APP_DIR)/example/.xci $(APP_DIR)/example/*.tcl $(APP_DIR)/example/vivado*.log
ifneq ($(wildcard $(APP_DIR)/src/$(EXAMPLE_VITISNETP4_IP_NAME)/rtl/src/$(EXAMPLE_VITISNETP4_IP_NAME)_extern.sv),)
	@echo "Stitching extern into example design..."
	@$(MAKE) -s -C $(APP_DIR)/src/$(EXAMPLE_VITISNETP4_IP_NAME)/rtl/src  VITISNETP4_IP_NAME=$(EXAMPLE_VITISNETP4_IP_NAME)
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
		BOARD=$(BOARD) BUILD_NAME=$(BUILD_NAME) APP_ROOT=$(APP_ROOT) max_pkt_len=$(max_pkt_len) jobs=$(jobs)
	@echo
	@echo "Done."

prune_build:
	@echo "Pruning $(BUILD_NAME)..."
	@echo
	@echo "----------------------------------------------------------"
	@echo "Removing intermediate build checkpoints ..."
	@echo
	@$(MAKE) -s -C $(PROJ_ROOT) -f makefile.esnet prune_build \
	   BOARD=$(BOARD) BUILD_NAME=$(BUILD_NAME)
	@echo
	@echo "Done."

package : | $(ARTIFACTS_BUILD_DIR)
	@echo "----------------------------------------------------------"
	@echo "Packaging build $(BUILD_NAME) ..."
	@$(MAKE) -s -C $(PROJ_ROOT)/src/smartnic/regio reg APP_ROOT=$(APP_ROOT)
	@$(MAKE) -C $(PROJ_ROOT) -f makefile.esnet package \
		BOARD=$(BOARD) BUILD_NAME=$(BUILD_NAME) APP_ROOT=$(APP_ROOT) ARTIFACTS_BUILD_DIR=$(ARTIFACTS_BUILD_DIR)
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

__SHELL_BUILD_OUTPUT_ROOT = $(OUTPUT_ROOT)/$(BOARD)/$(XILINX_VIVADO__VERSION)
SHELL_BUILD_OUT_DIR = $(__SHELL_BUILD_OUTPUT_ROOT)/smartnic/xilinx/alveo/shell/build/proj/proj.runs/impl_1
SHELL_HWAPI_DIR = $(ARTIFACTS_BUILD_DIR)/esnet-smartnic-hwapi

SHELL_REG_ARTIFACT = $(__SHELL_BUILD_OUTPUT_ROOT)/smartnic/xilinx/alveo/shell/regio/ir/esnet-smartnic-top-ir.yaml
SHELL_VITISNETP4_DRV_ARTIFACT = $(APP_ROOT)/app_if/smartnic_app_igr_drv.tar
SHELL_P4_ARTIFACT = $(APP_ROOT)/app_if/smartnic_app_igr.p4

BUILD_ID ?= $(shell date +"%s")

shell: shell_bitfile shell_package

shell_bitfile: config config_check
	@echo "Building ESnet shell bitfile ($(BUILD_ID))..."
	@$(MAKE) -s -C $(APP_ROOT)/src build COMPONENT=xilinx.alveo.shell.build@smartnic BOARD=$(BOARD) BUILD_ID=$(BUILD_ID)
	@test -e $(SHELL_BUILD_OUT_DIR)/esnet_smartnic.bit || (echo ERROR: bitfile not produced. && false)
	@test -e $(SHELL_BUILD_OUT_DIR)/esnet_smartnic.mcs || (echo ERROR: flash image not produced. && false)
	@echo "Done."

$(SHELL_REG_ARTIFACT): config
	@echo "Generating regmap artifact for ESnet shell build..."
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=xilinx.alveo.shell.regio@$(SMARTNIC_LIB_NAME) BOARD=$(BOARD) BUILD_ID=$(BUILD_ID) OUTPUT_ROOT=$(OUTPUT_ROOT) SMARTNIC_LIB_NAME=$(SMARTNIC_LIB_NAME)
	@echo "Done."

$(SHELL_VITISNETP4_DRV_ARTIFACT): config
	@$(MAKE) -s -C $(APP_ROOT)/app_if BOARD=$(BOARD) OUTPUT_ROOT=$(OUTPUT_ROOT)

shell_package: $(SHELL_REG_ARTIFACT) $(SHELL_VITISNETP4_DRV_ARTIFACT)
	@echo "Packaging ESnet shell build..."
	@mkdir -p $(ARTIFACTS_BUILD_DIR)
	@mkdir -p $(SHELL_HWAPI_DIR)
	@mkdir -p $(SHELL_HWAPI_DIR)/firmware
	@zstd -f9 $(SHELL_BUILD_OUT_DIR)/esnet_smartnic.bit -o $(SHELL_HWAPI_DIR)/firmware/esnet-smartnic.bit.zst
	@zstd -f9 $(SHELL_BUILD_OUT_DIR)/esnet_smartnic.mcs -o $(SHELL_HWAPI_DIR)/firmware/esnet-smartnic.mcs.zst
	@-cp $(SHELL_BUILD_OUT_DIR)/esnet_smartnic.ltx $(SHELL_HWAPI_DIR)/firmware/esnet-smartnic.ltx
	@mkdir -p $(SHELL_HWAPI_DIR)/libvitisnetp4drv
	@mkdir -p $(SHELL_HWAPI_DIR)/libvitisnetp4drv/vitisnetp4_igr
	@-tar xf $(SHELL_VITISNETP4_DRV_ARTIFACT) -C $(SHELL_HWAPI_DIR)/libvitisnetp4drv/vitisnetp4_igr
	@-cp $(SHELL_P4_ARTIFACT) $(SHELL_HWAPI_DIR)/firmware/esnet-smartnic-igr.p4
	@mkdir -p $(SHELL_HWAPI_DIR)/regmap
	@cp $(SHELL_REG_ARTIFACT) $(SHELL_HWAPI_DIR)/regmap
	@mkdir -p $(SHELL_HWAPI_DIR)/wireshark/plugins
	@(cd $(ARTIFACTS_BUILD_DIR) && \
		zip -r artifacts.$(BOARD).$(BUILD_NAME).0.zip esnet-smartnic-hwapi \
	)
	@echo "Done."

.PHONY: shell shell_bitfile shell_package shell_clean_artifacts

versal_shell: versal_shell_bitfile

versal_shell_bitfile:
	@echo "Building ESnet Versal shell bitfile ($(BUILD_ID))..."
	@cd $(AVED_ROOT)/hw/amd_v80_gen5x8_23.2_exdes_2 && ./build_all.sh

.PHONY: versal_shell versal_shell_bitfile

