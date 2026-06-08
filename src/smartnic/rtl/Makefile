# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: along with explicitly-listed sources, all
#   source files from ./src are added automatically, and
#   .include is added as an include directory automatically.
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
ifeq ($(BOARD),av80)
    IP_SUBCOMPONENTS = smartnic.ip.versal
else
    IP_SUBCOMPONENTS = smartnic.ip.usplus
endif

ifeq ($(BOARD),au250)
    HBM_SUBCOMPONENTS =
else ifeq ($(BOARD),av80)
    HBM_SUBCOMPONENTS =
else
    HBM_SUBCOMPONENTS = \
        xilinx.hbm.pkg \
        xilinx.hbm.rtl
endif

SUBCOMPONENTS = \
    smartnic.pkg \
    $(IP_SUBCOMPONENTS) \
    smartnic.regio.rtl \
    reg.endian.rtl@common \
    reg.proxy.rtl@common \
    axi4l.rtl@common \
    axi4s.rtl@common \
    mem.rtl@common \
    mem.infra.rtl@common \
    axi3.rtl@common \
    packet.rtl@common \
    $(HBM_SUBCOMPONENTS)
#    xilinx.axis.rtl \

EXT_LIBS =

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES = __$(BOARD)__

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
