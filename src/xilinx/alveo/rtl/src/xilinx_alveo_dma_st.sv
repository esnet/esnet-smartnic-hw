module xilinx_alveo_dma_st
    import xilinx_alveo_pkg::*;
#(
    parameter int PCIE_LINK_WID = 16
) (
    // From DMA controller
    axi4s_intf.tx          axis_dma_h2c,
    axi4s_intf.rx_async    axis_dma_c2h,
    // From/to core
    // -- AXI-L
    axi4l_intf.controller  axil_if,
    // -- AXI-S (streaming DMA)
    axi4s_intf.tx          axis_h2c [NUM_DMA_ST],
    axi4s_intf.rx_async    axis_c2h [NUM_DMA_ST]

);
    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_qdma_pkg::*;

    // =========================================================================
    // H2C Stream
    // =========================================================================
    // (Local) signals
    logic __axis_h2c_tready [NUM_DMA_ST];

    generate
        for (genvar g_h2c = 0; g_h2c < NUM_DMA_ST; g_h2c++) begin : g__h2c
            // (Local) signals
            axis_h2c_tuser_t __tuser;

            assign axis_h2c[g_h2c].aclk = axis_dma_h2c.aclk;
            assign axis_h2c[g_h2c].aresetn = axis_dma_h2c.c2h;
            assign axis_h2c[g_h2c].tvalid = axis_dma_h2c.tvalid && (axis_dma_h2c.tdest == g_h2c);
            assign axis_h2c[g_h2c].tdata = axis_dma_h2c.tdata;
            assign axis_h2c[g_h2c].tlast = axis_dma_h2c.tlast;
            assign axis_h2c[g_h2c].tkeep = axis_dma_h2c.tkeep;
            assign axis_h2c[g_h2c].tuser = axis_dma_h2c.tuser;

            assign __axis_h2c_tready[g_h2c] = axis_h2c[g_h2c].tready;
        end : g__h2c
    endgenerate

    // H2C TREADY mux (use port ID as selector)
    always_comb begin
        axis_dma_h2c.tready = 1'b0;
        for (int i = 0; i < NUM_DMA_ST; i++) begin
            if (axis_dma_h2c.tdest == i) axis_dma_h2c.tready = __axis_h2c_tready[i];
        end
    end

    // =========================================================================
    // C2H Stream
    // =========================================================================
    // (Local) signals
    logic            __axis_c2h_tvalid[NUM_DMA_ST];
    logic            __axis_c2h_tlast [NUM_DMA_ST];
    axis_tkeep_t     __axis_c2h_tkeep [NUM_DMA_ST];
    axis_tdata_t     __axis_c2h_tdata [NUM_DMA_ST];
    port_id_t        __axis_c2h_tid   [NUM_DMA_ST];
    qid_t            __axis_c2h_tdest [NUM_DMA_ST];
    axis_c2h_tuser_t __axis_c2h_tuser [NUM_DMA_ST];

    // C2H Mux
    generate
        for (genvar g_c2h = 0; g_c2h < NUM_DMA_ST; g_c2h++) begin : g__c2h
            assign axis_c2h[g_c2h].aclk = axis_dma_c2h.aclk;
            assign axis_c2h[g_c2h].aresetn = axis_dma_c2h.aresetn;

            assign __axis_c2h_tvalid[g_c2h] = axis_c2h[g_c2h].tvalid;
            assign __axis_c2h_tlast [g_c2h] = axis_c2h[g_c2h].tlast;
            assign __axis_c2h_tkeep [g_c2h] = axis_c2h[g_c2h].tkeep;
            assign __axis_c2h_tdata [g_c2h] = axis_c2h[g_c2h].tdata;
            assign __axis_c2h_tdest [g_c2h] = axis_c2h[g_c2h].tdest;
            assign __axis_c2h_tid   [g_c2h] = axis_c2h[g_c2h].tid;
            assign __axis_c2h_tuser [g_c2h] = axis_c2h[g_c2h].tuser;

            assign axis_c2h[g_c2h].tready = (g_c2h == 0) ? axis_dma_c2h.tready : 1'b0;
        end : g__c2h
    endgenerate

    assign axis_dma_c2h.tvalid = __axis_c2h_tvalid[0];
    assign axis_dma_c2h.tkeep  = __axis_c2h_tkeep [0];
    assign axis_dma_c2h.tlast  = __axis_c2h_tlast [0];
    assign axis_dma_c2h.tdata  = __axis_c2h_tdata [0];
    assign axis_dma_c2h.tid    = 0;
    assign axis_dma_c2h.tdest  = __axis_c2h_tdest [0];
    assign axis_dma_c2h.tuser  = __axis_c2h_tuser [0];

endmodule : xilinx_alveo_dma_st
