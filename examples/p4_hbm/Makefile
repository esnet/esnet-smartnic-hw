#------- Mandatory variables -------

# APP_DIR must be set to the pathname of application root directory.
export APP_DIR := $(CURDIR)

# SMARTNIC_DIR must be set to the pathname of smartnic root directory.
export SMARTNIC_DIR := $(APP_DIR)/../..


#------- Optional variables -------

# The following variables are optionally configured in this Makefile, or the command line.
# If NOT configured, each of these variables gets a default value in the smartnic Makefile, as specified below.

# APP_NAME - Used for default naming conventions below.
#export APP_NAME := $(shell basename $(APP_DIR) )

# P4_FILE - Full pathname of application p4 file.
#export P4_FILE := $(APP_DIR)/p4/$(APP_NAME).p4

# P4_OPTS - Optional properties to be used by Xilinx VitisNet P4 tool during mapping from P4 to logic.
#           (specified as a list of name/value pairs)
export P4_OPTS := CONFIG.CAM_RAM_STYLE_1 {HBM} \
	              CONFIG.CAM_TABLE_PARAMS {MatchActionImpl.filter {ram_style HBM clock CAM mode BCAM opt GLOBAL}}

# ARTIFACTS_DIR - Full pathname of root artifacts directory.
#export ARTIFACTS_DIR := $(APP_DIR)/artifacts

# BUILD_NAME - Name of subdirectory for artifacts of latest build i.e. artifacts go to $(ARTIFACTS_DIR)/$(BUILD_NAME)
#export BUILD_NAME := esnet-smartnic-$(APP_NAME)


#------- Targets -------

build:
	$(MAKE) -C $(SMARTNIC_DIR) build

clean_build:
	$(MAKE) -C $(SMARTNIC_DIR) clean_build

clean_artifacts:
	$(MAKE) -C $(SMARTNIC_DIR) clean_artifacts

.PHONY: build clean_build clean_artifacts
