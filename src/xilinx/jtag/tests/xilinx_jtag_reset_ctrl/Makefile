COMPONENT_ROOT := ../../..
include $(COMPONENT_ROOT)/config.mk

REGRESSION ?= 0
SEED ?= 0
waves ?= OFF
SIM ?= xsim

SUBCOMPONENTS = xilinx.jtag.rtl
EXT_LIBS =

all: build_test sim
build_test: _build_test
sim: _sim
info: _sim_info
clean: _clean_test _clean_sim

.PHONY: all build_test sim info clean

include $(SCRIPTS_ROOT)/Makefiles/svunit.mk
include $(SCRIPTS_ROOT)/Makefiles/sim.mk
