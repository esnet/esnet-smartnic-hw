    // Clock/reset
    wire logic clk;
    wire logic srst;

    // Aux clocks
    wire logic clk_100hz;

    // CMAC0
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) axis_cmac0_rx ();
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) axis_cmac0_tx ();

    // CMAC1
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) axis_cmac1_rx ();
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) axis_cmac1_tx ();

    // QDMA
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_T  (dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) axis_h2c ();
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TDEST_T(dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) axis_c2h ();

    // AXI-L (control)
    axi4l_intf #() axil_if ();
