package p4_proc_pkg;

    import smartnic_322mhz_pkg::*;

    // --------------------------------------------------------------
    // Parameters & Typedefs
    // --------------------------------------------------------------
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

    // Metadata format within p4_proc
    // (needs to be a superset of the fields described
    //  in smartnic_322mhz_pkg::tuser_smartnic_meta_t)
    typedef struct packed {
        timestamp_t  timestamp;
        logic [15:0] pid;
        logic        trunc_enable;
        logic [15:0] trunc_length;
        logic        rss_enable;
        logic [11:0] rss_entropy;
        logic        hdr_tlast;
    } tuser_t;

endpackage : p4_proc_pkg
