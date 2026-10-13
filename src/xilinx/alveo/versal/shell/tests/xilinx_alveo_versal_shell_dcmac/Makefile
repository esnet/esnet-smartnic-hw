# -----------------------------------------------
# Configuration
# -----------------------------------------------
REGRESSION = 0
SEED ?= 0
waves ?= OFF

# ----------------------------------------------------
# Defines / plusargs / options
# ----------------------------------------------------
override DEFINES += SIM_SPEED_UP=1 XIL_DCMAC_FORCE_FAST_ALIGN=1
override PLUSARGS +=

COMPILE_OPTS =
ELAB_OPTS =
SIM_OPTS =

# -----------------------------------------------
# Use common testcase Makefile
# -----------------------------------------------
SUBCOMPONENTS ?= \
    xilinx.alveo.versal.shell.rtl \
    xilinx.alveo.versal.regio.verif \
    xilinx.alveo.versal.pkg \
    xilinx.qdma.pkg \
    smartnic.core.rtl \
    smartnic_app.rtl \
    smartnic_app.igr_p4.vf_loopback.rtl \
    smartnic_app.egr_p4.vf_loopback.rtl \
    smartnic_app.igr.demux.rtl \
    smartnic_app.egr.mux.rtl \
    smartnic.pkg \
    packet.verif@common \
    axi4l.verif@common \
    axi4s.verif@common \

include ../test_base.mk
