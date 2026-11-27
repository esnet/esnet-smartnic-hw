module xilinx_alveo_usplus_au55c
    import xilinx_alveo_usplus_au55c_pkg::*;
(
    // Top-level I/O (AU55C)
    `include "xilinx_alveo_usplus_au55c_io.svh"
    ,
    // Alveo logic
    xilinx_alveo_usplus_hw_intf.hw  alveo_hw_if
);

    // =========================================================================
    // HBM cattrip
    // =========================================================================
    // This pin must be tied to 0; otherwise the board might be unrecoverable
    // after programming
    OBUF i_obuf_hbm_cattrip (.I(1'b0), .O(hbm_cattrip));

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
    IBUF i_ibuf_pcie_rstn (.I(pcie_rstn), .O(alveo_hw_if.pcie_rstn));
    assign alveo_hw_if.pcie_refclk_p = pcie_refclk_p;
    assign alveo_hw_if.pcie_refclk_n = pcie_refclk_n;
    assign alveo_hw_if.pcie_rxp = pcie_rxp;
    assign alveo_hw_if.pcie_rxn = pcie_rxn;
    assign pcie_txp = alveo_hw_if.pcie_txp;
    assign pcie_txn = alveo_hw_if.pcie_txn;

    // =========================================================================
    // 100MHz SYS_CLK (free-running)
    // =========================================================================
    IBUFDS sys_clk_ibuf_inst (.I(sys_clk_3_p), .IB(sys_clk_3_n), .O(alveo_hw_if.sys_clk_100mhz));

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
        .qsfp_modprsl ( '1 ),
        .qsfp_intl    ( '1 ),
        .qsfp_resetl  ( ),
        .qsfp_lpmode  ( ),
        .qsfp_modsell ( ),
        .irq ( ) // Software polls the CMS register window.
    );

endmodule : xilinx_alveo_usplus_au55c
