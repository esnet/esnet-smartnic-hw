package xilinx_cmac_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int AXIS_DATA_BYTE_WID = 64;
    localparam int AXIS_DATA_WIDTH    = AXIS_DATA_BYTE_WID * 8;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    typedef struct packed {logic unused;} unused_t;

    typedef unused_t                   axis_tid_t;
    typedef unused_t                   axis_tdest_t;
    typedef struct packed {logic err;} axis_tuser_t;

endpackage : xilinx_cmac_pkg
