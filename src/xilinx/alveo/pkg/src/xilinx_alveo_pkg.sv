package xilinx_alveo_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int NUM_DMA_ST = 2;
    localparam int NUM_CMAC_REGMAP = 2;

    localparam int DMA_ST_DATA_BYTE_WID = 64;
    localparam int DMA_ST_QUEUES = 2048;
    
    localparam int DMA_ST_Q_WID = $clog2(DMA_ST_QUEUES);

    localparam int CMAC_DATA_BYTE_WID = 64;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    typedef logic [DMA_ST_Q_WID-1:0] dma_st_qid_t;

    typedef struct packed {
        logic err;
    } dma_st_axis_tuser_t;

    typedef xilinx_cmac_pkg::axis_tuser_t cmac_axis_tuser_t;

endpackage : xilinx_alveo_pkg
