COMPONENT_ROOT := ../../../..
include $(COMPONENT_ROOT)/config.mk

REGRESSION ?= 0
SEED ?= 0
waves ?= OFF
SIM ?= xsim
override RUN_DIR = run_$(BOARD)_$(SEED)

SYSMON_IP_DIR = $(call get_lib_component_out_path_from_ref,xilinx.sysmon.ip,$(LIB_OUTPUT_ROOT))/xilinx_sysmon
SYSMON_DCP = $(SYSMON_IP_DIR)/xilinx_sysmon.dcp
SYSMON_SIM_NETLIST = $(SYSMON_IP_DIR)/xilinx_sysmon_test_netlist.v
SRC_FILES = \
    ../../../../sysmon/rtl/src/xilinx_sysmon_pkg.sv \
    ../../../../sysmon/rtl/src/xilinx_sysmon_wrapper.sv \
    $(SYSMON_SIM_NETLIST)
SUBCOMPONENTS = axi4l.verif@common xilinx.alveo.usplus.regio.rtl
EXT_LIBS = unisims_ver

all: build_test sim
build_test: _build_test
sim: _sim
clean: _clean_test _clean_sim
.PHONY: all build_test sim clean

include $(SCRIPTS_ROOT)/Makefiles/svunit.mk
include $(SCRIPTS_ROOT)/Makefiles/sim.mk

$(SYSMON_DCP): ../../../../sysmon/ip/xilinx_sysmon.tcl
	@$(MAKE) -C ../../../../sysmon/ip synth $(COMMON_ENV) $(LIB_ENV) $(USER_ENV)

$(SYSMON_SIM_NETLIST): $(SYSMON_DCP) export_sim.tcl
	@vivado -mode batch -nojournal -nolog -source export_sim.tcl -tclargs $< $@

_sim: _sysmon_sim_data
_sysmon_sim_data: _elab
	@cp design.dat $(RUN_DIR)/
.PHONY: _sysmon_sim_data
