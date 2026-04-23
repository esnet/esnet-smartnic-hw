# -----------------------------------------------
# Board setup
# -----------------------------------------------
BOARD ?= av80

# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ../..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Path setup
# -----------------------------------------------
# Export environment variables required by Tcl scripts
export AVED_ROOT = $(abspath $(COMPONENT_ROOT)/aved/hw)
export AVED_BASE_DESIGN = amd_v80_gen5x8_25.1

IP_REPO_PATHS = \
	$(AVED_ROOT)/hw/$(AVED_BASE_DESIGN)/src/iprepo

# ----------------------------------------------------
# BD listing
#
#   Each BD core in the source component needs to be
#   explicitly listed here. Each core must have a
#   corresponding Tcl stub describing BD creation
#   (Vivado `create_bd_design` command invocation) and
#   configuration in the current directory.
#
#   e.g.:
#
#   BD_LIST = bd1 bd2
#
#   Assumes ./bd1.tcl and ./bd2.tcl exist
#
#   Note: ./bd3.tcl and ./bd4.tcl could also exist, but
#   will be ignored by this makefile since they are
#   not explicitly listed.
# ----------------------------------------------------
BD_LIST = \
    xilinx_aved \
    xilinx_aved_mgmt_sc

# ----------------------------------------------------
# Simulation sources
#
#   Use the Vivado-generated vlog.prj / vhdl.prj as
#   sentinels to track when sim output products need
#   regeneration.  Actual compilation is handled by
#   _bd_prj_compile below (xvlog/xvhdl --prj), which
#   mirrors what the Vivado-generated .sh script does.
# ----------------------------------------------------
BD_XSIM_SCRIPTS_DIR = bd_proj/bd_proj.ip_user_files/sim_scripts/xilinx_aved_mgmt_sc/xsim

BD_SIM_SRC_FILES = \
    $(BD_XSIM_SCRIPTS_DIR)/vlog.prj \
    $(BD_XSIM_SCRIPTS_DIR)/vhdl.prj

# Pre-compiled Vivado simulation libraries needed for compile and elaboration.
# Compile libs mirror xvlog_opts in the Vivado-generated .sh script.
# Elab-only libs come from the xelab invocation in the same .sh script.
# All are listed here so they propagate via sub.libs to the test's xelab step.
EXT_LIBS = \
    uvm \
    smbus_v1_1_0 \
    cpm5_v1_0_19 \
    cpm4_v1_0_19 \
    cmd_queue_v2_0_0 \
    axi_infrastructure_v1_1_0 \
    axi_register_slice_v2_1_35 \
    axi_vip_v1_1_21 \
    proc_sys_reset_v5_0_17 \
    smartconnect_v1_0 \
    xlconstant_v1_1_10 \
    noc_nsu_sim_v1_0_0 \
    noc_hbm_v1_0_1 \
    noc_hbm_nmu_sim_v1_0_0 \
    noc_nmu_sim_v1_0_0 \
    versal_cips_ps_vip_v1_0_13 \
    unisims_ver \
    unimacro_ver \
    secureip \
    xpm \
    xilinx_vip

# Vivado VIP / bus-definition headers (absolute paths from Vivado installation)
INC_DIRS += \
    $(XILINX_VIVADO)/data/xilinx_vip/include \
    $(XILINX_VIVADO)/data/rsb/busdefs

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: ip compile synth

ip:      _bd
compile: ip _bd_prj_compile
synth:   _bd_synth
info:    _bd_info
status:  _bd_status
upgrade: _bd_upgrade
clean:   _bd_clean

.PHONY: all ip compile synth info status upgrade clean

# ----------------------------------------------------
# BD project management targets
#
#   These targets are used for managing block designs,
#   i.e. creating new BDs, or modifying existing BDs.
# ----------------------------------------------------
proj:       _bd_proj
proj_clean: _bd_proj_clean

.PHONY: proj proj_clean

# ----------------------------------------------------
# Import Vivado IP management targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_manage_bd.mk

# ----------------------------------------------------
# PRJ-based compile target
#
#   Drives xvlog/xvhdl with the Vivado-generated prj
#   files rather than listing individual source files.
#   xvlog resolves paths inside vlog.prj relative to
#   the directory containing the file, so we cd there
#   before invoking the tool.
# ----------------------------------------------------
XSIM_SCRIPTS_DIR = $(COMPONENT_OUT_PATH)/$(BD_XSIM_SCRIPTS_DIR)

# Rewritten prj files with the component library name substituted for xil_defaultlib,
# so compiled modules land in the library the build infrastructure expects to find.
# Must live in XSIM_SCRIPTS_DIR so xvlog resolves relative paths inside them correctly.
VLOG_PRJ_REWRITTEN = $(XSIM_SCRIPTS_DIR)/compile_vlog.prj
VHDL_PRJ_REWRITTEN = $(XSIM_SCRIPTS_DIR)/compile_vhdl.prj

_bd_prj_compile: _bd_sim_sources
	@echo "----------------------------------------------------------"
	@echo "Compiling BD simulation library '$(COMPONENT_NAME)' ..."
	@echo
	@mkdir -p $(OBJ_DIR)
	sed 's/xil_defaultlib/$(COMPONENT_NAME)/g' $(XSIM_SCRIPTS_DIR)/vlog.prj > $(VLOG_PRJ_REWRITTEN)
	xvlog --incr --relax $(LIB_REFS) \
	    -work $(COMPONENT_NAME)=$(OBJ_DIR) \
	    --log $(OBJ_DIR)/compile_vlog.log \
	    --prj $(VLOG_PRJ_REWRITTEN)
	sed 's/xil_defaultlib/$(COMPONENT_NAME)/g' $(XSIM_SCRIPTS_DIR)/vhdl.prj > $(VHDL_PRJ_REWRITTEN)
	xvhdl --incr --relax \
	    -work $(COMPONENT_NAME)=$(OBJ_DIR) \
	    --log $(OBJ_DIR)/compile_vhdl.log \
	    --prj $(VHDL_PRJ_REWRITTEN)
	@echo $(EXT_LIBS) | tr ' ' '\n' > $(OBJ_DIR)/sub.libs
	@touch $(SIM_LIB)
	@echo
	@echo "Done."

.PHONY: _bd_prj_compile
