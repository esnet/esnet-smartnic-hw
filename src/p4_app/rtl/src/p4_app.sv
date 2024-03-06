module p4_app
   import smartnic_322mhz_pkg::*;
#(
   parameter int N = 2, // Number of processor ports (per vitisnetp4 processor).
   parameter int M = 2  // Number of vitisnetp4 processors.
) (
   input logic        core_clk,
   input logic        core_rstn,
   input logic        axil_aclk,
   input timestamp_t  timestamp,

   axi4l_intf.peripheral axil_if,

   // (SDNet) AXI-L control interface
   // (synchronous to axil_aclk domain)
   // -- Reset
   input  logic [(M*  1)-1:0] axil_sdnet_aresetn,
   // -- Write address
   input  logic [(M*  1)-1:0] axil_sdnet_awvalid,
   output logic [(M*  1)-1:0] axil_sdnet_awready,
   input  logic [(M* 32)-1:0] axil_sdnet_awaddr,
   input  logic [(M*  3)-1:0] axil_sdnet_awprot,
   // -- Write data
   input  logic [(M*  1)-1:0] axil_sdnet_wvalid,
   output logic [(M*  1)-1:0] axil_sdnet_wready,
   input  logic [(M* 32)-1:0] axil_sdnet_wdata,
   input  logic [(M*  4)-1:0] axil_sdnet_wstrb,
   // -- Write response
   output logic [(M*  1)-1:0] axil_sdnet_bvalid,
   input  logic [(M*  1)-1:0] axil_sdnet_bready,
   output logic [(M*  2)-1:0] axil_sdnet_bresp,
   // -- Read address
   input  logic [(M*  1)-1:0] axil_sdnet_arvalid,
   output logic [(M*  1)-1:0] axil_sdnet_arready,
   input  logic [(M* 32)-1:0] axil_sdnet_araddr,
   input  logic [(M*  3)-1:0] axil_sdnet_arprot,
   // -- Read data
   output logic [(M*  1)-1:0] axil_sdnet_rvalid,
   input  logic [(M*  1)-1:0] axil_sdnet_rready,
   output logic [(M* 32)-1:0] axil_sdnet_rdata,
   output logic [(M*  2)-1:0] axil_sdnet_rresp,

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

   logic [M-1:0][DATA_BYTE_WID*8-1:0]  axis_to_sdnet_tdata;
   logic [M-1:0][DATA_BYTE_WID-1:0]    axis_to_sdnet_tkeep;
   logic [M-1:0]                       axis_to_sdnet_tvalid;
   logic [M-1:0]                       axis_to_sdnet_tlast;
   logic [M-1:0]                       axis_to_sdnet_tready;

   logic [M-1:0][DATA_BYTE_WID*8-1:0]  axis_from_sdnet_tdata;
   logic [M-1:0][DATA_BYTE_WID-1:0]    axis_from_sdnet_tkeep;
   logic [M-1:0]                       axis_from_sdnet_tvalid;
   logic [M-1:0]                       axis_from_sdnet_tlast;
   logic [M-1:0]                       axis_from_sdnet_tready;

   generate for (genvar i = 0; i < M; i += 1)
       begin
           assign axis_to_sdnet_tdata[i]    = axis_to_sdnet[i].tdata;
           assign axis_to_sdnet_tkeep[i]    = axis_to_sdnet[i].tkeep;
           assign axis_to_sdnet_tlast[i]    = axis_to_sdnet[i].tlast;
           assign axis_to_sdnet_tvalid[i]   = axis_to_sdnet[i].tvalid;
           assign axis_to_sdnet[i].tready   = axis_to_sdnet_tready[i];

           assign axis_from_sdnet[i].tdata  = axis_from_sdnet_tdata[i];
           assign axis_from_sdnet[i].tkeep  = axis_from_sdnet_tkeep[i];
           assign axis_from_sdnet[i].tlast  = axis_from_sdnet_tlast[i];
           assign axis_from_sdnet[i].tvalid = axis_from_sdnet_tvalid[i];
           assign axis_from_sdnet_tready[i] = axis_from_sdnet[i].tready;
       end
   endgenerate

   user_metadata_t user_metadata_in[M];
   logic           user_metadata_in_valid[M];

   user_metadata_t user_metadata_out[M];
   logic           user_metadata_out_valid[M];

   // --- ingress p4 processor complex (p4_proc + sdnet_igr_wrapper) ---
   p4_proc #(.N(2)) p4_proc_igr (
      .core_clk                ( core_clk ),
      .core_rstn               ( core_rstn ),
      .timestamp               ( timestamp ),
      .axil_if                 ( axil_to_p4_proc ),
      .axis_to_switch          ( axis_to_switch[0] ),
      .axis_from_switch        ( axis_from_switch[0] ),
      .axis_from_sdnet         ( axis_from_sdnet[0] ),
      .axis_to_sdnet           ( axis_to_sdnet[0] ),
      .user_metadata_in_valid  ( user_metadata_in_valid[0] ),
      .user_metadata_in        ( user_metadata_in[0] ),
      .user_metadata_out_valid ( user_metadata_out_valid[0] ),
      .user_metadata_out       ( user_metadata_out[0] )
   );

   sdnet_igr_wrapper sdnet_igr_wrapper_0 (
      .core_clk                ( core_clk ),
      .core_rstn               ( core_rstn ),

      .axil_sdnet_aclk         ( axil_aclk ),
      .axil_sdnet_aresetn      ( axil_sdnet_aresetn [0 +: 1] ),
      .axil_sdnet_awvalid      ( axil_sdnet_awvalid [0 +: 1] ),
      .axil_sdnet_awready      ( axil_sdnet_awready [0 +: 1] ),
      .axil_sdnet_awaddr       ( axil_sdnet_awaddr  [0 +: 32] ),
      .axil_sdnet_awprot       ( axil_sdnet_awprot  [0 +: 3] ),
      .axil_sdnet_wvalid       ( axil_sdnet_wvalid  [0 +: 1] ),
      .axil_sdnet_wready       ( axil_sdnet_wready  [0 +: 1] ),
      .axil_sdnet_wdata        ( axil_sdnet_wdata   [0 +: 32] ),
      .axil_sdnet_wstrb        ( axil_sdnet_wstrb   [0 +: 4] ),
      .axil_sdnet_bvalid       ( axil_sdnet_bvalid  [0 +: 1] ),
      .axil_sdnet_bready       ( axil_sdnet_bready  [0 +: 1] ),
      .axil_sdnet_bresp        ( axil_sdnet_bresp   [0 +: 2] ),
      .axil_sdnet_arvalid      ( axil_sdnet_arvalid [0 +: 1] ),
      .axil_sdnet_arready      ( axil_sdnet_arready [0 +: 1] ),
      .axil_sdnet_araddr       ( axil_sdnet_araddr  [0 +: 32] ),
      .axil_sdnet_arprot       ( axil_sdnet_arprot  [0 +: 3] ),
      .axil_sdnet_rvalid       ( axil_sdnet_rvalid  [0 +: 1] ),
      .axil_sdnet_rready       ( axil_sdnet_rready  [0 +: 1] ),
      .axil_sdnet_rdata        ( axil_sdnet_rdata   [0 +: 32] ),
      .axil_sdnet_rresp        ( axil_sdnet_rresp   [0 +: 2] ),

      .axis_to_sdnet_tdata     ( axis_to_sdnet_tdata[0] ),
      .axis_to_sdnet_tkeep     ( axis_to_sdnet_tkeep[0] ),
      .axis_to_sdnet_tvalid    ( axis_to_sdnet_tvalid[0] ),
      .axis_to_sdnet_tlast     ( axis_to_sdnet_tlast[0] ),
      .axis_to_sdnet_tready    ( axis_to_sdnet_tready[0] ),

      .axis_from_sdnet_tdata   ( axis_from_sdnet_tdata[0] ),
      .axis_from_sdnet_tkeep   ( axis_from_sdnet_tkeep[0] ),
      .axis_from_sdnet_tvalid  ( axis_from_sdnet_tvalid[0] ),
      .axis_from_sdnet_tlast   ( axis_from_sdnet_tlast[0] ),
      .axis_from_sdnet_tready  ( axis_from_sdnet_tready[0] ),

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

           p4_proc #(.N(2)) p4_proc_1 (
               .core_clk                ( core_clk ),
               .core_rstn               ( core_rstn ),
               .timestamp               ( timestamp ),
               .axil_if                 ( axil_to_p4_proc_1 ),
               .axis_to_switch          ( axis_to_switch[1] ),
               .axis_from_switch        ( axis_from_switch[1] ),
               .axis_from_sdnet         ( axis_from_sdnet[1] ),
               .axis_to_sdnet           ( axis_to_sdnet[1] ),
               .user_metadata_in_valid  ( user_metadata_in_valid[1] ),
               .user_metadata_in        ( user_metadata_in[1] ),
               .user_metadata_out_valid ( user_metadata_out_valid[1] ),
               .user_metadata_out       ( user_metadata_out[1] )
           );

           axi3_intf   #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_to_hbm_1[16] ();
           for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
                // For now, terminate sdnet_1 HBM memory interfaces (unused)
                axi3_intf_controller_term axi_to_hbm_1_term (.axi3_if(axi_to_hbm_1[g_hbm_if]));
           end : g__hbm_if

           sdnet_egr_wrapper sdnet_egr_wrapper_0 (
               .core_clk                ( core_clk ),
               .core_rstn               ( core_rstn ),

               .axil_sdnet_aclk         ( axil_aclk ),
               .axil_sdnet_aresetn      ( axil_sdnet_aresetn [ 1 +: 1]),
               .axil_sdnet_awvalid      ( axil_sdnet_awvalid [ 1 +: 1] ),
               .axil_sdnet_awready      ( axil_sdnet_awready [ 1 +: 1] ),
               .axil_sdnet_awaddr       ( axil_sdnet_awaddr  [32 +: 32] ),
               .axil_sdnet_awprot       ( axil_sdnet_awprot  [ 3 +: 3] ),
               .axil_sdnet_wvalid       ( axil_sdnet_wvalid  [ 1 +: 1] ),
               .axil_sdnet_wready       ( axil_sdnet_wready  [ 1 +: 1] ),
               .axil_sdnet_wdata        ( axil_sdnet_wdata   [32 +: 32] ),
               .axil_sdnet_wstrb        ( axil_sdnet_wstrb   [ 4 +: 4] ),
               .axil_sdnet_bvalid       ( axil_sdnet_bvalid  [ 1 +: 1] ),
               .axil_sdnet_bready       ( axil_sdnet_bready  [ 1 +: 1] ),
               .axil_sdnet_bresp        ( axil_sdnet_bresp   [ 2 +: 2] ),
               .axil_sdnet_arvalid      ( axil_sdnet_arvalid [ 1 +: 1] ),
               .axil_sdnet_arready      ( axil_sdnet_arready [ 1 +: 1] ),
               .axil_sdnet_araddr       ( axil_sdnet_araddr  [32 +: 32] ),
               .axil_sdnet_arprot       ( axil_sdnet_arprot  [ 3 +: 3] ),
               .axil_sdnet_rvalid       ( axil_sdnet_rvalid  [ 1 +: 1] ),
               .axil_sdnet_rready       ( axil_sdnet_rready  [ 1 +: 1] ),
               .axil_sdnet_rdata        ( axil_sdnet_rdata   [32 +: 32] ),
               .axil_sdnet_rresp        ( axil_sdnet_rresp   [ 2 +: 2] ),

               .axis_to_sdnet_tdata     ( axis_to_sdnet_tdata[1] ),
               .axis_to_sdnet_tkeep     ( axis_to_sdnet_tkeep[1] ),
               .axis_to_sdnet_tvalid    ( axis_to_sdnet_tvalid[1] ),
               .axis_to_sdnet_tlast     ( axis_to_sdnet_tlast[1] ),
               .axis_to_sdnet_tready    ( axis_to_sdnet_tready[1] ),

               .axis_from_sdnet_tdata   ( axis_from_sdnet_tdata[1] ),
               .axis_from_sdnet_tkeep   ( axis_from_sdnet_tkeep[1] ),
               .axis_from_sdnet_tvalid  ( axis_from_sdnet_tvalid[1] ),
               .axis_from_sdnet_tlast   ( axis_from_sdnet_tlast[1] ),
               .axis_from_sdnet_tready  ( axis_from_sdnet_tready[1] ),

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

endmodule: p4_app
