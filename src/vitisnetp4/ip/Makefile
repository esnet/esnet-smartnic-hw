# -----------------------------------------------
# Path setup
# -----------------------------------------------
IP_ROOT := ..

# -----------------------------------------------
# IP config
# -----------------------------------------------
include $(IP_ROOT)/config.mk

# -----------------------------------------------
# VitisNetP4 IP config
# -----------------------------------------------
VITISNETP4_IP_NAME = sdnet_0

P4_FILE ?= $(SRC_ROOT)/p4_app/p4/p4_app.p4
P4_OPTS ?= CONFIG.PKT_RATE {150} CONFIG.OUTPUT_METADATA_FOR_DROPPED_PKTS {true}

EXTERN_PORTS ?= False

VITISNETP4_WRAPPER_FILE = $(IP_OUT_DIR)/$(VITISNETP4_IP_NAME)/$(VITISNETP4_IP_NAME)_wrapper.sv

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/sources.mk)
# ----------------------------------------------------
#  Note: VitisNetP4 source files are automatically included by
#        the vivado_vitisnetp4.mk standard Makefile. Only user-supplied
#        files/dependencies need to be listed here
SRC_FILES = $(VITISNETP4_WRAPPER_FILE)

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
# Targets
# ----------------------------------------------------
all: synth compile

ip:      _vitisnetp4_ip vitisnetp4_wrapper
compile: vitisnetp4_wrapper _vitisnetp4_compile
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

vitisnetp4_wrapper: $(VITISNETP4_WRAPPER_FILE)

.PHONY: vitisnetp4_wrapper

$(VITISNETP4_WRAPPER_FILE): $(VITISNETP4_XCI_FILE)
	@$(SMARTNIC_ROOT)/scripts/vitisnetp4/gen_vitisnetp4_wrapper.py $< --out_dir $(<D) --template-dir $(SMARTNIC_ROOT)/scripts/vitisnetp4 --extern_ports $(EXTERN_PORTS)
