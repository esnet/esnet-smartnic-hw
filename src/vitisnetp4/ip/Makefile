# -----------------------------------------------
# Component setup
# -----------------------------------------------
VITISNETP4_COMPONENT_ROOT := ..

include $(VITISNETP4_COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# VitisNetP4 IP config
# (additional options specified in $(COMPONENT_ROOT)/config.mk
# -----------------------------------------------
P4_OPTS ?= CONFIG.PKT_RATE {150} CONFIG.OUTPUT_METADATA_FOR_DROPPED_PKTS {true}

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

all: synth compile

ifeq ($(P4_FILE),)
$(error No P4 file specified)
else
ip:      _vitisnetp4_ip
endif
compile: _vitisnetp4_compile
synth:   _vitisnetp4_synth
driver:  _vitisnetp4_driver
info:    _vitisnetp4_info
status:  _ip_status
upgrade: _ip_upgrade
clean:   _vitisnetp4_clean

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
include $(SCRIPTS_ROOT)/Makefiles/vivado_vitisnetp4.mk
