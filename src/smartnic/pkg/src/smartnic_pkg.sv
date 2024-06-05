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

    typedef enum logic [1:0] {
        CMAC_PORT0 = 2'h0,
        CMAC_PORT1 = 2'h1,
        HOST_PORT0 = 2'h2,
        HOST_PORT1 = 2'h3
    } port_encoding_t;

    typedef union packed {
        port_encoding_t encoded;
        bit [1:0]       raw;
    } port_t;

    typedef enum logic [1:0] {
        APP_P0 = 2'h0,
        APP_P1 = 2'h1,
        BYPASS = 2'h2,
        DROP   = 2'h3
    } igr_tdest_encoding_t;

    typedef union packed {
        port_encoding_t encoded;
        bit [1:0]       raw;
    } igr_tdest_t;

    typedef enum logic [2:0] {
        CMAC0 = 3'h0,
        CMAC1 = 3'h1,
        HOST0 = 3'h2,
        HOST1 = 3'h3,
        LOOPBACK = 3'h7
    } egr_tdest_encoding_t;

    typedef union packed {
        egr_tdest_encoding_t encoded;
        bit [2:0]       raw;
    } egr_tdest_t;

    typedef struct packed {
        logic [15:0] pid;
        logic        trunc_enable;
        logic [15:0] trunc_length;
        logic        rss_enable;
        logic [11:0] rss_entropy;
        logic        hdr_tlast;
    } tuser_smartnic_meta_t;

endpackage : smartnic_pkg
