module xilinx_alveo_usplus_au250
    import xilinx_alveo_usplus_au250_pkg::*;
(
    // Top-level I/O (AU250)
    `include "xilinx_alveo_usplus_au250_io.svh"
    ,
    // Alveo logic
    xilinx_alveo_usplus_hw_intf.hw  alveo_hw_if
);

    // =========================================================================
    // Port assignments
    // =========================================================================
    // QSFP
    assign alveo_hw_if.qsfp_refclk_p = qsfp_refclk_p;
    assign alveo_hw_if.qsfp_refclk_n = qsfp_refclk_n;
    assign alveo_hw_if.qsfp_rxp = qsfp_rxp;
    assign alveo_hw_if.qsfp_rxn = qsfp_rxn;
    assign qsfp_txp = alveo_hw_if.qsfp_txp;
    assign qsfp_txn = alveo_hw_if.qsfp_txn;
    // PCIe
    assign alveo_hw_if.pcie_rstn = pcie_rstn;
    assign alveo_hw_if.pcie_refclk_p = pcie_refclk_p;
    assign alveo_hw_if.pcie_refclk_n = pcie_refclk_n;
    assign alveo_hw_if.pcie_rxp = pcie_rxp;
    assign alveo_hw_if.pcie_rxn = pcie_rxn;
    assign pcie_txp = alveo_hw_if.pcie_txp;
    assign pcie_txn = alveo_hw_if.pcie_txn;

    // Free-running system clock (300MHz to 100MHz)
    wire logic clk1_300mhz;
    IBUFDS sys_clk_ibuf_inst (.I(clk1_300mhz_p), .IB(clk1_300mhz_n), .O(clk1_300mhz));
    xilinx_alveo_usplus_clk_100mhz i_xilinx_alveo_usplus_clk_100mhz (
        .clk_in1  ( clk1_300mhz ),
        .clk_out1 ( alveo_hw_if.sys_clk_100mhz )
    );

    // =========================================================================
    // Card management subsystem
    // =========================================================================
    xilinx_alveo_usplus_cms i_xilinx_alveo_usplus_cms (
        .axil_if            ( alveo_hw_if.axil_cms ),
        .satellite_uart_rxd ( satellite_uart_0_rxd ),
        .satellite_uart_txd ( satellite_uart_0_txd ),
        .satellite_gpio     ( satellite_gpio ),
        // HBM monitoring remains disabled until HBM controllers supply these.
        .hbm_temp_1  ( 7'd0 ),
        .hbm_temp_2  ( 7'd0 ),
        .hbm_cattrip ( 1'b0 ),
        .qsfp_modprsl ( qsfp_modprsl ),
        .qsfp_intl    ( qsfp_intl ),
        .qsfp_resetl  ( qsfp_resetl ),
        .qsfp_lpmode  ( qsfp_lpmode ),
        .qsfp_modsell ( qsfp_modsell ),
        .irq ( ) // Software polls the CMS register window.
    );

endmodule : xilinx_alveo_usplus_au250
