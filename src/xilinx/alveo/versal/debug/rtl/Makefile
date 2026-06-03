# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../../../..

include $(COMPONENT_ROOT)/config.mk

SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

SUBCOMPONENTS = \
    axi4l.rtl@common \
    xilinx.alveo.versal.debug.ip

EXT_LIBS =

DEFINES =

COMPILE_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: compile synth

compile: _compile_sim
synth:   _compile_synth
info:    _compile_info
clean:   _compile_clean

.PHONY: all compile synth info clean

include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
