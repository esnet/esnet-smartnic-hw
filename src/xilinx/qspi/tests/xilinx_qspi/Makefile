COMPONENT_ROOT := ../../..
include $(COMPONENT_ROOT)/config.mk

BOARD ?= au55c
REGRESSION ?= 0
SEED ?= 0
waves ?= OFF
SIM ?= xsim

SUBCOMPONENTS = xilinx.qspi.rtl
EXT_LIBS =

all: build_test sim
build_test: _build_test
sim: _sim
info: _sim_info
clean: _clean_test _clean_sim

.PHONY: all build_test sim info clean

include $(SCRIPTS_ROOT)/Makefiles/svunit.mk
include $(SCRIPTS_ROOT)/Makefiles/sim.mk

# The native model loads its flash-command decoder from these generated files.
QSPI_IP_OUT = $(call get_lib_component_out_path_from_ref,xilinx.qspi.ip,$(LIB_OUTPUT_ROOT))/xilinx_axi_quad_spi
_sim: _qspi_sim_data
_qspi_sim_data: _elab
	@cp $(QSPI_IP_OUT)/netlist/*.mem $(QSPI_IP_OUT)/netlist/*.mif $(RUN_DIR)/

.PHONY: _qspi_sim_data
