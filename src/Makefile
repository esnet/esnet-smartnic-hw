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
opt:     _opt
driver:  _driver
clean:   _clean

.PHONY: reg ip info compile synth clean

# Remove all output products for all library components
clean_all: _clean_all

.PHONY: _clean_all

# Force refresh of output products for cache safety, etc.
# Does not delete output products, but invalidates intermediate
# files where applicable (e.g. IP, regio) such that output products are
# regenerated if source files/config have changed.
refresh: _refresh

# ----------------------------------------------------
# Include standard library targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/lib_base.mk
