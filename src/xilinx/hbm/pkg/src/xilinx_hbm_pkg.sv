package xilinx_hbm_pkg;

    // Parameters
    localparam int AXI_DATA_BYTE_WID = 32;
    localparam int AXI_DATA_WID = AXI_DATA_BYTE_WID*8;
    localparam int AXI_ID_WID = 6;

    localparam int PSEUDO_CHANNELS_PER_STACK =  16;

    // Typedefs
    typedef enum {
        STACK_LEFT = 0,
        STACK_RIGHT = 1
    } stack_t;

    typedef enum {
        DENSITY_4G,
        DENSITY_8G
    } density_t;

    typedef logic [AXI_ID_WID-1:0] axi_id_t;

    // Functions
    function automatic int get_size(input density_t DENSITY);
        case (DENSITY)
            DENSITY_4G : return 4*1024**3;
            DENSITY_8G : return 8*1024**3;
            default    : return 4*1024**3;
        endcase
    endfunction

    function automatic int get_addr_wid(input density_t DENSITY);
        case (DENSITY)
            DENSITY_4G : return 33;
            DENSITY_8G : return 34;
            default    : return 33;
        endcase
    endfunction

endpackage : xilinx_hbm_pkg
