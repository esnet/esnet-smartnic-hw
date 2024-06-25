interface xilinx_alveo_hw_intf #(
    parameter int NUM_QSFP = 2,
    parameter int PCIE_LINK_WID = 16
);
    // -- QSFPs
    wire logic [NUM_QSFP-1:0]       qsfp_refclk_p;
    wire logic [NUM_QSFP-1:0]       qsfp_refclk_n;
    wire logic [NUM_QSFP-1:0][3:0]  qsfp_rxp;
    wire logic [NUM_QSFP-1:0][3:0]  qsfp_rxn;
    wire logic [NUM_QSFP-1:0][3:0]  qsfp_txp;
    wire logic [NUM_QSFP-1:0][3:0]  qsfp_txn;
    // -- PCIe
    wire logic                      pcie_rstn;
    wire logic                      pcie_refclk_p;
    wire logic                      pcie_refclk_n;
    wire logic[PCIE_LINK_WID-1:0]   pcie_rxp;
    wire logic[PCIE_LINK_WID-1:0]   pcie_rxn;
    wire logic[PCIE_LINK_WID-1:0]   pcie_txp;
    wire logic[PCIE_LINK_WID-1:0]   pcie_txn;
    // Clocks
    wire logic                      clk_100mhz;
    wire logic                      clk_125mhz;
    wire logic                      clk_250mhz;
    wire logic                      clk_333mhz;
    // Board-specific CMS (card management subsystem) control interface
    axi4l_intf                      axil_cms ();

    modport hw (
        output qsfp_refclk_p,
        output qsfp_refclk_n,
        output qsfp_rxp,
        output qsfp_rxn,
        input  qsfp_txp,
        input  qsfp_txn,
        output pcie_rstn,
        output pcie_refclk_p,
        output pcie_refclk_n,
        output pcie_rxp,
        output pcie_rxn,
        input  pcie_txp,
        input  pcie_txn,
        input  clk_100mhz,
        input  clk_125mhz,
        input  clk_250mhz,
        input  clk_333mhz
    );

    modport alveo (
        input  qsfp_refclk_p,
        input  qsfp_refclk_n,
        input  qsfp_rxp,
        input  qsfp_rxn,
        output qsfp_txp,
        output qsfp_txn,
        input  pcie_rstn,
        input  pcie_refclk_p,
        input  pcie_refclk_n,
        input  pcie_rxp,
        input  pcie_rxn,
        output pcie_txp,
        output pcie_txn,
        output clk_100mhz,
        output clk_125mhz,
        output clk_250mhz,
        output clk_333mhz
    );

endinterface : xilinx_alveo_hw_intf

