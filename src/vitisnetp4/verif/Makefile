# -----------------------------------------------
# Component setup
# -----------------------------------------------
VITISNETP4_COMPONENT_ROOT := ..

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
INC_DIRS = \
    $(COMPONENT_OUT_PATH)/../ip/$(VITISNETP4_IP_NAME)_ex/imports

SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
SUBCOMPONENTS = \
    $(COMPONENT_BASE).ip \
    std.verif@$(COMMON_LIB_NAME)

EXT_LIBS =

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES = \
    VITISNETP4_AGENT_NAME=$(VITISNETP4_IP_NAME)_agent \
    VITISNETP4_PKG_NAME=$(VITISNETP4_IP_NAME)_pkg \
    VITISNETP4_VERIF_PKG_NAME=$(VITISNETP4_IP_NAME)_verif_pkg

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: compile

compile: _compile_sim
info:    _compile_info
clean:   _compile_clean

.PHONY: all compile info clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
