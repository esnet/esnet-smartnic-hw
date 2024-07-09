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
    input  wire logic                               axis_cmac_rx__aclk   [NUM_CMAC],
    input  wire logic                               axis_cmac_rx__aresetn[NUM_CMAC],
    input  wire logic                               axis_cmac_rx__tvalid [NUM_CMAC],
    output wire logic                               axis_cmac_rx__tready [NUM_CMAC],
    input  wire logic [CMAC_DATA_BYTE_WID-1:0][7:0] axis_cmac_rx__tdata  [NUM_CMAC],
    input  wire logic [CMAC_DATA_BYTE_WID-1:0]      axis_cmac_rx__tkeep  [NUM_CMAC],
    input  wire logic                               axis_cmac_rx__tlast  [NUM_CMAC],
    input  wire cmac_rx_axis_tid_t                  axis_cmac_rx__tid    [NUM_CMAC],
    input  wire cmac_rx_axis_tdest_t                axis_cmac_rx__tdest  [NUM_CMAC],
    input  wire cmac_rx_axis_tuser_t                axis_cmac_rx__tuser  [NUM_CMAC],
    // -- TX
    output wire logic                               axis_cmac_tx__aclk   [NUM_CMAC],
    output wire logic                               axis_cmac_tx__aresetn[NUM_CMAC],
    output wire logic                               axis_cmac_tx__tvalid [NUM_CMAC],
    input  wire logic                               axis_cmac_tx__tready [NUM_CMAC],
    output wire logic [CMAC_DATA_BYTE_WID-1:0][7:0] axis_cmac_tx__tdata  [NUM_CMAC],
    output wire logic [CMAC_DATA_BYTE_WID-1:0]      axis_cmac_tx__tkeep  [NUM_CMAC],
    output wire logic                               axis_cmac_tx__tlast  [NUM_CMAC],
    output wire cmac_tx_axis_tid_t                  axis_cmac_tx__tid    [NUM_CMAC],
    output wire cmac_tx_axis_tdest_t                axis_cmac_tx__tdest  [NUM_CMAC],
    output wire cmac_tx_axis_tuser_t                axis_cmac_tx__tuser  [NUM_CMAC],

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

    // Interfaces
    axi4s_intf #(.DATA_BYTE_WID (CMAC_DATA_BYTE_WID), .TID_T (cmac_rx_axis_tid_t), .TDEST_T (cmac_rx_axis_tdest_t), .TUSER_T (cmac_rx_axis_tuser_t)) __axis_cmac_rx [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID (CMAC_DATA_BYTE_WID), .TID_T (cmac_tx_axis_tid_t), .TDEST_T (cmac_tx_axis_tdest_t), .TUSER_T (cmac_tx_axis_tuser_t)) __axis_cmac_tx [NUM_CMAC] ();

    // Clock/reset
    assign shell_if.clk = clk;
    assign shell_if.srst = srst;

    // Aux clocks
    assign shell_if.clk_100mhz = clk_100mhz;

    // CMACs
    // -- Pack interfaces into arrays
    axi4s_intf_connector i_axi4s_intf_connector_rx_0 (
        .axi4s_from_tx ( __axis_cmac_rx[0] ),
        .axi4s_to_rx   ( shell_if.axis_cmac0_rx )
    );
    axi4s_intf_connector i_axi4s_intf_connector_tx_0 (
        .axi4s_from_tx ( shell_if.axis_cmac0_tx ),
        .axi4s_to_rx   ( __axis_cmac_tx[0] )
    );
    axi4s_intf_connector i_axi4s_intf_connector_rx_1 (
        .axi4s_from_tx ( __axis_cmac_rx[1] ),
        .axi4s_to_rx   ( shell_if.axis_cmac1_rx )
    );
    axi4s_intf_connector i_axi4s_intf_connector_tx_1 (
        .axi4s_from_tx ( shell_if.axis_cmac1_tx ),
        .axi4s_to_rx   ( __axis_cmac_tx[1] )
    );
    // Convert from signals
    generate
        for (genvar g_cmac = 0; g_cmac < NUM_CMAC; g_cmac++) begin : g__cmac
            // -- Rx
            axi4s_intf_from_signals #(
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
            axi4s_intf_to_signals #(
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

    // DMA (streaming)
    // -- H2C
    assign shell_if.axis_h2c.aclk    = axis_h2c__aclk;
    assign shell_if.axis_h2c.aresetn = axis_h2c__aresetn;
    assign shell_if.axis_h2c.tvalid  = axis_h2c__tvalid;
    assign shell_if.axis_h2c.tdata   = axis_h2c__tdata;
    assign shell_if.axis_h2c.tkeep   = axis_h2c__tkeep;
    assign shell_if.axis_h2c.tlast   = axis_h2c__tlast;
    assign shell_if.axis_h2c.tid     = axis_h2c__tid;
    assign shell_if.axis_h2c.tdest   = '0;
    assign shell_if.axis_h2c.tuser   = axis_h2c__tuser;
    assign axis_h2c__tready = shell_if.axis_h2c.tready;
    // -- C2H
    assign axis_c2h__aclk    = shell_if.axis_c2h.aclk;
    assign axis_c2h__aresetn = shell_if.axis_c2h.aresetn;
    assign axis_c2h__tvalid  = shell_if.axis_c2h.tvalid;
    assign axis_c2h__tdata   = shell_if.axis_c2h.tdata;
    assign axis_c2h__tkeep   = shell_if.axis_c2h.tkeep;
    assign axis_c2h__tlast   = shell_if.axis_c2h.tlast;
    assign axis_c2h__tdest   = shell_if.axis_c2h.tdest;
    assign axis_c2h__tuser   = shell_if.axis_c2h.tuser;
    assign shell_if.axis_c2h.tready = axis_c2h__tready;

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
