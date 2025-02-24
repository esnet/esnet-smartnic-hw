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
SUBCOMPONENTS = \
    smartnic_app.regio.rtl$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    smartnic_app.regio.verif$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    std.verif@$(COMMON_LIB_NAME) \
    axi4l.verif@$(COMMON_LIB_NAME) \
    axi4s.verif@$(COMMON_LIB_NAME)

EXT_LIBS =

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES =

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
