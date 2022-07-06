# ----------------------------------------------------
# Application config
# ----------------------------------------------------
APP_DIR ?= ../..
include $(APP_DIR)/.app_config.mk

# -----------------------------------------------
# IP config (for compilation library setup)
# -----------------------------------------------
IP_ROOT = ../..
include $(IP_ROOT)/config.mk

LIB_NAME = p4_app_rtl

# -----------------------------------------------
# Set source directory to location of 'common' p4_app rtl
# -----------------------------------------------
SRC_DIR = $(IP_ROOT)/rtl/src
INC_DIR = $(IP_ROOT)/rtl/include

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
             p4_app_xilinx_ip=$(IP_ROOT)/xilinx_ip/$(APP_NAME) \
             util_rtl=$(LIB_ROOT)/src/util/rtl \
             axi4l_rtl=$(LIB_ROOT)/src/axi4l/rtl \
             axi4s_rtl=$(LIB_ROOT)/src/axi4s/rtl

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

compile: ip _compile

clean: _clean_compile clean_ip

.PHONY: all compile clean

ip:
	@$(MAKE) -s -C $(IP_ROOT)/xilinx_ip ip APP_DIR=$(APP_DIR)

clean_ip:
	@$(MAKE) -s -C $(IP_ROOT)/xilinx_ip clean APP_DIR=$(APP_DIR)

.PHONY: ip clean_ip

$(APP_DIR)/.app_config.mk: $(APP_DIR)/Makefile
	$(MAKE) -C $(APP_DIR) config

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
