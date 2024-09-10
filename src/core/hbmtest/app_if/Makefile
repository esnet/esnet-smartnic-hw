# ----------------------------------------------------
# Paths
# ----------------------------------------------------
COMPONENT_ROOT = ../..

include $(COMPONENT_ROOT)/config.mk

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: reg_package

reg_package:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=core.hbmtest.regio OUTPUT_ROOT=$(OUTPUT_ROOT)
	@cp $(OUTPUT_ROOT)/core/hbmtest/regio/ir/hbmtest_decoder-ir.yaml smartnic_app_decoder.yaml

.PHONY: all reg_package

