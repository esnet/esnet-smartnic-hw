module smartnic_app
#(
    parameter int HOST_NUM_IFS = 3,     // Number of HOST interfaces.
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
    input  logic [(NUM_PORTS*  4)-1:0] axis_app_igr_tid,
    input  logic [(NUM_PORTS*  4)-1:0] axis_app_igr_tdest,
    input  logic [(NUM_PORTS* 16)-1:0] axis_app_igr_tuser_pid,

    // AXI-S app_egr interface
    // (synchronous to core_clk domain)
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tvalid,
    input  logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tready,
    output logic [(NUM_PORTS*512)-1:0] axis_app_egr_tdata,
    output logic [(NUM_PORTS* 64)-1:0] axis_app_egr_tkeep,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tlast,
    output logic [(NUM_PORTS*  4)-1:0] axis_app_egr_tid,
    output logic [(NUM_PORTS*  4)-1:0] axis_app_egr_tdest,
    output logic [(NUM_PORTS*  1)-1:0] axis_app_egr_tuser_rss_enable,
    output logic [(NUM_PORTS* 12)-1:0] axis_app_egr_tuser_rss_entropy,

    // AXI-S c2h interface
    // (synchronous to core_clk domain)
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tvalid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tready,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*512)-1:0] axis_h2c_tdata,
    input  logic [(HOST_NUM_IFS*NUM_PORTS* 64)-1:0] axis_h2c_tkeep,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_h2c_tlast,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_h2c_tid,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_h2c_tdest,

    // AXI-S h2c interface
    // (synchronous to core_clk domain)
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tvalid,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tready,
    output logic [(HOST_NUM_IFS*NUM_PORTS*512)-1:0] axis_c2h_tdata,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 64)-1:0] axis_c2h_tkeep,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tlast,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_c2h_tid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_c2h_tdest,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tuser_rss_enable,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 12)-1:0] axis_c2h_tuser_rss_entropy,

    // flow control signals (one from each egress FIFO).
    input logic [3:0]    egr_flow_ctl
);

    import smartnic_pkg::*;
    import axi4s_pkg::*;

    // Parameters
    localparam int  AXIS_DATA_BYTE_WID = 64;

    // Interfaces
    axi4l_intf #() axil_if ();
    axi4l_intf #() app_axil_if ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)) axis_app_egr [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    tuser_smartnic_meta_t  axis_app_egr_tuser [NUM_PORTS];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)) axis_app_igr [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

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
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)) axis_h2c [HOST_NUM_IFS][NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    tuser_smartnic_meta_t  axis_h2c_tuser [HOST_NUM_IFS][NUM_PORTS];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)) axis_c2h [HOST_NUM_IFS][NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    tuser_smartnic_meta_t  axis_c2h_tuser [HOST_NUM_IFS][NUM_PORTS];

    generate
        for (genvar i = 0; i < HOST_NUM_IFS; i += 1) begin
            for (genvar j = 0; j < NUM_PORTS; j += 1) begin
                assign axis_c2h_tuser_rss_enable   [(i*NUM_PORTS+j)* 1 +:  1] = axis_c2h_tuser[i][j].rss_enable;
                assign axis_c2h_tuser_rss_entropy  [(i*NUM_PORTS+j)*12 +: 12] = axis_c2h_tuser[i][j].rss_entropy;

                assign axis_h2c_tuser[i][j].rss_enable   = '0;
                assign axis_h2c_tuser[i][j].rss_entropy  = '0;
            end
        end
    endgenerate

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
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)
            ) axis_app_igr_from_signals (
                .tvalid  ( axis_app_igr_tvalid [(j)*  1 +:   1] ),
                .tready  ( axis_app_igr_tready [(j)*  1 +:   1] ),
                .tdata   ( axis_app_igr_tdata  [(j)*512 +: 512] ),
                .tkeep   ( axis_app_igr_tkeep  [(j)* 64 +:  64] ),
                .tlast   ( axis_app_igr_tlast  [(j)*  1 +:   1] ),
                .tid     ( axis_app_igr_tid    [(j)*  4 +:   4] ),
                .tdest   ( axis_app_igr_tdest  [(j)*  4 +:   4] ),
                .tuser   ( axis_app_igr_tuser  [j] ),
                .axi4s_if( axis_app_igr[j] )
            );
            // AXI-S app_egr interface
            axi4s_intf_to_signals #(
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)
            ) axis_app_egr_to_signals (
                .tvalid  ( axis_app_egr_tvalid [(j)*  1 +:   1] ),
                .tready  ( axis_app_egr_tready [(j)*  1 +:   1] ),
                .tdata   ( axis_app_egr_tdata  [(j)*512 +: 512] ),
                .tkeep   ( axis_app_egr_tkeep  [(j)* 64 +:  64] ),
                .tlast   ( axis_app_egr_tlast  [(j)*  1 +:   1] ),
                .tid     ( axis_app_egr_tid    [(j)*  4 +:   4] ),
                .tdest   ( axis_app_egr_tdest  [(j)*  4 +:   4] ),
                .tuser   ( axis_app_egr_tuser  [j] ),
                .axi4s_if( axis_app_egr[j] )
            );

            for (genvar i = 0; i < HOST_NUM_IFS; i += 1) begin
                // AXI-S h2c interface
                axi4s_intf_from_signals #(
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)
                ) axis_h2c_from_signals (
                    .tvalid  ( axis_h2c_tvalid [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tready  ( axis_h2c_tready [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tdata   ( axis_h2c_tdata  [(i*NUM_PORTS+j)*512 +: 512] ),
                    .tkeep   ( axis_h2c_tkeep  [(i*NUM_PORTS+j)* 64 +:  64] ),
                    .tlast   ( axis_h2c_tlast  [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tid     ( axis_h2c_tid    [(i*NUM_PORTS+j)*  4 +:   4] ),
                    .tdest   ( axis_h2c_tdest  [(i*NUM_PORTS+j)*  4 +:   4] ),
                    .tuser   ( axis_h2c_tuser  [i][j] ),
                    .axi4s_if( axis_h2c[i][j] )
                );
                // AXI-S c2h interface
                axi4s_intf_to_signals #(
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)
                ) axis_c2h_to_signals (
                    .tvalid  ( axis_c2h_tvalid [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tready  ( axis_c2h_tready [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tdata   ( axis_c2h_tdata  [(i*NUM_PORTS+j)*512 +: 512] ),
                    .tkeep   ( axis_c2h_tkeep  [(i*NUM_PORTS+j)* 64 +:  64] ),
                    .tlast   ( axis_c2h_tlast  [(i*NUM_PORTS+j)*  1 +:   1] ),
                    .tid     ( axis_c2h_tid    [(i*NUM_PORTS+j)*  4 +:   4] ),
                    .tdest   ( axis_c2h_tdest  [(i*NUM_PORTS+j)*  4 +:   4] ),
                    .tuser   ( axis_c2h_tuser  [i][j] ),
                    .axi4s_if( axis_c2h[i][j] )
                );
            end
        end
    endgenerate

    // xilinx_axi4s_ila xilinx_axi4s_ila_0 (.axis_in(axis_app_igr[0]));

    // -------------------------------------------------------------------------------------------------------
    // APPLICATION-SPECIFIC CONNECTIVITY
    // -------------------------------------------------------------------------------------------------------

    // Terminate AXI-L and AXI4-S interfaces (unused)
    axi4l_intf_peripheral_term axi4l_intf_peripheral_term       ( .axi4l_if(axil_if) );
    axi4l_intf_peripheral_term app_axi4l_intf_peripheral_term   ( .axi4l_if(app_axil_if) );

    generate
        for (genvar j = 0; j < NUM_PORTS; j += 1) begin
            axi4s_intf_tx_term axis_app_egr_term (.to_rx  (axis_app_egr[j]));
            axi4s_intf_rx_sink axis_app_igr_sink (.from_tx(axis_app_igr[j]));

            for (genvar i = 0; i < HOST_NUM_IFS; i += 1) begin
                axi4s_intf_tx_term axis_c2h_term (.to_rx  (axis_c2h[i][j]));
                axi4s_intf_rx_sink axis_h2c_sink (.from_tx(axis_h2c[i][j]));
            end
        end
    endgenerate

endmodule: smartnic_app
