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
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_h2c_tid,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_h2c_tdest,
    input  logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_h2c_tuser_pid,

    // AXI-S h2c interface
    // (synchronous to core_clk domain)
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tvalid,
    input  logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tready,
    output logic [(HOST_NUM_IFS*NUM_PORTS*512)-1:0] axis_c2h_tdata,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 64)-1:0] axis_c2h_tkeep,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tlast,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_c2h_tid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  4)-1:0] axis_c2h_tdest,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_c2h_tuser_pid,
    output logic [(HOST_NUM_IFS*NUM_PORTS*  1)-1:0] axis_c2h_tuser_trunc_enable,
    output logic [(HOST_NUM_IFS*NUM_PORTS* 16)-1:0] axis_c2h_tuser_trunc_length,
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
    axi4l_intf #() axil_to_extern [NUM_P4_PROC] ();
    axi4l_intf #() axil_to_vitisnetp4 [NUM_P4_PROC] ();
    axi4l_intf     axil_c2h [HOST_NUM_IFS][NUM_PORTS] ();
    axi4l_intf     axil_h2c [HOST_NUM_IFS][NUM_PORTS] ();

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_app_egr [NUM_PORTS] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) _axis_app_egr [NUM_PORTS] ();

    tuser_smartnic_meta_t  axis_app_egr_tuser [NUM_PORTS];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_app_igr [NUM_PORTS] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) _axis_app_igr [NUM_PORTS] ();

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
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) _axis_h2c [HOST_NUM_IFS][NUM_PORTS] ();

    tuser_smartnic_meta_t  axis_h2c_tuser [HOST_NUM_IFS][NUM_PORTS];

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_c2h [HOST_NUM_IFS][NUM_PORTS] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) _axis_c2h [HOST_NUM_IFS][NUM_PORTS] ();

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
                .tid     ( axis_app_igr_tid    [(j)*  4 +:   4] ),
                .tdest   ( axis_app_igr_tdest  [(j)*  4 +:   4] ),
                .tuser   ( axis_app_igr_tuser  [j] ),
                .axi4s_if( axis_app_igr[j] )
            );
            // AXI-S app_egr interface
            axi4s_intf_to_signals #(
                .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)
            ) axis_app_egr_to_signals (
                .aclk    ( ), // Output
                .aresetn ( ), // Output
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
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)
                ) axis_h2c_from_signals (
                    .aclk    ( core_clk ),
                    .aresetn ( core_rstn ),
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

                axi4s_probe axis_probe_h2c (
                    .axi4l_if ( axil_h2c[i][j] ),
                    .axi4s_if ( axis_h2c[i][j] )
                );

                // AXI-S c2h interface
                axi4s_intf_to_signals #(
                    .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)
                ) axis_c2h_to_signals (
                    .aclk    ( ), // Output
                    .aresetn ( ), // Output
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

                axi4s_probe axis_probe_c2h (
                    .axi4l_if ( axil_c2h[i][j] ),
                    .axi4s_if ( axis_c2h[i][j] )
                );
            end
        end
    endgenerate

    // xilinx_axi4s_ila xilinx_axi4s_ila_0 (.axis_in(axis_app_igr[0]));

    // -------------------------------------------------------------------------------------------------------
    // Input/Output Pipelining
    // -------------------------------------------------------------------------------------------------------
    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__fifo
            axi4s_fifo_sync #(
                .DEPTH ( 8 )
            ) i_axi4s_fifo_sync__igr (
                .axi4s_in  ( axis_app_igr[g_port] ),
                .axi4s_out ( _axis_app_igr[g_port] )
            );

            axi4s_fifo_sync #(
                .DEPTH ( 8 )
            ) i_axi4s_fifo_sync__egr (
                .axi4s_in  ( _axis_app_egr[g_port] ),
                .axi4s_out ( axis_app_egr[g_port] )
            );

            for (genvar g_if = 0; g_if < HOST_NUM_IFS; g_if++) begin
                axi4s_fifo_sync #(
                    .DEPTH ( 8 )
                ) i_axi4s_fifo_sync__h2c (
                    .axi4s_in  ( axis_h2c[g_if][g_port] ),
                    .axi4s_out ( _axis_h2c[g_if][g_port] )
                );

                axi4s_fifo_sync #(
                    .DEPTH ( 8 )
                ) i_axi4s_fifo_sync__c2h (
                    .axi4s_in  ( _axis_c2h[g_if][g_port] ),
                    .axi4s_out ( axis_c2h[g_if][g_port] )
                );

            end
        end : g__fifo

    endgenerate

    // -------------------------------------------------------------------------------------------------------
    // APPLICATION-SPECIFIC CONNECTIVITY
    // -------------------------------------------------------------------------------------------------------

    // ----------------------------------------------------------------------
    //  axil register map. axil intf, regio block and decoder instantiations.
    // ----------------------------------------------------------------------
    axi4l_intf  axil_to_smartnic_app ();
    axi4l_intf  axil_to_smartnic_app__core_clk ();
    axi4l_intf  axil_to_smartnic_app_igr ();
    axi4l_intf  axil_to_smartnic_app_egr ();
    axi4l_intf  axil_to_p4_proc [NUM_P4_PROC] ();

    smartnic_app_reg_intf  smartnic_app_regs ();

    // smartnic_app register decoder
    smartnic_app_decoder smartnic_app_decoder_inst (
       .axil_if                   ( app_axil_if ),
       .igr_extern_axil_if        ( axil_to_extern[0] ),
       .egr_extern_axil_if        ( axil_to_extern[1] ),
       .smartnic_app_igr_axil_if  ( axil_to_smartnic_app_igr ),
       .smartnic_app_egr_axil_if  ( axil_to_smartnic_app_egr )
    );

    // p4 register decoder
    smartnic_p4_decoder smartnic_p4_decoder_inst (
       .axil_if                     ( axil_if ),
       .app_common_axil_if          ( axil_to_smartnic_app ),
       .vitisnetp4_igr_axil_if      ( axil_to_vitisnetp4[0] ),
       .vitisnetp4_egr_axil_if      ( axil_to_vitisnetp4[1] ),
       .p4_proc_igr_axil_if         ( axil_to_p4_proc[0] ),
       .p4_proc_egr_axil_if         ( axil_to_p4_proc[1] ),

       .probe_from_pf0_axil_if      ( axil_h2c[PF][0] ),
       .probe_from_pf1_axil_if      ( axil_h2c[PF][1] ),
       .probe_from_pf0_vf0_axil_if  ( axil_h2c[VF0][0] ),
       .probe_from_pf1_vf0_axil_if  ( axil_h2c[VF0][1] ),
       .probe_from_pf0_vf1_axil_if  ( axil_h2c[VF1][0] ),
       .probe_from_pf1_vf1_axil_if  ( axil_h2c[VF1][1] ),
       .probe_to_pf0_axil_if        ( axil_c2h[PF][0] ),
       .probe_to_pf1_axil_if        ( axil_c2h[PF][1] ),
       .probe_to_pf0_vf0_axil_if    ( axil_c2h[VF0][0] ),
       .probe_to_pf1_vf0_axil_if    ( axil_c2h[VF0][1] ),
       .probe_to_pf0_vf1_axil_if    ( axil_c2h[VF1][0] ),
       .probe_to_pf1_vf1_axil_if    ( axil_c2h[VF1][1] )
    );

    // Pass AXI-L interface from aclk (AXI-L clock) to core clk domain
    axi4l_intf_cdc i_axil_intf_cdc (
        .axi4l_if_from_controller  ( axil_to_smartnic_app ),
        .clk_to_peripheral         ( core_clk ),
        .axi4l_if_to_peripheral    ( axil_to_smartnic_app__core_clk )
    );

    // smartnic_app register block
    smartnic_app_reg_blk smartnic_app_reg_blk (
        .axil_if    ( axil_to_smartnic_app__core_clk ),
        .reg_blk_if ( smartnic_app_regs )
    );

    // ----------------------------------------------------------------------
    // p4 processor signals and interfaces.
    // ----------------------------------------------------------------------
    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_to_demux [NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_to_smartnic_app_igr [NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_to_smartnic_app_egr [NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_to_mux [NUM_PORTS] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axi4s_mux_in [NUM_PORTS][2] ();

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_from_mux [NUM_PORTS] ();

    // ----------------------------------------------------------------------
    // ingress p4 processor complex (p4_proc + vitisnetp4_igr_wrapper)
    // ----------------------------------------------------------------------
    smartnic_app_igr_p4 #(.NUM_PORTS(NUM_PORTS)) smartnic_app_igr_p4_inst (
        .core_clk,
        .core_rstn,
        .timestamp,
        .axil_to_p4_proc    ( axil_to_p4_proc[0] ),
        .axil_to_vitisnetp4 ( axil_to_vitisnetp4[0] ),
        .axil_to_extern     ( axil_to_extern[0] ),
        .egr_flow_ctl       ( egr_flow_ctl ),
        .axis_in            ( _axis_app_igr ),
        .axis_out           ( axis_to_demux ),
        .axis_to_extern     ( _axis_h2c[VF1][0] ),
        .axis_from_extern   ( _axis_c2h[VF1][0] )
    );

    // ----------------------------------------------------------------------
    // egress p4 processor complex (p4_proc + vitisnetp4_igr_wrapper)
    // ----------------------------------------------------------------------
    smartnic_app_egr_p4 #(.NUM_PORTS(NUM_PORTS)) smartnic_app_egr_p4_inst (
        .core_clk,
        .core_rstn,
        .timestamp,
        .axil_to_p4_proc    ( axil_to_p4_proc[1] ),
        .axil_to_vitisnetp4 ( axil_to_vitisnetp4[1] ),
        .axil_to_extern     ( axil_to_extern[1] ),
        .egr_flow_ctl       ( egr_flow_ctl ),
        .axis_in            ( axis_from_mux ),
        .axis_out           ( _axis_app_egr ),
        .axis_to_extern     ( _axis_h2c[VF1][1] ),
        .axis_from_extern   ( _axis_c2h[VF1][1] )
    );

    // ----------------------------------------------------------------------
    // smartnic app datapath logic (mux/demux and ingress/egress blocks).
    // ----------------------------------------------------------------------
    logic axis_to_demux_sel[NUM_PORTS];
    logic smartnic_app_igr_p4_out_sel[NUM_PORTS];

    axi4s_intf #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t), .TDEST_T(port_t))  axis_demux_out [NUM_PORTS][2] ();

    generate
        for (genvar i = 0; i < NUM_PORTS; i += 1) begin
            always_comb begin
                axis_to_demux_sel[i] = 1'b0;
                if (axis_to_demux[i].tdest == PF0) axis_to_demux_sel[i] = 1'b1;
            end

            assign smartnic_app_igr_p4_out_sel[i] = smartnic_app_regs.smartnic_app_igr_p4_out_sel.enable ?
                                                    smartnic_app_regs.smartnic_app_igr_p4_out_sel.value  : axis_to_demux_sel[i];

            axi4s_intf_demux #(.N(2)) axi4s_intf_demux_inst (
                .axi4s_in   ( axis_to_demux[i] ),
                .axi4s_out  ( axis_demux_out[i] ),
                .sel        ( smartnic_app_igr_p4_out_sel[i] )
            );

            axi4s_intf_pipe axis_demux_out_pipe_0 ( .axi4s_if_from_tx(axis_demux_out[i][0]), .axi4s_if_to_rx(axis_to_smartnic_app_igr[i]) );
            axi4s_intf_pipe axis_demux_out_pipe_1 ( .axi4s_if_from_tx(axis_demux_out[i][1]), .axi4s_if_to_rx(_axis_c2h[PF][i]) );

        end

    endgenerate

    // xilinx_axi4s_ila xilinx_axi4s_ila_3 (.axis_in(axis_to_demux[0]));

    smartnic_app_igr #(.NUM_PORTS(NUM_PORTS)) smartnic_app_igr_inst (
        .core_clk   ( core_clk ),
        .core_rstn  ( core_rstn ),
        .axi4s_in   ( axis_to_smartnic_app_igr ),
        .axi4s_out  ( axis_to_smartnic_app_egr ),
