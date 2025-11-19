package smartnic_pkg;
    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int PHY_NUM_PORTS = 2;
    localparam int PHY_DATA_BYTE_WID = 64;

    localparam int TIMESTAMP_WID = 64;

    localparam int MAX_PKT_LEN = 9200;

    localparam int NUM_EGR_QS = 128;


    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    typedef logic [TIMESTAMP_WID-1:0] timestamp_t;

    typedef logic [15:0] adpt_tx_tid_t;

    typedef enum logic {
        P0 = 1'b0,
        P1 = 1'b1
    } port_num_t;

    typedef enum logic [2:0] {
        PHY     = 3'h0,
        PF      = 3'h1,
        VF0     = 3'h2,
        VF1     = 3'h3,
        VF2     = 3'h4,
        APP_IGR = 3'h5,
        APP_EGR = 3'h6,
        UNSET   = 3'h7
    } port_typ_t;

    typedef struct packed {
        port_typ_t  typ;
        port_num_t  num;
    } port_encoding_t;

    typedef union packed {
        port_encoding_t encoded;
        logic [3:0]     raw;
    } port_t;

    function automatic logic get_port_idx(input port_t port);
        case (port.encoded.num)
            P0: return 1'b0;
            P1: return 1'b1;
        endcase
    endfunction

    typedef enum logic [1:0] {
        H2C_PF   = 2'h0,
        H2C_VF0  = 2'h1,
        H2C_VF1  = 2'h2,
        H2C_VF2  = 2'h3
    } h2c_encoding_t;

    typedef union packed {
        h2c_encoding_t encoded;
        logic [1:0]    raw;
    } h2c_t;

    typedef enum logic [1:0] {
        APP    = 2'h0,
        BYPASS = 2'h2,
        DROP   = 2'h3
    } igr_tdest_encoding_t;

    typedef union packed {
        igr_tdest_encoding_t encoded;
        logic [1:0]          raw;
    } igr_tdest_t;

    typedef struct packed {
        logic        rss_enable;
        logic [11:0] rss_entropy;
    } tuser_smartnic_meta_t;

    // typedef logic [EGR_Q_WID-1:0] egr_q_t;
    typedef tuser_smartnic_meta_t egr_q_t; // TEMP: for now, pass entropy through egress qs (required for VF2 extraction)

    // --------------------------------------------------------------
    // Derived parameters
    // --------------------------------------------------------------
    localparam int PORT_WID                = $bits(port_t);
    localparam int TUSER_SMARTNIC_META_WID = $bits(tuser_smartnic_meta_t);
    localparam int IGR_TDEST_WID           = $bits(igr_tdest_t);
    localparam int ADPT_TX_TID_WID         = $bits(adpt_tx_tid_t);
    // localparam int EGR_Q_WID               = $clog2(NUM_EGR_QS); 
    localparam int EGR_Q_WID              = TUSER_SMARTNIC_META_WID; // TEMP: for now, pass entropy through egress qs (required for VF2 extraction)

endpackage : smartnic_pkg
