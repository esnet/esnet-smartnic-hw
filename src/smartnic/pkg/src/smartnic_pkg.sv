package smartnic_pkg;
    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    // Timestamp
    localparam int TIMESTAMP_WID = 64;


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
        bit [3:0]       raw;
    } port_t;

    typedef enum logic [1:0] {
        H2C_PF   = 2'h0,
        H2C_VF0  = 2'h1,
        H2C_VF1  = 2'h2,
        H2C_VF2  = 2'h3
    } h2c_encoding_t;

    typedef union packed {
        h2c_encoding_t encoded;
        bit [1:0]       raw;
    } h2c_t;

    typedef enum logic [1:0] {
        APP    = 2'h0,
        BYPASS = 2'h2,
        DROP   = 2'h3
    } igr_tdest_encoding_t;

    typedef union packed {
        igr_tdest_encoding_t encoded;
        bit [1:0]            raw;
    } igr_tdest_t;

    typedef struct packed {
        logic [15:0] pid;
        logic        trunc_enable;
        logic [15:0] trunc_length;
        logic        rss_enable;
        logic [11:0] rss_entropy;
        logic        hdr_tlast;
    } tuser_smartnic_meta_t;

endpackage : smartnic_pkg
