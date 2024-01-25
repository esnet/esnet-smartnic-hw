# ----------------------------------------------------
# Path setup
# - specify paths in terms of SRC_ROOT
#   (defined in parent Makefile)
# ----------------------------------------------------
APP_DIR = $(abspath $(SRC_ROOT)/..)

include $(APP_DIR)/config.mk

# ----------------------------------------------------
# Library setup
# ----------------------------------------------------
LIB_NAME := "P2P SmartNIC application"
LIB_DESC := "RTL and verification for P2P SmartNIC application"

# ----------------------------------------------------
# Sub-library config
# ----------------------------------------------------
# LIBRARIES
#
# List of source libraries, as 'name=path' pairs; Allows 'import' of source
# files from libraries located at arbitrary locations.
#
# Indidual source components can be imported into designs using a dot/@ notation, where
# the dotted portion represents the component (and subcomponents) and the @ element
# represents name of the source library. For example, the following reference might be
# used to refer to an AXI RTL library from some vendor:
#
#   axi.rtl@vendorx
#
# For this to resolve properly it would be necessary to have a corresponding entry in
# the LIBRARIES variable, describing the path to the referenced library:
#
#   LIBRARIES = vendorx=[path_to_vendorx_library]
#
#  The local library is implied if the library name is omitted. For example, a reference
#  to the AXI rtl library provided in the local library could appear as:
#
#   axi.rtl
#
LIBRARIES = smartnic=$(SMARTNIC_ROOT)/src

# Specify name of 'common' library (for autogenerating register infrastructure from regio specifications)
COMMON_LIB_NAME = common@smartnic

# ----------------------------------------------------
# Environment setup
# - specify library-specific environment variables
#   that should be passed as arguments to library
#   operations
# - entries should be specified as a list of NAME=VALUE
#   pairs, e.g.:
#   LIB_ENV = VAR1_NAME=VAR1_VALUE VAR2_NAME=VAR2_VALUE
# ----------------------------------------------------
BOARD ?= au280

LIB_ENV = \
    BOARD=$(BOARD) \
    IP_OUT_SUBDIR=$(BOARD)
