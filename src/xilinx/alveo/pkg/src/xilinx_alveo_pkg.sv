package xilinx_alveo_pkg;
    import shell_pkg::*;

    // --------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------
    export shell_pkg::NUM_CMAC;

    localparam int NUM_CMAC_REGMAP = 2;

    export shell_pkg::DMA_ST_DATA_BYTE_WID;
    export shell_pkg::DMA_ST_QUEUES;
    
    export shell_pkg::CMAC_DATA_BYTE_WID;

    // --------------------------------------------------------------
    // Typedefs
    // --------------------------------------------------------------
    export shell_pkg::dma_st_qid_t;
    export shell_pkg::dma_st_h2c_axis_tuser_t;
    export shell_pkg::dma_st_c2h_axis_tuser_t;

    typedef xilinx_cmac_pkg::axis_tuser_t cmac_axis_tuser_t;

endpackage : xilinx_alveo_pkg
