module smartnic_app
#(
    parameter int AXI_HBM_NUM_IFS = 16, // Number of HBM AXI interfaces.
    parameter int HOST_NUM_IFS = 2,     // Number of HOST interfaces.
    parameter int NUM_PORTS = 2,        // Number of processor ports (per vitisnetp4 processor).
    parameter int NUM_P4_PROC = 2       // Number of vitisnetp4 processors.
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
    input  logic [(NUM_PORTS*  1)-1:0] axis_app_igr_tvalid,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_igr_tready,
    input  logic [(NUM_PORTS*512)-1:0] axis_app_igr_tdata,
    input  logic [(NUM_PORTS* 64)-1:0] axis_app_igr_tkeep,
    input  logic [(NUM_PORTS*  1)-1:0] axis_app_igr_tlast,
    input  logic [(NUM_PORTS*  2)-1:0] axis_app_igr_tid,
    input  logic [(NUM_PORTS*  2)-1:0] axis_app_igr_tdest,
    input  logic [(NUM_PORTS* 16)-1:0] axis_app_igr_tuser_pid,

    // AXI-S app_egr interface
    // (synchronous to core_clk domain)
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tvalid,
    input  logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tready,
    output logic [(NUM_PORTS*512)-1:0] axis_app_egr_tdata,
    output logic [(NUM_PORTS* 64)-1:0] axis_app_egr_tkeep,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tlast,
    output logic [(NUM_PORTS*  2)-1:0] axis_app_egr_tid,
    output logic [(NUM_PORTS*  3)-1:0] axis_app_egr_tdest,
    output logic [(NUM_PORTS* 16)-1:0] axis_app_egr_tuser_pid,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tuser_trunc_enable,
    output logic [(NUM_PORTS* 16)-1:0] axis_app_egr_tuser_trunc_length,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tuser_rss_enable,
    output logic [(NUM_PORTS* 12)-1:0] axis_app_egr_tuser_rss_entropy,

    // AXI-S c2h interface
    // (synchronous to core_clk domain)
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tvalid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tready,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*512)-1:0] axis_h2c_tdata,
    input  logic [(HOST_NUM_IFS*NUM_PORTS* 64)-1:0] axis_h2c_tkeep,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tlast,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  2)-1:0] axis_h2c_tid,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  2)-1:0] axis_h2c_tdest,
    input  logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_h2c_tuser_pid,

    // AXI-S h2c interface
    // (synchronous to core_clk domain)
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tvalid,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tready,
    output logic [(HOST_NUM_IFS*NUM_PORTS*512)-1:0] axis_c2h_tdata,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 64)-1:0] axis_c2h_tkeep,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tlast,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  2)-1:0] axis_c2h_tid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  3)-1:0] axis_c2h_tdest,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_c2h_tuser_pid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tuser_trunc_enable,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_c2h_tuser_trunc_length,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tuser_rss_enable,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 12)-1:0] axis_c2h_tuser_rss_entropy,

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
    import p4_proc_pkg::*;
    import axi4s_pkg::*;

    // Parameters
    localparam int  AXIS_DATA_BYTE_WID = 64;

    localparam int  AXI_HBM_DATA_BYTE_WID = 32;
    localparam int  AXI_HBM_ADDR_WID = 33;
    localparam type AXI_HBM_ID_T = logic[5:0];

    // Interfaces
    axi4l_intf #() axil_if ();
    axi4l_intf #() app_axil_if ();
    axi4l_intf #() axil_to_vitisnetp4 [NUM_P4_PROC] ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(egr_tdest_t), .TUSER_T(tuser_smartnic_meta_t)) axis_app_egr [NUM_PORTS] ();

    tuser_smartnic_meta_t  axis_app_egr_tuser [NUM_PORTS];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_app_igr [NUM_PORTS] ();

    tuser_smartnic_meta_t  axis_app_igr_tuser [NUM_PORTS];

    generate
        for (genvar j = 0; j < NUM_PORTS; j += 1) begin
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
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_h2c [HOST_NUM_IFS][NUM_PORTS] ();

    tuser_smartnic_meta_t  axis_h2c_tuser [HOST_NUM_IFS][NUM_PORTS];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_c2h [HOST_NUM_IFS][NUM_PORTS] ();

    tuser_smartnic_meta_t  axis_c2h_tuser [HOST_NUM_IFS][NUM_PORTS];

    generate
        for (genvar i = 0; i < HOST_NUM_IFS; i += 1) begin
            for (genvar j = 0; j < NUM_PORTS; j += 1) begin
                assign axis_c2h_tuser_pid          [(i*NUM_PORTS+j)*16 +: 16] = axis_c2h_tuser[i][j].pid;
                assign axis_c2h_tuser_trunc_enable [(i*NUM_PORTS+j)* 1 +:  1] = axis_c2h_tuser[i][j].trunc_enable;
                assign axis_c2h_tuser_trunc_length [(i*NUM_PORTS+j)*16 +: 16] = axis_c2h_tuser[i][j].trunc_length;
                assign axis_c2h_tuser_rss_enable   [(i*NUM_PORTS+j)* 1 +:  1] = axis_c2h_tuser[i][j].rss_enable;
                assign axis_c2h_tuser_rss_entropy  [(i*NUM_PORTS+j)*12 +: 12] = axis_c2h_tuser[i][j].rss_entropy;

                assign axis_h2c_tuser[i][j].pid          = axis_h2c_tuser_pid[(i*NUM_PORTS+j)*16 +: 16];
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
        for (genvar j = 0; j < NUM_PORTS; j += 1) begin
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
                    .tvalid  ( axis_h2c_tvalid [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tready  ( axis_h2c_tready [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tdata   ( axis_h2c_tdata  [(i*NUM_PORTS+j)*512 +: 512] ),
                    .tkeep   ( axis_h2c_tkeep  [(i*NUM_PORTS+j)* 64 +:  64] ),
                    .tlast   ( axis_h2c_tlast  [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tid     ( axis_h2c_tid    [(i*NUM_PORTS+j)*  2 +:   2] ),
                    .tdest   ( axis_h2c_tdest  [(i*NUM_PORTS+j)*  2 +:   2] ),
                    .tuser   ( axis_h2c_tuser  [i][j] ),
                    .axi4s_if( axis_h2c[i][j] )
                );
                // AXI-S c2h interface
                axi4s_intf_to_signals #(
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t), .TUSER_T(tuser_smartnic_meta_t)
                ) axis_c2h_to_signals (
                    .aclk    ( ), // Output
                    .aresetn ( ), // Output
                    .tvalid  ( axis_c2h_tvalid [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tready  ( axis_c2h_tready [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tdata   ( axis_c2h_tdata  [(i*NUM_PORTS+j)*512 +: 512] ),
                    .tkeep   ( axis_c2h_tkeep  [(i*NUM_PORTS+j)* 64 +:  64] ),
                    .tlast   ( axis_c2h_tlast  [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tid     ( axis_c2h_tid    [(i*NUM_PORTS+j)*  2 +:   2] ),
                    .tdest   ( axis_c2h_tdest  [(i*NUM_PORTS+j)*  3 +:   3] ),
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

    // ----------------------------------------------------------------------
    //  axil register map. axil intf, regio block and decoder instantiations.
    // ----------------------------------------------------------------------
    axi4l_intf  axil_to_p4_only ();
    axi4l_intf  axil_to_p4_only__core_clk ();
    axi4l_intf  axil_to_smartnic_app_igr ();
    axi4l_intf  axil_to_smartnic_app_egr ();
    axi4l_intf  axil_to_p4_proc [NUM_P4_PROC] ();

    p4_only_reg_intf  p4_only_regs ();

    // smartnic_app register decoder
    p4_only_decoder p4_only_decoder_inst (
       .axil_if                   ( app_axil_if ),
       .p4_only_axil_if           ( axil_to_p4_only ),
       .smartnic_app_igr_axil_if  ( axil_to_smartnic_app_igr ),
       .smartnic_app_egr_axil_if  ( axil_to_smartnic_app_egr )
    );

    axi4l_intf_controller_term axil_to_p4_proc_1_controller_term ( .axi4l_if (axil_to_p4_proc[1]) );

    // Pass AXI-L interface from aclk (AXI-L clock) to core clk domain
    axi4l_intf_cdc i_axil_intf_cdc (
        .axi4l_if_from_controller  ( axil_to_p4_only ),
        .clk_to_peripheral         ( core_clk ),
        .axi4l_if_to_peripheral    ( axil_to_p4_only__core_clk )
    );

    // smartnic_app register block
    p4_only_reg_blk p4_only_reg_blk (
        .axil_if    ( axil_to_p4_only__core_clk ),
        .reg_blk_if ( p4_only_regs )
    );


    // p4 register decoder
    smartnic_p4_decoder smartnic_p4_decoder_inst (
       .axil_if                 ( axil_if ),
       .vitisnetp4_igr_axil_if  ( axil_to_vitisnetp4[0] ),
       .vitisnetp4_egr_axil_if  ( axil_to_vitisnetp4[1] ),
       .p4_proc_igr_axil_if     ( axil_to_p4_proc[0] )
//       .p4_proc_egr_axil_if     ( axil_to_p4_proc[1] )  // commented out until non-transparent decoder support.
    );

    // ----------------------------------------------------------------------
    // p4 processor signals and interfaces.
    // ----------------------------------------------------------------------
    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_to_vitisnetp4 [NUM_P4_PROC] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_from_vitisnetp4 [NUM_P4_PROC] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_to_demux [NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_to_smartnic_app_igr [NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_to_smartnic_app_egr [NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_to_mux [NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axi4s_mux_in [NUM_PORTS][2] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_from_mux [NUM_PORTS] ();

    user_metadata_t user_metadata_in [NUM_P4_PROC];
    logic           user_metadata_in_valid [NUM_P4_PROC];

    user_metadata_t user_metadata_out [NUM_P4_PROC];
    logic           user_metadata_out_valid [NUM_P4_PROC];

    // ----------------------------------------------------------------------
    // ingress p4 processor complex (p4_proc + vitisnetp4_igr_wrapper)
    // ----------------------------------------------------------------------
    localparam logic P4_PROC_IGR_MODE = 1;

    generate
        if (P4_PROC_IGR_MODE) begin
            p4_proc #(.NUM_PORTS(NUM_PORTS)) p4_proc_igr (
                .core_clk                       ( core_clk ),
                .core_rstn                      ( core_rstn ),
                .timestamp                      ( timestamp ),
                .axil_if                        ( axil_to_p4_proc[0] ),
                .axis_in                        ( axis_app_igr ),
                .axis_out                       ( axis_to_demux ),
                .axis_to_vitisnetp4                  ( axis_to_vitisnetp4[0] ),
                .axis_from_vitisnetp4                ( axis_from_vitisnetp4[0] ),
                .user_metadata_to_vitisnetp4_valid   ( user_metadata_in_valid[0] ),
                .user_metadata_to_vitisnetp4         ( user_metadata_in[0] ),
                .user_metadata_from_vitisnetp4_valid ( user_metadata_out_valid[0] ),
                .user_metadata_from_vitisnetp4       ( user_metadata_out[0] )
            );

            vitisnetp4_igr_wrapper vitisnetp4_igr_wrapper_inst (
                .core_clk                ( core_clk ),
                .core_rstn               ( core_rstn ),
                .axil_if                 ( axil_to_vitisnetp4[0] ),
                .axis_rx                 ( axis_to_vitisnetp4[0] ),
                .axis_tx                 ( axis_from_vitisnetp4[0] ),
                .user_metadata_in_valid  ( user_metadata_in_valid[0] ),
                .user_metadata_in        ( user_metadata_in[0] ),
                .user_metadata_out_valid ( user_metadata_out_valid[0] ),
                .user_metadata_out       ( user_metadata_out[0] ),
                .axi_to_hbm              ( axi_to_hbm )
            );

        // axi4s_ila axi4s_ila_1 (.axis_in(axis_to_vitisnetp4[0]));
        // axi4s_ila axi4s_ila_2 (.axis_in(axis_from_vitisnetp4[0]));

        end else begin  // P4_PROC_IGR_MODE == 0
            axi4l_intf_peripheral_term axil_to_p4_proc_term ( .axi4l_if (axil_to_p4_proc[0]) );
            axi4l_intf_peripheral_term axil_to_vitisnetp4_0_term ( .axi4l_if (axil_to_vitisnetp4[0]) );

            for (genvar i = 0; i < NUM_PORTS; i += 1) begin
                // axi4s_intf_connector axis4s_intf_connector_inst ( .axi4s_from_tx(), .axi4s_to_rx() );
                axi4s_full_pipe p4_proc_igr_axis_full_pipe ( .axi4s_if_from_tx(axis_app_igr[i]), .axi4s_if_to_rx(axis_to_demux[i]) );
            end

            for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
                axi3_intf_controller_term axi_to_hbm_term (.axi3_if(axi_to_hbm[g_hbm_if]));
            end : g__hbm_if

        end
    endgenerate

    // ----------------------------------------------------------------------
    // egress p4 processor complex (p4_proc + vitisnetp4_igr_wrapper)
    // ----------------------------------------------------------------------
    localparam logic P4_PROC_EGR_MODE = 0;

    axi3_intf  #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_to_hbm_egr[AXI_HBM_NUM_IFS] ();

    generate
        for (genvar g_hbm1_if = 0; g_hbm1_if < AXI_HBM_NUM_IFS; g_hbm1_if++) begin : g__hbm1_if
            // For now, terminate vitisnetp4_1 HBM memory interfaces (unused)
            axi3_intf_controller_term axi_to_hbm_egr_term (.axi3_if(axi_to_hbm_egr[g_hbm1_if]));
        end : g__hbm1_if

        if (P4_PROC_EGR_MODE) begin
            p4_proc #(.NUM_PORTS(NUM_PORTS)) p4_proc_egr (
                .core_clk                       ( core_clk ),
                .core_rstn                      ( core_rstn ),
                .timestamp                      ( timestamp ),
                .axil_if                        ( axil_to_p4_proc[1] ),
                .axis_in                        ( axis_from_mux ),
                .axis_out                       ( axis_app_egr ),
                .axis_to_vitisnetp4                  ( axis_to_vitisnetp4[1] ),
                .axis_from_vitisnetp4                ( axis_from_vitisnetp4[1] ),
                .user_metadata_to_vitisnetp4_valid   ( user_metadata_in_valid[1] ),
                .user_metadata_to_vitisnetp4         ( user_metadata_in[1] ),
                .user_metadata_from_vitisnetp4_valid ( user_metadata_out_valid[1] ),
                .user_metadata_from_vitisnetp4       ( user_metadata_out[1] )
            );

            vitisnetp4_egr_wrapper vitisnetp4_egr_wrapper_inst (
                .core_clk                ( core_clk ),
                .core_rstn               ( core_rstn ),
                .axil_if                 ( axil_to_vitisnetp4[1] ),
                .axis_rx                 ( axis_to_vitisnetp4[1] ),
                .axis_tx                 ( axis_from_vitisnetp4[1] ),
                .user_metadata_in_valid  ( user_metadata_in_valid[1] ),
                .user_metadata_in        ( user_metadata_in[1] ),
                .user_metadata_out_valid ( user_metadata_out_valid[1] ),
                .user_metadata_out       ( user_metadata_out[1] ),
                .axi_to_hbm              ( axi_to_hbm_egr )
            );

        end else begin  // P4_PROC_EGR_MODE == 0
            axi4l_intf_peripheral_term axil_to_p4_proc_1_term ( .axi4l_if (axil_to_p4_proc[1]) );
            axi4l_intf_peripheral_term axil_to_vitisnetp4_1_term   ( .axi4l_if (axil_to_vitisnetp4[1]) );

            for (genvar i = 0; i < NUM_PORTS; i += 1) begin
                // axi4s_intf_connector axis4s_intf_connector_inst ( .axi4s_from_tx(), .axi4s_to_rx() );
                axi4s_full_pipe p4_proc_egr_axis_full_pipe ( .axi4s_if_from_tx(axis_from_mux[i]), .axi4s_if_to_rx(axis_app_egr[i]) );
            end

            for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
                axi3_intf_controller_term axi_to_hbm_egr_term (.axi3_if(axi_to_hbm_egr[g_hbm_if]));
            end : g__hbm_if
        end

    endgenerate


    // ----------------------------------------------------------------------
    // smartnic app datapath logic (mux/demux and ingress/egress blocks).
    // ----------------------------------------------------------------------
    logic [NUM_PORTS-1:0] igr_demux_sel;  // each sel signal has wordlength $clog2(2)

    always_comb begin
        case (axis_to_demux[0].tdest)
            HOST0:   igr_demux_sel[0] = 1'b1;
            HOST1:   igr_demux_sel[0] = 1'b1;
            default: igr_demux_sel[0] = 1'b0;
        endcase
    end

    always_comb begin
        case (axis_to_demux[1].tdest)
            HOST0:   igr_demux_sel[1] = 1'b1;
            HOST1:   igr_demux_sel[1] = 1'b1;
            default: igr_demux_sel[1] = 1'b0;
        endcase
    end

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(egr_tdest_t))  axis_demux_out [NUM_PORTS][2] ();

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        axi4s_intf_demux #(.N(2)) axi4s_intf_demux_inst (
            .axi4s_in   ( axis_to_demux[i] ),
            .axi4s_out  ( axis_demux_out[i] ),
            .sel        ( igr_demux_sel[i] )
        );

        axi4s_intf_connector axis4s_intf_connector_0 ( .axi4s_from_tx(axis_demux_out[i][0]), .axi4s_to_rx(axis_to_smartnic_app_igr[i]) );
        axi4s_intf_connector axis4s_intf_connector_1 ( .axi4s_from_tx(axis_demux_out[i][1]), .axi4s_to_rx(axis_c2h[0][i]) );

        //axi4s_intf_tx_term   axis_c2h_2_tx_term      (.axi4s_if(axis_c2h[2][i]));   // temporarily unused c2h[2] i/f (p4 extern).
    end endgenerate

    // axi4s_ila axi4s_ila_3 (.axis_in(axis_to_demux[0]));

    localparam logic SMARTNIC_APP_IGR_MODE = 0;
    generate
        if (SMARTNIC_APP_IGR_MODE) begin
            smartnic_app_igr #(.NUM_PORTS(NUM_PORTS)) smartnic_app_igr_inst (
                .core_clk   ( core_clk ),
                .core_rstn  ( core_rstn ),
                .axi4s_in   ( axis_to_smartnic_app_igr ),
                .axi4s_out  ( axis_to_smartnic_app_egr ),
                .axi4s_c2h  ( axis_c2h[1] ),
                .axil_if    ( axil_to_smartnic_app_igr )
            );

        end else begin  // SMARTNIC_APP_IGR_MODE == 0
            axi4l_intf_peripheral_term axil_to_smartnic_app_igr_term ( .axi4l_if (axil_to_smartnic_app_igr) );

            for (genvar i = 0; i < NUM_PORTS; i += 1) begin
                // axi4s_intf_connector axis4s_intf_connector_inst ( .axi4s_from_tx(), .axi4s_to_rx() );
                axi4s_full_pipe smartnic_app_igr_full_pipe ( .axi4s_if_from_tx(axis_to_smartnic_app_igr[i]), .axi4s_if_to_rx(axis_to_smartnic_app_egr[i]) );
            end

        end
    endgenerate


    localparam logic SMARTNIC_APP_EGR_MODE = 0;
    generate
        if (SMARTNIC_APP_EGR_MODE) begin
            smartnic_app_egr #(.NUM_PORTS(NUM_PORTS)) smartnic_app_egr_inst (
                .core_clk   ( core_clk ),
                .core_rstn  ( core_rstn ),
                .axi4s_in   ( axis_to_smartnic_app_egr ),
                .axi4s_h2c  ( axis_h2c[1] ),
                .axi4s_out  ( axis_to_mux ),
                .axil_if    ( axil_to_smartnic_app_egr )
            );

        end else begin  // SMARTNIC_APP_EGR_MODE == 0
            axi4l_intf_peripheral_term axil_to_smartnic_app_egr_term ( .axi4l_if (axil_to_smartnic_app_egr) );

            for (genvar i = 0; i < NUM_PORTS; i += 1) begin
                // axi4s_intf_connector axis4s_intf_connector_inst ( .axi4s_from_tx(), .axi4s_to_rx() );
                axi4s_full_pipe smartnic_app_egr_full_pipe ( .axi4s_if_from_tx(axis_to_smartnic_app_egr[i]), .axi4s_if_to_rx(axis_to_mux[i]) );
            end

        end
    endgenerate

    // axi4s_ila axi4s_ila_4 (.axis_in(axis_to_mux[0]));

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        axi4s_intf_connector axi4s_mux_in_connector_0 ( .axi4s_from_tx(axis_to_mux[i]), .axi4s_to_rx(axi4s_mux_in[i][0]) );
        axi4s_intf_connector axi4s_mux_in_connector_1 ( .axi4s_from_tx(axis_h2c[0][i]), .axi4s_to_rx(axi4s_mux_in[i][1]) );

        axi4s_mux #(.N(2)) axi4s_mux_inst (
            .axi4s_in   ( axi4s_mux_in[i] ),
            .axi4s_out  ( axis_from_mux[i] )
        );

        //axi4s_intf_rx_sink  axis_h2c_2_rx_sink_inst  (.axi4s_if(axis_h2c[2][i]));  // temporarily unused h2c[2] i/f (p4 extern).
    end endgenerate

    // axi4s_ila axi4s_ila_5 (.axis_in(axis_from_mux[0]));

endmodule: smartnic_app
