# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Regmap YAML sources
# -----------------------------------------------
REG_BLOCK_YAML = \
    versal_hw_regs.yaml \
    gtm_regs.yaml \

REG_DECODER_YAML = \
    gt_decoder.yaml \
    xilinx_alveo_versal_decoder.yaml

# ----------------------------------------------------
# Options
# ----------------------------------------------------
REGIO_ELABORATE_OPTS :=
REGIO_GENERATE_OPTS :=

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: reg compile synth

reg:     _reg
compile: _reg_compile
synth:   _reg_synth
info:    _reg_info
clean:   _reg_clean

.PHONY: all reg compile synth info clean

# -----------------------------------------------
# Include regio targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/regio.mk
