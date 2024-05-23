module smartnic_app
#(
    parameter int AXI_HBM_NUM_IFS = 16,
    parameter int HOST_NUM_IFS = 1,
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

    // AXI-S app_igr interface
    // (synchronous to core_clk domain)
    input  logic [(N*  1)-1:0] axis_app_igr_tvalid,
    output logic [(N*  1)-1:0] axis_app_igr_tready,
    input  logic [(N*512)-1:0] axis_app_igr_tdata,
    input  logic [(N* 64)-1:0] axis_app_igr_tkeep,
    input  logic [(N*  1)-1:0] axis_app_igr_tlast,
    input  logic [(N*  2)-1:0] axis_app_igr_tid,
    input  logic [(N*  2)-1:0] axis_app_igr_tdest,
    input  logic [(N* 16)-1:0] axis_app_igr_tuser_pid,

    // AXI-S app_egr interface
    // (synchronous to core_clk domain)
    output logic [(N*  1)-1:0] axis_app_egr_tvalid,
    input  logic [(N*  1)-1:0] axis_app_egr_tready,
    output logic [(N*512)-1:0] axis_app_egr_tdata,
    output logic [(N* 64)-1:0] axis_app_egr_tkeep,
    output logic [(N*  1)-1:0] axis_app_egr_tlast,
    output logic [(N*  2)-1:0] axis_app_egr_tid,
    output logic [(N*  3)-1:0] axis_app_egr_tdest,
    output logic [(N* 16)-1:0] axis_app_egr_tuser_pid,
    output logic [(N*  1)-1:0] axis_app_egr_tuser_trunc_enable,
    output logic [(N* 16)-1:0] axis_app_egr_tuser_trunc_length,
    output logic [(N*  1)-1:0] axis_app_egr_tuser_rss_enable,
    output logic [(N* 12)-1:0] axis_app_egr_tuser_rss_entropy,

    // AXI-S c2h interface
    // (synchronous to core_clk domain)
    input  logic [(HOST_NUM_IFS*N*  1)-1:0] axis_h2c_tvalid,
    output logic [(HOST_NUM_IFS*N*  1)-1:0] axis_h2c_tready,
    input  logic [(HOST_NUM_IFS*N*512)-1:0] axis_h2c_tdata,
    input  logic [(HOST_NUM_IFS*N* 64)-1:0] axis_h2c_tkeep,
    input  logic [(HOST_NUM_IFS*N*  1)-1:0] axis_h2c_tlast,
    input  logic [(HOST_NUM_IFS*N*  2)-1:0] axis_h2c_tid,
    input  logic [(HOST_NUM_IFS*N*  2)-1:0] axis_h2c_tdest,
    input  logic [(HOST_NUM_IFS*N* 16)-1:0] axis_h2c_tuser_pid,

    // AXI-S h2c interface
    // (synchronous to core_clk domain)
    output logic [(HOST_NUM_IFS*N*  1)-1:0] axis_c2h_tvalid,
    input  logic [(HOST_NUM_IFS*N*  1)-1:0] axis_c2h_tready,
    output logic [(HOST_NUM_IFS*N*512)-1:0] axis_c2h_tdata,
    output logic [(HOST_NUM_IFS*N* 64)-1:0] axis_c2h_tkeep,
    output logic [(HOST_NUM_IFS*N*  1)-1:0] axis_c2h_tlast,
    output logic [(HOST_NUM_IFS*N*  2)-1:0] axis_c2h_tid,
    output logic [(HOST_NUM_IFS*N*  3)-1:0] axis_c2h_tdest,
    output logic [(HOST_NUM_IFS*N* 16)-1:0] axis_c2h_tuser_pid,
    output logic [(HOST_NUM_IFS*N*  1)-1:0] axis_c2h_tuser_trunc_enable,
    output logic [(HOST_NUM_IFS*N* 16)-1:0] axis_c2h_tuser_trunc_length,
    output logic [(HOST_NUM_IFS*N*  1)-1:0] axis_c2h_tuser_rss_enable,
    output logic [(HOST_NUM_IFS*N* 12)-1:0] axis_c2h_tuser_rss_entropy,

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
                 .TID_T(port_t), .TDEST_T(egr_tdest_t), .TUSER_T(tuser_smartnic_meta_t)) axis_app_egr[N] ();

    tuser_smartnic_meta_t  axis_app_egr_tuser[N];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_app_igr[N] ();

    tuser_smartnic_meta_t  axis_app_igr_tuser[N];

    generate
        for (genvar j = 0; j < N; j += 1) begin
            assign axis_app_egr_tuser_pid          [(j)*16 +: 16] = axis_app_egr_tuser[j].pid;
            assign axis_app_egr_tuser_trunc_enable [(j)* 1 +:  1] = axis_app_egr_tuser[j].trunc_enable;
            assign axis_app_egr_tuser_trunc_length [(j)*16 +: 16] = axis_app_egr_tuser[j].trunc_length;
            assign axis_app_egr_tuser_rss_enable   [(j)* 1 +:  1] = axis_app_egr_tuser[j].rss_enable;
            assign axis_app_egr_tuser_rss_entropy  [(j)*12 +: 12] = axis_app_egr_tuser[j].rss_entropy;

            assign axis_app_igr_tuser[j].pid          = axis_app_igr_tuser_pid[(j)*16 +: 16];
            assign axis_app_igr_tuser[j].trunc_enable = '0;
            assign axis_app_igr_tuser[j].trunc_length = '0;
            assign axis_app_igr_tuser[j].rss_enable   = '0;
            assign axis_app_igr_tuser[j].rss_entropy  = '0;
        end
    endgenerate

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_h2c[HOST_NUM_IFS][N] ();

    tuser_smartnic_meta_t  axis_h2c_tuser[HOST_NUM_IFS][N];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_c2h[HOST_NUM_IFS][N] ();

    tuser_smartnic_meta_t  axis_c2h_tuser[HOST_NUM_IFS][N];

    generate
        for (genvar i = 0; i < HOST_NUM_IFS; i += 1) begin
            for (genvar j = 0; j < N; j += 1) begin
                assign axis_c2h_tuser_pid          [(i*N+j)*16 +: 16] = axis_c2h_tuser[i][j].pid;
                assign axis_c2h_tuser_trunc_enable [(i*N+j)* 1 +:  1] = axis_c2h_tuser[i][j].trunc_enable;
                assign axis_c2h_tuser_trunc_length [(i*N+j)*16 +: 16] = axis_c2h_tuser[i][j].trunc_length;
                assign axis_c2h_tuser_rss_enable   [(i*N+j)* 1 +:  1] = axis_c2h_tuser[i][j].rss_enable;
                assign axis_c2h_tuser_rss_entropy  [(i*N+j)*12 +: 12] = axis_c2h_tuser[i][j].rss_entropy;

                assign axis_h2c_tuser[i][j].pid          = axis_h2c_tuser_pid[(i*N+j)*16 +: 16];
                assign axis_h2c_tuser[i][j].trunc_enable = '0;
                assign axis_h2c_tuser[i][j].trunc_length = '0;
                assign axis_h2c_tuser[i][j].rss_enable   = '0;
                assign axis_h2c_tuser[i][j].rss_entropy  = '0;
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
        for (genvar j = 0; j < N; j += 1) begin
            // AXI-S app_igr interface
            axi4s_intf_from_signals #(
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)
            ) axis_app_igr_from_signals (
                .aclk    ( core_clk ),
                .aresetn ( core_rstn ),
                .tvalid  ( axis_app_igr_tvalid [(j)*  1 +:   1] ),
                .tready  ( axis_app_igr_tready [(j)*  1 +:   1] ),
                .tdata   ( axis_app_igr_tdata  [(j)*512 +: 512] ),
                .tkeep   ( axis_app_igr_tkeep  [(j)* 64 +:  64] ),
                .tlast   ( axis_app_igr_tlast  [(j)*  1 +:   1] ),
                .tid     ( axis_app_igr_tid    [(j)*  2 +:   2] ),
                .tdest   ( axis_app_igr_tdest  [(j)*  2 +:   2] ),
                .tuser   ( axis_app_igr_tuser  [j] ),
                .axi4s_if( axis_app_igr[j] )
            );
            // AXI-S app_egr interface
            axi4s_intf_to_signals #(
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t), .TUSER_T(tuser_smartnic_meta_t)
            ) axis_app_egr_to_signals (
                .aclk    ( ), // Output
                .aresetn ( ), // Output
                .tvalid  ( axis_app_egr_tvalid [(j)*  1 +:   1] ),
                .tready  ( axis_app_egr_tready [(j)*  1 +:   1] ),
                .tdata   ( axis_app_egr_tdata  [(j)*512 +: 512] ),
                .tkeep   ( axis_app_egr_tkeep  [(j)* 64 +:  64] ),
                .tlast   ( axis_app_egr_tlast  [(j)*  1 +:   1] ),
                .tid     ( axis_app_egr_tid    [(j)*  2 +:   2] ),
                .tdest   ( axis_app_egr_tdest  [(j)*  3 +:   3] ),
                .tuser   ( axis_app_egr_tuser  [j] ),
                .axi4s_if( axis_app_egr[j] )
            );

