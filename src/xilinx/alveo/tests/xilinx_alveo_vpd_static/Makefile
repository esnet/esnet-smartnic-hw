NUM_FUNCS ?= 2
override DEFINES += NUM_FUNCS=$(NUM_FUNCS)
SRC_FILES = ../../rtl/src/xilinx_alveo_vpd.sv
SUBCOMPONENTS = \
    pci.vpd.verif@common \
    xilinx.pci.rtl \
    xilinx.pci.verif
include ../test_base.mk
