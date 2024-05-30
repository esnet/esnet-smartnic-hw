package xilinx_cmac_pkg;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    localparam int AXIS_DATA_BYTE_WID = 64;
    localparam int AXIS_DATA_WIDTH    = AXIS_DATA_BYTE_WID * 8;

    localparam int NUM_PORTS = 2;
    localparam int PORT_ID_WID = $clog2(NUM_PORTS);

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    typedef logic [PORT_ID_WID-1:0] port_id_t;

    typedef struct packed {
        port_id_t port_id;
    } axis_tid_t;

    typedef struct packed {
        logic err;
    } axis_tuser_t;

endpackage : xilinx_cmac_pkg