// TODO - Validate tuser fields.
            for (genvar i = 0; i < HOST_NUM_IFS; i += 1) begin
                // AXI-S h2c interface
                axi4s_intf_from_signals #(
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)
                ) axis_h2c_from_signals (
                    .aclk    ( core_clk ),
                    .aresetn ( core_rstn ),
                    .tvalid  ( axis_h2c_tvalid [(i*N+j)*  1 +:   1] ),
                    .tready  ( axis_h2c_tready [(i*N+j)*  1 +:   1] ),
                    .tdata   ( axis_h2c_tdata  [(i*N+j)*512 +: 512] ),
                    .tkeep   ( axis_h2c_tkeep  [(i*N+j)* 64 +:  64] ),
                    .tlast   ( axis_h2c_tlast  [(i*N+j)*  1 +:   1] ),
                    .tid     ( axis_h2c_tid    [(i*N+j)*  2 +:   2] ),
                    .tdest   ( axis_h2c_tdest  [(i*N+j)*  2 +:   2] ),
                    .tuser   ( axis_h2c_tuser  [i][j] ),
                    .axi4s_if( axis_h2c[i][j] )
                );
                // AXI-S c2h interface
                axi4s_intf_to_signals #(
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t), .TUSER_T(tuser_smartnic_meta_t)
                ) axis_c2h_to_signals (
                    .aclk    ( ), // Output
                    .aresetn ( ), // Output
                    .tvalid  ( axis_c2h_tvalid [(i*N+j)*  1 +:   1] ),
                    .tready  ( axis_c2h_tready [(i*N+j)*  1 +:   1] ),
                    .tdata   ( axis_c2h_tdata  [(i*N+j)*512 +: 512] ),
                    .tkeep   ( axis_c2h_tkeep  [(i*N+j)* 64 +:  64] ),
                    .tlast   ( axis_c2h_tlast  [(i*N+j)*  1 +:   1] ),
                    .tid     ( axis_c2h_tid    [(i*N+j)*  2 +:   2] ),
                    .tdest   ( axis_c2h_tdest  [(i*N+j)*  3 +:   3] ),
                    .tuser   ( axis_c2h_tuser  [i][j] ),
                    .axi4s_if( axis_c2h[i][j] )
                );
            end
        end
    endgenerate

    // axi4s_ila axi4s_ila_0 (.axis_in(axis_app_igr[0]));

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

    // Terminate AXI-L and AXI4-S interfaces (unused)
    axi4l_intf_peripheral_term axi4l_intf_peripheral_term       ( .axi4l_if(axil_if) );
    axi4l_intf_peripheral_term app_axi4l_intf_peripheral_term   ( .axi4l_if(app_axil_if) );

    generate
        for (genvar j = 0; j < N; j += 1) begin
            axi4s_intf_tx_term axis_app_egr_term (.aclk(core_clk), .aresetn(core_rstn), .axi4s_if(axis_app_egr[j]));
            axi4s_intf_rx_sink axis_app_igr_sink (.axi4s_if(axis_app_igr[j]));

            for (genvar i = 0; i < HOST_NUM_IFS; i += 1) begin
                axi4s_intf_tx_term axis_c2h_term (.aclk(core_clk), .aresetn(core_rstn), .axi4s_if(axis_c2h[i][j]));
                axi4s_intf_rx_sink axis_h2c_sink (.axi4s_if(axis_h2c[i][j]));
            end
        end
    endgenerate

    // Terminate AXI HBM interfaces (unused)
    generate
        for (genvar g_hbm_if = 0; g_hbm_if < AXI_HBM_NUM_IFS; g_hbm_if++) begin : g__axi_if_tieoff
            axi3_intf_controller_term i_axi3_controller_term (
                .axi3_if ( axi_to_hbm[g_hbm_if] )
            );
        end : g__axi_if_tieoff
    endgenerate

endmodule: smartnic_app
