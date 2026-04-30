package shell_pkg;

    // --------------------------------------------------------------
    // Default platform parameters
    // (used as default values for shell_intf parameters)
    // --------------------------------------------------------------
    localparam int NUM_PORTS            = 2;
    localparam int PORT_DATA_BYTE_WID   = 64;

    localparam int DMA_ST_DATA_BYTE_WID = 64;
    localparam int DMA_ST_DATA_WID      = DMA_ST_DATA_BYTE_WID * 8;
    localparam int DMA_ST_QUEUES        = 2048;
    localparam int DMA_ST_QID_WID       = DMA_ST_QUEUES > 1 ? $clog2(DMA_ST_QUEUES) : 1;

    localparam int AXIL_ADDR_WID        = 32;
    localparam int AXIL_DATA_BYTE_WID   = 4;
    localparam int AXIL_DATA_WID        = AXIL_DATA_BYTE_WID * 8;

    // --------------------------------------------------------------
    // Semantic typedefs
    // (used by shell adapters for metadata field packing/unpacking)
    // --------------------------------------------------------------
    typedef struct packed {logic unused;} unused_t;

    // DMA streaming
    typedef logic [DMA_ST_QID_WID-1:0]           dma_st_qid_t;
    typedef struct packed {dma_st_qid_t qid;}     dma_st_axis_tid_t;
    typedef unused_t                              dma_st_axis_tdest_t;
    typedef struct packed {logic err;}            dma_st_axis_tuser_t;

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

    // AXI-L
    localparam int AXIL_PROT_WID = 3;
    localparam int AXIL_RESP_WID = $bits(axi4l_pkg::resp_t);

    typedef logic [AXIL_ADDR_WID-1:0]           axil_addr_t;
    typedef logic [AXIL_DATA_BYTE_WID-1:0]      axil_strb_t;
    typedef logic [AXIL_DATA_BYTE_WID-1:0][7:0] axil_data_t;
    typedef logic [2:0]                         axil_prot_t;

endpackage : shell_pkg
