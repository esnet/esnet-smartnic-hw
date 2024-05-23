`define getbit(width, index, offset)    ((index)*(width) + (offset))
`define getvec(width, index)            ((index)*(width)) +: (width)

module smartnic
#(
  parameter int NUM_CMAC = 2,
  parameter int MAX_PKT_LEN = 9100,
`ifndef SYNTHESIS
  parameter bit INCLUDE_HBM0 = 1'b1,
  parameter bit INCLUDE_HBM1 = 1'b1
`else
  parameter bit INCLUDE_HBM0 = smartnic_app_pkg::INCLUDE_HBM, // Application-specific HBM controller include/exclude
                                     // HBM0 controller is connected to application logic
                                     // (can be excluded for non-HBM applications to optimize resources/complexity)
  parameter bit INCLUDE_HBM1 = 1'b0  // HBM1 is connected to platform logic
                                     // (it is excluded by default because HBM is not currently used to implement any platform functions)
`endif
) (
  input                       s_axil_awvalid,
  input [31:0]                s_axil_awaddr,
  output                      s_axil_awready,
  input                       s_axil_wvalid,
  input [31:0]                s_axil_wdata,
  output                      s_axil_wready,
  output                      s_axil_bvalid,
  output [1:0]                s_axil_bresp,
  input                       s_axil_bready,
  input                       s_axil_arvalid,
  input [31:0]                s_axil_araddr,
  output                      s_axil_arready,
  output                      s_axil_rvalid,
  output [31:0]               s_axil_rdata,
  output [1:0]                s_axil_rresp,
  input                       s_axil_rready,

  input [NUM_CMAC-1:0]        s_axis_adpt_tx_322mhz_tvalid,
  input [(512*NUM_CMAC)-1:0]  s_axis_adpt_tx_322mhz_tdata,
  input [(64*NUM_CMAC)-1:0]   s_axis_adpt_tx_322mhz_tkeep,
  input [NUM_CMAC-1:0]        s_axis_adpt_tx_322mhz_tlast,
  input [(2*NUM_CMAC)-1:0]    s_axis_adpt_tx_322mhz_tdest,
  input [NUM_CMAC-1:0]        s_axis_adpt_tx_322mhz_tuser_err,
  output [NUM_CMAC-1:0]       s_axis_adpt_tx_322mhz_tready,

  output [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tvalid,
  output [(512*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tdata,
  output [(64*NUM_CMAC)-1:0]  m_axis_adpt_rx_322mhz_tkeep,
  output [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tlast,
  output [(2*NUM_CMAC)-1:0]   m_axis_adpt_rx_322mhz_tdest,
  output [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tuser_err,
  output [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tuser_rss_enable,
  output [(12*NUM_CMAC)-1:0]  m_axis_adpt_rx_322mhz_tuser_rss_entropy,
  input [NUM_CMAC-1:0]        m_axis_adpt_rx_322mhz_tready,

  output [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tvalid,
  output [(512*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tdata,
  output [(64*NUM_CMAC)-1:0]  m_axis_cmac_tx_322mhz_tkeep,
  output [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tlast,
  output [(2*NUM_CMAC)-1:0]   m_axis_cmac_tx_322mhz_tdest,
  output [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tuser_err,
  input [NUM_CMAC-1:0]        m_axis_cmac_tx_322mhz_tready,

  input [NUM_CMAC-1:0]        s_axis_cmac_rx_322mhz_tvalid,
  input [(512*NUM_CMAC)-1:0]  s_axis_cmac_rx_322mhz_tdata,
  input [(64*NUM_CMAC)-1:0]   s_axis_cmac_rx_322mhz_tkeep,
  input [NUM_CMAC-1:0]        s_axis_cmac_rx_322mhz_tlast,
  input [(2*NUM_CMAC)-1:0]    s_axis_cmac_rx_322mhz_tdest,
  input [NUM_CMAC-1:0]        s_axis_cmac_rx_322mhz_tuser_err,
  output [NUM_CMAC-1:0]       s_axis_cmac_rx_322mhz_tready,

  input                       mod_rstn,
  output                      mod_rst_done,

  input                       axil_aclk,
  input [NUM_CMAC-1:0]        cmac_clk
);

  localparam int HOST_NUM_IFS = 1;
  localparam int M = 2; // Number of vitisnetp4 processors.

  // Imports
  import smartnic_pkg::*;
  import smartnic_reg_pkg::*;
  import axi4s_pkg::*;

   // Signals
   wire                       axil_aresetn;
   wire [NUM_CMAC-1:0]        cmac_rstn;

   wire                       core_rstn;
   wire                       core_clk;

   wire                       clk_100mhz;
   wire                       hbm_ref_clk;

   tuser_smartnic_meta_t      m_axis_adpt_rx_322mhz_tuser [NUM_CMAC];

   logic [2*NUM_CMAC-1:0]     egr_flow_ctl, egr_flow_ctl_pipe[3];


  // Reset is clocked by the 125MHz AXI-Lite clock

  smartnic_reset #(
    .NUM_CMAC (NUM_CMAC)
  ) reset_inst (
    .mod_rstn     (mod_rstn),
    .mod_rst_done (mod_rst_done),

    .axil_aclk    (axil_aclk),
    .axil_aresetn (axil_aresetn),

    .cmac_clk     (cmac_clk),
    .cmac_srstn   (cmac_rstn),

    .core_srstn   (core_rstn),
    .core_clk     (core_clk),

    .clk_100mhz   (clk_100mhz),
    .hbm_ref_clk  (hbm_ref_clk)
  );

   // ----------------------------------------------------------------
   //  axil interface instantiations and regmap logic
   // ----------------------------------------------------------------

   axi4l_intf   s_axil_if                   ();
   axi4l_intf   axil_to_regs                ();
   axi4l_intf   axil_to_endian_check        ();
   axi4l_intf   axil_to_hbm_0               ();
   axi4l_intf   axil_to_hbm_1               ();
   axi4l_intf   axil_to_app_decoder__demarc ();
   axi4l_intf   axil_to_app_decoder         ();
   axi4l_intf   axil_to_app                 ();
   axi4l_intf   axil_to_p4                  ();

   axi4l_intf   axil_to_probe_from_cmac [NUM_CMAC] ();
   axi4l_intf   axil_to_ovfl_from_cmac  [NUM_CMAC] ();
   axi4l_intf   axil_to_err_from_cmac   [NUM_CMAC] ();
   axi4l_intf   axil_to_probe_from_host [NUM_CMAC] ();
   axi4l_intf   axil_to_ovfl_from_host  [NUM_CMAC] ();

   axi4l_intf   axil_to_probe_to_cmac   [NUM_CMAC] ();
   axi4l_intf   axil_to_ovfl_to_cmac    [NUM_CMAC] ();
   axi4l_intf   axil_to_probe_to_host   [NUM_CMAC] ();
   axi4l_intf   axil_to_ovfl_to_host    [NUM_CMAC] ();

   axi4l_intf   axil_to_fifo_to_cmac    [NUM_CMAC] ();
   axi4l_intf   axil_to_fifo_from_cmac  [NUM_CMAC] ();
   axi4l_intf   axil_to_fifo_to_host    [NUM_CMAC] ();
   axi4l_intf   axil_to_fifo_from_host  [NUM_CMAC] ();

   axi4l_intf   axil_to_core_to_app     [NUM_CMAC] ();
   axi4l_intf   axil_to_app_to_core     [NUM_CMAC] ();

   axi4l_intf   axil_to_probe_to_bypass            ();

   axi4l_intf   axil_to_drops_from_igr_sw          ();
   axi4l_intf   axil_to_drops_from_bypass          ();

   smartnic_reg_intf   smartnic_regs ();


   // Convert Xilinx AXI-L signals to interface format
   axi4l_intf_from_signals s_axil_from_signals_0 (
      // Signals (from controller)
      .aclk     (axil_aclk),
      .aresetn  (axil_aresetn),
      .awaddr   (s_axil_awaddr),
      .awprot   (3'b000),
      .awvalid  (s_axil_awvalid),
      .awready  (s_axil_awready),
      .wdata    (s_axil_wdata),
      .wstrb    (4'b1111),
      .wvalid   (s_axil_wvalid),
      .wready   (s_axil_wready),
      .bresp    (s_axil_bresp),
      .bvalid   (s_axil_bvalid),
      .bready   (s_axil_bready),
      .araddr   (s_axil_araddr),
      .arprot   (3'b000),
      .arvalid  (s_axil_arvalid),
      .arready  (s_axil_arready),
      .rdata    (s_axil_rdata),
      .rresp    (s_axil_rresp),
      .rvalid   (s_axil_rvalid),
      .rready   (s_axil_rready),

      // Interface (to peripheral)
      .axi4l_if (s_axil_if)
   );

   // smartnic top-level decoder
   smartnic_decoder smartnic_axil_decoder_0 (
      .axil_if                         (s_axil_if),
      .smartnic_regs_axil_if    (axil_to_regs),
      .endian_check_axil_if            (axil_to_endian_check),
      .probe_from_cmac_0_axil_if       (axil_to_probe_from_cmac[0]),
      .drops_ovfl_from_cmac_0_axil_if  (axil_to_ovfl_from_cmac[0]),
      .drops_err_from_cmac_0_axil_if   (axil_to_err_from_cmac[0]),
      .probe_from_cmac_1_axil_if       (axil_to_probe_from_cmac[1]),
      .drops_ovfl_from_cmac_1_axil_if  (axil_to_ovfl_from_cmac[1]),
      .drops_err_from_cmac_1_axil_if   (axil_to_err_from_cmac[1]),
      .probe_from_host_0_axil_if       (axil_to_probe_from_host[0]),
      .probe_from_host_1_axil_if       (axil_to_probe_from_host[1]),
      .probe_core_to_app0_axil_if      (axil_to_core_to_app[0]),
      .probe_core_to_app1_axil_if      (axil_to_core_to_app[1]),
      .probe_app0_to_core_axil_if      (axil_to_app_to_core[0]),
      .probe_app1_to_core_axil_if      (axil_to_app_to_core[1]),
      .probe_to_cmac_0_axil_if         (axil_to_probe_to_cmac[0]),
      .drops_ovfl_to_cmac_0_axil_if    (axil_to_ovfl_to_cmac[0]),
      .probe_to_cmac_1_axil_if         (axil_to_probe_to_cmac[1]),
      .drops_ovfl_to_cmac_1_axil_if    (axil_to_ovfl_to_cmac[1]),
      .probe_to_host_0_axil_if         (axil_to_probe_to_host[0]),
      .drops_ovfl_to_host_0_axil_if    (axil_to_ovfl_to_host[0]),
      .probe_to_host_1_axil_if         (axil_to_probe_to_host[1]),
      .drops_ovfl_to_host_1_axil_if    (axil_to_ovfl_to_host[1]),
      .probe_to_bypass_axil_if         (axil_to_probe_to_bypass),
      .drops_from_igr_sw_axil_if       (axil_to_drops_from_igr_sw),
      .drops_from_bypass_axil_if       (axil_to_drops_from_bypass),
      .fifo_to_host_0_axil_if          (axil_to_fifo_to_host[0]),
      .hbm_0_axil_if                   (axil_to_hbm_0),
      .hbm_1_axil_if                   (axil_to_hbm_1),
      .smartnic_to_app_axil_if         (axil_to_app_decoder__demarc)
   );

   // AXI-L interface synchronizer
   axi4l_intf axil_to_regs__core_clk ();

   axi4l_intf_cdc axil_to_regs_cdc (
      .axi4l_if_from_controller  ( axil_to_regs ),
      .clk_to_peripheral         ( core_clk ),
      .axi4l_if_to_peripheral    ( axil_to_regs__core_clk )
   );

   // smartnic register block
   smartnic_reg_blk     smartnic_reg_blk_0
   (
    .axil_if    (axil_to_regs__core_clk),
    .reg_blk_if (smartnic_regs)
   );

   // Endian check reg block
   reg_endian_check reg_endian_check_0 (
       .axil_if (axil_to_endian_check)
   );

   // Timestamp counter and access logic
   logic [63:0] timestamp;

   smartnic_timestamp  smartnic_timestamp_0 (
     .clk               (core_clk),
     .rstn              (core_rstn),
     .timestamp         (timestamp),
     .smartnic_regs (smartnic_regs)
   );

   // axis_to_host_tpause synchronizers
   logic axis_to_host_tpause [NUM_CMAC];

   sync_level sync_level_0 (
      .clk_in  ( core_clk ),
      .rst_in  ( 1'b0 ),
      .rdy_in  ( ),
      .lvl_in  ( smartnic_regs.switch_config.axis_to_host_0_tpause ),
      .clk_out ( cmac_clk[0] ),
      .rst_out ( 1'b0 ),
      .lvl_out ( axis_to_host_tpause[0] )
   );

   sync_level sync_level_1 (
      .clk_in  ( core_clk ),
      .rst_in  ( 1'b0 ),
      .rdy_in  ( ),
      .lvl_in  ( smartnic_regs.switch_config.axis_to_host_1_tpause ),
      .clk_out ( cmac_clk[1] ),
      .rst_out ( 1'b0 ),
      .lvl_out ( axis_to_host_tpause[1] )
   );

   // ----------------------------------------------------------------
   //  HBM0 (Left stack, 4GB)
   //
   //  (Optionally) used by application
   // ----------------------------------------------------------------
   // Signals
   logic [15:0]        axi_app_to_hbm_aclk;
   logic [15:0]        axi_app_to_hbm_aresetn;
   logic [15:0][5:0]   axi_app_to_hbm_awid;
   logic [15:0][32:0]  axi_app_to_hbm_awaddr;
   logic [15:0][3:0]   axi_app_to_hbm_awlen;
   logic [15:0][2:0]   axi_app_to_hbm_awsize;
   logic [15:0][1:0]   axi_app_to_hbm_awburst;
   logic [15:0][1:0]   axi_app_to_hbm_awlock;
   logic [15:0][3:0]   axi_app_to_hbm_awcache;
   logic [15:0][2:0]   axi_app_to_hbm_awprot;
   logic [15:0][3:0]   axi_app_to_hbm_awqos;
   logic [15:0][3:0]   axi_app_to_hbm_awregion;
   logic [15:0]        axi_app_to_hbm_awuser;
   logic [15:0]        axi_app_to_hbm_awvalid;
   logic [15:0]        axi_app_to_hbm_awready;
   logic [15:0][5:0]   axi_app_to_hbm_wid;
   logic [15:0][255:0] axi_app_to_hbm_wdata;
   logic [15:0][31:0]  axi_app_to_hbm_wstrb;
   logic [15:0]        axi_app_to_hbm_wlast;
   logic [15:0]        axi_app_to_hbm_wuser;
   logic [15:0]        axi_app_to_hbm_wvalid;
   logic [15:0]        axi_app_to_hbm_wready;
   logic [15:0][5:0]   axi_app_to_hbm_bid;
   logic [15:0][1:0]   axi_app_to_hbm_bresp;
   logic [15:0]        axi_app_to_hbm_buser;
   logic [15:0]        axi_app_to_hbm_bvalid;
   logic [15:0]        axi_app_to_hbm_bready;
   logic [15:0][5:0]   axi_app_to_hbm_arid;
   logic [15:0][32:0]  axi_app_to_hbm_araddr;
   logic [15:0][3:0]   axi_app_to_hbm_arlen;
   logic [15:0][2:0]   axi_app_to_hbm_arsize;
   logic [15:0][1:0]   axi_app_to_hbm_arburst;
   logic [15:0][1:0]   axi_app_to_hbm_arlock;
   logic [15:0][3:0]   axi_app_to_hbm_arcache;
   logic [15:0][2:0]   axi_app_to_hbm_arprot;
   logic [15:0][3:0]   axi_app_to_hbm_arqos;
   logic [15:0][3:0]   axi_app_to_hbm_arregion;
   logic [15:0]        axi_app_to_hbm_aruser;
   logic [15:0]        axi_app_to_hbm_arvalid;
   logic [15:0]        axi_app_to_hbm_arready;
   logic [15:0][5:0]   axi_app_to_hbm_rid;
   logic [15:0][255:0] axi_app_to_hbm_rdata;
   logic [15:0][1:0]   axi_app_to_hbm_rresp;
   logic [15:0]        axi_app_to_hbm_rlast;
   logic [15:0]        axi_app_to_hbm_ruser;
   logic [15:0]        axi_app_to_hbm_rvalid;
   logic [15:0]        axi_app_to_hbm_rready;

   generate
       if (INCLUDE_HBM0) begin : g__hbm_0
           // Include memory controller for 'Left' HBM stack (4GB)

           // (Local) interfaces
           axi3_intf   #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_if_from_app [16] ();

           // HBM controller
           smartnic_hbm #(
             .HBM_STACK   ( 0 )
           ) smartnic_hbm_0 (
             .clk         ( core_clk ),
             .rstn        ( core_rstn ),
             .hbm_ref_clk ( hbm_ref_clk ),
             .clk_100mhz  ( clk_100mhz ),
             .axil_if     ( axil_to_hbm_0 ),
             .axi_if      ( axi_if_from_app )
           );

           //  Map HBM0 memory interface signals into interface representation
           for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
               // (Local) interfaces
               axi3_intf   #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_if_from_app__demarc ();

               axi3_intf_from_signals #(
                   .DATA_BYTE_WID(32),
                   .ADDR_WID     (33),
                   .ID_T         (logic[5:0])
               ) axi3_intf_from_signals__hbm (
                   .aclk     ( core_clk ),
                   .aresetn  ( core_rstn ),
                   .awid     ( axi_app_to_hbm_awid    [g_hbm_if] ),
                   .awaddr   ( axi_app_to_hbm_awaddr  [g_hbm_if] ),
                   .awlen    ( axi_app_to_hbm_awlen   [g_hbm_if] ),
                   .awsize   ( axi_app_to_hbm_awsize  [g_hbm_if] ),
                   .awburst  ( axi_app_to_hbm_awburst [g_hbm_if] ),
                   .awlock   ( axi_app_to_hbm_awlock  [g_hbm_if] ),
                   .awcache  ( axi_app_to_hbm_awcache [g_hbm_if] ),
                   .awprot   ( axi_app_to_hbm_awprot  [g_hbm_if] ),
                   .awqos    ( axi_app_to_hbm_awqos   [g_hbm_if] ),
                   .awregion ( axi_app_to_hbm_awregion[g_hbm_if] ),
                   .awuser   ( axi_app_to_hbm_awuser  [g_hbm_if] ),
                   .awvalid  ( axi_app_to_hbm_awvalid [g_hbm_if] ),
                   .awready  ( axi_app_to_hbm_awready [g_hbm_if] ),
                   .wid      ( axi_app_to_hbm_wid     [g_hbm_if] ),
                   .wdata    ( axi_app_to_hbm_wdata   [g_hbm_if] ),
                   .wstrb    ( axi_app_to_hbm_wstrb   [g_hbm_if] ),
                   .wlast    ( axi_app_to_hbm_wlast   [g_hbm_if] ),
                   .wuser    ( axi_app_to_hbm_wuser   [g_hbm_if] ),
                   .wvalid   ( axi_app_to_hbm_wvalid  [g_hbm_if] ),
                   .wready   ( axi_app_to_hbm_wready  [g_hbm_if] ),
                   .bid      ( axi_app_to_hbm_bid     [g_hbm_if] ),
                   .bresp    ( axi_app_to_hbm_bresp   [g_hbm_if] ),
                   .buser    ( axi_app_to_hbm_buser   [g_hbm_if] ),
                   .bvalid   ( axi_app_to_hbm_bvalid  [g_hbm_if] ),
                   .bready   ( axi_app_to_hbm_bready  [g_hbm_if] ),
                   .arid     ( axi_app_to_hbm_arid    [g_hbm_if] ),
                   .araddr   ( axi_app_to_hbm_araddr  [g_hbm_if] ),
                   .arlen    ( axi_app_to_hbm_arlen   [g_hbm_if] ),
                   .arsize   ( axi_app_to_hbm_arsize  [g_hbm_if] ),
                   .arburst  ( axi_app_to_hbm_arburst [g_hbm_if] ),
                   .arlock   ( axi_app_to_hbm_arlock  [g_hbm_if] ),
                   .arcache  ( axi_app_to_hbm_arcache [g_hbm_if] ),
                   .arprot   ( axi_app_to_hbm_arprot  [g_hbm_if] ),
                   .arqos    ( axi_app_to_hbm_arqos   [g_hbm_if] ),
                   .arregion ( axi_app_to_hbm_arregion[g_hbm_if] ),
                   .aruser   ( axi_app_to_hbm_aruser  [g_hbm_if] ),
                   .arvalid  ( axi_app_to_hbm_arvalid [g_hbm_if] ),
                   .arready  ( axi_app_to_hbm_arready [g_hbm_if] ),
                   .rid      ( axi_app_to_hbm_rid     [g_hbm_if] ),
                   .rdata    ( axi_app_to_hbm_rdata   [g_hbm_if] ),
                   .rresp    ( axi_app_to_hbm_rresp   [g_hbm_if] ),
                   .rlast    ( axi_app_to_hbm_rlast   [g_hbm_if] ),
                   .ruser    ( axi_app_to_hbm_ruser   [g_hbm_if] ),
                   .rvalid   ( axi_app_to_hbm_rvalid  [g_hbm_if] ),
                   .rready   ( axi_app_to_hbm_rready  [g_hbm_if] ),
                   .axi3_if  ( axi_if_from_app__demarc )
               );

               // Inter-SLR pipelining
               axi3_reg_slice #(
                   .ADDR_WID      ( 33 ),
                   .DATA_BYTE_WID ( 32 ),
                   .ID_T          ( logic[5:0] ),
                   .CONFIG        ( xilinx_axi_pkg::XILINX_AXI_REG_SLICE_MULTI_SLR_CROSSING )
               ) axi3_reg_slice_inst (
                   .axi3_if_from_controller ( axi_if_from_app__demarc ),
                   .axi3_if_to_peripheral   ( axi_if_from_app[g_hbm_if] )
               );

           end : g__hbm_if
       end : g__hbm_0
       else begin : g__no_hbm_0
           // No HBM0 controller

           // Terminate AXI memory interfaces
           for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
               assign axi_app_to_hbm_awready[g_hbm_if] = 1'b0;
               assign axi_app_to_hbm_wready[g_hbm_if] = 1'b0;
               assign axi_app_to_hbm_bid[g_hbm_if] = '0;
               assign axi_app_to_hbm_bresp[g_hbm_if] = axi3_pkg::RESP_SLVERR;
               assign axi_app_to_hbm_buser[g_hbm_if] = '0;
               assign axi_app_to_hbm_bvalid[g_hbm_if] = 1'b0;
               assign axi_app_to_hbm_arready[g_hbm_if] = 1'b0;
               assign axi_app_to_hbm_rid[g_hbm_if] = '0;
               assign axi_app_to_hbm_rdata[g_hbm_if] = '0;
               assign axi_app_to_hbm_rresp[g_hbm_if] = axi3_pkg::RESP_SLVERR;
               assign axi_app_to_hbm_rlast[g_hbm_if] = 1'b0;
               assign axi_app_to_hbm_ruser[g_hbm_if] = '0;
               assign axi_app_to_hbm_rvalid[g_hbm_if] = 1'b0;
           end : g__hbm_if

           // Terminate AXI-L interface
           axi4l_intf_peripheral_term i_axi4l_peripheral_term (.axi4l_if (axil_to_hbm_0));
       end : g__no_hbm_0
   endgenerate

   // ----------------------------------------------------------------
   //  HBM1 (Right stack, 4GB)
   //
   //  (Optionally) used by platform
   // ----------------------------------------------------------------
   generate
       if (INCLUDE_HBM1) begin : g__hbm_1
           // Include memory controller for 'Right' HBM stack (4GB)

           // (Local) interfaces
           axi3_intf   #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_if[16] ();

           // HBM controller
           smartnic_hbm #(
             .HBM_STACK   (1)
           ) smartnic_hbm_1 (
             .clk         (core_clk),
             .rstn        (core_rstn),
             .hbm_ref_clk (hbm_ref_clk),
             .clk_100mhz  (clk_100mhz),
             .axil_if     (axil_to_hbm_1),
             .axi_if      (axi_if)
           );

           for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
               // For now, terminate HBM1 memory interfaces (unused)
               axi3_intf_controller_term axi_to_hbm_1_term (.axi3_if(axi_if[g_hbm_if]));
           end : g__hbm_if
       end : g__hbm_1
       else begin : g__no_hbm_1
           // No HBM 1 controller

           // Terminate AXI-L interface
           axi4l_intf_peripheral_term i_axi4l_peripheral_term (.axi4l_if (axil_to_hbm_1));
       end : g__no_hbm_1
   endgenerate

   // ----------------------------------------------------------------
   //  axi4s interface instantiations
   // ----------------------------------------------------------------

   axi4s_intf  #(.MODE(IGNORES_TREADY), .TUSER_MODE(PKT_ERROR),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         __axis_from_cmac    [NUM_CMAC] ();
   axi4s_intf  #(.MODE(IGNORES_TREADY), .TUSER_MODE(PKT_ERROR),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_from_cmac      [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_from_host      [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_cmac_to_core   [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_host_to_core   [NUM_CMAC] ();

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_core_to_bypass ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_bypass_to_core ();

   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))    axis_core_to_app [NUM_CMAC] ();
   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_to_app__demarc [NUM_CMAC] ();
   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_to_app [NUM_CMAC] ();

   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_h2c [HOST_NUM_IFS][NUM_CMAC] ();
   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_c2h [HOST_NUM_IFS][NUM_CMAC] ();

   tuser_smartnic_meta_t axis_to_app_tuser [NUM_CMAC];
   assign axis_to_app_tuser[0] = axis_to_app[0].tuser;
   assign axis_to_app_tuser[1] = axis_to_app[1].tuser;

   tuser_smartnic_meta_t axis_from_app_tuser [NUM_CMAC];
   assign axis_from_app[0].tuser = axis_from_app_tuser[0];
   assign axis_from_app[1].tuser = axis_from_app_tuser[1];

   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))    axis_from_app [NUM_CMAC] ();
   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))    axis_from_app__demarc [NUM_CMAC] ();
   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))    axis_app_to_core [NUM_CMAC] ();

   axi4s_intf  #(.MODE(IGNORES_TREADY), .TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_core_to_host [NUM_CMAC] ();
   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_to_host [NUM_CMAC] ();

   axi4s_intf  #(.MODE(IGNORES_TREADY),
                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_core_to_cmac [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_to_pad       [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         __axis_to_cmac    [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_to_cmac      [NUM_CMAC] ();


   // ----------------------------------------------------------------
   // fifos to go from independent CMAC clock domains to a single
   // core clock domain
   // ----------------------------------------------------------------

   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__fifo
       // (Local) signals
       port_t cmac_igr_sw_tid [NUM_CMAC];
       port_t host_igr_sw_tid [NUM_CMAC];

      //------------------------ from cmac to core --------------
      axi4s_intf_from_signals #(
        .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)
      ) axis_from_cmac_from_signals (
        .aclk     (cmac_clk[i]),
        .aresetn  (cmac_rstn[i]),
        .tvalid   (s_axis_cmac_rx_322mhz_tvalid[i]),
        .tready   (s_axis_cmac_rx_322mhz_tready[i]), // NOTE: tready signal is ignored by open-nic-shell.
        .tdata    (s_axis_cmac_rx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (s_axis_cmac_rx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (s_axis_cmac_rx_322mhz_tlast[i]),
        .tid      (cmac_igr_sw_tid[i]),
        .tdest    (s_axis_cmac_rx_322mhz_tdest[`getvec(2, i)]),
        .tuser    (s_axis_cmac_rx_322mhz_tuser_err[i]),

        .axi4s_if (__axis_from_cmac[i])
      );

      // Cross CMAC ingress switch port selection to cmac_clk domain
      sync_bus_sampled #(
        .DATA_T   ( port_t )
      ) i_sync_bus_sampled__cmac_igr_sw_tid (
        .clk_in   ( core_clk ),
        .rst_in   ( 1'b0 ),
        .data_in  ( smartnic_regs.igr_sw_tid[i]),
        .clk_out  ( cmac_clk[i] ),
        .rst_out  ( 1'b0 ),
        .data_out ( cmac_igr_sw_tid[i] )
      );

      // axi4s_ila axi4s_ila_0 (.axis_in(axis_from_cmac[i]));

      axi4s_reg_slice #(
          .DATA_BYTE_WID (64), .TID_T (port_t), .TDEST_T(port_t),
          .CONFIG ( xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_FULLY_REGISTERED )
      ) axi4s_reg_slice_from_cmac (
          .axi4s_from_tx (__axis_from_cmac[i]),
          .axi4s_to_rx   (axis_from_cmac[i])
      );

      axi4s_probe #( .MODE(ERRORS) ) axi4s_err_from_cmac (
            .axi4l_if  (axil_to_err_from_cmac[i]),
            .axi4s_if  (axis_from_cmac[i])
         );

      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (1024),
        .MAX_PKT_LEN    (MAX_PKT_LEN)
      ) fifo_from_cmac (
        .axi4s_in       (axis_from_cmac[i]),
        .clk_out        (core_clk),
        .axi4s_out      (axis_cmac_to_core[i]),
        .axil_to_probe  (axil_to_probe_from_cmac[i]),
        .axil_to_ovfl   (axil_to_ovfl_from_cmac[i]),
        .axil_if        (axil_to_fifo_from_cmac[i])
      );

      // Terminate unused AXI-L interface
      axi4l_intf_controller_term axi4l_fifo_from_cmac_term (.axi4l_if (axil_to_fifo_from_cmac[i]));



      //------------------------ from core to cmac --------------
      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (1024),
        .MAX_PKT_LEN    (MAX_PKT_LEN)
      ) fifo_to_cmac (
        .axi4s_in       (axis_core_to_cmac[i]),
        .clk_out        (cmac_clk[i]),
        .axi4s_out      (axis_to_pad[i]),
        .flow_ctl_thresh (smartnic_regs.egr_fc_thresh[i][15:0]),
        .flow_ctl       (egr_flow_ctl[i]),
        .axil_to_probe  (axil_to_probe_to_cmac[i]),
        .axil_to_ovfl   (axil_to_ovfl_to_cmac[i]),
        .axil_if        (axil_to_fifo_to_cmac[i])
      );

      // axi4s pad instantiation.
      axi4s_pad axi4s_pad_0 (
        .axi4s_in    (axis_to_pad[i]),
        .axi4s_out   (__axis_to_cmac[i])
      );

      axi4s_reg_slice #(
          .DATA_BYTE_WID (64), .TID_T (port_t), .TDEST_T(port_t),
          .CONFIG ( xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_FULLY_REGISTERED )
      ) axi4s_reg_slice_to_cmac (
          .axi4s_from_tx (__axis_to_cmac[i]),
          .axi4s_to_rx   (axis_to_cmac[i])
      );

      // axi4s_ila axi4s_ila_1 (.axis_in(axis_core_to_cmac[i]));
      // axi4s_ila axi4s_ila_2 (.axis_in(axis_to_cmac[i]));

      // Terminate unused AXI-L interface
      axi4l_intf_controller_term axi4l_fifo_to_cmac_term (.axi4l_if (axil_to_fifo_to_cmac[i]));

      axi4s_intf_to_signals #(
        .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)
      ) axis_to_cmac_to_signals (
        .aclk     (),
        .aresetn  (),
        .tvalid   (m_axis_cmac_tx_322mhz_tvalid[i]),
        .tready   (m_axis_cmac_tx_322mhz_tready[i]),
        .tdata    (m_axis_cmac_tx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (m_axis_cmac_tx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (m_axis_cmac_tx_322mhz_tlast[i]),
        .tid      (),
        .tdest    (m_axis_cmac_tx_322mhz_tdest[`getvec(2, i)]),
        .tuser    (m_axis_cmac_tx_322mhz_tuser_err[i]),

        .axi4s_if (axis_to_cmac[i])
      );


      //------------------------ from core to host --------------
      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (1024),
        .MAX_PKT_LEN    (MAX_PKT_LEN)
      ) fifo_to_host (
        .axi4s_in       (axis_core_to_host[i]),
        .clk_out        (cmac_clk[i]),
        .axi4s_out      (axis_to_host[i]),
        .flow_ctl_thresh (smartnic_regs.egr_fc_thresh[2+i][15:0]),
        .flow_ctl       (egr_flow_ctl[2+i]),
        .axil_to_probe  (axil_to_probe_to_host[i]),
        .axil_to_ovfl   (axil_to_ovfl_to_host[i]),
        .axil_if        (axil_to_fifo_to_host[i])
      );

      // axi4s_ila axi4s_ila_to_host (.axis_in(axis_to_host[i]));

      // Terminate unused AXI-L interface
      if (i != 0) axi4l_intf_controller_term axi4l_fifo_to_host_term (.axi4l_if (axil_to_fifo_to_host[i]));

      axi4s_intf_to_signals #(
        .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)
      ) axis_to_host_to_signals (
        .aclk     (),
        .aresetn  (),
        .tvalid   (),  // see assignment below
        .tready   (m_axis_adpt_rx_322mhz_tready[i] && !axis_to_host_tpause[i]),
        .tdata    (m_axis_adpt_rx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (m_axis_adpt_rx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (m_axis_adpt_rx_322mhz_tlast[i]),
        .tid      (),
        .tdest    (m_axis_adpt_rx_322mhz_tdest[`getvec(2, i)]),
        .tuser    (m_axis_adpt_rx_322mhz_tuser[i]),

        .axi4s_if (axis_to_host[i])
      );

      assign m_axis_adpt_rx_322mhz_tvalid[i] = axis_to_host[i].tvalid && !axis_to_host_tpause[i];

      assign m_axis_adpt_rx_322mhz_tuser_err[i] = '0;
      assign m_axis_adpt_rx_322mhz_tuser_rss_enable[i] = m_axis_adpt_rx_322mhz_tuser[i].rss_enable;
      assign m_axis_adpt_rx_322mhz_tuser_rss_entropy[`getvec(12, i)] = m_axis_adpt_rx_322mhz_tuser[i].rss_entropy;


      //------------------------ from host to core --------------
      axi4s_intf_from_signals #(
        .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)
      ) axis_from_host_from_signals (
        .aclk     (cmac_clk[i]),
        .aresetn  (cmac_rstn[i]),
        .tvalid   (s_axis_adpt_tx_322mhz_tvalid[i]),
        .tready   (s_axis_adpt_tx_322mhz_tready[i]),
        .tdata    (s_axis_adpt_tx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (s_axis_adpt_tx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (s_axis_adpt_tx_322mhz_tlast[i]),
        .tid      (host_igr_sw_tid[i]),
        .tdest    (s_axis_adpt_tx_322mhz_tdest[`getvec(2, i)]),
        .tuser    (s_axis_adpt_tx_322mhz_tuser_err[i]),  // this is a deadend for now. no use in smartnic.

        .axi4s_if (axis_from_host[i])
      );

      // Cross Host ingress switch port selection to cmac_clk domain
      sync_bus_sampled #(
        .DATA_T   ( port_t )
      ) i_sync_bus_sampled__host_igr_sw_tid (
        .clk_in   ( core_clk ),
        .rst_in   ( 1'b0 ),
        .data_in  ( smartnic_regs.igr_sw_tid[2+i]),
        .clk_out  ( cmac_clk[i] ),
        .rst_out  ( 1'b0 ),
        .data_out ( host_igr_sw_tid[i] )
      );

      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (128),
        .MAX_PKT_LEN    (MAX_PKT_LEN)
      ) fifo_from_host (
        .axi4s_in       (axis_from_host[i]),
        .clk_out        (core_clk),
        .axi4s_out      (axis_host_to_core[i]),
        .axil_to_probe  (axil_to_probe_from_host[i]),
        .axil_to_ovfl   (axil_to_ovfl_from_host[i]),
        .axil_if        (axil_to_fifo_from_host[i])
      );

      axi4l_intf_controller_term axi4l_ovfl_from_host_term (.axi4l_if (axil_to_ovfl_from_host[i]));
      axi4l_intf_controller_term axi4l_fifo_from_host_term (.axi4l_if (axil_to_fifo_from_host[i]));

   end : g__fifo

   endgenerate



   // smartnic_mux instantiation.
   smartnic_mux #(
       .NUM_CMAC (NUM_CMAC)
   ) smartnic_mux_inst ( 
       .core_clk            (core_clk),
       .core_rstn           (core_rstn),
       .axis_cmac_to_core   (axis_cmac_to_core),
       .axis_host_to_core   (axis_host_to_core),
       .axis_core_to_app    (axis_core_to_app),
       .axis_core_to_bypass (axis_core_to_bypass),
       .smartnic_regs       (smartnic_regs)
   );

   // axi4s_ila #(.PIPE_STAGES(2)) axi4s_ila_core_to_app  (.axis_in(axis_core_to_app[0]));
   // axi4s_ila #(.PIPE_STAGES(2)) axi4s_ila_app_to_core  (.axis_in(axis_app_to_core[0]));
   // axi4s_ila #(.PIPE_STAGES(2)) axi4s_ila_hdr_to_app   (.axis_in(axis_to_app__demarc[0]));
   // axi4s_ila #(.PIPE_STAGES(2)) axi4s_ila_hdr_from_app (.axis_in(axis_from_app__demarc[0]));

   // smartnic_mux instantiation.
   smartnic_bypass #(
       .MAX_PKT_LEN (MAX_PKT_LEN)
   ) smartnic_bypass_inst ( 
       .core_clk                  (core_clk),
       .core_rstn                 (core_rstn),
       .axis_core_to_bypass       (axis_core_to_bypass),
       .axis_bypass_to_core       (axis_bypass_to_core),
       .axil_to_drops_from_igr_sw (axil_to_drops_from_igr_sw),
       .axil_to_probe_to_bypass   (axil_to_probe_to_bypass),
       .axil_to_drops_from_bypass (axil_to_drops_from_bypass),
       .smartnic_regs             (smartnic_regs)
   );

   axi4s_intf_pipe axis_core_to_app_pipe_0 (.axi4s_if_from_tx(axis_core_to_app[0]),      .axi4s_if_to_rx(axis_to_app__demarc[0]));
   axi4s_intf_pipe axis_app_to_core_pipe_0 (.axi4s_if_from_tx(axis_from_app__demarc[0]), .axi4s_if_to_rx(axis_app_to_core[0]));

   axi4s_intf_pipe axis_core_to_app_pipe_1 (.axi4s_if_from_tx(axis_core_to_app[1]),      .axi4s_if_to_rx(axis_to_app__demarc[1]));
   axi4s_intf_pipe axis_app_to_core_pipe_1 (.axi4s_if_from_tx(axis_from_app__demarc[1]), .axi4s_if_to_rx(axis_app_to_core[1]));


   // smartnic_demux instantiation.
   smartnic_demux #(
       .NUM_CMAC (NUM_CMAC)
   ) smartnic_demux_inst ( 
       .core_clk            (core_clk),
       .core_rstn           (core_rstn),
       .axis_bypass_to_core (axis_bypass_to_core),
       .axis_app_to_core    (axis_app_to_core),
       .axis_core_to_cmac   (axis_core_to_cmac),
       .axis_core_to_host   (axis_core_to_host),
       .smartnic_regs       (smartnic_regs)
   );


   // ----------------------------------------------------------------
   // AXI register slices
   // ----------------------------------------------------------------
   // - demarcate physical boundary between SmartNIC platform and application
   //   and support efficient pipelining between SLRs

   // AXI-L interface
   axi4l_reg_slice #(
       .CONFIG (xilinx_axi_pkg::XILINX_AXI_REG_SLICE_SLR_CROSSING)
   ) i_axi4l_reg_slice__core_to_app_0 (
       .axi4l_if_from_controller ( axil_to_app_decoder__demarc ),
       .axi4l_if_to_peripheral   ( axil_to_app_decoder )
   );

   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__reg_slice
       // AXI-S interfaces
       axi4s_reg_slice #(
           .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t),
           .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
       ) i_axi4s_reg_slice__core_to_app (
           .axi4s_from_tx (axis_to_app__demarc[i]),
           .axi4s_to_rx   (axis_to_app[i])
       );

       axi4s_reg_slice #(
           .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t), .TUSER_T(tuser_smartnic_meta_t),
           .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
       ) i_axi4s_reg_slice__app_to_core (
           .axi4s_from_tx (axis_from_app[i]),
           .axi4s_to_rx   (axis_from_app__demarc[i])
       );
   end : g__reg_slice
   endgenerate

   // ----------------------------------------------------------------
   // Application Core
   // ----------------------------------------------------------------

   always @(posedge core_clk) begin
      if (!core_rstn) begin
         for (int i=0; i<3; i++) egr_flow_ctl_pipe[i] <= '0;
      end else begin
         egr_flow_ctl_pipe[2] <= egr_flow_ctl;
         for (int i=1; i<3; i++) egr_flow_ctl_pipe[i-1] <= egr_flow_ctl_pipe[i];
      end
   end

   logic [NUM_CMAC-1:0]        axis_app_igr_tvalid;
   logic [NUM_CMAC-1:0]        axis_app_igr_tready;
   logic [NUM_CMAC-1:0][511:0] axis_app_igr_tdata;
   logic [NUM_CMAC-1:0][63:0]  axis_app_igr_tkeep;
   logic [NUM_CMAC-1:0]        axis_app_igr_tlast;
   logic [NUM_CMAC-1:0][1:0]   axis_app_igr_tid;
   logic [NUM_CMAC-1:0][1:0]   axis_app_igr_tdest;
   logic [NUM_CMAC-1:0][15:0]  axis_app_igr_tuser_pid;

   logic [NUM_CMAC-1:0]        axis_app_egr_tvalid;
   logic [NUM_CMAC-1:0]        axis_app_egr_tready;
   logic [NUM_CMAC-1:0][511:0] axis_app_egr_tdata;
   logic [NUM_CMAC-1:0][63:0]  axis_app_egr_tkeep;
   logic [NUM_CMAC-1:0]        axis_app_egr_tlast;
   logic [NUM_CMAC-1:0][1:0]   axis_app_egr_tid;
   logic [NUM_CMAC-1:0][2:0]   axis_app_egr_tdest;
   logic [NUM_CMAC-1:0][15:0]  axis_app_egr_tuser_pid;
   logic [NUM_CMAC-1:0]        axis_app_egr_tuser_rss_enable;
   logic [NUM_CMAC-1:0][11:0]  axis_app_egr_tuser_rss_entropy;

   generate
       for (genvar j = 0; j < NUM_CMAC; j += 1) begin : g__app_igr_egr
           assign axis_app_igr_tvalid[j]    = axis_to_app[j].tvalid;
           assign axis_to_app[j].tready     = axis_app_igr_tready[j];
           assign axis_app_igr_tdata[j]     = axis_to_app[j].tdata;
           assign axis_app_igr_tkeep[j]     = axis_to_app[j].tkeep;
           assign axis_app_igr_tlast[j]     = axis_to_app[j].tlast;
           assign axis_app_igr_tid[j]       = axis_to_app[j].tid;
           assign axis_app_igr_tdest[j]     = axis_to_app[j].tdest;
           assign axis_app_igr_tuser_pid[j] = axis_to_app_tuser[j].pid;

           assign axis_from_app[j].aclk                = core_clk;
           assign axis_from_app[j].aresetn             = core_rstn;
           assign axis_from_app[j].tvalid              = axis_app_egr_tvalid[j];
           assign axis_app_egr_tready[j]               = axis_from_app[j].tready;
           assign axis_from_app[j].tdata               = axis_app_egr_tdata[j];
           assign axis_from_app[j].tkeep               = axis_app_egr_tkeep[j];
           assign axis_from_app[j].tlast               = axis_app_egr_tlast[j];
           assign axis_from_app[j].tid                 = axis_app_egr_tid[j];
           assign axis_from_app[j].tdest               = axis_app_egr_tdest[j];
           assign axis_from_app_tuser[j].pid           = axis_app_egr_tuser_pid[j];
           assign axis_from_app_tuser[j].rss_enable    = axis_app_egr_tuser_rss_enable[j];
           assign axis_from_app_tuser[j].rss_entropy   = axis_app_egr_tuser_rss_entropy[j];
           assign axis_from_app_tuser[j].hdr_tlast     = '0;
       end : g__app_igr_egr
   endgenerate

