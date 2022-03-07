# -----------------------------------------------
# Path setup
# -----------------------------------------------
IP_ROOT := ..

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
             util_rtl=$(LIB_ROOT)/src/util/rtl \
             axi4l_rtl=$(LIB_ROOT)/src/axi4l/rtl \
             axi4s_rtl=$(LIB_ROOT)/src/axi4s/rtl

EXT_LIBS = \
           axi_infrastructure_v1_1_0 \
           axi_register_slice_v1_1_22 \
           axi_register_slice_v2_1_22 \
           axis_register_slice_v1_1_22 \
           axis_infrastructure_v1_1_0 \
           axis_data_fifo_v2_0_4 \
           fifo_generator_v13_2_5 \
           axi_clock_converter_v2_1_21 \
           generic_baseblocks_v2_1_0 \
           unisims_ver \
           unimacro_ver \
           secureip \
           xpm

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

compile: _compile

clean: _clean_compile

.PHONY: all compile clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk
