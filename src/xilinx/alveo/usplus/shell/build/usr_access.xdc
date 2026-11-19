# USR_ACCESS supplies static build identification set during bitstream export.
# CFGCLK and DATAVALID are unused; this read path does not support AXSS updates.
# https://docs.amd.com/api/khub/documents/11iI3ZKQ3Er2IVcsrtNzfQ/content
# Disable the hidden CCLK arcs only for the shell's static identifier primitive.
set_disable_timing -from CCLK [get_cells {i_xilinx_alveo_usplus_shell/i_xilinx_alveo_usplus/USR_ACCESSE2_0}]
