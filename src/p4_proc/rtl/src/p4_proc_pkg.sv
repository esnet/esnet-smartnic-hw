package p4_proc_pkg;
    // --------------------------------------------------------------
    // Parameters & Typedefs
    // --------------------------------------------------------------
    // Timestamp
    localparam int TIMESTAMP_WID = 64;

    typedef logic [TIMESTAMP_WID-1:0] timestamp_t;

    // P4 metadata
    // - this should match the metadata defined by the p4 program,
    //   i.e. in sdnet_0_pkg.sv
    typedef struct packed {
        logic [63:0] timestamp_ns;
        logic [15:0] pid;
        logic [2:0] ingress_port;
        logic [2:0] egress_port;
        logic truncate_enable;
        logic [15:0] truncate_length;
        logic rss_enable;
        logic [11:0] rss_entropy;
        logic [3:0] drop_reason;
        logic [31:0] scratch;
    } user_metadata_t;

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
        timestamp_t  timestamp;
        logic [15:0] pid;
        logic        trunc_enable;
        logic [15:0] trunc_length;
        logic        rss_enable;
        logic [11:0] rss_entropy;
        logic        hdr_tlast;
    } tuser_smartnic_meta_t;
    // Typedefs from smartnic_322mhz_pkg --- end

endpackage : p4_proc_pkg
