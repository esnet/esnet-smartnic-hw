module xilinx_alveo_host
    import xilinx_alveo_pkg::*;
#(
    parameter int PCIE_LINK_WID = 16
) (
    // From/to pins
    // -- PCIe
    input  logic                     pcie_rstn,
    input  logic                     pcie_refclk_p,
    input  logic                     pcie_refclk_n,
    input  logic [PCIE_LINK_WID-1:0] pcie_rxp,
    input  logic [PCIE_LINK_WID-1:0] pcie_rxn,
    output logic [PCIE_LINK_WID-1:0] pcie_txp,
    output logic [PCIE_LINK_WID-1:0] pcie_txn,
    // Clocks (output)
    output logic                     clk_125mhz,
    output logic                     clk_250mhz,
    // -- AXI-L (Controller)
    axi4l_intf.controller            axil_if,
    // -- AXI-L (Peripheral)
    axi4l_intf.peripheral            axil_qdma,
    // -- DMA (streaming)
    axi4s_intf.tx                    axis_h2c,
    axi4s_intf.rx_async              axis_c2h
);

    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_qdma_pkg::*;

    // =========================================================================
    // Signals
    // =========================================================================
    logic __pcie_rstn;

    // =========================================================================
    // Interfaces
    // =========================================================================
    axi4l_intf #() __axil_if__250mhz ();

    // =========================================================================
    // PCIe reset input buffer
    // =========================================================================
    IBUF i_ibuf_pcie_rstn (.I(pcie_rstn), .O(__pcie_rstn));

    // =========================================================================
    // QDMA IP
    // =========================================================================
    xilinx_qdma_wrapper #(
        .PCIE_LINK_WID   ( PCIE_LINK_WID )
    ) i_xilinx_alveo_qdma (
        .pcie_rstn ( __pcie_rstn ),
        .pcie_refclk_p,
        .pcie_refclk_n,
        .pcie_rxp,
        .pcie_rxn,
        .pcie_txp,
        .pcie_txn,
        .axil_if ( __axil_if__250mhz ),
        .axis_h2c,
        .axis_c2h
    );
     
    // =========================================================================
    // AXI-L ILA (250MHz domain)
    // =========================================================================
    xilinx_alveo_axil_ila i_xilinx_alveo_axil_ila__250mhz (
        .clk     ( __axil_if__250mhz.aclk ),
        .probe0  ( __axil_if__250mhz.wready ),
        .probe1  ( __axil_if__250mhz.awaddr ),
        .probe2  ( __axil_if__250mhz.bresp ),
        .probe3  ( __axil_if__250mhz.bvalid ),
        .probe4  ( __axil_if__250mhz.bready ),
        .probe5  ( __axil_if__250mhz.araddr ),
        .probe6  ( __axil_if__250mhz.rready ),
        .probe7  ( __axil_if__250mhz.wvalid ),
        .probe8  ( __axil_if__250mhz.arvalid ),
        .probe9  ( __axil_if__250mhz.arready ),
        .probe10 ( __axil_if__250mhz.rdata ),
        .probe11 ( __axil_if__250mhz.awvalid ),
        .probe12 ( __axil_if__250mhz.awready ),
        .probe13 ( __axil_if__250mhz.rresp ),
        .probe14 ( __axil_if__250mhz.wdata ),
        .probe15 ( __axil_if__250mhz.wstrb ),
        .probe16 ( __axil_if__250mhz.rvalid ),
        .probe17 ( __axil_if__250mhz.arprot ),
        .probe18 ( __axil_if__250mhz.awprot )
    );

    // =========================================================================
    // AXI-L clock divider (250MHz to 125MHz)
    // =========================================================================
    assign clk_250mhz = __axil_if__250mhz.aclk;

    xilinx_alveo_clk_axil i_xilinx_alveo_clk_axil (
        .clk_in1  ( clk_250mhz ),
        .clk_out1 ( clk_125mhz )
    );

    // =========================================================================
    // AXI-L synchronizer (250Mhz to 125MHz)
    // =========================================================================
    axi4l_intf_cdc i_axi4l_intf_cdc (
        .axi4l_if_from_controller ( __axil_if__250mhz ),
        .clk_to_peripheral        ( clk_125mhz ),
        .axi4l_if_to_peripheral   ( axil_if )
    );

    // TEMP: Tie off unused AXI-L interface
    axi4l_intf_peripheral_term (.axi4l_if(axil_qdma));

    // =========================================================================
    // AXI-L ILA (125MHz domain)
    // =========================================================================
    xilinx_alveo_axil_ila i_xilinx_alveo_axil_ila__125mhz (
        .clk     ( axil_if.aclk ),
        .probe0  ( axil_if.wready ),
        .probe1  ( axil_if.awaddr ),
        .probe2  ( axil_if.bresp ),
        .probe3  ( axil_if.bvalid ),
        .probe4  ( axil_if.bready ),
        .probe5  ( axil_if.araddr ),
        .probe6  ( axil_if.rready ),
        .probe7  ( axil_if.wvalid ),
        .probe8  ( axil_if.arvalid ),
        .probe9  ( axil_if.arready ),
        .probe10 ( axil_if.rdata ),
        .probe11 ( axil_if.awvalid ),
        .probe12 ( axil_if.awready ),
        .probe13 ( axil_if.rresp ),
        .probe14 ( axil_if.wdata ),
        .probe15 ( axil_if.wstrb ),
        .probe16 ( axil_if.rvalid ),
        .probe17 ( axil_if.arprot ),
        .probe18 ( axil_if.awprot )
    );

endmodule : xilinx_alveo_host
