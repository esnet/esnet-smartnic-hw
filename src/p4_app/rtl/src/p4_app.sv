module p4_app
   import smartnic_322mhz_pkg::*;
#(
   parameter int N = 2, // Number of processor ports (per vitisnetp4 processor).
   parameter int M = 2  // Number of vitisnetp4 processors.
) (
   input logic        core_clk,
   input logic        core_rstn,
   input timestamp_t  timestamp,

   axi4l_intf.peripheral axil_if,
   axi4l_intf.peripheral axil_to_sdnet[M],

   axi4s_intf.tx      axis_to_switch[M][N],
   axi4s_intf.rx      axis_from_switch[M][N],

   axi3_intf.controller  axi_to_hbm[16]  // Connected to vitisnetp4_igr procesor.
);
   import p4_proc_pkg::*;

   localparam int  DATA_BYTE_WID = axis_from_switch[0][0].DATA_BYTE_WID;
   localparam type TID_T         = axis_from_switch[0][0].TID_T;
   localparam type TDEST_T       = axis_from_switch[0][0].TDEST_T;
   localparam type TUSER_T       = axis_from_switch[0][0].TUSER_T;

   // ----------------------------------------------------------------------
   //  axil register map. axil intf, regio block and decoder instantiations.
   // ----------------------------------------------------------------------
   axi4l_intf  axil_to_p4_app ();
   axi4l_intf  axil_to_p4_app__core_clk ();
   axi4l_intf  axil_to_p4_proc ();

   p4_app_reg_intf  p4_app_regs ();

   // p4_app register decoder
   p4_app_decoder p4_app_decoder (
      .axil_if          (axil_if),
      .p4_app_axil_if   (axil_to_p4_app),
      .p4_proc_axil_if  (axil_to_p4_proc)
   );

   // Pass AXI-L interface from aclk (AXI-L clock) to core clk domain
   axi4l_intf_cdc i_axil_intf_cdc (
       .axi4l_if_from_controller   ( axil_to_p4_app ),
       .clk_to_peripheral          ( core_clk ),
       .axi4l_if_to_peripheral     ( axil_to_p4_app__core_clk )
   );

   // p4_app register block
   p4_app_reg_blk p4_app_reg_blk 
   (
    .axil_if    (axil_to_p4_app__core_clk),
    .reg_blk_if (p4_app_regs)
   );


   // ----------------------------------------------------------------------
   // p4 processor interfaces, signals and instantiations.
   // ----------------------------------------------------------------------
   axi4s_intf #(.TUSER_T(TUSER_T),
                .DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T))  axis_to_sdnet[M] ();

   axi4s_intf #(.TUSER_T(TUSER_T),
                .DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T))  axis_from_sdnet[M] ();

   axi4s_intf #(.TUSER_T(TUSER_T),
                .DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T))  axis_to_demux[N] ();

   axi4s_intf #(.TUSER_T(TUSER_T),
                .DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T))  axis_to_p4_app_igr[N] ();

   axi4s_intf #(.TUSER_T(TUSER_T),
                .DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T))  axis_to_p4_app_egr[N] ();

   axi4s_intf #(.TUSER_T(TUSER_T),
                .DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T))  axis_to_mux[N] ();

   axi4s_intf #(.TUSER_T(TUSER_T),
                .DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T))  axis_from_mux[N] ();

   user_metadata_t user_metadata_in[M];
   logic           user_metadata_in_valid[M];

   user_metadata_t user_metadata_out[M];
   logic           user_metadata_out_valid[M];

   // --- ingress p4 processor complex (p4_proc + sdnet_igr_wrapper) ---
//   p4_proc_igr #(.N(N)) p4_proc_igr (
   p4_proc_p2p #(.N(N)) p4_proc_igr (
      .core_clk                       ( core_clk ),
      .core_rstn                      ( core_rstn ),
      .timestamp                      ( timestamp ),
      .axil_if                        ( axil_to_p4_proc ),
      .axis_in                        ( axis_from_switch[0] ),
      .axis_out                       ( axis_to_demux ),
      .axis_to_sdnet                  ( axis_to_sdnet[0] ),
      .axis_from_sdnet                ( axis_from_sdnet[0] ),
      .user_metadata_to_sdnet_valid   ( user_metadata_in_valid[0] ),
      .user_metadata_to_sdnet         ( user_metadata_in[0] ),
      .user_metadata_from_sdnet_valid ( user_metadata_out_valid[0] ),
      .user_metadata_from_sdnet       ( user_metadata_out[0] )
   );

//   sdnet_igr_wrapper sdnet_igr_wrapper_inst (
   sdnet_stub sdnet_igr_wrapper_inst (
      .core_clk                ( core_clk ),
      .core_rstn               ( core_rstn ),
      .axil_if                 ( axil_to_sdnet[0] ),
      .axis_rx                 ( axis_to_sdnet[0] ),
      .axis_tx                 ( axis_from_sdnet[0] ),
      .user_metadata_in_valid  ( user_metadata_in_valid[0] ),
      .user_metadata_in        ( user_metadata_in[0] ),
      .user_metadata_out_valid ( user_metadata_out_valid[0] ),
      .user_metadata_out       ( user_metadata_out[0] ),
      .axi_to_hbm              ( axi_to_hbm )
   );

   assign axis_from_sdnet[0].aclk = core_clk;
   assign axis_from_sdnet[0].aresetn = core_rstn;

   generate if (M==2)
       begin
           // --- egress p4 processor complex (p4_proc + sdnet_igr_wrapper) ---
           axi4l_intf  axil_to_p4_proc_1 ();
           axi4l_intf_controller_term axil_to_p4_proc_1_term (.axi4l_if (axil_to_p4_proc_1));

