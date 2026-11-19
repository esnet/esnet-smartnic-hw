COMPONENT_ROOT := ../../../..
include $(COMPONENT_ROOT)/config.mk

REGRESSION ?= 0
SEED ?= 0
waves ?= OFF
SIM ?= xsim
override RUN_DIR = run_$(BOARD)_$(SEED)

CMS_IP_DIR = $(call get_lib_component_out_path_from_ref,xilinx.alveo.usplus.ip,$(LIB_OUTPUT_ROOT))/xilinx_usplus_cms_subsystem
CMS_SIM_NETLIST = $(CMS_IP_DIR)/xilinx_usplus_cms_subsystem_sim_netlist.v
SRC_FILES = ../../rtl/src/xilinx_alveo_usplus_cms.sv $(CMS_SIM_NETLIST)
SUBCOMPONENTS = axi4l.verif@common
EXT_LIBS = unisims_ver unimacro_ver secureip
ifeq ($(BOARD),au250)
DEFINES = XILINX_USPLUS_CMS_QSFP_IO
endif

all: build_test sim
build_test: _build_test
sim: _sim
clean: _clean_test _clean_sim
.PHONY: all build_test sim clean

include $(SCRIPTS_ROOT)/Makefiles/svunit.mk
include $(SCRIPTS_ROOT)/Makefiles/sim.mk

$(CMS_SIM_NETLIST): ../../ip/xilinx_usplus_cms_subsystem.tcl ../../ip/cms_sim.tcl
	@$(MAKE) -C ../../ip synth IP_LIST=xilinx_usplus_cms_subsystem $(COMMON_ENV) $(LIB_ENV) $(USER_ENV)
	@vivado -mode batch -nojournal -nolog -source ../../ip/cms_sim.tcl -tclargs $(CMS_IP_DIR)/xilinx_usplus_cms_subsystem.dcp $@
