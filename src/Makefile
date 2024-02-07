# ----------------------------------------------------
# Path setup
# ----------------------------------------------------
SRC_ROOT = .

include config.mk

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
help: _help

.PHONY: help

reg:     _reg
ip:      _ip
info:    _info
compile: _compile
synth:   _synth
driver:  _driver
clean:   _clean

.PHONY: reg ip info compile synth clean

# Remove all output products for all library components
clean_all: _clean_all

.PHONY: _clean_all

# ----------------------------------------------------
# Include standard library targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/lib_base.mk
