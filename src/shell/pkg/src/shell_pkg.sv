package shell_pkg;

    // --------------------------------------------------------------
    // Semantic typedefs
    // (used by shell adapters for metadata field packing/unpacking)
    // --------------------------------------------------------------
    typedef struct packed {logic unused;} unused_t;

    // DMA streaming
    localparam int DMA_ST_QUEUES     = 2048;
    localparam int DMA_ST_QID_WID    = DMA_ST_QUEUES > 1 ? $clog2(DMA_ST_QUEUES) : 1;

    typedef logic [DMA_ST_QID_WID-1:0]           dma_st_qid_t;
    typedef struct packed {dma_st_qid_t qid;}     dma_st_axis_tid_t;
    typedef unused_t                              dma_st_axis_tdest_t;
    typedef struct packed {logic rss_enable; logic [11:0] rss_entropy;}  dma_st_axis_tuser_t;


    localparam int DMA_ST_AXIS_TID_WID   = $bits(dma_st_axis_tid_t);
    localparam int DMA_ST_AXIS_TDEST_WID = $bits(dma_st_axis_tdest_t);
    localparam int DMA_ST_AXIS_TUSER_WID = $bits(dma_st_axis_tuser_t);

    // Network port
    typedef unused_t                              port_axis_tid_t;
    typedef unused_t                              port_axis_tdest_t;
    typedef struct packed {logic err;}            port_axis_tuser_t;

    localparam int PORT_AXIS_TID_WID   = $bits(port_axis_tid_t);
    localparam int PORT_AXIS_TDEST_WID = $bits(port_axis_tdest_t);
    localparam int PORT_AXIS_TUSER_WID = $bits(port_axis_tuser_t);

endpackage : shell_pkg
