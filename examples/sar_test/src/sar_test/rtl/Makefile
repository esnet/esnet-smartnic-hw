# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

# ----------------------------------------------------
# Sources
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
# ----------------------------------------------------
SUBCOMPONENTS = \
    sar_test.ip \
    sar_test.regio.rtl \
    sar.rtl@$(COMMON_LIB_NAME) \
    xilinx.hbm.rtl@$(SMARTNIC_LIB_NAME) \
    util.rtl@$(COMMON_LIB_NAME) \
    axi4l.rtl@$(COMMON_LIB_NAME) \
    axi4s.rtl@$(COMMON_LIB_NAME) \
    axi3.rtl@$(COMMON_LIB_NAME) \
    mem.rtl@$(COMMON_LIB_NAME) \
    mem.proxy.rtl@$(COMMON_LIB_NAME) \
    packet.rtl@$(COMMON_LIB_NAME) \
    timer.rtl@$(COMMON_LIB_NAME)

EXT_LIBS =

# ----------------------------------------------------
# Defines
# ----------------------------------------------------
DEFINES =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
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

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
