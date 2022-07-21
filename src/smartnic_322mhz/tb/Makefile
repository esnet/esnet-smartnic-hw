# -----------------------------------------------
# IP config (for compilation library setup)
# -----------------------------------------------
IP_ROOT = ..
include $(IP_ROOT)/config.mk

# ----------------------------------------------------
# Application config (p4_app by default)
# ----------------------------------------------------
APP_DIR ?= $(abspath $(PROJ_ROOT)/src/p4_app)
include $(PROJ_ROOT)/scripts/app_config.mk

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
COMPONENTS = xilinx_ip reg.verif rtl \
             std_rtl=$(LIB_ROOT)/src/std/rtl \
             std_verif=$(LIB_ROOT)/src/std/verif \
             reg.reg.verif=$(LIB_ROOT)/src/reg/reg/verif \
             axi4l_verif=$(LIB_ROOT)/src/axi4l/verif \
             axi4s_verif=$(LIB_ROOT)/src/axi4s/verif \
             axi4s_reg_verif=$(LIB_ROOT)/src/axi4s/reg/verif \
             xilinx_hbm_verif=$(LIB_ROOT)/src/xilinx/hbm/verif \
             p4_app_xilinx_ip=$(APP_DIR)/xilinx_ip/$(APP_NAME)

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

config:
	$(_print_app_config)
	$(_write_app_config)

ip: config
	$(MAKE) -C $(APP_ROOT)/xilinx_ip APP_NAME=$(APP_NAME)

compile:
	$(MAKE) ip
	$(MAKE) _compile

clean: _clean_compile

.PHONY: all config compile clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
