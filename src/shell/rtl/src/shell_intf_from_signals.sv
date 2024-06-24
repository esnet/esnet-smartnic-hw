module shell_intf_from_signals
    import shell_pkg::*;
(
    // Shell interface signals (in)
    // ----------------------------
    // Clock/reset
    input  wire logic clk,
    input  wire logic srst,

    // Aux clocks
    input  wire logic clk_100mhz,

    // CMAC
    // -- RX
    input  wire logic                               axis_cmac_rx__aclk,
    input  wire logic                               axis_cmac_rx__aresetn,
    input  wire logic                               axis_cmac_rx__tvalid,
    output wire logic                               axis_cmac_rx__tready,
    input  wire logic [CMAC_DATA_BYTE_WID-1:0][7:0] axis_cmac_rx__tdata,
    input  wire logic [CMAC_DATA_BYTE_WID-1:0]      axis_cmac_rx__tkeep,
    input  wire logic                               axis_cmac_rx__tlast,
    input  wire cmac_rx_axis_tid_t                  axis_cmac_rx__tid,
    input  wire cmac_rx_axis_tdest_t                axis_cmac_rx__tdest,
    input  wire cmac_rx_axis_tuser_t                axis_cmac_rx__tuser,
    // -- TX
    output wire logic                               axis_cmac_tx__aclk,
    output wire logic                               axis_cmac_tx__aresetn,
    output wire logic                               axis_cmac_tx__tvalid,
    input  wire logic                               axis_cmac_tx__tready,
    output wire logic [CMAC_DATA_BYTE_WID-1:0][7:0] axis_cmac_tx__tdata,
    output wire logic [CMAC_DATA_BYTE_WID-1:0]      axis_cmac_tx__tkeep,
    output wire logic                               axis_cmac_tx__tlast,
    output wire cmac_tx_axis_tid_t                  axis_cmac_tx__tid,
    output wire cmac_tx_axis_tdest_t                axis_cmac_tx__tdest,
    output wire cmac_tx_axis_tuser_t                axis_cmac_tx__tuser,

    // DMA (streaming)
    // -- H2C
    input  wire logic                                 axis_h2c__aclk,
    input  wire logic                                 axis_h2c__aresetn,
    input  wire logic                                 axis_h2c__tvalid,
    output wire logic                                 axis_h2c__tready,
    input  wire logic [DMA_ST_DATA_BYTE_WID-1:0][7:0] axis_h2c__tdata,
    input  wire logic [DMA_ST_DATA_BYTE_WID-1:0]      axis_h2c__tkeep,
    input  wire logic                                 axis_h2c__tlast,
    input  wire dma_st_h2c_axis_tid_t                 axis_h2c__tid,
    input  wire dma_st_h2c_axis_tdest_t               axis_h2c__tdest,
    input  wire dma_st_h2c_axis_tuser_t               axis_h2c__tuser,
    // -- C2H
    output wire logic                                 axis_c2h__aclk,
    output wire logic                                 axis_c2h__aresetn,
    output wire logic                                 axis_c2h__tvalid,
    input  wire logic                                 axis_c2h__tready,
    output wire logic [DMA_ST_DATA_BYTE_WID-1:0][7:0] axis_c2h__tdata,
    output wire logic [DMA_ST_DATA_BYTE_WID-1:0]      axis_c2h__tkeep,
    output wire logic                                 axis_c2h__tlast,
    output wire dma_st_c2h_axis_tid_t                 axis_c2h__tid,
    output wire dma_st_c2h_axis_tdest_t               axis_c2h__tdest,
    output wire dma_st_c2h_axis_tuser_t               axis_c2h__tuser,

    // AXI-L (control)
    input  wire logic                           axil__aclk, 
    input  wire logic                           axil__aresetn,
    input  wire logic                           axil__awvalid,
    output wire logic                           axil__awready,
    input  wire logic [AXIL_ADDR_WID-1:0]       axil__awaddr,
    input  wire logic [1:0]                     axil__awprot,
    input  wire logic                           axil__wvalid,
    output wire logic                           axil__wready,
    input  wire logic [AXIL_DATA_WID-1:0]       axil__wdata,
    input  wire logic [AXIL_DATA_BYTE_WID-1:0]  axil__wstrb,
    output wire logic                           axil__bvalid,
    input  wire logic                           axil__bready,
    output wire logic [1:0]                     axil__bresp,
    input  wire logic                           axil__arvalid,
    output wire logic                           axil__arready,
    input  wire logic [AXIL_ADDR_WID:0]         axil__araddr,
    input  wire logic [1:0]                     axil__arprot,
    output wire logic                           axil__rvalid,
    input  wire logic                           axil__rready,
    output wire logic [AXIL_DATA_WID-1:0]       axil__rdata,
    output wire logic                           axil__rresp,

    // Shell interface (out)
    // --------------------------
    shell_intf.shell shell_if
);
    // Clock/reset
    assign shell_if.clk = clk;
    assign shell_if.srst = srst;

    // Aux clocks
    assign shell_if.clk_100mhz = clk_100mhz;

    // CMACs
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            // -- Rx
            assign shell_if.axis_cmac_rx[g_cmac].aclk    = axis_cmac_rx__aclk;
            assign shell_if.axis_cmac_rx[g_cmac].aresetn = axis_cmac_rx__aresetn;
            assign shell_if.axis_cmac_rx[g_cmac].tvalid  = axis_cmac_rx__tvalid;
            assign shell_if.axis_cmac_rx[g_cmac].tdata   = axis_cmac_rx__tdata;
            assign shell_if.axis_cmac_rx[g_cmac].tkeep   = axis_cmac_rx__tkeep;
            assign shell_if.axis_cmac_rx[g_cmac].tlast   = axis_cmac_rx__tlast;
            assign shell_if.axis_cmac_rx[g_cmac].tid     = '0;
            assign shell_if.axis_cmac_rx[g_cmac].tdest   = '0;
            assign shell_if.axis_cmac_rx[g_cmac].tuser   = axis_cmac_rx__tuser;
            assign axis_cmac_rx__tready = shell_if.axis_cmac_rx[g_cmac].tready;
            // -- Tx
            assign axis_cmac_tx__aclk    = shell_if.axis_cmac_tx[g_cmac].aclk;
            assign axis_cmac_tx__aresetn = shell_if.axis_cmac_tx[g_cmac].aresetn;
            assign axis_cmac_tx__tvalid  = shell_if.axis_cmac_tx[g_cmac].tvalid;
            assign axis_cmac_tx__tdata   = shell_if.axis_cmac_tx[g_cmac].tdata;
            assign axis_cmac_tx__tkeep   = shell_if.axis_cmac_tx[g_cmac].tkeep;
            assign axis_cmac_tx__tlast   = shell_if.axis_cmac_tx[g_cmac].tlast;
            assign axis_cmac_tx__tuser   = shell_if.axis_cmac_tx[g_cmac].tuser;
            assign shell_if.axis_cmac_tx[g_cmac].tready = axis_cmac_tx__tready;
        end
    endgenerate

    // DMA (streaming) channels
    generate
        for (genvar g_ch = 0; g_ch < NUM_DMA_ST; g_ch++) begin : g__ch
            // -- H2C
            assign shell_if.axis_h2c[g_cmac].aclk    = axis_h2c__aclk;
            assign shell_if.axis_h2c[g_cmac].aresetn = axis_h2c__aresetn;
            assign shell_if.axis_h2c[g_cmac].tvalid  = axis_h2c__tvalid;
            assign shell_if.axis_h2c[g_cmac].tdata   = axis_h2c__tdata;
            assign shell_if.axis_h2c[g_cmac].tkeep   = axis_h2c__tkeep;
            assign shell_if.axis_h2c[g_cmac].tlast   = axis_h2c__tlast;
            assign shell_if.axis_h2c[g_cmac].tid     = axis_h2c__tid;
            assign shell_if.axis_h2c[g_cmac].tdest   = '0;
            assign shell_if.axis_h2c[g_cmac].tuser   = axis_h2c__tuser;
            assign axis_h2c__tready = shell_if.axis_h2c[g_cmac].tready;
            // -- C2H 
            assign axis_c2h__aclk    = shell_if.axis_c2h[g_cmac].aclk;
            assign axis_c2h__aresetn = shell_if.axis_c2h[g_cmac].aresetn;
            assign axis_c2h__tvalid  = shell_if.axis_c2h[g_cmac].tvalid;
            assign axis_c2h__tdata   = shell_if.axis_c2h[g_cmac].tdata;
            assign axis_c2h__tkeep   = shell_if.axis_c2h[g_cmac].tkeep;
            assign axis_c2h__tlast   = shell_if.axis_c2h[g_cmac].tlast;
            assign axis_c2h__tdest   = shell_if.axis_c2h[g_cmac].tdest;
            assign axis_c2h__tuser   = shell_if.axis_c2h[g_cmac].tuser;
            assign shell_if.axis_c2h[g_cmac].tready = axis_c2h__tready;
        end
    endgenerate

    // AXI-L control
    assign shell_if.axil_if.aclk    = axil__aclk;
    assign shell_if.axil_if.aresetn = axil__aresetn;
    assign shell_if.axil_if.awvalid = axil__awvalid;
    assign shell_if.axil_if.awaddr  = axil__awaddr;
    assign shell_if.axil_if.awprot  = axil__awprot;
    assign shell_if.axil_if.wvalid  = axil__wvalid;
    assign shell_if.axil_if.wdata   = axil__wdata;
    assign shell_if.axil_if.wstrb   = axil__wstrb;
    assign shell_if.axil_if.bready  = axil__bready;
    assign shell_if.axil_if.arvalid = axil__arvalid;
    assign shell_if.axil_if.araddr  = axil__araddr;
    assign shell_if.axil_if.arprot  = axil__arprot;
    assign shell_if.axil_if.rready  = axil__rready;
    assign axil__awready = shell_if.axil_if.awready;
    assign axil__wready  = shell_if.axil_if.wready;
    assign axil__bvalid  = shell_if.axil_if.bvalid;
    assign axil__bresp   = shell_if.axil_if.bresp;
    assign axil__arready = shell_if.axil_if.arready;
    assign axil__rvalid  = shell_if.axil_if.rvalid;
    assign axil__rdata   = shell_if.axil_if.rdata;
    assign axil__rresp   = shell_if.axil_if.rresp;

endmodule : shell_intf_from_signals
