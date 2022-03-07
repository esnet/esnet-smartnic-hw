# -----------------------------------------------
# Path setup
# -----------------------------------------------
IP_ROOT := ../..

# -----------------------------------------------
# IP config
# -----------------------------------------------
include $(IP_ROOT)/config.mk

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/sources.mk)
#   Note: if no sources are explicitly listed, all
#   source files from ./src are added automatically,
#   with include directory ./include
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List IP component and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/dependencies.mk)
# ----------------------------------------------------
COMPONENTS = reg \
             reg_verif=$(LIB_ROOT)/src/reg/verif
EXT_LIBS =

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS=
ELAB_OPTS=--debug typical
SIM_OPTS=

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: compile

compile: reg
	$(MAKE) _compile

reg:
	@$(MAKE) -C .. _reg_verif

clean: _clean_compile

.PHONY: all compile reg clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
COMPONENT_NAME = reg_verif
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
