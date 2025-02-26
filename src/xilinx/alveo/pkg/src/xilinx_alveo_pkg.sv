package xilinx_alveo_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int NUM_CMAC = 2;

    localparam int DMA_ST_DATA_BYTE_WID = 64;
    localparam int DMA_ST_QUEUES = 2048;
    localparam int DMA_ST_QID_WID = DMA_ST_QUEUES > 1 ? $clog2(DMA_ST_QUEUES) : 1;
    
    localparam int CMAC_DATA_BYTE_WID = 64;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    typedef struct packed {logic unused;} unused_t;

    typedef logic [DMA_ST_QID_WID-1:0] dma_st_qid_t;

    typedef struct packed {dma_st_qid_t qid;} dma_st_axis_tid_t;
    typedef unused_t                          dma_st_axis_tdest_t;
    typedef struct packed {logic err;}        dma_st_axis_tuser_t;

    localparam int DMA_ST_AXIS_TID_WID   = $bits(dma_st_axis_tid_t);
    localparam int DMA_ST_AXIS_TDEST_WID = $bits(dma_st_axis_tdest_t);
    localparam int DMA_ST_AXIS_TUSER_WID = $bits(dma_st_axis_tuser_t);

    typedef unused_t                          cmac_axis_tid_t;
    typedef unused_t                          cmac_axis_tdest_t;
    typedef struct packed {logic err;}        cmac_axis_tuser_t;

    localparam int CMAC_AXIS_TID_WID   = $bits(cmac_axis_tid_t);
    localparam int CMAC_AXIS_TDEST_WID = $bits(cmac_axis_tdest_t);
    localparam int CMAC_AXIS_TUSER_WID = $bits(cmac_axis_tuser_t);

endpackage : xilinx_alveo_pkg
