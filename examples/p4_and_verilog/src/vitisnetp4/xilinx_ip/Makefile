# -----------------------------------------------
# Path setup
# -----------------------------------------------
IP_ROOT := ..

# -----------------------------------------------
# IP config
# -----------------------------------------------
include $(IP_ROOT)/config.mk

# -----------------------------------------------
# VitisNetP4 IP config
# -----------------------------------------------
VITISNETP4_IP_NAME = sdnet_0
VITISNETP4_IP_DIR = $(COMPONENT_OUT_PATH)

P4_FILE = $(APP_DIR)/p4/p4_and_verilog.p4
P4_OPTS = CONFIG.PKT_RATE {150} CONFIG.OUTPUT_METADATA_FOR_DROPPED_PKTS {true}

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/sources.mk)
#   Note: if no sources are explicitly listed, all
#   source files from ./src are added automatically,
#   with include directory ./include
#
#   NOTE: By default, IP output products are being generated at
#         the path represented by $(COMPONENT_OUT_PATH). This
#         path can be queried using 'make info',
#         and $(COMPONENT_OUT_PATH) can be used to reference these
#         files for compilation.
# ----------------------------------------------------
#  Note: VitisNetP4 source files are automatically included by
#        the vivado_vitisnetp4.mk standard Makefile. Only user-supplied
#        files/dependencies need to be listed here
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List IP component and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/dependencies.mk)
# ----------------------------------------------------
COMPONENTS =
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
# Compile Targets
# ----------------------------------------------------
all: compile

ip: _vitisnetp4_ip

compile: _vitisnetp4_compile

synth: _vitisnetp4_synth

clean: _vitisnetp4_clean

.PHONY: all ip compile synth clean

# ----------------------------------------------------
# Info targets
# ----------------------------------------------------
info: _vitisnetp4_info

.PHONY: info

# ----------------------------------------------------
# IP management targets
#
#   These targets are used for managing IP, i.e. creating
#   new IP, or modifying or upgrading existing IP.
# ----------------------------------------------------
ip_proj: _ip_proj

ip_upgrade: _ip_upgrade

ip_status: _ip_status

ip_proj_clean: _ip_proj_clean

.PHONY: ip_proj ip_upgrade ip_status ip_proj_clean

# ----------------------------------------------------
# Import Vivado IP management targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_vitisnetp4.mk
