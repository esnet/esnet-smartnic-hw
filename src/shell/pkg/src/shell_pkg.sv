package shell_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    // CMAC
    localparam int NUM_CMAC = 2;
    localparam int CMAC_DATA_BYTE_WID = 64;

    // DMA (streaming)
    localparam int DMA_ST_DATA_BYTE_WID = 64;
    localparam int DMA_ST_DATA_WID = DMA_ST_DATA_BYTE_WID*8;
    localparam int DMA_ST_QUEUES = 2048;
    localparam int DMA_ST_QID_WID = DMA_ST_QUEUES > 1 ? $clog2(DMA_ST_QUEUES) : 1;

    // AXI-L
    localparam int AXIL_ADDR_WID      = 32;
    localparam int AXIL_DATA_BYTE_WID = 4;
    localparam int AXIL_DATA_WID      = AXIL_DATA_BYTE_WID*8;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    // Generic
    // ------------------------------
    typedef struct packed {logic unused;} unused_t;

    // DMA (streaming)
    // ------------------------------
    typedef logic [DMA_ST_QID_WID-1:0] dma_st_qid_t;

    typedef logic [DMA_ST_DATA_BYTE_WID-1:0]      dma_st_axis_tkeep_t;
    typedef logic [DMA_ST_DATA_BYTE_WID-1:0][7:0] dma_st_axis_tdata_t;
    typedef struct packed {dma_st_qid_t qid;}     dma_st_axis_tid_t;
    typedef unused_t                              dma_st_axis_tdest_t;
    typedef struct packed {logic err;}            dma_st_axis_tuser_t;

    localparam int DMA_ST_AXIS_TKEEP_WID = $bits(dma_st_axis_tkeep_t);
    localparam int DMA_ST_AXIS_TDATA_WID = $bits(dma_st_axis_tdata_t);
    localparam int DMA_ST_AXIS_TID_WID   = $bits(dma_st_axis_tid_t);
    localparam int DMA_ST_AXIS_TDEST_WID = $bits(dma_st_axis_tdest_t);
    localparam int DMA_ST_AXIS_TUSER_WID = $bits(dma_st_axis_tuser_t);

    typedef struct packed {
        logic                             tvalid;
        logic                             tlast;
        logic [DMA_ST_AXIS_TKEEP_WID-1:0] tkeep;
        logic [DMA_ST_AXIS_TDATA_WID-1:0] tdata;
        logic [DMA_ST_AXIS_TID_WID-1:0]   tid;
        logic [DMA_ST_AXIS_TDEST_WID-1:0] tdest;
        logic [DMA_ST_AXIS_TUSER_WID-1:0] tuser;
    } dma_st_axis_fwd_t;
    localparam int DMA_ST_AXIS_FWD_WID = $bits(dma_st_axis_fwd_t);

    typedef struct packed {
        logic tready;
    } dma_st_axis_rev_t;
    localparam int DMA_ST_AXIS_REV_WID = $bits(dma_st_axis_rev_t);

    // CMAC
    // ------------------------------
    typedef logic [CMAC_DATA_BYTE_WID-1:0]        cmac_axis_tkeep_t;
    typedef logic [CMAC_DATA_BYTE_WID-1:0][7:0]   cmac_axis_tdata_t;
    typedef unused_t                              cmac_axis_tid_t;
    typedef unused_t                              cmac_axis_tdest_t;
    typedef struct packed {logic err;}            cmac_axis_tuser_t;

    localparam int CMAC_AXIS_TKEEP_WID = $bits(cmac_axis_tkeep_t);
    localparam int CMAC_AXIS_TDATA_WID = $bits(cmac_axis_tdata_t);
    localparam int CMAC_AXIS_TID_WID   = $bits(cmac_axis_tid_t);
    localparam int CMAC_AXIS_TDEST_WID = $bits(cmac_axis_tdest_t);
    localparam int CMAC_AXIS_TUSER_WID = $bits(cmac_axis_tuser_t);

    typedef struct packed {
        logic                           tvalid;
        logic                           tlast;
        logic [CMAC_AXIS_TKEEP_WID-1:0] tkeep;
        logic [CMAC_AXIS_TDATA_WID-1:0] tdata;
        logic [CMAC_AXIS_TID_WID-1:0]   tid;
        logic [CMAC_AXIS_TDEST_WID-1:0] tdest;
        logic [CMAC_AXIS_TUSER_WID-1:0] tuser;
    } cmac_axis_fwd_t;
    localparam int CMAC_AXIS_FWD_WID = $bits(cmac_axis_fwd_t);

    typedef struct packed {
        logic tready;
    } cmac_axis_rev_t;
    localparam int CMAC_AXIS_REV_WID = $bits(cmac_axis_rev_t);

    // AXI-L
    // ------------------------------
    typedef logic [AXIL_ADDR_WID-1:0]           axil_addr_t;
    typedef logic [AXIL_DATA_BYTE_WID-1:0]      axil_strb_t;
    typedef logic [AXIL_DATA_BYTE_WID-1:0][7:0] axil_data_t;
    typedef logic [2:0]                         axil_prot_t;

    localparam int AXIL_PROT_WID = $bits(axil_prot_t);
    localparam int AXIL_RESP_WID = $bits(axi4l_pkg::resp_t);

    typedef struct packed {
        logic                          awvalid;
        logic [AXIL_ADDR_WID-1:0]      awaddr;
        logic [AXIL_PROT_WID-1:0]      awprot;
        logic                          wvalid;
        logic [AXIL_DATA_WID-1:0]      wdata;
        logic [AXIL_DATA_BYTE_WID-1:0] wstrb;
        logic                          bready;
        logic                          arvalid;
        logic [AXIL_ADDR_WID-1:0]      araddr;
        logic [AXIL_PROT_WID-1:0]      arprot;
        logic                          rready;
    } axil_fwd_t;
    localparam int AXIL_FWD_WID = $bits(axil_fwd_t);

    typedef struct packed {
        logic                     awready;
        logic                     wready;
        logic                     bvalid;
        logic [AXIL_RESP_WID-1:0] bresp;
        logic                     arready;
        logic                     rvalid;
        logic [AXIL_DATA_WID-1:0] rdata;
        logic [AXIL_RESP_WID-1:0] rresp;
    } axil_rev_t;
    localparam int AXIL_REV_WID = $bits(axil_rev_t);

    // Interface definition
    // ------------------------------
    typedef struct packed {
        logic [AXIL_FWD_WID-1:0]                    axil;
        logic [NUM_CMAC-1:0][CMAC_AXIS_FWD_WID-1:0] cmac_rx;
        logic [NUM_CMAC-1:0][CMAC_AXIS_REV_WID-1:0] cmac_tx;
        logic [DMA_ST_AXIS_FWD_WID-1:0]             h2c;
        logic [DMA_ST_AXIS_REV_WID-1:0]             c2h;
    } shell_to_core_t;
    localparam int SHELL_TO_CORE_WID = $bits(shell_to_core_t);

    typedef struct packed {
        logic [AXIL_REV_WID-1:0]                    axil;
        logic [NUM_CMAC-1:0][CMAC_AXIS_REV_WID-1:0] cmac_rx;
        logic [NUM_CMAC-1:0][CMAC_AXIS_FWD_WID-1:0] cmac_tx;
        logic [DMA_ST_AXIS_REV_WID-1:0]             h2c;
        logic [DMA_ST_AXIS_FWD_WID-1:0]             c2h;
    } core_to_shell_t;
    localparam int CORE_TO_SHELL_WID = $bits(core_to_shell_t);

endpackage : shell_pkg
