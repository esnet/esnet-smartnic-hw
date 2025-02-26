package xilinx_qdma_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int AXIS_DATA_BYTE_WID = 64;
    localparam int AXIS_DATA_WIDTH    = AXIS_DATA_BYTE_WID * 8;

    localparam int QID_WID        = 11;
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

    // (Internal) C2H completion data format
    typedef struct packed {
        qid_t    qid;
        pkt_id_t pkt_id;
        len_t    len;
    } c2h_cmpt_data_t;

    // (External) AXI-S types
    typedef logic [AXIS_DATA_BYTE_WID-1:0][7:0] axis_tdata_t;
    typedef logic [AXIS_DATA_BYTE_WID-1:0]      axis_tkeep_t;
    typedef struct packed {qid_t qid;}          axis_tid_t;
    typedef unused_t                            axis_tdest_t;
    typedef struct packed {logic err;}          axis_tuser_t;

endpackage : xilinx_qdma_pkg
