# QSFP pin assignments for the V80 (xcv80-lsva4737).
# These are commented out in the AMD AVED base impl.pins.xdc and are
# added here as an ESnet extension, keeping the AVED submodule clean.

# QSFP0 322 MHz reference clock (Bank 209, GTM_REFCLKP0)
set_property -dict { PACKAGE_PIN AR51 } [get_ports "qsfp0_322mhz_clk_p"]    ;# Bank 209 GTM_REFCLKP0_209

# QSFP0 RX (Bank 209)
set_property -dict { PACKAGE_PIN AE67 } [get_ports "qsfp0_4x_grx_p[0]"]     ;# Bank 209 GTM_RXP0_209
set_property -dict { PACKAGE_PIN AE64 } [get_ports "qsfp0_4x_grx_p[1]"]     ;# Bank 209 GTM_RXP1_209
set_property -dict { PACKAGE_PIN AC67 } [get_ports "qsfp0_4x_grx_p[2]"]     ;# Bank 209 GTM_RXP2_209
set_property -dict { PACKAGE_PIN AC64 } [get_ports "qsfp0_4x_grx_p[3]"]     ;# Bank 209 GTM_RXP3_209

# QSFP0 TX (Bank 209)
set_property -dict { PACKAGE_PIN AG61 } [get_ports "qsfp0_4x_gtx_p[0]"]     ;# Bank 209 GTM_TXP0_209
set_property -dict { PACKAGE_PIN AG58 } [get_ports "qsfp0_4x_gtx_p[1]"]     ;# Bank 209 GTM_TXP1_209
set_property -dict { PACKAGE_PIN AE61 } [get_ports "qsfp0_4x_gtx_p[2]"]     ;# Bank 209 GTM_TXP2_209
set_property -dict { PACKAGE_PIN AE58 } [get_ports "qsfp0_4x_gtx_p[3]"]     ;# Bank 209 GTM_TXP3_209

# QSFP1 RX (Bank 210)
set_property -dict { PACKAGE_PIN AA67 } [get_ports "qsfp1_4x_grx_p[0]"]     ;# Bank 210 GTM_RXP0_210
set_property -dict { PACKAGE_PIN AA64 } [get_ports "qsfp1_4x_grx_p[1]"]     ;# Bank 210 GTM_RXP1_210
set_property -dict { PACKAGE_PIN W67  } [get_ports "qsfp1_4x_grx_p[2]"]     ;# Bank 210 GTM_RXP2_210
set_property -dict { PACKAGE_PIN W64  } [get_ports "qsfp1_4x_grx_p[3]"]     ;# Bank 210 GTM_RXP3_210

# QSFP1 TX (Bank 210)
set_property -dict { PACKAGE_PIN AC61 } [get_ports "qsfp1_4x_gtx_p[0]"]     ;# Bank 210 GTM_TXP0_210
set_property -dict { PACKAGE_PIN AC58 } [get_ports "qsfp1_4x_gtx_p[1]"]     ;# Bank 210 GTM_TXP1_210
set_property -dict { PACKAGE_PIN AA61 } [get_ports "qsfp1_4x_gtx_p[2]"]     ;# Bank 210 GTM_TXP2_210
set_property -dict { PACKAGE_PIN AA58 } [get_ports "qsfp1_4x_gtx_p[3]"]     ;# Bank 210 GTM_TXP3_210


# Map DCMAC and GTM_QUAD Instances to the correct floorplan sites.
set_property LOC DCMAC_X1Y1 [get_cells -hier -filter {REF_NAME == DCMAC}]
set_property LOC GTM_QUAD_X1Y7 [get_cells -hierarchical -filter {REF_NAME =~ GTME5_QUAD && NAME == i_xilinx_alveo_versal_shell/dcmac_wrapper_0/g_gt[0].i_xilinx_gt_wrapper/i_xilinx_gt_0/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst}]
set_property LOC GTM_QUAD_X1Y8 [get_cells -hierarchical -filter {REF_NAME =~ GTME5_QUAD && NAME == i_xilinx_alveo_versal_shell/dcmac_wrapper_0/g_gt[1].i_xilinx_gt_wrapper/i_xilinx_gt_0/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst}]

#set_property LOC DCMAC_X0Y2 [get_cells -hier -filter {REF_NAME == DCMAC}]
#set_property LOC GTM_QUAD_X0Y9 [get_cells -hierarchical -filter {REF_NAME =~ GTME5_QUAD && NAME == i_xilinx_alveo_versal_shell/dcmac_wrapper_0/g_gt[0].i_xilinx_gt_wrapper/i_xilinx_gt_0/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst}]
#set_property LOC GTM_QUAD_X0Y10 [get_cells -hierarchical -filter {REF_NAME =~ GTME5_QUAD && NAME == i_xilinx_alveo_versal_shell/dcmac_wrapper_0/g_gt[1].i_xilinx_gt_wrapper/i_xilinx_gt_0/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst/quad_inst}]
