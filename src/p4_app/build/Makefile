# ----------------------------------------------------
# Paths
# ----------------------------------------------------
IP_ROOT = ..
include $(IP_ROOT)/config.mk

# -----------------------------------------------
# Export parameters (used in add_sources.tcl)
# -----------------------------------------------
export LIB_ROOT
export SRC_ROOT
export OUTPUT_ROOT
export SMARTNIC_ROOT

# -----------------------------------------------
# Specify top-level module
# -----------------------------------------------
TOP = smartnic_322mhz_app

# -----------------------------------------------
# vitisnetp4 options
# -----------------------------------------------
EXTERN_PORTS ?= False

# -----------------------------------------------
# User-specific environment
# -specify environment variables to pass to
#  library operations in NAME=VALUE format, e.g.:
#  USER_ENV= VAR1=VAR1_VALUE VAR2=VAR2_VALUE
# -----------------------------------------------
USER_ENV = \
    EXTERN_PORTS=$(EXTERN_PORTS)

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: opt

reg:
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=fifo.regio@common@smartnic
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=axi4s.regio@common@smartnic
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=p4_proc.regio@smartnic
	@$(MAKE) -s -C $(SRC_ROOT) reg COMPONENT=p4_app.regio@smartnic

ip:
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=fifo.ip@common@smartnic
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=axi4s.ip@common@smartnic
	@$(MAKE) -s -C $(SRC_ROOT) synth COMPONENT=vitisnetp4.ip USER_ENV=$(USER_ENV)
.PHONY: reg ip

pre_synth: reg ip
synth:     _synth
opt:       _opt
.PHONY: pre_synth synth opt

clean: _clean_build
.PHONY: clean

# -----------------------------------------------
# Include Vivado definitions/targets
# -----------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_build_core.mk
