# ----------------------------------------------------
# Application config
# ----------------------------------------------------
APP_DIR ?= ..
include $(APP_DIR)/.app_config.mk

# -----------------------------------------------
# IP config (for compilation library setup)
# -----------------------------------------------
IP_ROOT = ..
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
COMPONENTS = verif \
             p4_app_xilinx_ip=$(IP_ROOT)/xilinx_ip/$(APP_NAME) \
             std_rtl=$(LIB_ROOT)/src/std/rtl \
             std_verif=$(LIB_ROOT)/src/std/verif \
             axi3_rtl=$(LIB_ROOT)/src/axi3/rtl \
             axi4l_rtl=$(LIB_ROOT)/src/axi4l/rtl \
             axi4s_rtl=$(LIB_ROOT)/src/axi4s/rtl \
             smartnic_322mhz_rtl=$(PROJ_ROOT)/src/smartnic_322mhz/rtl \
             axi4l_verif=$(LIB_ROOT)/src/axi4l/verif \
             axi4s_verif=$(LIB_ROOT)/src/axi4s/verif \

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

clean: _clean_compile

ip:
	@$(MAKE) -s -C $(IP_ROOT)/xilinx_ip ip APP_DIR=$(abspath $(APP_DIR))

.PHONY: all compile clean ip

$(APP_DIR)/.app_config.mk: $(APP_DIR)/Makefile
	$(MAKE) -s -C $(APP_DIR) config

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
