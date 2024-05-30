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
#   Assumes ./ip1.tcl and ./ip2.tcl exist
#
#   Note: ./ip3.tcl and ./ip4.tcl could also exist, but
#   will be ignored by this makefile since they are
#   not explicitly listed.
# ----------------------------------------------------
IP_LIST = \
    xilinx_qdma_ecc \
    xilinx_qdma

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
#  List simulation source files and include directories
#  (see $SCRIPTS_ROOT/Makefiles/templates/sources.mk)
IP_SIM_SRC_FILES = \
    xilinx_qdma_ecc/sim/xilinx_qdma_ecc.v \
    xilinx_qdma/ip_0/ip_0/sim/gtwizard_ultrascale_v1_7_gtye4_channel.v \
    xilinx_qdma/ip_0/ip_0/sim/gtwizard_ultrascale_v1_7_gtye4_common.v \
    xilinx_qdma/ip_0/ip_0/sim/xilinx_qdma_pcie4c_ip_gt_gtwizard_gtye4.v \
    xilinx_qdma/ip_0/ip_0/sim/xilinx_qdma_pcie4c_ip_gt_gtwizard_top.v \
    xilinx_qdma/ip_0/ip_0/sim/xilinx_qdma_pcie4c_ip_gt_gtye4_channel_wrapper.v \
    xilinx_qdma/ip_0/ip_0/sim/xilinx_qdma_pcie4c_ip_gt_gtye4_common_wrapper.v \
    xilinx_qdma/ip_0/ip_0/sim/xilinx_qdma_pcie4c_ip_gt.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_async_fifo.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_cc_intfc.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_cc_output_mux.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_cq_intfc.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_cq_output_mux.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_intfc_int.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_intfc.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_rc_intfc.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_rc_output_mux.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_rq_intfc.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_rq_output_mux.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_512b_sync_fifo.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram_16k_int.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram_16k.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram_32k.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram_4k_int.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram_msix.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram_rep_int.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram_rep.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram_tph.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_bram.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_cxs_remap.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_cdr_ctrl_on_eidle.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_gt_channel.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_gt_common.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_phy_clk.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_phy_rst.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_phy_rxeq.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_phy_txeq.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_phy_wrapper.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gt_receiver_detect_rxterm.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_gtwizard_top.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_init_ctrl.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_pcie4c_uscale_core_top.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_phy_ff_chain.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_phy_pipeline.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_phy_top.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_pipe.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_pl_eq.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_seqnum_fifo.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_sync_cell.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_sync.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_sys_clk_gen_ps.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_vf_decode_attr.v \
    xilinx_qdma/ip_0/source/xilinx_qdma_pcie4c_ip_vf_decode.v \
    xilinx_qdma/ip_0/sim/xilinx_qdma_pcie4c_ip.v \
    xilinx_qdma/xilinx_qdmahdl/verilog/xilinx_qdma_core_top.sv \
    xilinx_qdma/sim/xilinx_qdma.sv

IP_SIM_INC_DIRS = \
	xilinx_qdma/ip_0/source

#   List external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
EXT_LIBS = \
    ecc_v2_0_15 \
    gtwizard_ultrascale_v1_7_17 \
    qdma_v5_0_6 \
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
all: ip compile synth

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
