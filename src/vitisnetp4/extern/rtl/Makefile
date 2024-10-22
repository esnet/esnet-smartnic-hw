# -----------------------------------------------
# Component setup
# -----------------------------------------------
VITISNETP4_COMPONENT_ROOT := ../..

include $(VITISNETP4_COMPONENT_ROOT)/config.mk

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

SUBCOMPONENTS = \
    smartnic.pkg$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    axi4l.rtl@$(COMMON_LIB_NAME) \
    axi4s.rtl@$(COMMON_LIB_NAME)

EXT_LIBS =

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES = VITISNETP4_EXTERN_NAME=$(VITISNETP4_IP_NAME)_extern

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
