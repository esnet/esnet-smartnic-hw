# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Regmap YAML sources
#   No block or decoder YAML here — the shell_decoder_core.yaml is consumed
#   directly by shell_build_base.mk when building the top-level IR.
#   This Makefile exists to make the component discoverable and to provide
#   a standalone reg target for use by the shell build infrastructure.
# -----------------------------------------------
REG_BLOCK_YAML =
REG_DECODER_YAML =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
REGIO_ELABORATE_OPTS :=
REGIO_GENERATE_OPTS :=

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: reg

info:    _reg_info
clean:   _reg_clean

.PHONY: all reg info clean

# -----------------------------------------------
# Include regio targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/regio.mk

# -----------------------------------------------
# Build top-level IR
#
# Depends on core_decoder-ir.yaml (built by the shell build infrastructure
# via CORE_BUILD_REF → CORE.regio) and elaborates the Versal-specific
# esnet-smartnic-top.yaml against the assembled IR directory.
# -----------------------------------------------
reg: _reg $(REGIO_IR_OUTPUT_DIR)/esnet-smartnic-top-ir.yaml

$(REGIO_IR_OUTPUT_DIR)/esnet-smartnic-top-ir.yaml: $(REGIO_IR_OUTPUT_DIR)/core_decoder-ir.yaml
	@mkdir -p $(REGIO_IR_OUTPUT_DIR)
	@$(REGIO_ELABORATE_CMD) -f top \
	    -i $(REGIO_IR_OUTPUT_DIR) \
	    -o $@ \
	    esnet-smartnic-top.yaml

# core_decoder-ir.yaml is built externally (by the shell build regio target)
# and placed here by shell_build_base.mk. Declare it as a dependency so
# Make knows it must exist, but don't provide a recipe — the caller is
# responsible for generating it.
$(REGIO_IR_OUTPUT_DIR)/core_decoder-ir.yaml:
	$(error core_decoder-ir.yaml not found. Run the shell build regio target \
	    (e.g. make .shell_build_regio) to generate it first.)

.PHONY: $(REGIO_IR_OUTPUT_DIR)/esnet-smartnic-top-ir.yaml
