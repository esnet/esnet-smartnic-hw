# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Environment setup
# -----------------------------------------------
#  Export BOARD type to allow for board-specific IP
#  parameters within Tcl specifications
export BOARD

# ----------------------------------------------------
# IP listing
#
#   Each IP core in the source component needs to be
#   explicitly listed here. Each core must have a
#   corresponding Tcl stub describing IP creation
#   (Vivado `create_ip` command invocation) and
#   configuration in the current directory.
#
#   e.g.:
#
#   IP_LIST = ip1 ip2
#
#	Assumes ./ip1.tcl and ./ip2.tcl exist
#
#	Note: ./ip3.tcl and ./ip4.tcl could also exist, but
#	will be ignored by this makefile since they are
#	not explicitly listed.
# ----------------------------------------------------
IP_LIST = \
    xilinx_gtm_0

# ----------------------------------------------------
# Simulation sources
#
#   List source files and include directories for compiling
#   the IP core (or a model of the component) for simulation.
#
#   NOTE: The paths to the sources should be specified
#         relative to the directory into which the IP output
#         products are generated. For example, to include the
#         verilog source file describing the simulation model
#         for IP core `foo`, the following could be used:
#
#         IP_SIM_SRC_FILES = foo/sim/foo.v
#
#         and NOT:
#
#         IP_SIM_SRC_FILES = <path-to-out-dir>/foo/sim/foo.v
#
#         (The <path-to-out-dir> is prepended automatically)
# ----------------------------------------------------
# Import IP core revision details from version-specific tool config
include $(CFG_ROOT)/vivado_ip.mk

#  List simulation source files and include directories
#  (see $SCRIPTS_ROOT/Makefiles/templates/sources.mk)
IP_SIM_SRC_FILES = \
    xilinx_gtm_0/xilinx_gtm_0_powergood_logic.v \
    xilinx_gtm_0/xilinx_gtm_0_reset_ip.v \
    xilinx_gtm_0/xilinx_gtm_0_quad_top.v \
    xilinx_gtm_0/xilinx_gtm_0_intf_quad_map.v \
    xilinx_gtm_0/xilinx_gtm_0_inst.v \
    xilinx_gtm_0/ip_0/xilinx_gtm_0_gt_quad_base_0_axi_lite_to_apb3_inst.v \
    xilinx_gtm_0/ip_0/xilinx_gtm_0_gt_quad_base_0_inst.v \
    xilinx_gtm_0/ip_0/sim/xilinx_gtm_0_gt_quad_base_0.v \
    xilinx_gtm_0/sim/xilinx_gtm_0.v

IP_SIM_INC_DIRS =

#   List external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
EXT_LIBS = \
    unisims_ver \
    unimacro_ver \
    secureip \
    xpm

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
#all: ip compile synth
all: ip compile

ip:      _ip
compile: _ip_compile
synth:   _ip_synth
info:    _ip_info
status:  _ip_status
upgrade: _ip_upgrade
clean:   _ip_clean

.PHONY: all ip compile synth info status upgrade clean

# ----------------------------------------------------
# IP project management targets
#
#   These targets are used for managing IP, i.e. creating
#   new IP, or modifying existing IP.
# ----------------------------------------------------
proj:       _ip_proj
proj_clean: _ip_proj_clean

.PHONY: proj proj_clean

# ----------------------------------------------------
# Import Vivado IP management targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_manage_ip.mk
