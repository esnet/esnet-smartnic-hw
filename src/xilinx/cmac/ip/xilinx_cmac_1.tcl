set module_name xilinx_cmac_1

create_ip -name cmac_usplus -vendor xilinx.com -library ip -module_name $module_name -dir . -force

# Configure board-specific parameters first
# - for some (unknown) reason, selecting the BOARD_INTERFACEs
#   causes some existing properties to be reset
switch $env(BOARD) {
    au55c {
        set_property -dict {
            CONFIG.GT_REF_CLK_FREQ {161.1328125}
            CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y4}
            CONFIG.GT_GROUP_SELECT {X0Y28~X0Y31}
            CONFIG.LANE1_GT_LOC {X0Y28}
            CONFIG.LANE2_GT_LOC {X0Y29}
            CONFIG.LANE3_GT_LOC {X0Y30}
            CONFIG.LANE4_GT_LOC {X0Y31}
            CONFIG.ETHERNET_BOARD_INTERFACE {qsfp1_4x}
            CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp1_refclk0}
        } [get_ips $module_name]
    }
    au250 {
        set_property -dict {
            CONFIG.GT_REF_CLK_FREQ {156.25}
            CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y7}
            CONFIG.GT_GROUP_SELECT {X1Y40~X1Y43}
            CONFIG.LANE1_GT_LOC {X1Y40}
            CONFIG.LANE2_GT_LOC {X1Y41}
            CONFIG.LANE3_GT_LOC {X1Y42}
            CONFIG.LANE4_GT_LOC {X1Y43}
            CONFIG.ETHERNET_BOARD_INTERFACE {qsfp1_4x}
            CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp1_156mhz}
        } [get_ips $module_name]
    }
    au280 -
    default {
        set_property -dict {
            CONFIG.GT_REF_CLK_FREQ {156.25}
            CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y7}
            CONFIG.GT_GROUP_SELECT {X0Y44~X0Y47}
            CONFIG.LANE1_GT_LOC {X0Y44}
            CONFIG.LANE2_GT_LOC {X0Y45}
            CONFIG.LANE3_GT_LOC {X0Y46}
            CONFIG.LANE4_GT_LOC {X0Y47}
            CONFIG.ETHERNET_BOARD_INTERFACE {qsfp1_4x}
            CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp1_156mhz}
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
