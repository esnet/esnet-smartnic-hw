module tb;
    import tb_pkg::*;
    import smartnic_pkg::*;

    // (Local) parameters
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    localparam int HOST_NUM_IFS = 1;
    localparam int N = 2;  // Number of processor ports (per vitisnetp4 processor).
    localparam int M = 2;  // Number of vitisnetp4 processors.

    //===================================
    // (Common) test environment
    //===================================
    tb_env env;

    //===================================
    // Device Under Test
    //===================================

    // Signals
    logic        clk;
    logic        rstn;

    logic [63:0] timestamp;

    axi4l_intf axil_if       ();
    axi4l_intf app_axil_if   ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_in_if[N] ();
    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_out_if[N] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_h2c_if[N * HOST_NUM_IFS] ();
    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_c2h_if[N * HOST_NUM_IFS] ();

    axi3_intf  #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_to_hbm [16] ();

    logic [N-1:0]        axis_app_igr_tvalid;
    logic [N-1:0]        axis_app_igr_tready;
    logic [N-1:0][511:0] axis_app_igr_tdata;
    logic [N-1:0][63:0]  axis_app_igr_tkeep;
    logic [N-1:0]        axis_app_igr_tlast;
    logic [N-1:0][1:0]   axis_app_igr_tid;
    logic [N-1:0][1:0]   axis_app_igr_tdest;
    logic [N-1:0][15:0]  axis_app_igr_tuser_pid;

    generate
        for (genvar j = 0; j < N; j += 1) begin
            assign axis_app_igr_tvalid[j]    = axis_in_if[j].tvalid; 
            assign axis_in_if[j].tready      = axis_app_igr_tready[j];
            assign axis_app_igr_tdata[j]     = axis_in_if[j].tdata;
            assign axis_app_igr_tkeep[j]     = axis_in_if[j].tkeep;
            assign axis_app_igr_tlast[j]     = axis_in_if[j].tlast;
            assign axis_app_igr_tid[j]       = axis_in_if[j].tid;
            assign axis_app_igr_tdest[j]     = axis_in_if[j].tdest;
            assign axis_app_igr_tuser_pid[j] = axis_in_if[j].tuser.pid;
        end
    endgenerate

    logic [N-1:0]        axis_app_egr_tvalid;
    logic [N-1:0]        axis_app_egr_tready;
    logic [N-1:0][511:0] axis_app_egr_tdata;
    logic [N-1:0][63:0]  axis_app_egr_tkeep;
    logic [N-1:0]        axis_app_egr_tlast;
    logic [N-1:0][1:0]   axis_app_egr_tid;
    logic [N-1:0][2:0]   axis_app_egr_tdest;
    logic [N-1:0][15:0]  axis_app_egr_tuser_pid;
    logic [N-1:0]        axis_app_egr_tuser_trunc_enable;
    logic [N-1:0][15:0]  axis_app_egr_tuser_trunc_length;
    logic [N-1:0]        axis_app_egr_tuser_rss_enable;
    logic [N-1:0][11:0]  axis_app_egr_tuser_rss_entropy;

    generate
        for (genvar j = 0; j < N; j += 1) begin
            assign axis_out_if[j].tvalid             = axis_app_egr_tvalid[j];
            assign axis_app_egr_tready[j]            = axis_out_if[j].tready;
            assign axis_out_if[j].tdata              = axis_app_egr_tdata[j];
            assign axis_out_if[j].tkeep              = axis_app_egr_tkeep[j];
            assign axis_out_if[j].tlast              = axis_app_egr_tlast[j];
            assign axis_out_if[j].tid                = axis_app_egr_tid[j];
            assign axis_out_if[j].tdest              = axis_app_egr_tdest[j];
            assign axis_out_if[j].tuser.pid          = axis_app_egr_tuser_pid[j];
            assign axis_out_if[j].tuser.trunc_enable = axis_app_egr_tuser_trunc_enable[j];
            assign axis_out_if[j].tuser.trunc_length = axis_app_egr_tuser_trunc_length[j];
            assign axis_out_if[j].tuser.rss_enable   = axis_app_egr_tuser_rss_enable[j];
            assign axis_out_if[j].tuser.rss_entropy  = axis_app_egr_tuser_rss_entropy[j];
        end
    endgenerate

    logic [N*HOST_NUM_IFS-1:0]        axis_h2c_tvalid;
    logic [N*HOST_NUM_IFS-1:0]        axis_h2c_tready;
    logic [N*HOST_NUM_IFS-1:0][511:0] axis_h2c_tdata;
    logic [N*HOST_NUM_IFS-1:0][63:0]  axis_h2c_tkeep;
    logic [N*HOST_NUM_IFS-1:0]        axis_h2c_tlast;
    logic [N*HOST_NUM_IFS-1:0][1:0]   axis_h2c_tid;
    logic [N*HOST_NUM_IFS-1:0][1:0]   axis_h2c_tdest;
    logic [N*HOST_NUM_IFS-1:0][15:0]  axis_h2c_tuser_pid;

    generate
        for (genvar j = 0; j < N*HOST_NUM_IFS; j += 1) begin
            assign axis_h2c_tvalid[j]    = '0;