//           p4_proc_egr #(.N(N)) p4_proc_egr (
           p4_proc_p2p #(.N(N)) p4_proc_egr (
               .core_clk                       ( core_clk ),
               .core_rstn                      ( core_rstn ),
               .timestamp                      ( timestamp ),
               .axil_if                        ( axil_to_p4_proc_1 ),
               .axis_in                        ( axis_from_mux ),
               .axis_out                       ( axis_to_switch[0] ),
               .axis_to_sdnet                  ( axis_to_sdnet[1] ),
               .axis_from_sdnet                ( axis_from_sdnet[1] ),
               .user_metadata_to_sdnet_valid   ( user_metadata_in_valid[1] ),
               .user_metadata_to_sdnet         ( user_metadata_in[1] ),
               .user_metadata_from_sdnet_valid ( user_metadata_out_valid[1] ),
               .user_metadata_from_sdnet       ( user_metadata_out[1] )
           );

           axi3_intf   #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_to_hbm_1[16] ();
           for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
                // For now, terminate sdnet_1 HBM memory interfaces (unused)
                axi3_intf_controller_term axi_to_hbm_1_term (.axi3_if(axi_to_hbm_1[g_hbm_if]));
           end : g__hbm_if

//           sdnet_egr_wrapper sdnet_egr_wrapper_inst (
           sdnet_stub sdnet_egr_wrapper_inst (
               .core_clk                ( core_clk ),
               .core_rstn               ( core_rstn ),
               .axil_if                 ( axil_to_sdnet[1] ),
               .axis_rx                 ( axis_to_sdnet[1] ),
               .axis_tx                 ( axis_from_sdnet[1] ),
               .user_metadata_in_valid  ( user_metadata_in_valid[1] ),
               .user_metadata_in        ( user_metadata_in[1] ),
               .user_metadata_out_valid ( user_metadata_out_valid[1] ),
               .user_metadata_out       ( user_metadata_out[1] ),
               .axi_to_hbm              ( axi_to_hbm_1 )
           );

           assign axis_from_sdnet[1].aclk = core_clk;
           assign axis_from_sdnet[1].aresetn = core_rstn;
       end
   endgenerate


   // ----------------------------------------------------------------------
   // p4_app datapath logic (mux/demux and ingress/egress blocks).
   // ----------------------------------------------------------------------
   generate for (genvar i = 0; i < N; i += 1) begin
       axi4s_intf_1to2_demux axi4s_intf_1to2_demux_inst (
           .axi4s_in   ( axis_to_demux[i] ),
           .axi4s_out0 ( axis_to_p4_app_igr[i] ),
           .axi4s_out1 ( axis_to_switch[1][i] ),
//           .output_sel ( axis_to_demux[i].tdest[1] )
           .output_sel ( 1'b0 )
       );
   end endgenerate

   axi4l_intf  axil_to_p4_app_igr ();
   axi4l_intf_controller_term axil_to_p4_app_igr_term (.axi4l_if (axil_to_p4_app_igr));

//   p4_app_igr #(.N(N)) p4_app_igr_inst (
   p4_app_p2p #(.N(N)) p4_app_igr_inst (
       .axi4s_in   ( axis_to_p4_app_igr ),
       .axi4s_out  ( axis_to_p4_app_egr ),
       .axil_if    ( axil_to_p4_app_igr )
   );

   axi4l_intf  axil_to_p4_app_egr ();
   axi4l_intf_controller_term axil_to_p4_app_egr_term (.axi4l_if (axil_to_p4_app_egr));

//   p4_app_egr #(.N(N)) p4_app_egr_inst (
   p4_app_p2p #(.N(N)) p4_app_egr_inst (
       .axi4s_in   ( axis_to_p4_app_egr ),
       .axi4s_out  ( axis_to_mux ),
       .axil_if    ( axil_to_p4_app_egr )
   );

   axi4s_intf #(.TUSER_T(TUSER_T),
       .DATA_BYTE_WID(DATA_BYTE_WID), .TID_T(TID_T), .TDEST_T(TDEST_T))  axi4s_mux_in[N][2] ();

   generate for (genvar i = 0; i < N; i += 1) begin
       axi4s_intf_connector axi4s_mux_in_connector_0 ( .axi4s_from_tx(axis_to_mux[i]),         .axi4s_to_rx(axi4s_mux_in[i][0]) );
       axi4s_intf_connector axi4s_mux_in_connector_1 ( .axi4s_from_tx(axis_from_switch[1][i]), .axi4s_to_rx(axi4s_mux_in[i][1]) );

       axi4s_mux axi4s_mux_inst (
           .axi4s_in   ( axi4s_mux_in[i] ),
           .axi4s_out  ( axis_from_mux[i] )
       );
   end endgenerate

endmodule: p4_app
