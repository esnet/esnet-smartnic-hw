# -----------------------------------------------
# Component setup
# -----------------------------------------------
VITISNETP4_COMPONENT_ROOT := ..

include $(VITISNETP4_COMPONENT_ROOT)/config.mk

# -----------------------------------------------
# VitisNetP4 wrapper config
# -----------------------------------------------
VITISNETP4_XCI_FILE = $(call get_component_out_path_from_ref,$(COMPONENT_BASE).ip,$(LIB_OUTPUT_ROOT))/$(VITISNETP4_IP_NAME)/$(VITISNETP4_IP_NAME).xci
VITISNETP4_WRAPPER_FILE = $(COMPONENT_OUT_PATH)/$(VITISNETP4_IP_NAME)_wrapper.sv

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/templates/sources.mk)
#   NOTE: along with explicitly-listed sources, all
#   source files from ./src are added automatically, and
#   .include is added as an include directory automatically.
# ----------------------------------------------------
SRC_FILES = $(VITISNETP4_WRAPPER_FILE)
INC_DIRS =
SRC_LIST_FILES =

# ----------------------------------------------------
# Dependencies
#   List subcomponent and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/templates/dependencies.mk)
# ----------------------------------------------------
SUBCOMPONENTS = \
    $(COMPONENT_BASE).ip \
    p4_proc.pkg$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    smartnic.pkg$(if $(SMARTNIC_LIB_NAME),@$(SMARTNIC_LIB_NAME),) \
    axi4s.rtl@$(COMMON_LIB_NAME) \
    axi4l.rtl@$(COMMON_LIB_NAME)

EXT_LIBS =

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =

# ----------------------------------------------------
# Targets
# ----------------------------------------------------
all: compile synth

compile: _compile_sim
synth:   _compile_synth
info:    _compile_info
clean:   _compile_clean

.PHONY: all compile synth info clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk

$(VITISNETP4_WRAPPER_FILE): $(VITISNETP4_XCI_FILE) | $(COMPONENT_OUT_PATH)
	@$(SMARTNIC_ROOT)/scripts/vitisnetp4/gen_vitisnetp4_wrapper.py $< --out_dir $(COMPONENT_OUT_PATH) --template-dir $(SMARTNIC_ROOT)/scripts/vitisnetp4

$(COMPONENT_OUT_PATH):
	@mkdir -p $@
