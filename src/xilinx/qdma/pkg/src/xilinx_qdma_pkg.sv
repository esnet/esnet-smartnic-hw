package xilinx_qdma_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int AXIS_DATA_BYTE_WID = 64;
    localparam int AXIS_DATA_WIDTH    = AXIS_DATA_BYTE_WID * 8;

    localparam int QID_WID        = 12;
    localparam int PORT_ID_WID    = 3;
    localparam int MDATA_WID      = 32;
    localparam int MTY_WID        = $clog2(AXIS_DATA_BYTE_WID);
    localparam int LEN_WID        = 16;
    localparam int PLD_PKT_ID_WID = 16;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    typedef struct packed {logic unused;} unused_t;

    typedef logic [QID_WID-1:0]         qid_t;
    typedef logic [PORT_ID_WID-1:0]     port_id_t;
    typedef logic [MDATA_WID-1:0]       mdata_t;
    typedef logic [MTY_WID-1:0]         mty_t;
    typedef logic [LEN_WID-1:0]         len_t;
    typedef logic [PLD_PKT_ID_WID-1:0]  pkt_id_t;

    // (Internal) H2C metadata format
    typedef struct packed {
        logic [15:0] rsvd;
        len_t        len;
    } h2c_tuser_mdata_t;

    // (Internal) C2H completion data format — 8B entry (cmpt_size = 2'b00).
    // Matches union qdma_ul_st_cmpt_ring, the layout the upstream QDMA DPDK
    // PMD parses:
    //   [3:0]   data_frmt, color, err, desc_used — inserted by the DMA
    //   [19:4]  length
    //   [23:20] reserved
    //   [63:24] user defined
    typedef struct packed {
        pkt_id_t    pkt_id;    // [51:36]
        qid_t       qid;       // [35:24]
        logic [3:0] user_rsv;  // [23:20]
        len_t       len;       // [19:4]
        logic [3:0] dma_rsv;   // [3:0]
    } c2h_cmpt_data_t;

    // (External) AXI-S types
    typedef logic [AXIS_DATA_BYTE_WID-1:0][7:0] axis_tdata_t;
    typedef logic [AXIS_DATA_BYTE_WID-1:0]      axis_tkeep_t;
    typedef struct packed {qid_t qid;}          axis_tid_t;
    typedef unused_t                            axis_tdest_t;
    typedef struct packed {logic err;}          axis_tuser_t;

    localparam int AXIS_TID_WID = $bits(axis_tid_t);
    localparam int AXIS_TDEST_WID = $bits(axis_tdest_t);
    localparam int AXIS_TUSER_WID = $bits(axis_tuser_t);

endpackage : xilinx_qdma_pkg
