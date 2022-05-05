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
    sdnet_0_sources.f

# ----------------------------------------------------
# Dependencies
#   List IP component and external library dependencies
#   (see $SCRIPTS_ROOT/Makefiles/dependencies.mk)
# ----------------------------------------------------
COMPONENTS =
EXT_LIBS = cam_v2_2_2 \
           vitis_net_p4_v1_0_2

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

ip_proj/ip_proj.xpr : config.tcl ip_list.tcl create_sdnet_ip.tcl $(P4_FILE)
	rm -f .proj_created
	rm -f .*_generated
	rm -rf sdnet_0/src
	rm -rf sdnet_0/sdnet_0.dcp
	vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_create.tcl -source create_sdnet_ip.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_import.tcl
	./gen_vitisnet_p4_wrapper.py sdnet_0/sdnet_0.xci --out_file sdnet_0/sdnet_0_wrapper.sv
	touch .proj_created

sim_targets: sdnet_ex_design .sim_targets_generated
.PHONY: sim_targets

.sim_targets_generated: | proj
	vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_gen_sim_targets.tcl
	touch .sim_targets_generated

synth_targets: .synth_targets_generated
.PHONY: synth_targets

.synth_targets_generated: | proj
	vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_gen_synth_targets.tcl
	touch .synth_targets_generated

.sdnet_ex_design_generated: | proj
	vivado -mode batch -source config.tcl create_sdnet_ex_design.tcl
	touch .sdnet_ex_design_generated

sdnet_ex_design: .sdnet_ex_design_generated
.PHONY: sdnet_ex_design

clean_proj:
	-vivado -mode batch -source config.tcl -source $(VIVADO_SCRIPTS_ROOT)/ip_proj_clean.tcl
	@rm -f .proj_created
	@rm -f .*_generated
	@rm -f *.jou
	@rm -f *.log
	@rm -f *.str
	@rm -rf .Xil
	@rm -rf hbs
	@rm -rf ip_user_files
	@rm -rf ip_proj
	@rm -rf sdnet_0
