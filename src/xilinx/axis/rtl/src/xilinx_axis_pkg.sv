package xilinx_axis_pkg;

    // Register slice configurations
    // Conversion from config enum to Xilinx config value
    typedef enum int {
        XILINX_AXIS_REG_SLICE_BYPASS             = 0,  // Connect input to output
        XILINX_AXIS_REG_SLICE_DEFAULT            = 1,  // Two-deep registered mode (supports back-to-back transfers), balances performance/fanout
        XILINX_AXIS_REG_SLICE_LIGHTWEIGHT        = 7,  // Inserts one 'bubble' cycle after each transfer
        XILINX_AXIS_REG_SLICE_FULLY_REGISTERED   = 8,  // Similar to DEFAULT, except all payload/handshake outputs are driven directly from registers
        XILINX_AXIS_REG_SLICE_SLR_CROSSING       = 12, // Adds extra pipeline stages to optimally cross one SLR boundary (all SLR crossings are flop-to-flop with fanout=1)
//      XILINX_AXIS_REG_SLICE_SLR_TDM_CROSSING   = 13, // Not supported (requires 2x clock) [Similar to SLR crossing, except consumes half number of payload wires across boundary; requires 2x clock)
//      XILINX_AXIS_REG_SLICE_MULTI_SLR_CROSSING = 15, // Supports spanning zero or more SLR boundaries using a single slice instance; also inserts additional pipeline stages within each SLR to help meet timing goals.
        XILINX_AXIS_REG_SLICE_AUTO_PIPELINED     = 16, // Not documented; believe to be equivalent to Multi-SLR + auto-pipelining
        XILINX_AXIS_REG_SLICE_PRESERVE_SI        = 17, // ??
        XILINX_AXIS_REG_SLICE_PRESERVE_MI        = 18  // ??
    } xilinx_axis_reg_slice_config_t;

    typedef enum int {
        FULL,
        LITE
    } xilinx_axis_ila_mode_t;

endpackage : xilinx_axis_pkg
