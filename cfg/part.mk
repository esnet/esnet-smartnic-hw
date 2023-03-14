# -----------------------------------------
# Repo configuration
# -----------------------------------------
# select open-nic-shell repo by default.
BOARD_REPO = $(ONS_ROOT)/board_files/Xilinx

# -----------------------------------------
# Device configuration
# -----------------------------------------
# select xcu280 by default.
PART = xcu280-fsvh2892-2L-e
BOARD_PART = xilinx.com:au280:part0:1.1

ifeq ($(BOARD), au55c)
PART = xcu55c-fsvh2892-2L-e
BOARD_PART = xilinx.com:au55c:part0:1.0
endif
