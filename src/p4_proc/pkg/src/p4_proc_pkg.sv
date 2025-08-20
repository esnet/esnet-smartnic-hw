package p4_proc_pkg;

    // --------------------------------------------------------------
    // Parameters & Typedefs
    // --------------------------------------------------------------
    localparam TRUNCATE_LENGTH_WID = 16;
    localparam PID_WID = 16;

    // P4 metadata
    // - this should match the metadata defined by the p4 program,
    //   i.e. in vitisnetp4_0_pkg.sv
    typedef struct packed {
        logic [63:0] timestamp_ns;
        logic [PID_WID-1:0]  pid;
        logic [3:0] ingress_port;
        logic [3:0] egress_port;
        logic truncate_enable;
        logic [TRUNCATE_LENGTH_WID-1:0] truncate_length;
        logic rss_enable;
        logic [11:0] rss_entropy;
        logic [3:0] drop_reason;
        logic [31:0] scratch;
    } user_metadata_t;

    typedef struct packed {
        logic                           enable;
        logic [TRUNCATE_LENGTH_WID-1:0] length;
    } trunc_meta_t;
    localparam int TRUNC_META_WID = $bits(trunc_meta_t);

endpackage : p4_proc_pkg
