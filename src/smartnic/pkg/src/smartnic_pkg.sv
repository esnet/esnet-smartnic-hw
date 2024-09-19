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

    typedef enum logic [3:0] {
        CMAC0    = 4'h0,
        CMAC1    = 4'h1,
        PF0_VF2  = 4'h2,
        PF1_VF2  = 4'h3,
        PF0_VF1  = 4'h4,
        PF1_VF1  = 4'h5,
        PF0_VF0  = 4'h6,
        PF1_VF0  = 4'h7,
        PF0      = 4'h8,
        PF1      = 4'h9,
        LOOPBACK = 4'hf
    } port_encoding_t;

    typedef union packed {
        port_encoding_t encoded;
        bit [3:0]       raw;
    } port_t;

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
