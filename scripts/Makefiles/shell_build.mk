# shell_build.mk
#
# Board-dispatching wrapper for shell build includes.
#
# Selects the appropriate board-family shell build include based on BOARD:
#   av*  -> versal_shell_build.mk  (Versal / V80)
#   au*  -> usplus_shell_build.mk  (UltraScale+ / Alveo U-series) [future]
#
# See shell_build_base.mk for the common shell+core assembly logic and its
# required/optional inputs.

export LIB_ROOT

ifeq ($(filter av%,$(BOARD)),$(BOARD))
include $(SMARTNIC_ROOT)/scripts/Makefiles/versal_shell_build.mk
else ifeq ($(filter au%,$(BOARD)),$(BOARD))
include $(SMARTNIC_ROOT)/scripts/Makefiles/usplus_shell_build.mk
else
$(error shell_build.mk: unrecognised BOARD '$(BOARD)' — expected av* or au*)
endif
