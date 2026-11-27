# AU55C shell pin assignments.
# Sources:
#   AMD U55C master XDC v1.00 (U55C_xdc_1v00.xdc).
#   https://download.amd.com/opendownload/xlnx/U55C_xdc_1v00.xdc

# Serial data pads are placed by the QDMA and CMAC IP GT constraints.

# PCIe.
set_property -dict {PACKAGE_PIN AR15} [get_ports {pcie_refclk_p}]
set_property -dict {PACKAGE_PIN AR14} [get_ports {pcie_refclk_n}]
set_property -dict {PACKAGE_PIN BF41 IOSTANDARD LVCMOS18} [get_ports {pcie_rstn}]

# QSFP reference clocks (SYNCE_CLK0/1).
set_property -dict {PACKAGE_PIN AD42} [get_ports {qsfp_refclk_p[0]}]
set_property -dict {PACKAGE_PIN AD43} [get_ports {qsfp_refclk_n[0]}]
set_property -dict {PACKAGE_PIN AB42} [get_ports {qsfp_refclk_p[1]}]
set_property -dict {PACKAGE_PIN AB43} [get_ports {qsfp_refclk_n[1]}]

# 100 MHz system clock (SYSCLK3).
set_property -dict {PACKAGE_PIN BK43 IOSTANDARD LVDS DQS_BIAS TRUE} [get_ports {sys_clk_3_p}]
set_property -dict {PACKAGE_PIN BK44 IOSTANDARD LVDS DQS_BIAS TRUE} [get_ports {sys_clk_3_n}]

# Satellite controller.
set_property -dict {PACKAGE_PIN BH42 IOSTANDARD LVCMOS18} [get_ports {satellite_uart_0_txd}]
set_property -dict {PACKAGE_PIN BJ42 IOSTANDARD LVCMOS18} [get_ports {satellite_uart_0_rxd}]
set_property -dict {PACKAGE_PIN BE46 IOSTANDARD LVCMOS18} [get_ports {satellite_gpio[0]}]
set_property -dict {PACKAGE_PIN BH46 IOSTANDARD LVCMOS18} [get_ports {satellite_gpio[1]}]
set_property -dict {PACKAGE_PIN BF45 IOSTANDARD LVCMOS18} [get_ports {satellite_gpio[2]}]
set_property -dict {PACKAGE_PIN BF46 IOSTANDARD LVCMOS18} [get_ports {satellite_gpio[3]}]

# HBM temperature alarm.
# The shell drives this output low while HBM is unused.
set_property -dict {PACKAGE_PIN BE45 IOSTANDARD LVCMOS18 PULLDOWN TRUE} [get_ports {hbm_cattrip}]

