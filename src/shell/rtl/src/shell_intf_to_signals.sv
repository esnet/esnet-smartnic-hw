module shell_intf_to_signals 
    import shell_pkg::*;
(
    // Shell interface (in)
    // --------------------------
    shell_intf.core shell_if,

    // Shell interface signals (out)
    // -----------------------------
    // Clock/reset
    output wire logic clk,
    output wire logic srst,

    // Aux clocks
    output wire logic clk_100mhz,

    // CMAC
    // -- RX
    output wire logic                               axis_cmac_rx__aclk   [NUM_CMAC],
    output wire logic                               axis_cmac_rx__aresetn[NUM_CMAC],
    output wire logic                               axis_cmac_rx__tvalid [NUM_CMAC],
    input  wire logic                               axis_cmac_rx__tready [NUM_CMAC],
    output wire logic [CMAC_DATA_BYTE_WID-1:0][7:0] axis_cmac_rx__tdata  [NUM_CMAC],
    output wire logic [CMAC_DATA_BYTE_WID-1:0]      axis_cmac_rx__tkeep  [NUM_CMAC],
    output wire logic                               axis_cmac_rx__tlast  [NUM_CMAC],
    output wire cmac_rx_axis_tid_t                  axis_cmac_rx__tid    [NUM_CMAC],
    output wire cmac_rx_axis_tdest_t                axis_cmac_rx__tdest  [NUM_CMAC],
    output wire cmac_rx_axis_tuser_t                axis_cmac_rx__tuser  [NUM_CMAC],
    // -- TX
    input  wire logic                               axis_cmac_tx__aclk   [NUM_CMAC],
    input  wire logic                               axis_cmac_tx__aresetn[NUM_CMAC],
    input  wire logic                               axis_cmac_tx__tvalid [NUM_CMAC],
    output wire logic                               axis_cmac_tx__tready [NUM_CMAC],
    input  wire logic [CMAC_DATA_BYTE_WID-1:0][7:0] axis_cmac_tx__tdata  [NUM_CMAC],
    input  wire logic [CMAC_DATA_BYTE_WID-1:0]      axis_cmac_tx__tkeep  [NUM_CMAC],
    input  wire logic                               axis_cmac_tx__tlast  [NUM_CMAC],
    input  wire cmac_tx_axis_tid_t                  axis_cmac_tx__tid    [NUM_CMAC],
    input  wire cmac_tx_axis_tdest_t                axis_cmac_tx__tdest  [NUM_CMAC],
    input  wire cmac_tx_axis_tuser_t                axis_cmac_tx__tuser  [NUM_CMAC],

    // DMA (streaming)
    // -- H2C
    output wire logic                                 axis_h2c__aclk,
    output wire logic                                 axis_h2c__aresetn,
    output wire logic                                 axis_h2c__tvalid,
    input  wire logic                                 axis_h2c__tready,
    output wire logic [DMA_ST_DATA_BYTE_WID-1:0][7:0] axis_h2c__tdata,
    output wire logic [DMA_ST_DATA_BYTE_WID-1:0]      axis_h2c__tkeep,
    output wire logic                                 axis_h2c__tlast,
    output wire dma_st_h2c_axis_tid_t                 axis_h2c__tid,
    output wire dma_st_h2c_axis_tdest_t               axis_h2c__tdest,
    output wire dma_st_h2c_axis_tuser_t               axis_h2c__tuser,
    // -- C2H
    input  wire logic                                 axis_c2h__aclk,
    input  wire logic                                 axis_c2h__aresetn,
    input  wire logic                                 axis_c2h__tvalid,
    output wire logic                                 axis_c2h__tready,
    input  wire logic [DMA_ST_DATA_BYTE_WID-1:0][7:0] axis_c2h__tdata,
    input  wire logic [DMA_ST_DATA_BYTE_WID-1:0]      axis_c2h__tkeep,
    input  wire logic                                 axis_c2h__tlast,
    input  wire dma_st_c2h_axis_tid_t                 axis_c2h__tid,
    input  wire dma_st_c2h_axis_tdest_t               axis_c2h__tdest,
    input  wire dma_st_c2h_axis_tuser_t               axis_c2h__tuser,

    // AXI-L (control)
    output wire logic                           axil__aclk, 
    output wire logic                           axil__aresetn,
    output wire logic                           axil__awvalid,
    input  wire logic                           axil__awready,
    output wire logic [AXIL_ADDR_WID-1:0]       axil__awaddr,
    output wire logic [1:0]                     axil__awprot,
    output wire logic                           axil__wvalid,
    input  wire logic                           axil__wready,
    output wire logic [AXIL_DATA_WID-1:0]       axil__wdata,
    output wire logic [AXIL_DATA_BYTE_WID-1:0]  axil__wstrb,
    input  wire logic                           axil__bvalid,
    output wire logic                           axil__bready,
    input  wire logic [1:0]                     axil__bresp,
    output wire logic                           axil__arvalid,
    input  wire logic                           axil__arready,
    output wire logic [AXIL_ADDR_WID:0]         axil__araddr,
    output wire logic [1:0]                     axil__arprot,
    input  wire logic                           axil__rvalid,
    output wire logic                           axil__rready,
    input  wire logic [AXIL_DATA_WID-1:0]       axil__rdata,
    input  wire logic                           axil__rresp
);

    // Interfaces
    axi4s_intf #(.DATA_BYTE_WID (CMAC_DATA_BYTE_WID), .TID_T (cmac_rx_axis_tid_t), .TDEST_T (cmac_rx_axis_tdest_t), .TUSER_T (cmac_rx_axis_tuser_t)) __axis_cmac_rx [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID (CMAC_DATA_BYTE_WID), .TID_T (cmac_tx_axis_tid_t), .TDEST_T (cmac_tx_axis_tdest_t), .TUSER_T (cmac_tx_axis_tuser_t)) __axis_cmac_tx [NUM_CMAC] ();

    // Clock/reset
    assign clk = shell_if.clk;
    assign srst = shell_if.srst;

    // Aux clocks
    assign clk_100mhz = shell_if.clk_100mhz;

    // CMACs
    // -- Pack interfaces into arrays
    axi4s_intf_connector i_axi4s_intf_connector_rx_0 (
        .axi4s_from_tx ( shell_if.axis_cmac0_rx ),
        .axi4s_to_rx   ( __axis_cmac_rx[0] )
    );
    axi4s_intf_connector i_axi4s_intf_connector_tx_0 (
        .axi4s_from_tx ( __axis_cmac_tx[0] ),
        .axi4s_to_rx   ( shell_if.axis_cmac0_tx )
    );
    axi4s_intf_connector i_axi4s_intf_connector_rx_1 (
        .axi4s_from_tx ( shell_if.axis_cmac1_rx ),
        .axi4s_to_rx   ( __axis_cmac_rx[1] )
    );
    axi4s_intf_connector i_axi4s_intf_connector_tx_1 (
        .axi4s_from_tx ( __axis_cmac_tx[1] ),
        .axi4s_to_rx   ( shell_if.axis_cmac1_tx )
    );

    // Convert to signals
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            // -- Rx
            axi4s_intf_to_signals #(
                .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
                .TID_T         ( cmac_rx_axis_tid_t ),
                .TDEST_T       ( cmac_rx_axis_tdest_t ),
                .TUSER_T       ( cmac_rx_axis_tuser_t )
            ) i_axi4s_intf_to_signals (
                .aclk     ( axis_cmac_rx__aclk   [g_cmac] ),
                .aresetn  ( axis_cmac_rx__aresetn[g_cmac] ),
                .tvalid   ( axis_cmac_rx__tvalid [g_cmac] ),
                .tready   ( axis_cmac_rx__tready [g_cmac] ),
                .tdata    ( axis_cmac_rx__tdata  [g_cmac] ),
                .tkeep    ( axis_cmac_rx__tkeep  [g_cmac] ),
                .tlast    ( axis_cmac_rx__tlast  [g_cmac] ),
                .tid      ( axis_cmac_rx__tid    [g_cmac] ),
                .tdest    ( axis_cmac_rx__tdest  [g_cmac] ),
                .tuser    ( axis_cmac_rx__tuser  [g_cmac] ),
                .axi4s_if ( __axis_cmac_rx[g_cmac] )
            );
            // -- Tx
            axi4s_intf_from_signals #(
                .DATA_BYTE_WID ( CMAC_DATA_BYTE_WID ),
                .TID_T         ( cmac_tx_axis_tid_t ),
                .TDEST_T       ( cmac_tx_axis_tdest_t ),
                .TUSER_T       ( cmac_tx_axis_tuser_t )
            ) i_axi4s_intf_from_signals (
                .aclk     ( axis_cmac_tx__aclk   [g_cmac] ),
                .aresetn  ( axis_cmac_tx__aresetn[g_cmac] ),
                .tvalid   ( axis_cmac_tx__tvalid [g_cmac] ),
                .tready   ( axis_cmac_tx__tready [g_cmac] ),
                .tdata    ( axis_cmac_tx__tdata  [g_cmac] ),
                .tkeep    ( axis_cmac_tx__tkeep  [g_cmac] ),
                .tlast    ( axis_cmac_tx__tlast  [g_cmac] ),
                .tid      ( axis_cmac_tx__tid    [g_cmac] ),
                .tdest    ( axis_cmac_tx__tdest  [g_cmac] ),
                .tuser    ( axis_cmac_tx__tuser  [g_cmac] ),
                .axi4s_if ( __axis_cmac_tx[g_cmac] )
            );
        end
    endgenerate

    // DMA (streaming) channel
    // -- H2C
    assign axis_h2c__aclk    = shell_if.axis_h2c.aclk;
    assign axis_h2c__aresetn = shell_if.axis_h2c.aresetn;
    assign axis_h2c__tvalid  = shell_if.axis_h2c.tvalid;
    assign axis_h2c__tdata   = shell_if.axis_h2c.tdata;
    assign axis_h2c__tkeep   = shell_if.axis_h2c.tkeep;
    assign axis_h2c__tlast   = shell_if.axis_h2c.tlast;
    assign axis_h2c__tid     = shell_if.axis_h2c.tid;
    assign axis_h2c__tuser   = shell_if.axis_h2c.tuser;
    assign shell_if.axis_h2c.tready = axis_h2c__tready;
    // -- C2H
    assign shell_if.axis_c2h.aclk    = axis_c2h__aclk;
    assign shell_if.axis_c2h.aresetn = axis_c2h__aresetn;
    assign shell_if.axis_c2h.tvalid  = axis_c2h__tvalid;
    assign shell_if.axis_c2h.tdata   = axis_c2h__tdata;
    assign shell_if.axis_c2h.tkeep   = axis_c2h__tkeep;
    assign shell_if.axis_c2h.tlast   = axis_c2h__tlast;
    assign shell_if.axis_c2h.tdest   = axis_c2h__tdest;
    assign shell_if.axis_c2h.tid     = '0;
    assign shell_if.axis_c2h.tuser   = axis_c2h__tuser;
    assign axis_c2h__tready = shell_if.axis_c2h.tready;

    // AXI-L control
    assign axil__aclk    = shell_if.axil_if.aclk;
    assign axil__aresetn = shell_if.axil_if.aresetn;
    assign axil__awvalid = shell_if.axil_if.awvalid;
    assign axil__awaddr  = shell_if.axil_if.awaddr;
    assign axil__awprot  = shell_if.axil_if.awprot;
    assign axil__wvalid  = shell_if.axil_if.wvalid;
    assign axil__wdata   = shell_if.axil_if.wdata;
    assign axil__wstrb   = shell_if.axil_if.wstrb;
    assign axil__bready  = shell_if.axil_if.bready;
    assign axil__arvalid = shell_if.axil_if.arvalid;
    assign axil__araddr  = shell_if.axil_if.araddr;
    assign axil__arprot  = shell_if.axil_if.arprot;
    assign axil__rready  = shell_if.axil_if.rready;
    assign shell_if.axil_if.awready   = axil__awready;
    assign shell_if.axil_if.wready    = axil__wready;
    assign shell_if.axil_if.bvalid    = axil__bvalid;
    assign shell_if.axil_if.bresp.raw = axil__bresp;
    assign shell_if.axil_if.arready   = axil__arready;
    assign shell_if.axil_if.rvalid    = axil__rvalid;
    assign shell_if.axil_if.rdata     = axil__rdata;
    assign shell_if.axil_if.rresp.raw = axil__rresp;

endmodule : shell_intf_to_signals
