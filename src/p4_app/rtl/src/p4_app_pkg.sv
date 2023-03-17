package p4_app_pkg;
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

endpackage : p4_app_pkg
