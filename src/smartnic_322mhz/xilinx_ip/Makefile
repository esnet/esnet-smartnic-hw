# -----------------------------------------------
# Path setup
# -----------------------------------------------
IP_ROOT := ..

# -----------------------------------------------
# IP config
# -----------------------------------------------
include $(IP_ROOT)/config.mk

# ----------------------------------------------------
# Sources
#   List source files and include directories for component.
#   (see $(SCRIPTS_ROOT)/Makefiles/sources.mk)
#   Note: if no sources are explicitly listed, all
#   source files from ./src are added automatically,
#   with include directory ./include
# ----------------------------------------------------
SRC_FILES =
INC_DIRS =
SRC_LIST_FILES = \
    axis_switch_egress/sources.f \
    axis_switch_ingress/sources.f \
    clk_wiz_0/sources.f 

# ----------------------------------------------------
# Dependencies
#   List IP component and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/dependencies.mk)
# ----------------------------------------------------
COMPONENTS = 

EXT_LIBS = \
           axis_infrastructure_v1_1_0 \
           axi_infrastructure_v1_1_0 \
           axi_register_slice_v2_1_25 \
           axis_register_slice_v1_1_25 \
           axis_infrastructure_v1_1_0 \
           axi_clock_converter_v2_1_24 \
           generic_baseblocks_v2_1_0 \
           axi_crossbar_v2_1_23 \
           axis_switch_v1_1_25 \
           unisims_ver \
           unimacro_ver \
           secureip \
           xpm

# ----------------------------------------------------
# Defines
#   List macro definitions.
# ----------------------------------------------------
DEFINES =

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS=
ELAB_OPTS=--debug typical
SIM_OPTS=

# ----------------------------------------------------
# Compile Targets
# ----------------------------------------------------
all: compile

compile: sim_targets _compile

clean: _clean_compile clean_proj

.PHONY: all compile clean

# ----------------------------------------------------
# Import Vivado compile targets
# ----------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/vivado_compile.mk

# ----------------------------------------------------
# Managed IP Project targets
# ----------------------------------------------------
VIVADO_SCRIPTS_ROOT = $(SCRIPTS_ROOT)/vivado

proj:
ifeq (,$(wildcard ./.proj_created))
	@rm -rf ip_proj
endif
	$(MAKE) _create_proj

synth: synth_targets
	vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_synth.tcl

_create_proj: ip_proj/ip_proj.xpr
.PHONY: _create_proj

ip_proj/ip_proj.xpr : config.tcl ip_list.tcl 
	rm -f .proj_created
	rm -f .*_generated
	vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_create.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_import.tcl
	touch .proj_created

sim_targets: .sim_targets_generated
.PHONY: sim_targets

.sim_targets_generated: | proj
	vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_gen_sim_targets.tcl
	touch .sim_targets_generated

synth_targets: .synth_targets_generated
.PHONY: synth_targets

.synth_targets_generated: | proj
	vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_gen_synth_targets.tcl
	touch .synth_targets_generated

clean_proj:
	vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_clean.tcl
	@rm -f .proj_created
	@rm -f .*targets_generated
	@rm -f *.jou
	@rm -f *.log
	@rm -f *.str
	@rm -rf .Xil
	@rm -rf hbs
	@rm -rf ip_user_files
	@rm -rf ip_proj

