    // Clock/reset
    logic clk;
    logic srst;

    // CMAC
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) axis_cmac_rx [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID(CMAC_DATA_BYTE_WID), .TUSER_T(cmac_axis_tuser_t)) axis_cmac_tx [NUM_CMAC] ();

    // QDMA
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TID_T  (dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) axis_h2c [NUM_DMA_ST] ();
    axi4s_intf #(.DATA_BYTE_WID(DMA_ST_DATA_BYTE_WID), .TDEST_T(dma_st_qid_t), .TUSER_T(dma_st_axis_tuser_t)) axis_c2h [NUM_DMA_ST] ();

    // AXI-L (control)
    axi4l_intf #() axil_if ();
