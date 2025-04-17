package xilinx_axi_pkg;

    typedef enum int {
        XILINX_AXI_PROTOCOL_AXI3 = 1,
        XILINX_AXI_PROTOCOL_AXI4L = 2
    } xilinx_axi_protocol_t;

    // Register slice configurations
    // Conversion from config enum to Xilinx config value
    // (see Xilinx PG373 v2.1)
    typedef enum int {
        XILINX_AXI_REG_SLICE_BYPASS             = 0,  // Connect input to output
        XILINX_AXI_REG_SLICE_FULL               = 1,  // One latency cycle, no bubble cycles
        XILINX_AXI_REG_SLICE_FORWARD            = 2,
        XILINX_AXI_REG_SLICE_REVERSE            = 3,
        XILINX_AXI_REG_SLICE_INPUTS             = 6,
        XILINX_AXI_REG_SLICE_LIGHT              = 7,  // Inserts one 'bubble' cycle after each transfer
        XILINX_AXI_REG_SLICE_SI_MI_REG          = 9,  // SI Reg for AW/W/AR channels, MI Reg for B/R channels
//      XILINX_AXI_REG_SLICE_SLR_CROSSING       = 11, // Encoding per PG373; mismatch to IP generator so doc is likely out of date
        XILINX_AXI_REG_SLICE_SLR_CROSSING       = 12, // Three latency cycles, no bubble cycles
//      XILINX_AXI_REG_SLICE_SLR_TDM_CROSSING   = 13, // Not supported (requires 2x clock)
//      XILINX_AXI_REG_SLICE_MULTI_SLR_CROSSING = 15, // Encoding per PG373; mismatch to IP generator so doc is likely out of date
        XILINX_AXI_REG_SLICE_MULTI_SLR_CROSSING = 16  // Supports spanning zero or more SLR boundaries using a single slice instance
    } xilinx_axi_reg_slice_config_t;

endpackage : xilinx_axi_pkg
