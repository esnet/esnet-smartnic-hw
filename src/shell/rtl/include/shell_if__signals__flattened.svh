    // Clock/reset
    wire logic clk;
    wire logic srst;

    // Aux clocks
    wire logic clk_100mhz;

    // CMAC
    // -- RX
    wire logic                              axis_cmac_rx__aclk    [NUM_CMAC];
    wire logic                              axis_cmac_rx__aresetn [NUM_CMAC];
    wire logic                              axis_cmac_rx__tvalid  [NUM_CMAC];
    wire logic                              axis_cmac_rx__tready  [NUM_CMAC];
    wire logic[CMAC_DATA_BYTE_WID-1:0][7:0] axis_cmac_rx__tdata   [NUM_CMAC];
    wire logic[CMAC_DATA_BYTE_WID-1:0]      axis_cmac_rx__tkeep   [NUM_CMAC];
    wire logic                              axis_cmac_rx__tlast   [NUM_CMAC];
    wire cmac_rx_axis_tid_t                 axis_cmac_rx__tid     [NUM_CMAC];
    wire cmac_rx_axis_tdest_t               axis_cmac_rx__tdest   [NUM_CMAC];
    wire cmac_rx_axis_tuser_t               axis_cmac_rx__tuser   [NUM_CMAC];
    // -- TX
    wire logic                              axis_cmac_tx__aclk    [NUM_CMAC];
    wire logic                              axis_cmac_tx__aresetn [NUM_CMAC];
    wire logic                              axis_cmac_tx__tvalid  [NUM_CMAC];
    wire logic                              axis_cmac_tx__tready  [NUM_CMAC];
    wire logic[CMAC_DATA_BYTE_WID-1:0][7:0] axis_cmac_tx__tdata   [NUM_CMAC];
    wire logic[CMAC_DATA_BYTE_WID-1:0]      axis_cmac_tx__tkeep   [NUM_CMAC];
    wire logic                              axis_cmac_tx__tlast   [NUM_CMAC];
    wire cmac_tx_axis_tid_t                 axis_cmac_tx__tid     [NUM_CMAC];
    wire cmac_tx_axis_tdest_t               axis_cmac_tx__tdest   [NUM_CMAC];
    wire cmac_tx_axis_tuser_t               axis_cmac_tx__tuser   [NUM_CMAC];

    // DMA
    // -- H2C
    wire logic                                 axis_h2c__aclk;
    wire logic                                 axis_h2c__aresetn;
    wire logic                                 axis_h2c__tvalid;
    wire logic                                 axis_h2c__tready;
    wire logic [DMA_ST_DATA_BYTE_WID-1:0][7:0] axis_h2c__tdata;
    wire logic [DMA_ST_DATA_BYTE_WID-1:0]      axis_h2c__tkeep;
    wire logic                                 axis_h2c__tlast;
    wire dma_st_h2c_axis_tid_t                 axis_h2c__tid;
    wire dma_st_h2c_axis_tdest_t               axis_h2c__tdest;
    wire dma_st_h2c_axis_tuser_t               axis_h2c__tuser;
        // -- C2H
    wire logic                                 axis_c2h__aclk;
    wire logic                                 axis_c2h__aresetn;
    wire logic                                 axis_c2h__tvalid;
    wire logic                                 axis_c2h__tready;
    wire logic [DMA_ST_DATA_BYTE_WID-1:0][7:0] axis_c2h__tdata;
    wire logic [DMA_ST_DATA_BYTE_WID-1:0]      axis_c2h__tkeep;
    wire logic                                 axis_c2h__tlast;
    wire dma_st_c2h_axis_tid_t                 axis_c2h__tid;
    wire dma_st_c2h_axis_tdest_t               axis_c2h__tdest;
    wire dma_st_c2h_axis_tuser_t               axis_c2h__tuser;
 
    // AXI-L (control)
    wire logic                           axil__aclk; 
    wire logic                           axil__aresetn;
    wire logic                           axil__awvalid;
    wire logic                           axil__awready;
    wire logic [AXIL_ADDR_WID-1:0]       axil__awaddr;
    wire logic [1:0]                     axil__awprot;
    wire logic                           axil__wvalid;
    wire logic                           axil__wready;
    wire logic [AXIL_DATA_WID-1:0]       axil__wdata;
    wire logic [AXIL_DATA_BYTE_WID-1:0]  axil__wstrb;
    wire logic                           axil__bvalid;
    wire logic                           axil__bready;
    wire logic [1:0]                     axil__bresp;
    wire logic                           axil__arvalid;
    wire logic                           axil__arready;
    wire logic [AXIL_ADDR_WID:0]         axil__araddr;
    wire logic [1:0]                     axil__arprot;
    wire logic                           axil__rvalid;
    wire logic                           axil__rready;
    wire logic [AXIL_DATA_WID-1:0]       axil__rdata;
    wire logic                           axil__rresp;
