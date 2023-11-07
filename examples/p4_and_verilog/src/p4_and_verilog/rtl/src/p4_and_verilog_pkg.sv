package p4_and_verilog_pkg;
    // --------------------------------------------------------------
    // Imports
    // --------------------------------------------------------------
    import sdnet_0_pkg::*;

    // --------------------------------------------------------------
    // Parameters & Typedefs
    // --------------------------------------------------------------

    // Timestamp
    localparam int TIMESTAMP_WID = 64;

    typedef logic [TIMESTAMP_WID-1:0] timestamp_t;

    // User metadata
    typedef USER_META_DATA_T user_metadata_t;

    // Typedefs from smartnic_322mhz_pkg --- begin
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
    // Typedefs from smartnic_322mhz_pkg --- end

endpackage : p4_and_verilog_pkg
