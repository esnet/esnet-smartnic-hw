# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# Configuration
# Note: these parameters can also be provided
#       at the command line, e.g.:
#       make REGRESSION=1
#       make waves=ON
#       make SEED=29 waves=ON
# -----------------------------------------------
REGRESSION ?= 0
SEED ?= 0
waves ?= OFF

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk for details)
# ----------------------------------------------------
SUBCOMPONENTS = \
    vitisnetp4_igr.rtl \
    vitisnetp4_igr.verif \
    vitisnetp4_egr.rtl \
    vitisnetp4_egr.verif \
    smartnic_app.igr.rtl \
    smartnic_app.egr.rtl \
    smartnic_app.igr_p4.rtl@$(SMARTNIC_LIB_NAME) \
    smartnic_app.egr_p4.rtl@$(SMARTNIC_LIB_NAME) \
    smartnic_app.verif@$(SMARTNIC_LIB_NAME) \
    smartnic_app.tb@$(SMARTNIC_LIB_NAME) \
    axi4l.rtl@$(COMMON_LIB_NAME) \
    axi4s.rtl@$(COMMON_LIB_NAME) \
    axi4l.verif@$(COMMON_LIB_NAME) \
    axi4s.verif@$(COMMON_LIB_NAME)

EXT_LIBS =

# ----------------------------------------------------
# Defines
#   List macro definitions.
#   Macros listed here will add to any defines set at
#   command line, as e.g.:
#     make DEFINES="DEBUG FAST=TRUE"
# ----------------------------------------------------
override DEFINES +=

# ----------------------------------------------------
# Run-time arguments
#   List runtime arguments passed to simulator as
#   plusarg (+ARG) references.
#   Arguments listed here will add to any arguments
#   set at the command line, as e.g.:
#   make PLUSARGS="FAST_SIM MODE=1"
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
all: p4bm build_test sim

p4bm:
	$(MAKE) sim-all P4BM_LOGFILE="-l log" -C $(COMPONENT_ROOT)/../p4/sim_igr

build_test: _build_test
sim:        _sim
info:       _sim_info
clean:      _clean_test _clean_sim

.PHONY: all p4bm build_test sim info clean

# ----------------------------------------------------
# Import SVUNIT build targets/configuration
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/svunit.mk

# Add testbench as top module (in addition to SVUnit testrunner)
TOP += smartnic_app__tb.tb

# ----------------------------------------------------
# Import VitisNetP4 IP simulation configuration
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/test_vitisnetp4.mk

# ----------------------------------------------------
# Import Vivado sim targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_sim.mk
