package shell_pkg;

    // --------------------------------------------------------------
    // Semantic typedefs
    // (used by shell adapters for metadata field packing/unpacking)
    // --------------------------------------------------------------
    typedef struct packed {logic unused;} unused_t;

    // DMA streaming
    //
    // tid carries the queue ID, whose width depends on the platform's DMA
    // engine. It is therefore not defined here: shell_intf derives it from its
    // DMA_ST_QUEUES parameter, which each platform top-level supplies from its
    // own package.
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
