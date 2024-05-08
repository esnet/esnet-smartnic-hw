module smartnic_app
#(
    parameter int AXI_HBM_NUM_IFS = 16,
    parameter int N = 2, // Number of processor ports (per vitisnetp4 processor).
    parameter int M = 2  // Number of vitisnetp4 processors.
) (
    input  logic         core_clk,
    input  logic         core_rstn,
    input  logic         axil_aclk,
    input  logic [63:0]  timestamp,

    // P4 AXI-L control interface
    // (synchronous to axil_aclk domain)
    // -- Reset
    input  logic         axil_aresetn,
    // -- Write address
    input  logic         axil_awvalid,
    output logic         axil_awready,
    input  logic [31:0]  axil_awaddr,
    input  logic [2:0]   axil_awprot,
    // -- Write data
    input  logic         axil_wvalid,
    output logic         axil_wready,
    input  logic [31:0]  axil_wdata,
    input  logic [3:0]   axil_wstrb,
    // -- Write response
    output logic         axil_bvalid,
    input  logic         axil_bready,
    output logic [1:0]   axil_bresp,
    // -- Read address
    input  logic         axil_arvalid,
    output logic         axil_arready,
    input  logic [31:0]  axil_araddr,
    input  logic [2:0]   axil_arprot,
    // -- Read data
    output logic         axil_rvalid,
    input  logic         axil_rready,
    output logic [31:0]  axil_rdata,
    output logic [1:0]   axil_rresp,

    // App AXI-L control interface
    // (synchronous to axil_aclk domain)
    // -- Reset
    input  logic         app_axil_aresetn,
    // -- Write address
    input  logic         app_axil_awvalid,
    output logic         app_axil_awready,
    input  logic [31:0]  app_axil_awaddr,
    input  logic [2:0]   app_axil_awprot,
    // -- Write data
    input  logic         app_axil_wvalid,
    output logic         app_axil_wready,
    input  logic [31:0]  app_axil_wdata,
    input  logic [3:0]   app_axil_wstrb,
    // -- Write response
    output logic         app_axil_bvalid,
    input  logic         app_axil_bready,
    output logic [1:0]   app_axil_bresp,
    // -- Read address
    input  logic         app_axil_arvalid,
    output logic         app_axil_arready,
    input  logic [31:0]  app_axil_araddr,
    input  logic [2:0]   app_axil_arprot,
    // -- Read data
    output logic         app_axil_rvalid,
    input  logic         app_axil_rready,
    output logic [31:0]  app_axil_rdata,
    output logic [1:0]   app_axil_rresp,

    // AXI-S data interface (from switch)
    // (synchronous to core_clk domain)
    input  logic [(M*N*  1)-1:0] axis_from_switch_tvalid,
    output logic [(M*N*  1)-1:0] axis_from_switch_tready,
    input  logic [(M*N*512)-1:0] axis_from_switch_tdata,
    input  logic [(M*N* 64)-1:0] axis_from_switch_tkeep,
    input  logic [(M*N*  1)-1:0] axis_from_switch_tlast,
    input  logic [(M*N*  2)-1:0] axis_from_switch_tid,
    input  logic [(M*N*  2)-1:0] axis_from_switch_tdest,
    input  logic [(M*N* 16)-1:0] axis_from_switch_tuser_pid,

    // AXI-S data interface (to switch)
    // (synchronous to core_clk domain)
    output logic [(M*N*  1)-1:0] axis_to_switch_tvalid,
    input  logic [(M*N*  1)-1:0] axis_to_switch_tready,
    output logic [(M*N*512)-1:0] axis_to_switch_tdata,
    output logic [(M*N* 64)-1:0] axis_to_switch_tkeep,
    output logic [(M*N*  1)-1:0] axis_to_switch_tlast,
    output logic [(M*N*  2)-1:0] axis_to_switch_tid,
    output logic [(M*N*  3)-1:0] axis_to_switch_tdest,
    output logic [(M*N* 16)-1:0] axis_to_switch_tuser_pid,
    output logic [(M*N*  1)-1:0] axis_to_switch_tuser_trunc_enable,
    output logic [(M*N* 16)-1:0] axis_to_switch_tuser_trunc_length,
    output logic [(M*N*  1)-1:0] axis_to_switch_tuser_rss_enable,
    output logic [(M*N* 12)-1:0] axis_to_switch_tuser_rss_entropy,

    // flow control signals (one from each egress FIFO).
    input logic [3:0]    egr_flow_ctl,

    // AXI3 interfaces to HBM
    // (synchronous to core clock domain)
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_aclk,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_aresetn,
    output logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_awid,
    output logic [(AXI_HBM_NUM_IFS* 33)-1:0] axi_to_hbm_awaddr,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_awlen,
    output logic [(AXI_HBM_NUM_IFS*  3)-1:0] axi_to_hbm_awsize,
    output logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_awburst,
    output logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_awlock,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_awcache,
    output logic [(AXI_HBM_NUM_IFS*  3)-1:0] axi_to_hbm_awprot,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_awqos,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_awregion,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_awvalid,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_awready,
    output logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_wid,
    output logic [(AXI_HBM_NUM_IFS*256)-1:0] axi_to_hbm_wdata,
    output logic [(AXI_HBM_NUM_IFS* 32)-1:0] axi_to_hbm_wstrb,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_wlast,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_wvalid,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_wready,
    input  logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_bid,
    input  logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_bresp,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_bvalid,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_bready,
    output logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_arid,
    output logic [(AXI_HBM_NUM_IFS* 33)-1:0] axi_to_hbm_araddr,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_arlen,
    output logic [(AXI_HBM_NUM_IFS*  3)-1:0] axi_to_hbm_arsize,
    output logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_arburst,
    output logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_arlock,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_arcache,
    output logic [(AXI_HBM_NUM_IFS*  3)-1:0] axi_to_hbm_arprot,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_arqos,
    output logic [(AXI_HBM_NUM_IFS*  4)-1:0] axi_to_hbm_arregion,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_arvalid,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_arready,
    input  logic [(AXI_HBM_NUM_IFS*  6)-1:0] axi_to_hbm_rid,
    input  logic [(AXI_HBM_NUM_IFS*256)-1:0] axi_to_hbm_rdata,
    input  logic [(AXI_HBM_NUM_IFS*  2)-1:0] axi_to_hbm_rresp,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_rlast,
    input  logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_rvalid,
    output logic [(AXI_HBM_NUM_IFS*  1)-1:0] axi_to_hbm_rready
);
    import smartnic_pkg::*;
    import axi4s_pkg::*;

    // Parameters
    localparam int  AXIS_DATA_BYTE_WID = 64;

    localparam int  AXI_HBM_DATA_BYTE_WID = 32;
    localparam int  AXI_HBM_ADDR_WID = 33;
    localparam type AXI_HBM_ID_T = logic[5:0];

    // Interfaces
    axi4l_intf #() axil_if ();
    axi4l_intf #() app_axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(egr_tdest_t), .TUSER_T(tuser_smartnic_meta_t)) axis_to_switch [M][N] ();

    tuser_smartnic_meta_t  axis_to_switch_tuser[M][N];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_from_switch [M][N] ();

    tuser_smartnic_meta_t  axis_from_switch_tuser[M][N];

    generate
        for (genvar i = 0; i < M; i += 1) begin
            for (genvar j = 0; j < N; j += 1) begin
                assign axis_to_switch_tuser_pid          [(i*N+j)*16 +: 16] = axis_to_switch_tuser[i][j].pid;
                assign axis_to_switch_tuser_trunc_enable [(i*N+j)* 1 +:  1] = axis_to_switch_tuser[i][j].trunc_enable;
                assign axis_to_switch_tuser_trunc_length [(i*N+j)*16 +: 16] = axis_to_switch_tuser[i][j].trunc_length;
                assign axis_to_switch_tuser_rss_enable   [(i*N+j)* 1 +:  1] = axis_to_switch_tuser[i][j].rss_enable;
                assign axis_to_switch_tuser_rss_entropy  [(i*N+j)*12 +: 12] = axis_to_switch_tuser[i][j].rss_entropy;

                assign axis_from_switch_tuser[i][j].pid          = axis_from_switch_tuser_pid[(i*N+j)*16 +: 16];
                assign axis_from_switch_tuser[i][j].trunc_enable = '0;
                assign axis_from_switch_tuser[i][j].trunc_length = '0;
                assign axis_from_switch_tuser[i][j].rss_enable   = '0;
                assign axis_from_switch_tuser[i][j].rss_entropy  = '0;
            end
        end
    endgenerate

    axi3_intf  #(
        .DATA_BYTE_WID(AXI_HBM_DATA_BYTE_WID), .ADDR_WID(AXI_HBM_ADDR_WID), .ID_T(AXI_HBM_ID_T)
    ) axi_to_hbm [AXI_HBM_NUM_IFS] ();

    // -------------------------------------------------------------------------------------------------------
    // MAP FROM 'FLAT' SIGNAL REPRESENTATION TO INTERFACE REPRESENTATION (COMMON TO ALL APPLICATIONS)
    // -------------------------------------------------------------------------------------------------------
    // -- P4 AXI-L interface
    axi4l_intf_from_signals axil_if_from_signals (
        .aclk     ( axil_aclk ),
        .aresetn  ( axil_aresetn ),
        .awvalid  ( axil_awvalid ),
        .awready  ( axil_awready ),
        .awaddr   ( axil_awaddr ),
        .awprot   ( axil_awprot ),
        .wvalid   ( axil_wvalid ),
        .wready   ( axil_wready ),
        .wdata    ( axil_wdata ),
        .wstrb    ( axil_wstrb ),
        .bvalid   ( axil_bvalid ),
        .bready   ( axil_bready ),
        .bresp    ( axil_bresp ),
        .arvalid  ( axil_arvalid ),
        .arready  ( axil_arready ),
        .araddr   ( axil_araddr ),
        .arprot   ( axil_arprot ),
        .rvalid   ( axil_rvalid ),
        .rready   ( axil_rready ),
        .rdata    ( axil_rdata ),
        .rresp    ( axil_rresp ),
        .axi4l_if ( axil_if )
    );

    // -- App AXI-L interface
    axi4l_intf_from_signals app_axil_if_from_signals (
        .aclk     ( axil_aclk ),
        .aresetn  ( app_axil_aresetn ),
        .awvalid  ( app_axil_awvalid ),
        .awready  ( app_axil_awready ),
        .awaddr   ( app_axil_awaddr ),
        .awprot   ( app_axil_awprot ),
        .wvalid   ( app_axil_wvalid ),
        .wready   ( app_axil_wready ),
        .wdata    ( app_axil_wdata ),
        .wstrb    ( app_axil_wstrb ),
        .bvalid   ( app_axil_bvalid ),
        .bready   ( app_axil_bready ),
        .bresp    ( app_axil_bresp ),
        .arvalid  ( app_axil_arvalid ),
        .arready  ( app_axil_arready ),
        .araddr   ( app_axil_araddr ),
        .arprot   ( app_axil_arprot ),
        .rvalid   ( app_axil_rvalid ),
        .rready   ( app_axil_rready ),
        .rdata    ( app_axil_rdata ),
        .rresp    ( app_axil_rresp ),
        .axi4l_if ( app_axil_if )
    );

    generate
        for (genvar i = 0; i < M; i += 1) begin
            for (genvar j = 0; j < N; j += 1) begin
                // -- AXI-S interface from switch
                axi4s_intf_from_signals #(
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)
                ) i_axi4s_intf_from_signals_from_switch (
                    .aclk    ( core_clk ),
                    .aresetn ( core_rstn ),
                    .tvalid  ( axis_from_switch_tvalid [(i*N+j)*  1 +:   1] ),
                    .tready  ( axis_from_switch_tready [(i*N+j)*  1 +:   1] ),
                    .tdata   ( axis_from_switch_tdata  [(i*N+j)*512 +: 512] ),
                    .tkeep   ( axis_from_switch_tkeep  [(i*N+j)* 64 +:  64] ),
                    .tlast   ( axis_from_switch_tlast  [(i*N+j)*  1 +:   1] ),
                    .tid     ( axis_from_switch_tid    [(i*N+j)*  2 +:   2] ),
                    .tdest   ( axis_from_switch_tdest  [(i*N+j)*  2 +:   2] ),
                    .tuser   ( axis_from_switch_tuser  [i][j] ),
                    .axi4s_if( axis_from_switch[i][j] )
                );
                // -- AXI-S interface to switch
                axi4s_intf_to_signals #(
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t), .TUSER_T(tuser_smartnic_meta_t)
                ) i_axi4s_to_signals_to_switch (
                    .aclk    ( ), // Output
                    .aresetn ( ), // Output
                    .tvalid  ( axis_to_switch_tvalid [(i*N+j)*  1 +:   1] ),
                    .tready  ( axis_to_switch_tready [(i*N+j)*  1 +:   1] ),
                    .tdata   ( axis_to_switch_tdata  [(i*N+j)*512 +: 512] ),
                    .tkeep   ( axis_to_switch_tkeep  [(i*N+j)* 64 +:  64] ),
                    .tlast   ( axis_to_switch_tlast  [(i*N+j)*  1 +:   1] ),
                    .tid     ( axis_to_switch_tid    [(i*N+j)*  2 +:   2] ),
                    .tdest   ( axis_to_switch_tdest  [(i*N+j)*  3 +:   3] ),
                    .tuser   ( axis_to_switch_tuser  [i][j] ),
                    .axi4s_if( axis_to_switch[i][j] )
                );
            end
        end
    endgenerate

    // -- AXI memory interfaces to HBM
    generate
        for (genvar g_hbm_if = 0; g_hbm_if < AXI_HBM_NUM_IFS; g_hbm_if++) begin : g__hbm_if
            axi3_intf_to_signals #(
                .DATA_BYTE_WID(AXI_HBM_DATA_BYTE_WID),
                .ADDR_WID     (AXI_HBM_ADDR_WID),
                .ID_T         (AXI_HBM_ID_T)
            ) i_axi3_intf_to_signals__hbm (
                .axi3_if  ( axi_to_hbm [g_hbm_if] ),
                .aclk     ( axi_to_hbm_aclk    [g_hbm_if*  1 +:   1] ),
                .aresetn  ( axi_to_hbm_aresetn [g_hbm_if*  1 +:   1] ),
                .awid     ( axi_to_hbm_awid    [g_hbm_if*  6 +:   6] ),
                .awaddr   ( axi_to_hbm_awaddr  [g_hbm_if* 33 +:  33] ),
                .awlen    ( axi_to_hbm_awlen   [g_hbm_if*  4 +:   4] ),
                .awsize   ( axi_to_hbm_awsize  [g_hbm_if*  3 +:   3] ),
                .awburst  ( axi_to_hbm_awburst [g_hbm_if*  2 +:   2] ),
                .awlock   ( axi_to_hbm_awlock  [g_hbm_if*  2 +:   2] ),
                .awcache  ( axi_to_hbm_awcache [g_hbm_if*  4 +:   4] ),
                .awprot   ( axi_to_hbm_awprot  [g_hbm_if*  3 +:   3] ),
                .awqos    ( axi_to_hbm_awqos   [g_hbm_if*  4 +:   4] ),
                .awregion ( axi_to_hbm_awregion[g_hbm_if*  4 +:   4] ),
                .awuser   (                                          ), // Unused
                .awvalid  ( axi_to_hbm_awvalid [g_hbm_if*  1 +:   1] ),
                .awready  ( axi_to_hbm_awready [g_hbm_if*  1 +:   1] ),
                .wid      ( axi_to_hbm_wid     [g_hbm_if*  6 +:   6] ),
                .wdata    ( axi_to_hbm_wdata   [g_hbm_if*256 +: 256] ),
                .wstrb    ( axi_to_hbm_wstrb   [g_hbm_if* 32 +:  32] ),
                .wlast    ( axi_to_hbm_wlast   [g_hbm_if*  1 +:   1] ),
                .wuser    (                                          ), // Unused
                .wvalid   ( axi_to_hbm_wvalid  [g_hbm_if*  1 +:   1] ),
                .wready   ( axi_to_hbm_wready  [g_hbm_if*  1 +:   1] ),
                .bid      ( axi_to_hbm_bid     [g_hbm_if*  6 +:   6] ),
                .bresp    ( axi_to_hbm_bresp   [g_hbm_if*  2 +:   2] ),
                .buser    ( '0                                       ), // Unused
                .bvalid   ( axi_to_hbm_bvalid  [g_hbm_if*  1 +:   1] ),
                .bready   ( axi_to_hbm_bready  [g_hbm_if*  1 +:   1] ),
                .arid     ( axi_to_hbm_arid    [g_hbm_if*  6 +:   6] ),
                .araddr   ( axi_to_hbm_araddr  [g_hbm_if* 33 +:  33] ),
                .arlen    ( axi_to_hbm_arlen   [g_hbm_if*  4 +:   4] ),
                .arsize   ( axi_to_hbm_arsize  [g_hbm_if*  3 +:   3] ),
                .arburst  ( axi_to_hbm_arburst [g_hbm_if*  2 +:   2] ),
                .arlock   ( axi_to_hbm_arlock  [g_hbm_if*  2 +:   2] ),
                .arcache  ( axi_to_hbm_arcache [g_hbm_if*  4 +:   4] ),
                .arprot   ( axi_to_hbm_arprot  [g_hbm_if*  3 +:   3] ),
                .arqos    ( axi_to_hbm_arqos   [g_hbm_if*  4 +:   4] ),
                .arregion ( axi_to_hbm_arregion[g_hbm_if*  4 +:   4] ),
                .aruser   (                                          ), // Unused
                .arvalid  ( axi_to_hbm_arvalid [g_hbm_if*  1 +:   1] ),
                .arready  ( axi_to_hbm_arready [g_hbm_if*  1 +:   1] ),
                .rid      ( axi_to_hbm_rid     [g_hbm_if*  6 +:   6] ),
                .rdata    ( axi_to_hbm_rdata   [g_hbm_if*256 +: 256] ),
                .rresp    ( axi_to_hbm_rresp   [g_hbm_if*  2 +:   2] ),
                .rlast    ( axi_to_hbm_rlast   [g_hbm_if*  1 +:   1] ),
                .ruser    ( '0                                       ), // Unused
                .rvalid   ( axi_to_hbm_rvalid  [g_hbm_if*  1 +:   1] ),
                .rready   ( axi_to_hbm_rready  [g_hbm_if*  1 +:   1] )
            );
        end : g__hbm_if
    endgenerate

    // -------------------------------------------------------------------------------------------------------
    // APPLICATION-SPECIFIC CONNECTIVITY
    // -------------------------------------------------------------------------------------------------------
    p4_and_verilog p4_and_verilog_0
    (
        .core_clk      ( core_clk ),
        .core_rstn     ( core_rstn ),
        .timestamp     ( timestamp ),

        .axil_if       ( app_axil_if ),
        .axil_to_vitisnetp4 ( axil_if ),

        .axis_from_switch_0  ( axis_from_switch[0][0] ),
        .axis_from_switch_1  ( axis_from_switch[0][1] ),
//        .axis_to_switch_0    ( axis_to_switch[0][0] ),
//        .axis_to_switch_1    ( axis_to_switch[0][1] )
        .axis_to_switch_0    ( axis_to_switch[1][0] ),
        .axis_to_switch_1    ( axis_to_switch[1][1] )
    );

    for (genvar i = 0; i < N; i += 1) begin
        // axi4s_intf_connector axis4s_intf_connector_inst ( .axi4s_from_tx(), .axi4s_to_rx() );
        axi4s_full_pipe axis_switch_1_full_pipe ( .axi4s_if_from_tx(axis_from_switch[1][i]), .axi4s_if_to_rx(axis_to_switch[0][i]) );
    end

    // Terminate AXI HBM interfaces (unused)
    generate
        for (genvar g_hbm_if = 0; g_hbm_if < AXI_HBM_NUM_IFS; g_hbm_if++) begin : g__axi_if_tieoff
            axi3_intf_controller_term i_axi3_controller_term (
                .axi3_if ( axi_to_hbm[g_hbm_if] )
            );
        end : g__axi_if_tieoff
    endgenerate

endmodule: smartnic_app