# Complete upstream pin reference
# All package-pin assignments listed in the sources above, including unused
# interfaces and any explicit no-connect entries. Signal names are the upstream
# board names. The shell column identifies the explicit constraints above;
# serial data pads can also be used through the IP GT constraints.
# A dash denotes an unspecified I/O standard or no explicit shell assignment.
# This reference table is comments only and does not apply constraints.
# Listed package pins: 742.
#
# Package pin  Board signal                     I/O standard         Shell port
# F23          SYSCLK4_N                        LVDS                 -
# F24          SYSCLK4_P                        LVDS                 -
# BK44         SYSCLK3_N                        LVDS                 sys_clk_3_n
# BK43         SYSCLK3_P                        LVDS                 sys_clk_3_p
# BL10         SYSCLK2_N                        LVDS                 -
# BK10         SYSCLK2_P                        LVDS                 -
# BN42         TESTCLK_OUT                      LVCMOS18             -
# BJ33         PPS_IN_FPGA                      LVCMOS18             -
# BH32         PPS_OUT_FPGA                     LVCMOS18             -
# AR41         NS2_REFCLK0_N                    -                    -
# AR40         NS2_REFCLK0_P                    -                    -
# AP43         NS2_SYSCLK6_N                    -                    -
# AP42         NS2_SYSCLK6_P                    -                    -
# AL41         NS1_REFCLK0_N                    -                    -
# AL40         NS1_REFCLK0_P                    -                    -
# AK43         NS1_SYSCLK5_N                    -                    -
# AK42         NS1_SYSCLK5_P                    -                    -
# AD43         SYNCE_CLK0_N                     -                    qsfp_refclk_n[0]
# AD42         SYNCE_CLK0_P                     -                    qsfp_refclk_p[0]
# AB43         SYNCE_CLK1_N                     -                    qsfp_refclk_n[1]
# AB42         SYNCE_CLK1_P                     -                    qsfp_refclk_p[1]
# AR14         PCIE_REFCLK1_N                   -                    pcie_refclk_n
# AR15         PCIE_REFCLK1_P                   -                    pcie_refclk_p
# AP12         PCIE_SYSCLK1_N                   -                    -
# AP13         PCIE_SYSCLK1_P                   -                    -
# AL14         PCIE_REFCLK0_N                   -                    -
# AL15         PCIE_REFCLK0_P                   -                    -
# AK12         PCIE_SYSCLK0_N                   -                    -
# AK13         PCIE_SYSCLK0_P                   -                    -
# BM8          SI_RSTBB                         LVCMOS18             -
# BM9          SI_INTRB                         LVCMOS18             -
# BN10         SI_PLL_LOCK                      LVCMOS18             -
# BM10         SI_IN_LOS                        LVCMOS18             -
# BM14         I2C_SI5394_SCL                   LVCMOS18             -
# BN14         I2C_SI5394_SDA                   LVCMOS18             -
# BE45         HBM_CATTRIP_LS                   LVCMOS18             hbm_cattrip
# BF41         PCIE_PERST_LS_65                 LVCMOS18             pcie_rstn
# BG43         PEX_PWRBRKN_FPGA_65              LVCMOS18             -
# BP8          PCIE_PERST_LS_R                  LVCMOS18             -
# BN11         PEX_PWRBRKN_FPGA_R               LVCMOS18             -
# BG45         CPU_RESET_FPGA                   LVCMOS18             -
# BM12         RSTN_68                          LVCMOS18             -
# BK41         FPGA_UART0_RXD                   LVCMOS18             -
# BJ41         FPGA_UART0_TXD                   LVCMOS18             -
# BL46         FPGA_UART2_RXD                   LVCMOS18             -
# BL45         FPGA_UART2_TXD                   LVCMOS18             -
# BP47         FPGA_UART1_RXD                   LVCMOS18             -
# BN47         FPGA_UART1_TXD                   LVCMOS18             -
# BH12         FPGA_TXD_MSP_R                   LVCMOS18             -
# BH14         FPGA_RXD_MSP_R                   LVCMOS18             -
# BJ42         FPGA_RXD_MSP_65                  LVCMOS18             satellite_uart_0_rxd
# BH42         FPGA_TXD_MSP_65                  LVCMOS18             satellite_uart_0_txd
# BE46         MSP_GPIO0                        LVCMOS18             satellite_gpio[0]
# BF46         MSP_GPIO3                        LVCMOS18             satellite_gpio[3]
# BF45         MSP_GPIO2                        LVCMOS18             satellite_gpio[2]
# BH46         MSP_GPIO1                        LVCMOS18             satellite_gpio[1]
# BJ31         NS1_SMB_SCL                      LVCMOS18             -
# BH31         NS1_SMB_SDA                      LVCMOS18             -
# BG30         NS2_SMB_SCL                      LVCMOS18             -
# BG29         NS2_SMB_SDA                      LVCMOS18             -
# BF32         NS1_SMB_INT_RST                  LVCMOS18             -
# BH35         NS2_SMB_INT_RST                  LVCMOS18             -
# BJ29         NS1_SPARE1_FPGA                  LVCMOS18             -
# BF31         NS1_SPARE2_FPGA                  LVCMOS18             -
# BF36         NS2_SPARE1_FPGA                  LVCMOS18             -
# BK35         NS2_SPARE2_FPGA                  LVCMOS18             -
# BK14         QSFP28_1_ACTIVITY_LED            LVCMOS18             -
# BK15         QSFP28_1_LINK_STAT_LEDG          LVCMOS18             -
# BL12         QSFP28_1_LINK_STAT_LEDY          LVCMOS18             -
# BL13         QSFP28_0_ACTIVITY_LED            LVCMOS18             -
# BK11         QSFP28_0_LINK_STAT_LEDG          LVCMOS18             -
# BJ11         QSFP28_0_LINK_STAT_LEDY          LVCMOS18             -
# BC54         NS2_RX7_N                        -                    -
# BB52         NS2_RX6_N                        -                    -
# BA54         NS2_RX5_N                        -                    -
# BA50         NS2_RX4_N                        -                    -
# BC53         NS2_RX7_P                        -                    -
# BB51         NS2_RX6_P                        -                    -
# BA53         NS2_RX5_P                        -                    -
# BA49         NS2_RX4_P                        -                    -
# BC49         NS2_TX7_N                        -                    -
# BC45         NS2_TX6_N                        -                    -
# BB47         NS2_TX5_N                        -                    -
# BA45         NS2_TX4_N                        -                    -
# BC48         NS2_TX7_P                        -                    -
# BC44         NS2_TX6_P                        -                    -
# BB46         NS2_TX5_P                        -                    -
# BA44         NS2_TX4_P                        -                    -
# AY52         NS2_RX3_N                        -                    -
# AW54         NS2_RX2_N                        -                    -
# AW50         NS2_RX1_N                        -                    -
# AV52         NS2_RX0_N                        -                    -
# AY51         NS2_RX3_P                        -                    -
# AW53         NS2_RX2_P                        -                    -
# AW49         NS2_RX1_P                        -                    -
# AV51         NS2_RX0_P                        -                    -
# AY47         NS2_TX3_N                        -                    -
# AW45         NS2_TX2_N                        -                    -
# AV47         NS2_TX1_N                        -                    -
# AU45         NS2_TX0_N                        -                    -
# AY46         NS2_TX3_P                        -                    -
# AW44         NS2_TX2_P                        -                    -
# AV46         NS2_TX1_P                        -                    -
# AU44         NS2_TX0_P                        -                    -
# AU54         NS1_RX7_N                        -                    -
# AT52         NS1_RX6_N                        -                    -
# AR54         NS1_RX5_N                        -                    -
# AP52         NS1_RX4_N                        -                    -
# AU53         NS1_RX7_P                        -                    -
# AT51         NS1_RX6_P                        -                    -
# AR53         NS1_RX5_P                        -                    -
# AP51         NS1_RX4_P                        -                    -
# AU49         NS1_TX7_N                        -                    -
# AT47         NS1_TX6_N                        -                    -
# AR49         NS1_TX5_N                        -                    -
# AR45         NS1_TX4_N                        -                    -
# AU48         NS1_TX7_P                        -                    -
# AT46         NS1_TX6_P                        -                    -
# AR48         NS1_TX5_P                        -                    -
# AR44         NS1_TX4_P                        -                    -
# AN54         NS1_RX3_N                        -                    -
# AN50         NS1_RX2_N                        -                    -
# AM52         NS1_RX1_N                        -                    -
# AL54         NS1_RX0_N                        -                    -
# AN53         NS1_RX3_P                        -                    -
# AN49         NS1_RX2_P                        -                    -
# AM51         NS1_RX1_P                        -                    -
# AL53         NS1_RX0_P                        -                    -
# AP47         NS1_TX3_N                        -                    -
# AN45         NS1_TX2_N                        -                    -
# AM47         NS1_TX1_N                        -                    -
# AL45         NS1_TX0_N                        -                    -
# AP46         NS1_TX3_P                        -                    -
# AN44         NS1_TX2_P                        -                    -
# AM46         NS1_TX1_P                        -                    -
# AL44         NS1_TX0_P                        -                    -
# AE41         N46843036                        -                    -
# AU41         N46888322                        -                    -
# AD52         QSFP28_0_RX1_N                   -                    -
# AC54         QSFP28_0_RX2_N                   -                    -
# AC50         QSFP28_0_RX3_N                   -                    -
# AB52         QSFP28_0_RX4_N                   -                    -
# AD51         QSFP28_0_RX1_P                   -                    -
# AC53         QSFP28_0_RX2_P                   -                    -
# AC49         QSFP28_0_RX3_P                   -                    -
# AB51         QSFP28_0_RX4_P                   -                    -
# AD47         QSFP28_0_TX1_N                   -                    -
# AC45         QSFP28_0_TX2_N                   -                    -
# AB47         QSFP28_0_TX3_N                   -                    -
# AA49         QSFP28_0_TX4_N                   -                    -
# AD46         QSFP28_0_TX1_P                   -                    -
# AC44         QSFP28_0_TX2_P                   -                    -
# AB46         QSFP28_0_TX3_P                   -                    -
# AA48         QSFP28_0_TX4_P                   -                    -
# AA54         QSFP28_1_RX1_N                   -                    -
# Y52          QSFP28_1_RX2_N                   -                    -
# W54          QSFP28_1_RX3_N                   -                    -
# V52          QSFP28_1_RX4_N                   -                    -
# AA53         QSFP28_1_RX1_P                   -                    -
# Y51          QSFP28_1_RX2_P                   -                    -
# W53          QSFP28_1_RX3_P                   -                    -
# V51          QSFP28_1_RX4_P                   -                    -
# AA45         QSFP28_1_TX1_N                   -                    -
# Y47          QSFP28_1_TX2_N                   -                    -
# W49          QSFP28_1_TX3_N                   -                    -
# W45          QSFP28_1_TX4_N                   -                    -
# AA44         QSFP28_1_TX1_P                   -                    -
# Y46          QSFP28_1_TX2_P                   -                    -
# W48          QSFP28_1_TX3_P                   -                    -
# W44          QSFP28_1_TX4_P                   -                    -
# BC1          PEX_RX15_N                       -                    -
# BB3          PEX_RX14_N                       -                    -
# BA1          PEX_RX13_N                       -                    -
# BA5          PEX_RX12_N                       -                    -
# BC2          PEX_RX15_P                       -                    -
# BB4          PEX_RX14_P                       -                    -
# BA2          PEX_RX13_P                       -                    -
# BA6          PEX_RX12_P                       -                    -
# BC6          PEX_TX15_N                       -                    -
# BC10         PEX_TX14_N                       -                    -
# BB8          PEX_TX13_N                       -                    -
# BA10         PEX_TX12_N                       -                    -
# BC7          PEX_TX15_P                       -                    -
# BC11         PEX_TX14_P                       -                    -
# BB9          PEX_TX13_P                       -                    -
# BA11         PEX_TX12_P                       -                    -
# AY3          PEX_RX11_N                       -                    -
# AW1          PEX_RX10_N                       -                    -
# AW5          PEX_RX9_N                        -                    -
# AV3          PEX_RX8_N                        -                    -
# AY4          PEX_RX11_P                       -                    -
# AW2          PEX_RX10_P                       -                    -
# AW6          PEX_RX9_P                        -                    -
# AV4          PEX_RX8_P                        -                    -
# AY8          PEX_TX11_N                       -                    -
# AW10         PEX_TX10_N                       -                    -
# AV8          PEX_TX9_N                        -                    -
# AU6          PEX_TX8_N                        -                    -
# AY9          PEX_TX11_P                       -                    -
# AW11         PEX_TX10_P                       -                    -
# AV9          PEX_TX9_P                        -                    -
# AU7          PEX_TX8_P                        -                    -
# AU1          PEX_RX7_N                        -                    -
# AT3          PEX_RX6_N                        -                    -
# AR1          PEX_RX5_N                        -                    -
# AP3          PEX_RX4_N                        -                    -
# AU2          PEX_RX7_P                        -                    -
# AT4          PEX_RX6_P                        -                    -
# AR2          PEX_RX5_P                        -                    -
# AP4          PEX_RX4_P                        -                    -
# AU10         PEX_TX7_N                        -                    -
# AT8          PEX_TX6_N                        -                    -
# AR6          PEX_TX5_N                        -                    -
# AR10         PEX_TX4_N                        -                    -
# AU11         PEX_TX7_P                        -                    -
# AT9          PEX_TX6_P                        -                    -
# AR7          PEX_TX5_P                        -                    -
# AR11         PEX_TX4_P                        -                    -
# AN1          PEX_RX3_N                        -                    -
# AN5          PEX_RX2_N                        -                    -
# AM3          PEX_RX1_N                        -                    -
# AL1          PEX_RX0_N                        -                    -
# AN2          PEX_RX3_P                        -                    -
# AN6          PEX_RX2_P                        -                    -
# AM4          PEX_RX1_P                        -                    -
# AL2          PEX_RX0_P                        -                    -
# AP8          PEX_TX3_N                        -                    -
# AN10         PEX_TX2_N                        -                    -
# AM8          PEX_TX1_N                        -                    -
# AL10         PEX_TX0_N                        -                    -
# AP9          PEX_TX3_P                        -                    -
# AN11         PEX_TX2_P                        -                    -
# AM9          PEX_TX1_P                        -                    -
# AL11         PEX_TX0_P                        -                    -
# AU14         N45904402                        -                    -
# AL50         GND                              -                    -
# AK52         GND                              -                    -
# AJ54         GND                              -                    -
# AH52         GND                              -                    -
# AL49         GND                              -                    -
# AK51         GND                              -                    -
# AJ53         GND                              -                    -
# AH51         GND                              -                    -
# AG54         GND                              -                    -
# AF52         GND                              -                    -
# AE54         GND                              -                    -
# AE50         GND                              -                    -
# AG53         GND                              -                    -
# AF51         GND                              -                    -
# AE53         GND                              -                    -
# AE49         GND                              -                    -
# AL5          GND                              -                    -
# AK3          GND                              -                    -
# AJ1          GND                              -                    -
# AH3          GND                              -                    -
# AL6          GND                              -                    -
# AK4          GND                              -                    -
# AJ2          GND                              -                    -
# AH4          GND                              -                    -
# AE14         GND                              -                    -
# AG1          GND                              -                    -
# AF3          GND                              -                    -
# AE1          GND                              -                    -
# AE5          GND                              -                    -
# AG2          GND                              -                    -
# AF4          GND                              -                    -
# AE2          GND                              -                    -
# AE6          GND                              -                    -
# AD3          GND                              -                    -
# AC1          GND                              -                    -
# AC5          GND                              -                    -
# AB3          GND                              -                    -
# AD4          GND                              -                    -
# AC2          GND                              -                    -
# AC6          GND                              -                    -
# AB4          GND                              -                    -
# AA1          GND                              -                    -
# Y3           GND                              -                    -
# W1           GND                              -                    -
# V3           GND                              -                    -
# AA2          GND                              -                    -
# Y4           GND                              -                    -
# W2           GND                              -                    -
# V4           GND                              -                    -
# BF21         No Connect                       -                    -
# BF22         No Connect                       -                    -
# BH22         No Connect                       -                    -
# BG22         No Connect                       -                    -
# BJ21         No Connect                       -                    -
# BH21         No Connect                       -                    -
# BK21         No Connect                       -                    -
# BJ22         No Connect                       -                    -
# BK23         No Connect                       -                    -
# BK24         No Connect                       -                    -
# BL22         No Connect                       -                    -
# BL23         No Connect                       -                    -
# BG23         No Connect                       -                    -
# BF23         No Connect                       -                    -
# BH24         No Connect                       -                    -
# BG24         No Connect                       -                    -
# BG25         No Connect                       -                    -
# BF25         No Connect                       -                    -
# BF26         No Connect                       -                    -
# BF27         No Connect                       -                    -
# BG27         No Connect                       -                    -
# BG28         No Connect                       -                    -
# BJ23         No Connect                       -                    -
# BJ24         No Connect                       -                    -
# BH25         No Connect                       -                    -
# BH26         No Connect                       -                    -
# BJ27         No Connect                       -                    -
# BH27         No Connect                       -                    -
# BK25         No Connect                       -                    -
# BJ26         No Connect                       -                    -
# BL25         No Connect                       -                    -
# BK26         No Connect                       -                    -
# BK28         No Connect                       -                    -
# BJ28         No Connect                       -                    -
# BL26         No Connect                       -                    -
# BL27         No Connect                       -                    -
# BM27         No Connect                       -                    -
# BL28         No Connect                       -                    -
# BN27         No Connect                       -                    -
# BP27         No Connect                       -                    -
# BN22         No Connect                       -                    -
# BM22         No Connect                       -                    -
# BM23         No Connect                       -                    -
# BM24         No Connect                       -                    -
# BN25         No Connect                       -                    -
# BM25         No Connect                       -                    -
# BP24         No Connect                       -                    -
# BN24         No Connect                       -                    -
# BP26         No Connect                       -                    -
# BN26         No Connect                       -                    -
# BP22         No Connect                       -                    -
# BP23         No Connect                       -                    -
# BE51         No Connect                       -                    -
# BD51         No Connect                       -                    -
# BE50         No Connect                       -                    -
# BE49         No Connect                       -                    -
# BF48         No Connect                       -                    -
# BF47         No Connect                       -                    -
# BF52         No Connect                       -                    -
# BF51         No Connect                       -                    -
# BG50         No Connect                       -                    -
# BF50         No Connect                       -                    -
# BG49         No Connect                       -                    -
# BG48         No Connect                       -                    -
# BG47         No Connect                       -                    -
# BF53         No Connect                       -                    -
# BE54         No Connect                       -                    -
# BE53         No Connect                       -                    -
# BG54         No Connect                       -                    -
# BG53         No Connect                       -                    -
# BJ54         No Connect                       -                    -
# BH54         No Connect                       -                    -
# BK54         No Connect                       -                    -
# BK53         No Connect                       -                    -
# BH52         No Connect                       -                    -
# BG52         No Connect                       -                    -
# BJ53         No Connect                       -                    -
# BJ52         No Connect                       -                    -
# BH50         No Connect                       -                    -
# BH49         No Connect                       -                    -
# BJ51         No Connect                       -                    -
# BH51         No Connect                       -                    -
# BJ47         No Connect                       -                    -
# BH47         No Connect                       -                    -
# BJ49         No Connect                       -                    -
# BJ48         No Connect                       -                    -
# BK51         No Connect                       -                    -
# BK50         No Connect                       -                    -
# BK49         No Connect                       -                    -
# BK48         No Connect                       -                    -
# BL48         No Connect                       -                    -
# BL50         No Connect                       -                    -
# BL53         No Connect                       -                    -
# BL52         No Connect                       -                    -
# BM52         No Connect                       -                    -
# BL51         No Connect                       -                    -
# BM50         No Connect                       -                    -
# BM49         No Connect                       -                    -
# BN49         No Connect                       -                    -
# BM48         No Connect                       -                    -
# BN51         No Connect                       -                    -
# BN50         No Connect                       -                    -
# BP49         No Connect                       -                    -
# BP48         No Connect                       -                    -
# BE44         No Connect                       -                    -
# BE43         No Connect                       -                    -
# BD42         No Connect                       -                    -
# BC42         No Connect                       -                    -
# BF43         No Connect                       -                    -
# BF42         No Connect                       -                    -
# BE41         No Connect                       -                    -
# BD41         No Connect                       -                    -
# BH41         No Connect                       -                    -
# BG44         No Connect                       -                    -
# BG42         No Connect                       -                    -
# BJ46         No Connect                       -                    -
# BH45         No Connect                       -                    -
# BH44         No Connect                       -                    -
# BJ44         No Connect                       -                    -
# BJ43         No Connect                       -                    -
# BK46         No Connect                       -                    -
# BK45         No Connect                       -                    -
# BL43         No Connect                       -                    -
# BL42         No Connect                       -                    -
# BM47         No Connect                       -                    -
# BL47         No Connect                       -                    -
# BM42         No Connect                       -                    -
# BM43         No Connect                       -                    -
# BN45         No Connect                       -                    -
# BM45         No Connect                       -                    -
# BN44         No Connect                       -                    -
# BM44         No Connect                       -                    -
# BP46         No Connect                       -                    -
# BN46         No Connect                       -                    -
# BP44         No Connect                       -                    -
# BP43         No Connect                       -                    -
# BP42         No Connect                       -                    -
# BF33         No Connect                       -                    -
# BK30         No Connect                       -                    -
# BG32         No Connect                       -                    -
# BH30         No Connect                       -                    -
# BH29         No Connect                       -                    -
# BK29         No Connect                       -                    -
# BG33         No Connect                       -                    -
# BH34         No Connect                       -                    -
# BF35         No Connect                       -                    -
# BK34         No Connect                       -                    -
# BG35         No Connect                       -                    -
# BG34         No Connect                       -                    -
# BJ34         No Connect                       -                    -
# BJ32         No Connect                       -                    -
# BL33         No Connect                       -                    -
# BK33         No Connect                       -                    -
# BL31         No Connect                       -                    -
# BK31         No Connect                       -                    -
# BM35         No Connect                       -                    -
# BL35         No Connect                       -                    -
# BM33         No Connect                       -                    -
# BL32         No Connect                       -                    -
# BP34         No Connect                       -                    -
# BN34         No Connect                       -                    -
# BN35         No Connect                       -                    -
# BM34         No Connect                       -                    -
# BP33         No Connect                       -                    -
# BM32         No Connect                       -                    -
# BP32         No Connect                       -                    -
# BN32         No Connect                       -                    -
# BM30         No Connect                       -                    -
# BL30         No Connect                       -                    -
# BN30         No Connect                       -                    -
# BN29         No Connect                       -                    -
# BP31         No Connect                       -                    -
# BN31         No Connect                       -                    -
# BP29         No Connect                       -                    -
# BP28         No Connect                       -                    -
# BM29         No Connect                       -                    -
# BM28         No Connect                       -                    -
# A16          No Connect                       -                    -
# B16          No Connect                       -                    -
# A18          No Connect                       -                    -
# A19          No Connect                       -                    -
# A20          No Connect                       -                    -
# A21          No Connect                       -                    -
# B17          No Connect                       -                    -
# B18          No Connect                       -                    -
# B20          No Connect                       -                    -
# B21          No Connect                       -                    -
# C17          No Connect                       -                    -
# C18          No Connect                       -                    -
# C19          No Connect                       -                    -
# C20          No Connect                       -                    -
# D19          No Connect                       -                    -
# D20          No Connect                       -                    -
# D16          No Connect                       -                    -
# D17          No Connect                       -                    -
# D21          No Connect                       -                    -
# E21          No Connect                       -                    -
# E16          No Connect                       -                    -
# F16          No Connect                       -                    -
# E18          No Connect                       -                    -
# E19          No Connect                       -                    -
# E17          No Connect                       -                    -
# F18          No Connect                       -                    -
# F19          No Connect                       -                    -
# F20          No Connect                       -                    -
# G17          No Connect                       -                    -
# G18          No Connect                       -                    -
# F21          No Connect                       -                    -
# G21          No Connect                       -                    -
# H18          No Connect                       -                    -
# H19          No Connect                       -                    -
# G20          No Connect                       -                    -
# H20          No Connect                       -                    -
# G16          No Connect                       -                    -
# H17          No Connect                       -                    -
# J16          No Connect                       -                    -
# J17          No Connect                       -                    -
# J19          No Connect                       -                    -
# J20          No Connect                       -                    -
# J21          No Connect                       -                    -
# K21          No Connect                       -                    -
# K18          No Connect                       -                    -
# K19          No Connect                       -                    -
# L20          No Connect                       -                    -
# L21          No Connect                       -                    -
# L18          No Connect                       -                    -
# L19          No Connect                       -                    -
# K16          No Connect                       -                    -
# K17          No Connect                       -                    -
# A8           No Connect                       -                    -
# A9           No Connect                       -                    -
# A10          No Connect                       -                    -
# A11          No Connect                       -                    -
# A13          No Connect                       -                    -
# B13          No Connect                       -                    -
# B12          No Connect                       -                    -
# C12          No Connect                       -                    -
# B10          No Connect                       -                    -
# B11          No Connect                       -                    -
# C9           No Connect                       -                    -
# C10          No Connect                       -                    -
# C13          No Connect                       -                    -
# C14          No Connect                       -                    -
# A14          No Connect                       -                    -
# A15          No Connect                       -                    -
# B15          No Connect                       -                    -
# C15          No Connect                       -                    -
# D14          No Connect                       -                    -
# D15          No Connect                       -                    -
# E14          No Connect                       -                    -
# F15          No Connect                       -                    -
# F13          No Connect                       -                    -
# F14          No Connect                       -                    -
# D12          No Connect                       -                    -
# E13          No Connect                       -                    -
# E11          No Connect                       -                    -
# F11          No Connect                       -                    -
# D11          No Connect                       -                    -
# E12          No Connect                       -                    -
# D9           No Connect                       -                    -
# D10          No Connect                       -                    -
# E9           No Connect                       -                    -
# F9           No Connect                       -                    -
# F10          No Connect                       -                    -
# G11          No Connect                       -                    -
# G10          No Connect                       -                    -
# H10          No Connect                       -                    -
# H9           No Connect                       -                    -
# G12          No Connect                       -                    -
# G13          No Connect                       -                    -
# H14          No Connect                       -                    -
# H12          No Connect                       -                    -
# H13          No Connect                       -                    -
# G15          No Connect                       -                    -
# H15          No Connect                       -                    -
# J11          No Connect                       -                    -
# J12          No Connect                       -                    -
# J14          No Connect                       -                    -
# J15          No Connect                       -                    -
# K13          No Connect                       -                    -
# K14          No Connect                       -                    -
# BF1          No Connect                       -                    -
# BE1          No Connect                       -                    -
# BE3          No Connect                       -                    -
# BE4          No Connect                       -                    -
# BE5          No Connect                       -                    -
# BE6          No Connect                       -                    -
# BF2          No Connect                       -                    -
# BF3          No Connect                       -                    -
# BG2          No Connect                       -                    -
# BG3          No Connect                       -                    -
# BG4          No Connect                       -                    -
# BG5          No Connect                       -                    -
# BF5          No Connect                       -                    -
# BF6          No Connect                       -                    -
# BF7          No Connect                       -                    -
# BF8          No Connect                       -                    -
# BG7          No Connect                       -                    -
# BG8          No Connect                       -                    -
# BJ7          No Connect                       -                    -
# BH7          No Connect                       -                    -
# BK8          No Connect                       -                    -
# BJ8          No Connect                       -                    -
# BH4          No Connect                       -                    -
# BH5          No Connect                       -                    -
# BJ6          No Connect                       -                    -
# BH6          No Connect                       -                    -
# BK4          No Connect                       -                    -
# BK5          No Connect                       -                    -
# BK3          No Connect                       -                    -
# BJ4          No Connect                       -                    -
# BJ2          No Connect                       -                    -
# BJ3          No Connect                       -                    -
# BH1          No Connect                       -                    -
# BH2          No Connect                       -                    -
# BK1          No Connect                       -                    -
# BJ1          No Connect                       -                    -
# BL2          No Connect                       -                    -
# BL3          No Connect                       -                    -
# BK6          No Connect                       -                    -
# BL5          No Connect                       -                    -
# BM3          No Connect                       -                    -
# BM4          No Connect                       -                    -
# BM5          No Connect                       -                    -
# BL6          No Connect                       -                    -
# BM7          No Connect                       -                    -
# BL7          No Connect                       -                    -
# BN4          No Connect                       -                    -
# BN5          No Connect                       -                    -
# BN6          No Connect                       -                    -
# BN7          No Connect                       -                    -
# BP6          No Connect                       -                    -
# BP7          No Connect                       -                    -
# BE9          No Connect                       -                    -
# BE10         No Connect                       -                    -
# BF10         No Connect                       -                    -
# BE11         No Connect                       -                    -
# BF11         No Connect                       -                    -
# BF12         No Connect                       -                    -
# BG9          No Connect                       -                    -
# BG10         No Connect                       -                    -
# BG12         No Connect                       -                    -
# BG13         No Connect                       -                    -
# BH9          No Connect                       -                    -
# BH10         No Connect                       -                    -
# BH11         No Connect                       -                    -
# BH15         No Connect                       -                    -
# BJ12         No Connect                       -                    -
# BJ13         No Connect                       -                    -
# BK13         No Connect                       -                    -
# BJ14         No Connect                       -                    -
# BK9          No Connect                       -                    -
# BJ9          No Connect                       -                    -
# BL8          No Connect                       -                    -
# BN9          No Connect                       -                    -
# BP9          No Connect                       -                    -
# BL11         No Connect                       -                    -
# BM15         No Connect                       -                    -
# BL15         No Connect                       -                    -
# BM13         No Connect                       -                    -
# BN15         No Connect                       -                    -
# BN12         No Connect                       -                    -
# BP13         No Connect                       -                    -
# BP14         No Connect                       -                    -
# BP11         No Connect                       -                    -
# BP12         No Connect                       -                    -
# AV43         No Connect                       -                    -
# AV42         No Connect                       -                    -
# AT43         No Connect                       -                    -
# AT42         No Connect                       -                    -
# AN41         No Connect                       -                    -
# AN40         No Connect                       -                    -
# AM43         No Connect                       -                    -
# AM42         No Connect                       -                    -
# AJ41         No Connect                       -                    -
# AJ40         No Connect                       -                    -
# AH43         No Connect                       -                    -
# AH42         No Connect                       -                    -
# AK47         No Connect                       -                    -
# AJ49         No Connect                       -                    -
# AJ45         No Connect                       -                    -
# AH47         No Connect                       -                    -
# AK46         No Connect                       -                    -
# AJ48         No Connect                       -                    -
# AJ44         No Connect                       -                    -
# AH46         No Connect                       -                    -
# AG41         No Connect                       -                    -
# AG40         No Connect                       -                    -
# AF43         No Connect                       -                    -
# AF42         No Connect                       -                    -
# AG49         No Connect                       -                    -
# AG45         No Connect                       -                    -
# AF47         No Connect                       -                    -
# AE45         No Connect                       -                    -
# AG48         No Connect                       -                    -
# AG44         No Connect                       -                    -
# AF46         No Connect                       -                    -
# AE44         No Connect                       -                    -
# AC41         No Connect                       -                    -
# AC40         No Connect                       -                    -
# AA41         No Connect                       -                    -
# AA40         No Connect                       -                    -
# AV12         No Connect                       -                    -
# AV13         No Connect                       -                    -
# AT12         No Connect                       -                    -
# AT13         No Connect                       -                    -
# AN14         No Connect                       -                    -
# AN15         No Connect                       -                    -
# AM12         No Connect                       -                    -
# AM13         No Connect                       -                    -
# AJ14         No Connect                       -                    -
# AJ15         No Connect                       -                    -
# AH12         No Connect                       -                    -
# AH13         No Connect                       -                    -
# AK8          No Connect                       -                    -
# AJ6          No Connect                       -                    -
# AJ10         No Connect                       -                    -
# AH8          No Connect                       -                    -
# AK9          No Connect                       -                    -
# AJ7          No Connect                       -                    -
# AJ11         No Connect                       -                    -
# AH9          No Connect                       -                    -
# AG14         No Connect                       -                    -
# AG15         No Connect                       -                    -
# AF12         No Connect                       -                    -
# AF13         No Connect                       -                    -
# AG6          No Connect                       -                    -
# AG10         No Connect                       -                    -
# AF8          No Connect                       -                    -
# AE10         No Connect                       -                    -
# AG7          No Connect                       -                    -
# AG11         No Connect                       -                    -
# AF9          No Connect                       -                    -
# AE11         No Connect                       -                    -
# AD12         No Connect                       -                    -
# AD13         No Connect                       -                    -
# AC14         No Connect                       -                    -
# AC15         No Connect                       -                    -
# AD8          No Connect                       -                    -
# AC10         No Connect                       -                    -
# AB8          No Connect                       -                    -
# AA6          No Connect                       -                    -
# AD9          No Connect                       -                    -
# AC11         No Connect                       -                    -
# AB9          No Connect                       -                    -
# AA7          No Connect                       -                    -
# AB12         No Connect                       -                    -
# AB13         No Connect                       -                    -
# AA14         No Connect                       -                    -
# AA15         No Connect                       -                    -
# AA10         No Connect                       -                    -
# Y8           No Connect                       -                    -
# W6           No Connect                       -                    -
# W10          No Connect                       -                    -
# AA11         No Connect                       -                    -
# Y9           No Connect                       -                    -
# W7           No Connect                       -                    -
# W11          No Connect                       -                    -
