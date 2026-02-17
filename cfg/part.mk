# -----------------------------------------
# Repo configuration
# -----------------------------------------
# select open-nic-shell repo by default.
BOARD_REPO = $(abspath $(CFG_ROOT)/../open-nic-shell/board_files/Xilinx)

# -----------------------------------------
# Device configuration
# -----------------------------------------
# select xcu55c by default.
PART = xcu55c-fsvh2892-2L-e
BOARD_PART = xilinx.com:au55c:part0:1.0

ifeq ($(BOARD), au280)
PART = xcu280-fsvh2892-2L-e
BOARD_PART = xilinx.com:au280:part0:1.1
endif

ifeq ($(BOARD), au250)
PART = xcu250-figd2104-2l-e
BOARD_PART = xilinx.com:au250:part0:1.3
endif

ifeq ($(BOARD), av80)
PART = xcv80-lsva4737-2MHP-e-S
BOARD_PART = ""
endif
