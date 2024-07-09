module xilinx_alveo_au280
    import xilinx_alveo_au280_pkg::*;
(
    // I/O (AU280)
    `include "xilinx_alveo_au280_io.svh"
    ,
    // Alveo logic
    xilinx_alveo_hw_intf.hw  alveo_hw_if
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

    // =========================================================================
    // HBM cattrip
    // =========================================================================
    // This pin must be tied to 0; otherwise the board might be unrecoverable
    // after programming
    OBUF i_obuf_hbm_cattrip (.I(1'b0), .O(hbm_cattrip));

    // =========================================================================
    // Card management subsystem
    // =========================================================================
    generate
        if (INCLUDE_CMS) begin : g__cms
            // TODO: add CMS instance
        end : g__cms
        else begin : g__no_cms
            // Tie off unused CMS AXI-L interface
            axi4l_intf_peripheral_term i_axi4l_intf_peripheral_term (.axi4l_if (alveo_hw_if.axil_cms));

        end : g__no_cms
    endgenerate

endmodule : xilinx_alveo_au280
