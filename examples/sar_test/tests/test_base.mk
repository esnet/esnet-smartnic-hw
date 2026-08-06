# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Configuration
# -----------------------------------------------
REGRESSION ?= 0
SEED ?= 0
waves ?= OFF

# ----------------------------------------------------
# Dependencies
# ----------------------------------------------------
SUBCOMPONENTS = \
    sar_test.rtl \
    sar_test.verif \
    vitisnetp4_igr.rtl \
    vitisnetp4_igr.verif \
    smartnic_app.igr_p4.rtl@$(SMARTNIC_LIB_NAME) \
    smartnic_app.igr.rtl \
    smartnic_app.egr.passthru.rtl@$(SMARTNIC_LIB_NAME) \
    smartnic_app.egr_p4.vf_loopback.rtl@$(SMARTNIC_LIB_NAME) \
    smartnic_app.egr.passthru.rtl@$(SMARTNIC_LIB_NAME) \
    smartnic_app.tb@$(SMARTNIC_LIB_NAME) \
    xilinx.hbm.verif@$(SMARTNIC_LIB_NAME) \
    axi4l.rtl@$(COMMON_LIB_NAME) \
    axi4s.rtl@$(COMMON_LIB_NAME) \
    axi4l.verif@$(COMMON_LIB_NAME) \
    axi4s.verif@$(COMMON_LIB_NAME) \
    packet.verif@$(COMMON_LIB_NAME) \
    pcap.pkg@$(COMMON_LIB_NAME)

EXT_LIBS =

# ----------------------------------------------------
# Defines
# ----------------------------------------------------
override DEFINES +=

# ----------------------------------------------------
# Run-time arguments
# ----------------------------------------------------
override PLUSARGS +=

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =
ELAB_OPTS = --relax --debug typical
SIM_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: build_test sim

build_test: _build_test
sim:        _sim
info:       _sim_info
clean:      _clean_test _clean_sim

.PHONY: all build_test sim info clean

# ----------------------------------------------------
# Import SVUNIT build targets/configuration
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/svunit.mk

# Add testbench as top module (in addition to SVUnit testrunner)
TOP += smartnic_app__tb.tb

# ----------------------------------------------------
# Import Vivado sim targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_sim.mk
