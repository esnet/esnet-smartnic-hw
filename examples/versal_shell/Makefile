#------- Mandatory variables -------

# SMARTNIC_DIR must be set to the pathname of smartnic root directory.
SMARTNIC_DIR := ../..

#------- Optional variables -------

# The following variables are optionally configured in this Makefile, or on the command line.
# If NOT configured, each of these variables gets a default value (as specified below)

# APP_NAME - Application name. Used for default naming conventions below.
export APP_NAME := $(notdir $(abspath $(CURDIR)))

# P4_FILE - Full pathname of application p4 file.
export P4_IGR_FILE = $(CURDIR)/p4/$(APP_NAME).p4

# ARTIFACTS_DIR - Full pathname of root artifacts directory.
#export ARTIFACTS_DIR := $(CURDIR)/artifacts

# BUILD_NAME - Name of subdirectory for artifacts of latest build i.e. artifacts go to $(ARTIFACTS_DIR)/$(BUILD_NAME)
#export BUILD_NAME := esnet-smartnic-$(APP_NAME)

# BOARD - Name of AMD (Xilinx) Alveo board used for target application.
# Supports 'au280', 'au250' and 'au55c'.  Default is 'au280'.
#export BOARD ?= au280

# EXAMPLE_TEST_DIR - Full pathname of p4 test directory used for example design generation.

#------- Targets -------
build:
	@$(MAKE) -s -C $(SMARTNIC_DIR) versal_shell APP_DIR=$(CURDIR)

config:
	@$(MAKE) -s -C $(SMARTNIC_DIR) config APP_DIR=$(CURDIR)

example:
	@$(MAKE) -s -C $(SMARTNIC_DIR) example APP_DIR=$(CURDIR)

clean:
	@$(MAKE) -s -C $(SMARTNIC_DIR) clean_build APP_DIR=$(CURDIR)

clean_artifacts:
	@$(MAKE) -s -C $(SMARTNIC_DIR) clean_artifacts APP_DIR=$(CURDIR)

.PHONY: build example config clean clean_artifacts
