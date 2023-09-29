    // QSFP
    input  wire [NUM_CMAC-1:0]      qsfp_refclk_p,
    input  wire [NUM_CMAC-1:0]      qsfp_refclk_n,
    input  wire [NUM_CMAC-1:0][3:0] qsfp_rxp,
    input  wire [NUM_CMAC-1:0][3:0] qsfp_rxn,
    output wire [NUM_CMAC-1:0][3:0] qsfp_txp,
    output wire [NUM_CMAC-1:0][3:0] qsfp_txn,

    output wire [NUM_CMAC-1:0]      qsfp_resetl,
    input  wire [NUM_CMAC-1:0]      qsfp_modprsl,
    input  wire [NUM_CMAC-1:0]      qsfp_intl,
    output wire [NUM_CMAC-1:0]      qsfp_lpmode,
    output wire [NUM_CMAC-1:0]      qsfp_modsell,

    // PCIe
    input  wire                     pcie_refclk_p,
    input  wire                     pcie_refclk_n,
    input  wire [PCIE_LINK_WID-1:0] pcie_rxp,
    input  wire [PCIE_LINK_WID-1:0] pcie_rxn,
    output wire [PCIE_LINK_WID-1:0] pcie_txp,
    output wire [PCIE_LINK_WID-1:0] pcie_txn,
    input  wire                     pcie_rstn,

    // Satellite controller
    input  wire                     satellite_uart_0_rxd,
    output wire                     satellite_uart_0_txd,
    input  wire [3:0]               satellite_gpio
