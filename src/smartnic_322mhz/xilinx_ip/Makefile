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
IP_LIST = \
    axis_switch_egress \
    axis_switch_ingress \
    clk_wiz_0 \
    clk_wiz_1 \
    hbm_4g_left \
    hbm_4g_right

SRC_FILES =
INC_DIRS =
SRC_LIST_FILES = \
    axis_switch_egress/sources.f \
    axis_switch_ingress/sources.f \
    clk_wiz_0/sources.f \
    clk_wiz_1/sources.f

# ----------------------------------------------------
# Dependencies
#   List IP component and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/dependencies.mk)
# ----------------------------------------------------
COMPONENTS = 

EXT_LIBS = \
           axi_infrastructure_v1_1_0 \
           axi_clock_converter_v2_1_25 \
           axi_register_slice_v2_1_26 \
           axi_crossbar_v2_1_27 \
           axis_register_slice_v1_1_26 \
           axis_infrastructure_v1_1_0 \
           axis_switch_v1_1_26 \
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
# Compile Targets
# ----------------------------------------------------
all: compile

compile: _ip _compile

synth: _ip_synth

clean: _clean_compile _ip_proj_clean

.PHONY: all compile synth clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk

# ----------------------------------------------------
# Import Vivado IP management targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_manage_ip.mk
