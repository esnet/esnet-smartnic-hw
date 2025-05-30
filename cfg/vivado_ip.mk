# ------------------------------------------------------------------
# Vivado IP configuration
#
# - list of IP cores used in project for which licenses are
#   (or may be) required
# - used for validating that the proper licenses are in place
#   ahead of launching builds
# - omitting IP here only omits that IP from being considered in the
#   pre-validation step (i.e. it does not omit the IP from the design)
#
#   Format is [Vivado IP def spec]=[IP core revision]
#   e.g. xilinx.com:ip:cmac_usplus:3.1=1
# ------------------------------------------------------------------
# IP listings can (and often must) be provided per tool version. Simultaneous
# support for multiple patch versions of the tool is supported by managing
# IP definitions files, which are searched in the following order:
#
# 1. $(CFG_ROOT)/[active_vivado_version]/vivado_ip.mk
#
#     (where active_vivado_version is the version of the tool currently configured
#      i.e the full result of vivado -version; e.g. 2024.2.1_AR1)
#
# 2. $(CFG_ROOT)/[active_vivado_major_minor_version]/vivado_ip.mk
#
#     (where active_vivado_major_minor_version is the major/minor version currently configured
#      i.e the result of vivado -version, without patch release; e.g. 2024.2.1)
#
# 3. $(CFG_ROOT)/[active_vivado_major_version]/vivado_ip.mk
#
#     (where active_vivado_major_version is the major version currently configured
#      i.e the result of vivado -version, without minor version or patch release; e.g. 2024.2)
#
# 4. $(CFG_ROOT)/[project_vivado_version]/vivado_ip.mk
#
#     (where project_vivado_version is the full version of the tool expected by the project)
#
# 5. $(CFG_ROOT)/[project_vivado_major_minor_version]/vivado_ip.mk
#
#     (where project_vivado_major_minor_version is the major/minor (no patch) version of the
#      tool expected by the project)
#
# 6. $(CFG_ROOT)/[project_vivado_major_version]/vivado_ip.mk
#
#     (where project_vivado_major_version is the major (no minor, no patch) version of the
#      tool expected by the project)
#
# 7. Defaults (provided in this file, below)
#
# Note: the currently configured Vivado IP can be queried using `make info`

# Provide IP defaults (only used when no version-specific config is provided)
VIVADO_IP ?=

# ------------------------------------------------------------------
# Import targets for querying tool and IP version info
# ------------------------------------------------------------------
include $(SCRIPTS_ROOT)/Makefiles/cfg_vivado_ip_base.mk


