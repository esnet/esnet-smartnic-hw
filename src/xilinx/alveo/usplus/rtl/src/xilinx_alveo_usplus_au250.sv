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
    // Parameters
    // =========================================================================
    localparam bit INCLUDE_CMS = 0;

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
    generate
        if (INCLUDE_CMS) begin : g__cms
            // TODO: add CMS instance
        end : g__cms
        else begin : g__no_cms
            // Release module reset, enable normal power, and deselect the I2C interface.
            assign qsfp_resetl  = '1;
            assign qsfp_lpmode  = '0;
            assign qsfp_modsell = '1;
            // UART idle level while card management is disabled.
            assign satellite_uart_0_txd = 1'b1;

            // Tie off unused CMS AXI-L interface
            axi4l_intf_peripheral_term i_axi4l_intf_peripheral_term (.axi4l_if (alveo_hw_if.axil_cms));

        end : g__no_cms
    endgenerate

endmodule : xilinx_alveo_usplus_au250
