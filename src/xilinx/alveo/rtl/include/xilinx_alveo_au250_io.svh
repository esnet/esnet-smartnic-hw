    // QSFP
    input  wire logic [NUM_QSFP-1:0]      qsfp_refclk_p,
    input  wire logic [NUM_QSFP-1:0]      qsfp_refclk_n,
    input  wire logic [NUM_QSFP-1:0][3:0] qsfp_rxp,
    input  wire logic [NUM_QSFP-1:0][3:0] qsfp_rxn,
    output wire logic [NUM_QSFP-1:0][3:0] qsfp_txp,
    output wire logic [NUM_QSFP-1:0][3:0] qsfp_txn,

    output wire logic [NUM_QSFP-1:0]      qsfp_resetl,
    input  wire logic [NUM_QSFP-1:0]      qsfp_modprsl,
    input  wire logic [NUM_QSFP-1:0]      qsfp_intl,
    output wire logic [NUM_QSFP-1:0]      qsfp_lpmode,
    output wire logic [NUM_QSFP-1:0]      qsfp_modsell,

    // PCIe
    input  wire logic                     pcie_refclk_p,
    input  wire logic                     pcie_refclk_n,
    input  wire logic [PCIE_LINK_WID-1:0] pcie_rxp,
    input  wire logic [PCIE_LINK_WID-1:0] pcie_rxn,
    output wire logic [PCIE_LINK_WID-1:0] pcie_txp,
    output wire logic [PCIE_LINK_WID-1:0] pcie_txn,
    input  wire logic                     pcie_rstn,

    // Satellite controller
    input  wire logic                     satellite_uart_0_rxd,
    output wire logic                     satellite_uart_0_txd,
    input  wire logic [3:0]               satellite_gpio
