# -----------------------------------------------
# Configuration
# Note: these parameters can also be provided
#       at the command line, e.g.:
#       make REGRESSION=1
#       make waves=ON
#       make SEED=29 waves=ON
# -----------------------------------------------
REGRESSION = 0
SEED ?= 0
waves ?= OFF

# ----------------------------------------------------
# Defines
#   List macro definitions.
#   Macros listed here will add to any defines set at
#   command line, as e.g.:
#     make DEFINES="DEBUG FAST=TRUE"
# ----------------------------------------------------
override DEFINES +=

# ----------------------------------------------------
# Run-time arguments
#   List runtime arguments passed to simulator as
#   plusarg (+ARG) references.
#   Arguments listed here will add to any arguments
#   set at the command line, as e.g.:
#   make PLUSARGS="FAST_SIM MODE=1"
# ----------------------------------------------------
override PLUSARGS +=

# ----------------------------------------------------
# Options
# ----------------------------------------------------
COMPILE_OPTS =
ELAB_OPTS =
SIM_OPTS =

# -----------------------------------------------
# Use common testcase Makefile
# -----------------------------------------------
include ../../test_base.mk