//        .axi4s_c2h  ( _axis_c2h[VF0] ),
        .axi4s_c2h  ( _axis_c2h[1] ),
        .axil_if    ( axil_to_smartnic_app_igr )
    );


    smartnic_app_egr #(.NUM_PORTS(NUM_PORTS)) smartnic_app_egr_inst (
        .core_clk   ( core_clk ),
        .core_rstn  ( core_rstn ),
        .axi4s_in   ( axis_to_smartnic_app_egr ),
//        .axi4s_h2c  ( _axis_h2c[VF0] ),
        .axi4s_h2c  ( _axis_h2c[1] ),
        .axi4s_out  ( axis_to_mux ),
        .axil_if    ( axil_to_smartnic_app_egr )
    );

    // xilinx_axi4s_ila xilinx_axi4s_ila_4 (.axis_in(axis_to_mux[0]));

    generate
        for (genvar i = 0; i < NUM_PORTS; i += 1) begin
            axi4s_intf_connector axis_mux_in_pipe_0 ( .axi4s_from_tx(axis_to_mux[i]), .axi4s_to_rx(axi4s_mux_in[i][0]) );
            axi4s_intf_connector axis_mux_in_pipe_1 ( .axi4s_from_tx(_axis_h2c[PF][i]), .axi4s_to_rx(axi4s_mux_in[i][1]) );

            axi4s_mux #(.N(2)) axi4s_mux_inst (
                .axi4s_in   ( axi4s_mux_in[i] ),
                .axi4s_out  ( axis_from_mux[i] )
            );

        end

    endgenerate

    // xilinx_axi4s_ila xilinx_axi4s_ila_5 (.axis_in(axis_from_mux[0]));

endmodule: smartnic_app
