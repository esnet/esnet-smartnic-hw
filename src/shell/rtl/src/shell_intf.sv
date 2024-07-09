interface shell_intf;
    // Imports
    import shell_pkg::*;

    // Clock/reset
    wire logic clk;
    wire logic srst;

    // Aux clocks
    wire logic clk_100mhz;

    // CMAC0
    axi4s_intf #(
        .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
        .TID_T         ( cmac_rx_axis_tid_t ),
        .TDEST_T       ( cmac_rx_axis_tdest_t ),
        .TUSER_T       ( cmac_rx_axis_tuser_t )
    ) axis_cmac0_rx ();

    axi4s_intf #(
        .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
        .TID_T         ( cmac_tx_axis_tid_t ),
        .TDEST_T       ( cmac_tx_axis_tdest_t ),
        .TUSER_T       ( cmac_tx_axis_tuser_t )
    ) axis_cmac0_tx ();

    // CMAC1
    axi4s_intf #(
        .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
        .TID_T         ( cmac_rx_axis_tid_t ),
        .TDEST_T       ( cmac_rx_axis_tdest_t ),
        .TUSER_T       ( cmac_rx_axis_tuser_t )
    ) axis_cmac1_rx ();

    axi4s_intf #(
        .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
        .TID_T         ( cmac_tx_axis_tid_t ),
        .TDEST_T       ( cmac_tx_axis_tdest_t ),
        .TUSER_T       ( cmac_tx_axis_tuser_t )
    ) axis_cmac1_tx ();

    // DMA (streaming)
    axi4s_intf #(
        .DATA_BYTE_WID ( DMA_ST_DATA_BYTE_WID ),
        .TID_T         ( dma_st_h2c_axis_tid_t),
        .TDEST_T       ( dma_st_h2c_axis_tdest_t),
        .TUSER_T       ( dma_st_h2c_axis_tuser_t)
    ) axis_h2c ();

    axi4s_intf #(
        .DATA_BYTE_WID ( DMA_ST_DATA_BYTE_WID ),
        .TID_T         ( dma_st_c2h_axis_tid_t),
        .TDEST_T       ( dma_st_c2h_axis_tdest_t),
        .TUSER_T       ( dma_st_c2h_axis_tuser_t)
    ) axis_c2h ();

    // AXI-L (control)
    axi4l_intf axil_if ();
    
    modport shell (
        output clk,
        output srst,
        output clk_100mhz
    );

    modport core (
        input clk,
        input srst,
        input clk_100mhz
    );

endinterface : shell_intf
