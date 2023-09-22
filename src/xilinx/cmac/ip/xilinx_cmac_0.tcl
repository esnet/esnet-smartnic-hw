set module_name xilinx_cmac_0

create_ip -name cmac_usplus -vendor xilinx.com -library ip -module_name $module_name -dir . -force

# Configure board-specific parameters first
# - for some (unknown) reason, selecting the BOARD_INTERFACEs
#   causes some existing properties to be reset
switch $env(BOARD) {
    au55c {
        set_property -dict {
            CONFIG.GT_REF_CLK_FREQ {161.1328125}
            CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y3}
            CONFIG.GT_GROUP_SELECT {X0Y24~X0Y27}
            CONFIG.LANE1_GT_LOC {X0Y24}
            CONFIG.LANE2_GT_LOC {X0Y25}
            CONFIG.LANE3_GT_LOC {X0Y26}
            CONFIG.LANE4_GT_LOC {X0Y27}
            CONFIG.ETHERNET_BOARD_INTERFACE {qsfp0_4x}
            CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp0_refclk0}
        } [get_ips $module_name]
    }
    au250 {
        set_property -dict {
            CONFIG.GT_REF_CLK_FREQ {156.25}
            CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y8}
            CONFIG.GT_GROUP_SELECT {X1Y44~X1Y47}
            CONFIG.LANE1_GT_LOC {X1Y44}
            CONFIG.LANE2_GT_LOC {X1Y45}
            CONFIG.LANE3_GT_LOC {X1Y46}
            CONFIG.LANE4_GT_LOC {X1Y47}
            CONFIG.ETHERNET_BOARD_INTERFACE {qsfp0_4x}
            CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp0_156mhz}
        } [get_ips $module_name]

    }
    au280 -
    default {
        set_property -dict {
            CONFIG.GT_REF_CLK_FREQ {156.25}
            CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y6}
            CONFIG.GT_GROUP_SELECT {X0Y40~X0Y43}
            CONFIG.LANE1_GT_LOC {X0Y40}
            CONFIG.LANE2_GT_LOC {X0Y41}
            CONFIG.LANE3_GT_LOC {X0Y42}
            CONFIG.LANE4_GT_LOC {X0Y43}
            CONFIG.ETHERNET_BOARD_INTERFACE {qsfp0_4x}
            CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp0_156mhz}
        } [get_ips $module_name]

    }
}

# Then configure common parameters
set_property -dict {
    CONFIG.CMAC_CAUI4_MODE {1}
    CONFIG.NUM_LANES {4x25}
    CONFIG.USER_INTERFACE {AXIS}
    CONFIG.GT_DRP_CLK {125.00}
    CONFIG.ENABLE_AXI_INTERFACE {1}
    CONFIG.INCLUDE_STATISTICS_COUNTERS {1}
    CONFIG.LANE5_GT_LOC {NA}
    CONFIG.LANE6_GT_LOC {NA}
    CONFIG.LANE7_GT_LOC {NA}
    CONFIG.LANE8_GT_LOC {NA}
    CONFIG.LANE9_GT_LOC {NA}
    CONFIG.LANE10_GT_LOC {NA}
    CONFIG.RX_GT_BUFFER {1}
    CONFIG.GT_RX_BUFFER_BYPASS {0}
    CONFIG.INS_LOSS_NYQ {20}
    CONFIG.INCLUDE_RS_FEC {1}
    CONFIG.ENABLE_PIPELINE_REG {1}
} [get_ips $module_name]
