package shell_pkg;

    // Common application-facing DMA geometry.
    localparam int DMA_ST_DATA_BYTE_WID = 64;
    localparam int DMA_ST_QUEUES = 512;
    localparam int DMA_ST_QID_WID = $clog2(DMA_ST_QUEUES);

    // --------------------------------------------------------------
    // Semantic typedefs
    // (used by shell adapters for metadata field packing/unpacking)
    // --------------------------------------------------------------
    typedef struct packed {logic unused;} unused_t;

    // DMA streaming
    //
    // tid carries the queue ID, sized from the common queue space.
    typedef unused_t                              dma_st_axis_tdest_t;
    typedef struct packed {logic rss_enable; logic [11:0] rss_entropy;}  dma_st_axis_tuser_t;

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
