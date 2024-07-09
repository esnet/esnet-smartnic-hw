module xilinx_alveo_dma_st
    import xilinx_alveo_pkg::*;
#(
    parameter int PCIE_LINK_WID = 16
) (
    // From DMA controller
    axi4s_intf.tx          axis_dma_h2c,
    axi4s_intf.rx_async    axis_dma_c2h,
    // From/to core
    // -- AXI-L
    axi4l_intf.controller  axil_if,
    // -- AXI-S (streaming DMA)
    axi4s_intf.tx          axis_h2c,
    axi4s_intf.rx_async    axis_c2h

);
    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_qdma_pkg::*;

    // =========================================================================
    // H2C Stream
    // =========================================================================
    axi4s_intf_connector i_axi4s_intf_connector__h2c (
        .axi4s_from_tx ( axis_dma_h2c ),
        .axi4s_to_rx   ( axis_h2c )
    );
    // =========================================================================
    // C2H Stream
    // =========================================================================
    axi4s_intf_connector i_axi4s_intf_connector__c2h (
        .axi4s_from_tx ( axis_c2h ),
        .axi4s_to_rx   ( axis_dma_c2h )
    );
    
endmodule : xilinx_alveo_dma_st