//            assign axis_in_if[j].tready  = axis_h2c_tready[j];
            assign axis_h2c_tdata[j]     = '0;
            assign axis_h2c_tkeep[j]     = '0;
            assign axis_h2c_tlast[j]     = '0;
            assign axis_h2c_tid[j]       = '0;
            assign axis_h2c_tdest[j]     = '0;
            assign axis_h2c_tuser_pid[j] = '0;
        end
    endgenerate

    logic [N*HOST_NUM_IFS-1:0]        axis_c2h_tvalid;
    logic [N*HOST_NUM_IFS-1:0]        axis_c2h_tready;
    logic [N*HOST_NUM_IFS-1:0][511:0] axis_c2h_tdata;
    logic [N*HOST_NUM_IFS-1:0][63:0]  axis_c2h_tkeep;
    logic [N*HOST_NUM_IFS-1:0]        axis_c2h_tlast;
    logic [N*HOST_NUM_IFS-1:0][1:0]   axis_c2h_tid;
    logic [N*HOST_NUM_IFS-1:0][2:0]   axis_c2h_tdest;
    logic [N*HOST_NUM_IFS-1:0][15:0]  axis_c2h_tuser_pid;
    logic [N*HOST_NUM_IFS-1:0]        axis_c2h_tuser_trunc_enable;
    logic [N*HOST_NUM_IFS-1:0][15:0]  axis_c2h_tuser_trunc_length;
    logic [N*HOST_NUM_IFS-1:0]        axis_c2h_tuser_rss_enable;
    logic [N*HOST_NUM_IFS-1:0][11:0]  axis_c2h_tuser_rss_entropy;

    generate
        for (genvar j = 0; j < N*HOST_NUM_IFS; j += 1) begin
            assign axis_c2h_if[j].tvalid             = axis_c2h_tvalid[j];
            assign axis_c2h_tready[j]                = axis_c2h_if[j].tready;
            assign axis_c2h_if[j].tdata              = axis_c2h_tdata[j];
            assign axis_c2h_if[j].tkeep              = axis_c2h_tkeep[j];
            assign axis_c2h_if[j].tlast              = axis_c2h_tlast[j];
            assign axis_c2h_if[j].tid                = axis_c2h_tid[j];
            assign axis_c2h_if[j].tdest              = axis_c2h_tdest[j];
            assign axis_c2h_if[j].tuser.pid          = axis_c2h_tuser_pid[j];
            assign axis_c2h_if[j].tuser.trunc_enable = axis_c2h_tuser_trunc_enable[j];
            assign axis_c2h_if[j].tuser.trunc_length = axis_c2h_tuser_trunc_length[j];
            assign axis_c2h_if[j].tuser.rss_enable   = axis_c2h_tuser_rss_enable[j];
            assign axis_c2h_if[j].tuser.rss_entropy  = axis_c2h_tuser_rss_entropy[j];
        end
    endgenerate

    logic [15:0]        axi_to_hbm_aclk;
    logic [15:0]        axi_to_hbm_aresetn;
    logic [15:0][5:0]   axi_to_hbm_awid;
    logic [15:0][32:0]  axi_to_hbm_awaddr;
    logic [15:0][3:0]   axi_to_hbm_awlen;
    logic [15:0][2:0]   axi_to_hbm_awsize;
    logic [15:0][1:0]   axi_to_hbm_awburst;
    logic [15:0][1:0]   axi_to_hbm_awlock;
    logic [15:0][3:0]   axi_to_hbm_awcache;
    logic [15:0][2:0]   axi_to_hbm_awprot;
    logic [15:0][3:0]   axi_to_hbm_awqos;
    logic [15:0][3:0]   axi_to_hbm_awregion;
    logic [15:0]        axi_to_hbm_awuser;
    logic [15:0]        axi_to_hbm_awvalid;
    logic [15:0]        axi_to_hbm_awready;
    logic [15:0][5:0]   axi_to_hbm_wid;
    logic [15:0][255:0] axi_to_hbm_wdata;
    logic [15:0][31:0]  axi_to_hbm_wstrb;
    logic [15:0]        axi_to_hbm_wlast;
    logic [15:0]        axi_to_hbm_wuser;
    logic [15:0]        axi_to_hbm_wvalid;
    logic [15:0]        axi_to_hbm_wready;
    logic [15:0][5:0]   axi_to_hbm_bid;
    logic [15:0][1:0]   axi_to_hbm_bresp;
    logic [15:0]        axi_to_hbm_buser;
    logic [15:0]        axi_to_hbm_bvalid;
    logic [15:0]        axi_to_hbm_bready;
    logic [15:0][5:0]   axi_to_hbm_arid;
    logic [15:0][32:0]  axi_to_hbm_araddr;
    logic [15:0][3:0]   axi_to_hbm_arlen;
    logic [15:0][2:0]   axi_to_hbm_arsize;
    logic [15:0][1:0]   axi_to_hbm_arburst;
    logic [15:0][1:0]   axi_to_hbm_arlock;
    logic [15:0][3:0]   axi_to_hbm_arcache;
    logic [15:0][2:0]   axi_to_hbm_arprot;
    logic [15:0][3:0]   axi_to_hbm_arqos;
    logic [15:0][3:0]   axi_to_hbm_arregion;
    logic [15:0]        axi_to_hbm_aruser;
    logic [15:0]        axi_to_hbm_arvalid;
    logic [15:0]        axi_to_hbm_arready;
    logic [15:0][5:0]   axi_to_hbm_rid;
    logic [15:0][255:0] axi_to_hbm_rdata;
    logic [15:0][1:0]   axi_to_hbm_rresp;
    logic [15:0]        axi_to_hbm_rlast;
    logic [15:0]        axi_to_hbm_ruser;
    logic [15:0]        axi_to_hbm_rvalid;
    logic [15:0]        axi_to_hbm_rready;

    generate
        for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
               axi3_intf_from_signals #(
                   .DATA_BYTE_WID(32),
                   .ADDR_WID     (33),
                   .ID_T         (logic[5:0])
               ) axi3_intf_from_signals__hbm (
                   .aclk     ( axi_to_hbm_aclk    [g_hbm_if] ),
                   .aresetn  ( axi_to_hbm_aresetn [g_hbm_if] ),
                   .awid     ( axi_to_hbm_awid    [g_hbm_if] ),
                   .awaddr   ( axi_to_hbm_awaddr  [g_hbm_if] ),
                   .awlen    ( axi_to_hbm_awlen   [g_hbm_if] ),
                   .awsize   ( axi_to_hbm_awsize  [g_hbm_if] ),
                   .awburst  ( axi_to_hbm_awburst [g_hbm_if] ),
                   .awlock   ( axi_to_hbm_awlock  [g_hbm_if] ),
                   .awcache  ( axi_to_hbm_awcache [g_hbm_if] ),
                   .awprot   ( axi_to_hbm_awprot  [g_hbm_if] ),
                   .awqos    ( axi_to_hbm_awqos   [g_hbm_if] ),
                   .awregion ( axi_to_hbm_awregion[g_hbm_if] ),
                   .awuser   ( axi_to_hbm_awuser  [g_hbm_if] ),
                   .awvalid  ( axi_to_hbm_awvalid [g_hbm_if] ),
                   .awready  ( axi_to_hbm_awready [g_hbm_if] ),
                   .wid      ( axi_to_hbm_wid     [g_hbm_if] ),
                   .wdata    ( axi_to_hbm_wdata   [g_hbm_if] ),
                   .wstrb    ( axi_to_hbm_wstrb   [g_hbm_if] ),
                   .wlast    ( axi_to_hbm_wlast   [g_hbm_if] ),
                   .wuser    ( axi_to_hbm_wuser   [g_hbm_if] ),
                   .wvalid   ( axi_to_hbm_wvalid  [g_hbm_if] ),
                   .wready   ( axi_to_hbm_wready  [g_hbm_if] ),
                   .bid      ( axi_to_hbm_bid     [g_hbm_if] ),
                   .bresp    ( axi_to_hbm_bresp   [g_hbm_if] ),
                   .buser    ( axi_to_hbm_buser   [g_hbm_if] ),
                   .bvalid   ( axi_to_hbm_bvalid  [g_hbm_if] ),
                   .bready   ( axi_to_hbm_bready  [g_hbm_if] ),
                   .arid     ( axi_to_hbm_arid    [g_hbm_if] ),
                   .araddr   ( axi_to_hbm_araddr  [g_hbm_if] ),
                   .arlen    ( axi_to_hbm_arlen   [g_hbm_if] ),
                   .arsize   ( axi_to_hbm_arsize  [g_hbm_if] ),
                   .arburst  ( axi_to_hbm_arburst [g_hbm_if] ),
                   .arlock   ( axi_to_hbm_arlock  [g_hbm_if] ),
                   .arcache  ( axi_to_hbm_arcache [g_hbm_if] ),
                   .arprot   ( axi_to_hbm_arprot  [g_hbm_if] ),
                   .arqos    ( axi_to_hbm_arqos   [g_hbm_if] ),
                   .arregion ( axi_to_hbm_arregion[g_hbm_if] ),
                   .aruser   ( axi_to_hbm_aruser  [g_hbm_if] ),
                   .arvalid  ( axi_to_hbm_arvalid [g_hbm_if] ),
                   .arready  ( axi_to_hbm_arready [g_hbm_if] ),
                   .rid      ( axi_to_hbm_rid     [g_hbm_if] ),
                   .rdata    ( axi_to_hbm_rdata   [g_hbm_if] ),
                   .rresp    ( axi_to_hbm_rresp   [g_hbm_if] ),
                   .rlast    ( axi_to_hbm_rlast   [g_hbm_if] ),
                   .ruser    ( axi_to_hbm_ruser   [g_hbm_if] ),
                   .rvalid   ( axi_to_hbm_rvalid  [g_hbm_if] ),
                   .rready   ( axi_to_hbm_rready  [g_hbm_if] ),
                   .axi3_if  ( axi_to_hbm [g_hbm_if] )
               );
        end : g__hbm_if
    endgenerate

    // DUT instance
    smartnic_app DUT (
        .core_clk     (clk),
        .core_rstn    (rstn),
        .timestamp    (timestamp),
        .axil_aclk    (axil_if.aclk),
        // P4 AXI-L control interface
        .axil_aresetn (axil_if.aresetn),
        .axil_awvalid (axil_if.awvalid),
        .axil_awready (axil_if.awready),
        .axil_awaddr  (axil_if.awaddr),
        .axil_awprot  (axil_if.awprot),
        .axil_wvalid  (axil_if.wvalid),
        .axil_wready  (axil_if.wready),
        .axil_wdata   (axil_if.wdata),
        .axil_wstrb   (axil_if.wstrb),
        .axil_bvalid  (axil_if.bvalid),
        .axil_bready  (axil_if.bready),
        .axil_bresp   (axil_if.bresp),
        .axil_arvalid (axil_if.arvalid),
        .axil_arready (axil_if.arready),
        .axil_araddr  (axil_if.araddr),
        .axil_arprot  (axil_if.arprot),
        .axil_rvalid  (axil_if.rvalid),
        .axil_rready  (axil_if.rready),
        .axil_rdata   (axil_if.rdata),
        .axil_rresp   (axil_if.rresp),
        // App AXI-L control interface
        .app_axil_aresetn (app_axil_if.aresetn),
        .app_axil_awvalid (app_axil_if.awvalid),
        .app_axil_awready (app_axil_if.awready),
        .app_axil_awaddr  (app_axil_if.awaddr),
        .app_axil_awprot  (app_axil_if.awprot),
        .app_axil_wvalid  (app_axil_if.wvalid),
        .app_axil_wready  (app_axil_if.wready),
        .app_axil_wdata   (app_axil_if.wdata),
        .app_axil_wstrb   (app_axil_if.wstrb),
        .app_axil_bvalid  (app_axil_if.bvalid),
        .app_axil_bready  (app_axil_if.bready),
        .app_axil_bresp   (app_axil_if.bresp),
        .app_axil_arvalid (app_axil_if.arvalid),
        .app_axil_arready (app_axil_if.arready),
        .app_axil_araddr  (app_axil_if.araddr),
        .app_axil_arprot  (app_axil_if.arprot),
        .app_axil_rvalid  (app_axil_if.rvalid),
        .app_axil_rready  (app_axil_if.rready),
        .app_axil_rdata   (app_axil_if.rdata),
        .app_axil_rresp   (app_axil_if.rresp),
         // AXI-S data interface (from switch output 0, to app)
        .axis_app_igr_tvalid    ( axis_app_igr_tvalid ),
        .axis_app_igr_tready    ( axis_app_igr_tready ),
        .axis_app_igr_tdata     ( axis_app_igr_tdata ),
        .axis_app_igr_tkeep     ( axis_app_igr_tkeep ),
        .axis_app_igr_tlast     ( axis_app_igr_tlast ),
        .axis_app_igr_tid       ( axis_app_igr_tid ),
        .axis_app_igr_tdest     ( axis_app_igr_tdest ),
        .axis_app_igr_tuser_pid ( axis_app_igr_tuser_pid ),
        // AXI-S data interface (from app, to switch input 0)
        .axis_app_egr_tvalid            ( axis_app_egr_tvalid ),
        .axis_app_egr_tready            ( axis_app_egr_tready ),
        .axis_app_egr_tdata             ( axis_app_egr_tdata ),
        .axis_app_egr_tkeep             ( axis_app_egr_tkeep ),
        .axis_app_egr_tlast             ( axis_app_egr_tlast ),
        .axis_app_egr_tid               ( axis_app_egr_tid ),
        .axis_app_egr_tdest             ( axis_app_egr_tdest ),
        .axis_app_egr_tuser_pid         ( axis_app_egr_tuser_pid ),
        .axis_app_egr_tuser_rss_enable  ( axis_app_egr_tuser_rss_enable ),
        .axis_app_egr_tuser_rss_entropy ( axis_app_egr_tuser_rss_entropy ),
         // AXI-S data interface (from switch output 0, to app)
        .axis_h2c_tvalid    ( axis_h2c_tvalid ),
        .axis_h2c_tready    ( axis_h2c_tready ),
        .axis_h2c_tdata     ( axis_h2c_tdata ),
        .axis_h2c_tkeep     ( axis_h2c_tkeep ),
        .axis_h2c_tlast     ( axis_h2c_tlast ),
        .axis_h2c_tid       ( axis_h2c_tid ),
        .axis_h2c_tdest     ( axis_h2c_tdest ),
        .axis_h2c_tuser_pid ( axis_h2c_tuser_pid ),
        // AXI-S data interface (from app, to switch input 0)
        .axis_c2h_tvalid            ( axis_c2h_tvalid ),
        .axis_c2h_tready            ( axis_c2h_tready ),
        .axis_c2h_tdata             ( axis_c2h_tdata ),
        .axis_c2h_tkeep             ( axis_c2h_tkeep ),
        .axis_c2h_tlast             ( axis_c2h_tlast ),
        .axis_c2h_tid               ( axis_c2h_tid ),
        .axis_c2h_tdest             ( axis_c2h_tdest ),
        .axis_c2h_tuser_pid         ( axis_c2h_tuser_pid ),
        .axis_c2h_tuser_rss_enable  ( axis_c2h_tuser_rss_enable ),
        .axis_c2h_tuser_rss_entropy ( axis_c2h_tuser_rss_entropy ),
        // egress flow control interface
        .egr_flow_ctl            ( '0 ),
        // AXI3 interfaces to HBM
        // (synchronous to core clock domain)
        .axi_to_hbm_aclk     ( axi_to_hbm_aclk    ),
        .axi_to_hbm_aresetn  ( axi_to_hbm_aresetn ),
        .axi_to_hbm_awid     ( axi_to_hbm_awid    ),
        .axi_to_hbm_awaddr   ( axi_to_hbm_awaddr  ),
        .axi_to_hbm_awlen    ( axi_to_hbm_awlen   ),
        .axi_to_hbm_awsize   ( axi_to_hbm_awsize  ),
        .axi_to_hbm_awburst  ( axi_to_hbm_awburst ),
        .axi_to_hbm_awlock   ( axi_to_hbm_awlock  ),
        .axi_to_hbm_awcache  ( axi_to_hbm_awcache ),
        .axi_to_hbm_awprot   ( axi_to_hbm_awprot  ),
        .axi_to_hbm_awqos    ( axi_to_hbm_awqos   ),
        .axi_to_hbm_awregion ( axi_to_hbm_awregion),
        .axi_to_hbm_awvalid  ( axi_to_hbm_awvalid ),
        .axi_to_hbm_awready  ( axi_to_hbm_awready ),
        .axi_to_hbm_wid      ( axi_to_hbm_wid     ),
        .axi_to_hbm_wdata    ( axi_to_hbm_wdata   ),
        .axi_to_hbm_wstrb    ( axi_to_hbm_wstrb   ),
        .axi_to_hbm_wlast    ( axi_to_hbm_wlast   ),
        .axi_to_hbm_wvalid   ( axi_to_hbm_wvalid  ),
        .axi_to_hbm_wready   ( axi_to_hbm_wready  ),
        .axi_to_hbm_bid      ( axi_to_hbm_bid     ),
        .axi_to_hbm_bresp    ( axi_to_hbm_bresp   ),
        .axi_to_hbm_bvalid   ( axi_to_hbm_bvalid  ),
        .axi_to_hbm_bready   ( axi_to_hbm_bready  ),
        .axi_to_hbm_arid     ( axi_to_hbm_arid    ),
        .axi_to_hbm_araddr   ( axi_to_hbm_araddr  ),
        .axi_to_hbm_arlen    ( axi_to_hbm_arlen   ),
        .axi_to_hbm_arsize   ( axi_to_hbm_arsize  ),
        .axi_to_hbm_arburst  ( axi_to_hbm_arburst ),
        .axi_to_hbm_arlock   ( axi_to_hbm_arlock  ),
        .axi_to_hbm_arcache  ( axi_to_hbm_arcache ),
        .axi_to_hbm_arprot   ( axi_to_hbm_arprot  ),
        .axi_to_hbm_arqos    ( axi_to_hbm_arqos   ),
        .axi_to_hbm_arregion ( axi_to_hbm_arregion),
        .axi_to_hbm_arvalid  ( axi_to_hbm_arvalid ),
        .axi_to_hbm_arready  ( axi_to_hbm_arready ),
        .axi_to_hbm_rid      ( axi_to_hbm_rid     ),
        .axi_to_hbm_rdata    ( axi_to_hbm_rdata   ),
        .axi_to_hbm_rresp    ( axi_to_hbm_rresp   ),
        .axi_to_hbm_rlast    ( axi_to_hbm_rlast   ),
        .axi_to_hbm_rvalid   ( axi_to_hbm_rvalid  ),
        .axi_to_hbm_rready   ( axi_to_hbm_rready  )
    );

    hbm_bfm #(.PSEUDO_CHANNELS (16)) i_hbm_model (.axi3_if (axi_to_hbm));

    //===================================
    // Local signals
    //===================================
    logic rst;

    // Interfaces
    std_reset_intf #(.ACTIVE_LOW(1)) reset_if      (.clk(clk));
    std_reset_intf #(.ACTIVE_LOW(1)) mgmt_reset_if (.clk(axil_if.aclk));

    timestamp_if #() timestamp_if (.clk(clk), .srst(rst));

    // Generate datapath clock
    initial clk = 1'b0;
    always #1455ps clk = ~clk; // 343.75 MHz

    // Generate AXI management clock
    initial axil_if.aclk = 1'b0;
    always  #4ns axil_if.aclk = ~axil_if.aclk; // 125 MHz


    // Assign reset interfaces
    assign rstn = reset_if.reset;
    initial reset_if.ready = 1'b0;
    always @(posedge clk) reset_if.ready <= rstn;

    assign axil_if.aresetn = mgmt_reset_if.reset;
    initial mgmt_reset_if.ready = 1'b0;
    always @(posedge axil_if.aclk) mgmt_reset_if.ready <= axil_if.aresetn;

    assign rst = ~rstn;

    // App AXI-L interface shares common AXI-L clock/reset
    assign app_axil_if.aclk    = axil_if.aclk;
    assign app_axil_if.aresetn = axil_if.aresetn;

    // Timestamp
    assign timestamp = timestamp_if.timestamp;

    // Assign AXI-S input clock/reset
    assign axis_in_if[0].aclk = clk;
    assign axis_in_if[0].aresetn = rstn;

    assign axis_in_if[1].aclk = clk;
    assign axis_in_if[1].aresetn = rstn;

    assign axis_out_if[0].aclk = clk;
    assign axis_out_if[0].aresetn = rstn;

    assign axis_out_if[1].aclk = clk;
    assign axis_out_if[1].aresetn = rstn;

    assign axis_c2h_if[0].aclk = clk;
    assign axis_c2h_if[0].aresetn = rstn;

    assign axis_c2h_if[1].aclk = clk;
    assign axis_c2h_if[1].aresetn = rstn;

    //===================================
    // Build
    //===================================
    function void build();
        if (env == null) begin
            // Instantiate environment
            env = new("tb_env",0); // Configure for little-endian

            // Connect
            env.reset_vif = reset_if;
            env.mgmt_reset_vif = mgmt_reset_if;
            env.timestamp_vif = timestamp_if;
            env.axil_vif = app_axil_if;
            env.axil_vitisnetp4_vif = axil_if;
            env.axis_in_vif[0]  = axis_in_if[0];
            env.axis_in_vif[1]  = axis_in_if[1];
            env.axis_out_vif[0] = axis_out_if[0];
            env.axis_out_vif[1] = axis_out_if[1];
            env.axis_c2h_vif[0] = axis_c2h_if[0];
            env.axis_c2h_vif[1] = axis_c2h_if[1];

            env.axi_to_hbm_vif = axi_to_hbm;

            env.connect();
        end
    endfunction

    // Export AXI-L accessors to VitisNetP4 shared library
    export "DPI-C" task axi_lite_wr;
    task axi_lite_wr(input int address, input int data);
        env.vitisnetp4_write(address, data);
    endtask

    export "DPI-C" task axi_lite_rd;
    task axi_lite_rd(input int address, inout int data);
        env.vitisnetp4_read(address, data);
    endtask

endmodule : tb