//   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
//                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_h2c [HOST_NUM_IFS][NUM_CMAC] ();

   tuser_smartnic_meta_t axis_h2c_tuser [HOST_NUM_IFS][NUM_CMAC];
   assign axis_h2c_tuser[0][0] = axis_h2c[0][0].tuser;
   assign axis_h2c_tuser[0][1] = axis_h2c[0][1].tuser;

   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_h2c_tvalid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_h2c_tready;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][511:0] axis_h2c_tdata;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][63:0]  axis_h2c_tkeep;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_h2c_tlast;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][1:0]   axis_h2c_tid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][1:0]   axis_h2c_tdest;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][15:0]  axis_h2c_tuser_pid;

//   axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
//                 .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))         axis_c2h [HOST_NUM_IFS][NUM_CMAC] ();

   tuser_smartnic_meta_t axis_c2h_tuser [HOST_NUM_IFS][NUM_CMAC];
   assign axis_c2h[0][0].tuser = axis_c2h_tuser[0][0];
   assign axis_c2h[0][1].tuser = axis_c2h_tuser[0][1];

   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tvalid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tready;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][511:0] axis_c2h_tdata;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][63:0]  axis_c2h_tkeep;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tlast;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][1:0]   axis_c2h_tid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][2:0]   axis_c2h_tdest;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][15:0]  axis_c2h_tuser_pid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tuser_trunc_enable;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][15:0]  axis_c2h_tuser_trunc_length;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tuser_rss_enable;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][11:0]  axis_c2h_tuser_rss_entropy;

   generate
       for (genvar i = 0; i < HOST_NUM_IFS; i += 1) begin : g__h2c_c2h
           for (genvar j = 0; j < NUM_CMAC; j += 1) begin : g__cmac_idx
               assign axis_h2c_tvalid[i][j]    = axis_h2c[i][j].tvalid;
               assign axis_h2c[i][j].tready    = axis_h2c_tready[i][j];
               assign axis_h2c_tdata[i][j]     = axis_h2c[i][j].tdata;
               assign axis_h2c_tkeep[i][j]     = axis_h2c[i][j].tkeep;
               assign axis_h2c_tlast[i][j]     = axis_h2c[i][j].tlast;
               assign axis_h2c_tid[i][j]       = axis_h2c[i][j].tid;
               assign axis_h2c_tdest[i][j]     = axis_h2c[i][j].tdest;
               assign axis_h2c_tuser_pid[i][j] = axis_h2c_tuser[i][j].pid;

               axi4s_intf_tx_term  axi4s_intf_tx_term_inst  (.axi4s_if(axis_h2c[i][j]));

               assign axis_c2h[i][j].aclk                = core_clk;
               assign axis_c2h[i][j].aresetn             = core_rstn;
               assign axis_c2h[i][j].tvalid              = axis_c2h_tvalid[i][j];
               assign axis_c2h_tready[i][j]              = axis_c2h[i][j].tready;
               assign axis_c2h[i][j].tdata               = axis_c2h_tdata[i][j];
               assign axis_c2h[i][j].tkeep               = axis_c2h_tkeep[i][j];
               assign axis_c2h[i][j].tlast               = axis_c2h_tlast[i][j];
               assign axis_c2h[i][j].tid                 = axis_c2h_tid[i][j];
               assign axis_c2h[i][j].tdest               = axis_c2h_tdest[i][j];
               assign axis_c2h_tuser[i][j].pid           = axis_c2h_tuser_pid[i][j];
               assign axis_c2h_tuser[i][j].trunc_enable  = axis_c2h_tuser_trunc_enable[i][j];
               assign axis_c2h_tuser[i][j].trunc_length  = axis_c2h_tuser_trunc_length[i][j];
               assign axis_c2h_tuser[i][j].rss_enable    = axis_c2h_tuser_rss_enable[i][j];
               assign axis_c2h_tuser[i][j].rss_entropy   = axis_c2h_tuser_rss_entropy[i][j];
               assign axis_c2h_tuser[i][j].hdr_tlast     = '0;

               axi4s_intf_rx_sink  axi4s_intf_rx_sink_inst  (.axi4s_if(axis_c2h[i][j]));
           end : g__cmac_idx
       end : g__h2c_c2h
   endgenerate


   // Provide dedicated AXI-L interfaces for app and p4 control
   smartnic_to_app_decoder smartnic_to_app_decoder_inst (
       .axil_if                  (axil_to_app_decoder),
       .smartnic_app_axil_if     (axil_to_app),
       .smartnic_p4_axil_if      (axil_to_p4)
   );

   smartnic_app smartnic_app
   (
    .core_clk            (core_clk),
    .core_rstn           (core_rstn),
    .axil_aclk           (axil_aclk),
    .timestamp           (timestamp),
    // P4 AXI-L control interface
    .axil_aresetn        (axil_to_p4.aresetn),
    .axil_awvalid        (axil_to_p4.awvalid),
    .axil_awready        (axil_to_p4.awready),
    .axil_awaddr         (axil_to_p4.awaddr),
    .axil_awprot         (axil_to_p4.awprot),
    .axil_wvalid         (axil_to_p4.wvalid),
    .axil_wready         (axil_to_p4.wready),
    .axil_wdata          (axil_to_p4.wdata),
    .axil_wstrb          (axil_to_p4.wstrb),
    .axil_bvalid         (axil_to_p4.bvalid),
    .axil_bready         (axil_to_p4.bready),
    .axil_bresp          (axil_to_p4.bresp),
    .axil_arvalid        (axil_to_p4.arvalid),
    .axil_arready        (axil_to_p4.arready),
    .axil_araddr         (axil_to_p4.araddr),
    .axil_arprot         (axil_to_p4.arprot),
    .axil_rvalid         (axil_to_p4.rvalid),
    .axil_rready         (axil_to_p4.rready),
    .axil_rdata          (axil_to_p4.rdata),
    .axil_rresp          (axil_to_p4.rresp),
    // App AXI-L control interface
    .app_axil_aresetn    (axil_to_app.aresetn),
    .app_axil_awvalid    (axil_to_app.awvalid),
    .app_axil_awready    (axil_to_app.awready),
    .app_axil_awaddr     (axil_to_app.awaddr),
    .app_axil_awprot     (axil_to_app.awprot),
    .app_axil_wvalid     (axil_to_app.wvalid),
    .app_axil_wready     (axil_to_app.wready),
    .app_axil_wdata      (axil_to_app.wdata),
    .app_axil_wstrb      (axil_to_app.wstrb),
    .app_axil_bvalid     (axil_to_app.bvalid),
    .app_axil_bready     (axil_to_app.bready),
    .app_axil_bresp      (axil_to_app.bresp),
    .app_axil_arvalid    (axil_to_app.arvalid),
    .app_axil_arready    (axil_to_app.arready),
    .app_axil_araddr     (axil_to_app.araddr),
    .app_axil_arprot     (axil_to_app.arprot),
    .app_axil_rvalid     (axil_to_app.rvalid),
    .app_axil_rready     (axil_to_app.rready),
    .app_axil_rdata      (axil_to_app.rdata),
    .app_axil_rresp      (axil_to_app.rresp),
    // AXI-S app_igr interface
    .axis_app_igr_tvalid ( axis_app_igr_tvalid ),
    .axis_app_igr_tready ( axis_app_igr_tready ),
    .axis_app_igr_tdata  ( axis_app_igr_tdata ),
    .axis_app_igr_tkeep  ( axis_app_igr_tkeep ),
    .axis_app_igr_tlast  ( axis_app_igr_tlast ),
    .axis_app_igr_tid    ( axis_app_igr_tid ),
    .axis_app_igr_tdest  ( axis_app_igr_tdest ),
    .axis_app_igr_tuser_pid ( axis_app_igr_tuser_pid ),
    // AXI-S app_egr interface
    .axis_app_egr_tvalid ( axis_app_egr_tvalid ),
    .axis_app_egr_tready ( axis_app_egr_tready ),
    .axis_app_egr_tdata  ( axis_app_egr_tdata ),
    .axis_app_egr_tkeep  ( axis_app_egr_tkeep ),
    .axis_app_egr_tlast  ( axis_app_egr_tlast ),
    .axis_app_egr_tid    ( axis_app_egr_tid ),
    .axis_app_egr_tdest  ( axis_app_egr_tdest ),
    .axis_app_egr_tuser_pid ( axis_app_egr_tuser_pid ),
    .axis_app_egr_tuser_rss_enable  ( axis_app_egr_tuser_rss_enable ),
    .axis_app_egr_tuser_rss_entropy ( axis_app_egr_tuser_rss_entropy ),
    // AXI-S c2h interface
    .axis_h2c_tvalid     ( axis_h2c_tvalid ),
    .axis_h2c_tready     ( axis_h2c_tready ),
    .axis_h2c_tdata      ( axis_h2c_tdata ),
    .axis_h2c_tkeep      ( axis_h2c_tkeep ),
    .axis_h2c_tlast      ( axis_h2c_tlast ),
    .axis_h2c_tid        ( axis_h2c_tid ),
    .axis_h2c_tdest      ( axis_h2c_tdest ),
    .axis_h2c_tuser_pid  ( axis_h2c_tuser_pid ),
    // AXI-S h2c interface 
    .axis_c2h_tvalid     ( axis_c2h_tvalid ),
    .axis_c2h_tready     ( axis_c2h_tready ),
    .axis_c2h_tdata      ( axis_c2h_tdata ),
    .axis_c2h_tkeep      ( axis_c2h_tkeep ),
    .axis_c2h_tlast      ( axis_c2h_tlast ),
    .axis_c2h_tid        ( axis_c2h_tid ),
    .axis_c2h_tdest      ( axis_c2h_tdest ),
    .axis_c2h_tuser_pid  ( axis_c2h_tuser_pid ),
    .axis_c2h_tuser_rss_enable  ( axis_c2h_tuser_rss_enable ),
    .axis_c2h_tuser_rss_entropy ( axis_c2h_tuser_rss_entropy ),
    // egress flow control interface
    .egr_flow_ctl            ( egr_flow_ctl_pipe[0] ),
    // AXI3 interfaces to HBM
    // (synchronous to core clock domain)
    .axi_to_hbm_aclk     ( axi_app_to_hbm_aclk    ),
    .axi_to_hbm_aresetn  ( axi_app_to_hbm_aresetn ),
    .axi_to_hbm_awid     ( axi_app_to_hbm_awid    ),
    .axi_to_hbm_awaddr   ( axi_app_to_hbm_awaddr  ),
    .axi_to_hbm_awlen    ( axi_app_to_hbm_awlen   ),
    .axi_to_hbm_awsize   ( axi_app_to_hbm_awsize  ),
    .axi_to_hbm_awburst  ( axi_app_to_hbm_awburst ),
    .axi_to_hbm_awlock   ( axi_app_to_hbm_awlock  ),
    .axi_to_hbm_awcache  ( axi_app_to_hbm_awcache ),
    .axi_to_hbm_awprot   ( axi_app_to_hbm_awprot  ),
    .axi_to_hbm_awqos    ( axi_app_to_hbm_awqos   ),
    .axi_to_hbm_awregion ( axi_app_to_hbm_awregion),
    .axi_to_hbm_awvalid  ( axi_app_to_hbm_awvalid ),
    .axi_to_hbm_awready  ( axi_app_to_hbm_awready ),
    .axi_to_hbm_wid      ( axi_app_to_hbm_wid     ),
    .axi_to_hbm_wdata    ( axi_app_to_hbm_wdata   ),
    .axi_to_hbm_wstrb    ( axi_app_to_hbm_wstrb   ),
    .axi_to_hbm_wlast    ( axi_app_to_hbm_wlast   ),
    .axi_to_hbm_wvalid   ( axi_app_to_hbm_wvalid  ),
    .axi_to_hbm_wready   ( axi_app_to_hbm_wready  ),
    .axi_to_hbm_bid      ( axi_app_to_hbm_bid     ),
    .axi_to_hbm_bresp    ( axi_app_to_hbm_bresp   ),
    .axi_to_hbm_bvalid   ( axi_app_to_hbm_bvalid  ),
    .axi_to_hbm_bready   ( axi_app_to_hbm_bready  ),
    .axi_to_hbm_arid     ( axi_app_to_hbm_arid    ),
    .axi_to_hbm_araddr   ( axi_app_to_hbm_araddr  ),
    .axi_to_hbm_arlen    ( axi_app_to_hbm_arlen   ),
    .axi_to_hbm_arsize   ( axi_app_to_hbm_arsize  ),
    .axi_to_hbm_arburst  ( axi_app_to_hbm_arburst ),
    .axi_to_hbm_arlock   ( axi_app_to_hbm_arlock  ),
    .axi_to_hbm_arcache  ( axi_app_to_hbm_arcache ),
    .axi_to_hbm_arprot   ( axi_app_to_hbm_arprot  ),
    .axi_to_hbm_arqos    ( axi_app_to_hbm_arqos   ),
    .axi_to_hbm_arregion ( axi_app_to_hbm_arregion),
    .axi_to_hbm_arvalid  ( axi_app_to_hbm_arvalid ),
    .axi_to_hbm_arready  ( axi_app_to_hbm_arready ),
    .axi_to_hbm_rid      ( axi_app_to_hbm_rid     ),
    .axi_to_hbm_rdata    ( axi_app_to_hbm_rdata   ),
    .axi_to_hbm_rresp    ( axi_app_to_hbm_rresp   ),
    .axi_to_hbm_rlast    ( axi_app_to_hbm_rlast   ),
    .axi_to_hbm_rvalid   ( axi_app_to_hbm_rvalid  ),
    .axi_to_hbm_rready   ( axi_app_to_hbm_rready  )
   );

   generate
       for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__probe
           axi4s_probe axis_probe_app_to_core (
              .axi4l_if  (axil_to_app_to_core[i]),
              .axi4s_if  (axis_app_to_core[i])
           );

           axi4s_probe axis_probe_core_to_app (
              .axi4l_if  (axil_to_core_to_app[i]),
              .axi4s_if  (axis_core_to_app[i])
           );
       end : g__probe
   endgenerate

endmodule: smartnic
