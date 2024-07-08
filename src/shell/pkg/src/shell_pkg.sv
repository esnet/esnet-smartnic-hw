package shell_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    // CMAC
    localparam int NUM_CMAC = 2;
    localparam int CMAC_DATA_BYTE_WID = 64;

    // DMA (streaming)
    localparam int DMA_ST_DATA_BYTE_WID = 64;
    localparam int DMA_ST_QUEUES = 2048;
    localparam int DMA_ST_QID_WID = $clog2(DMA_ST_QUEUES);

    // AXI-L
    localparam int AXIL_ADDR_WID      = 32;
    localparam int AXIL_DATA_BYTE_WID = 4;
    localparam int AXIL_DATA_WID      = AXIL_DATA_BYTE_WID*8;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    // Generic
    typedef struct packed {logic unused;} unused_t;

    // DMA (streaming)
    typedef logic [DMA_ST_QID_WID-1:0] dma_st_qid_t;
    // -- H2C
    typedef struct packed {dma_st_qid_t qid;} dma_st_h2c_axis_tid_t;
    typedef unused_t                          dma_st_h2c_axis_tdest_t;
    typedef struct packed {logic err;}        dma_st_h2c_axis_tuser_t;
    // -- C2H
    typedef unused_t                          dma_st_c2h_axis_tid_t;
    typedef struct packed {dma_st_qid_t qid;} dma_st_c2h_axis_tdest_t;
    typedef struct packed {logic err;}        dma_st_c2h_axis_tuser_t;

    // CMAC
    // -- Rx
    typedef unused_t                   cmac_rx_axis_tid_t;
    typedef unused_t                   cmac_rx_axis_tdest_t;
    typedef struct packed {logic err;} cmac_rx_axis_tuser_t;
    // -- Tx
    typedef unused_t                   cmac_tx_axis_tid_t;
    typedef unused_t                   cmac_tx_axis_tdest_t;
    typedef struct packed {logic err;} cmac_tx_axis_tuser_t;

endpackage : shell_pkg
