# -----------------------------------------------
# Component setup
# -----------------------------------------------
COMPONENT_ROOT := ..

include $(COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# VitisNetP4 IP config
# -----------------------------------------------
VITISNETP4_IP_NAME = sdnet_egr

P4_EGR_FILE ?= $(SMARTNIC_ROOT)/src/vitisnetp4/p4/p4_app.p4
P4_FILE = $(P4_EGR_FILE)
P4_OPTS ?= CONFIG.PKT_RATE {150} CONFIG.OUTPUT_METADATA_FOR_DROPPED_PKTS {true}

EXTERN_PORTS ?= False

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS=

# ----------------------------------------------------
# Compile Targets
# ----------------------------------------------------
ifneq ($(P4_FILE),)
all: synth compile
endif

echo_var:
	@echo "Egress P4_FILE: $(P4_FILE)"
ip:      echo_var _vitisnetp4_ip
compile: _vitisnetp4_compile
synth:   _vitisnetp4_synth
driver:  _vitisnetp4_driver
info:    _vitisnetp4_info
status:  _ip_status
upgrade: _ip_upgrade
clean:   _vitisnetp4_clean

.PHONY: all echo_var ip compile synth info status upgrade clean

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
include $(SCRIPTS_ROOT)/Makefiles/vivado_vitisnetp4.mk
