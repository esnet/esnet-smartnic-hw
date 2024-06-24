interface shell_intf;
    // Imports
    import shell_pkg::*;

    // Parameters (make explicit to allow referencing by instantiating modules)
    localparam int NUM_CMAC = shell_pkg::NUM_CMAC;
    localparam int NUM_DMA_ST = shell_pkg::NUM_DMA_ST;

    // Clock/reset
    wire logic clk;
    wire logic srst;

    // Aux clocks
    wire logic clk_100mhz;

    // CMAC
    axi4s_intf #(
        .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
        .TID_T         ( cmac_rx_axis_tid_t ),
        .TDEST_T       ( cmac_rx_axis_tdest_t ),
        .TUSER_T       ( cmac_rx_axis_tuser_t )
    ) axis_cmac_rx [NUM_CMAC] ();

    axi4s_intf #(
        .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
        .TID_T         ( cmac_tx_axis_tid_t ),
        .TDEST_T       ( cmac_tx_axis_tdest_t ),
        .TUSER_T       ( cmac_tx_axis_tuser_t )
    ) axis_cmac_tx [NUM_CMAC] ();
    
    // DMA (streaming)
    axi4s_intf #(
        .DATA_BYTE_WID ( DMA_ST_DATA_BYTE_WID ),
        .TID_T         ( dma_st_h2c_axis_tid_t),
        .TDEST_T       ( dma_st_h2c_axis_tdest_t),
        .TUSER_T       ( dma_st_h2c_axis_tuser_t)
    ) axis_h2c [NUM_DMA_ST] ();

    axi4s_intf #(
        .DATA_BYTE_WID ( DMA_ST_DATA_BYTE_WID ),
        .TID_T         ( dma_st_c2h_axis_tid_t),
        .TDEST_T       ( dma_st_c2h_axis_tdest_t),
        .TUSER_T       ( dma_st_c2h_axis_tuser_t)
    ) axis_c2h [NUM_DMA_ST] ();

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
