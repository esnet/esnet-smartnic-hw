// =============================================================================
//  NOTICE: This computer software was prepared by The Regents of the
//  University of California through Lawrence Berkeley National Laboratory
//  and Yatish Kumar  hereinafter the Contractor, under Contract No.
//  DE-AC02-05CH11231 with the Department of Energy (DOE). All rights in the
//  computer software are reserved by DOE on behalf of the United States
//  Government and the Contractor as provided in the Contract. You are
//  authorized to use this computer software for Governmental purposes but it
//  is not to be released or distributed to the public.
//
//  NEITHER THE GOVERNMENT NOR THE CONTRACTOR MAKES ANY WARRANTY, EXPRESS OR
//  IMPLIED, OR ASSUMES ANY LIABILITY FOR THE USE OF THIS SOFTWARE.
//
//  This notice including this sentence must appear on any copies of this
//  computer software.
// =============================================================================

`define getbit(width, index, offset)    ((index)*(width) + (offset))
`define getvec(width, index)            ((index)*(width)) +: (width)

`timescale 1ns/1ps

module smartnic_322mhz
  import smartnic_322mhz_pkg::*;
#(
  parameter int NUM_CMAC = 2,
  parameter int MAX_PKT_LEN = 9100,
`ifdef SIMULATION
  parameter bit INCLUDE_HBM0 = 1'b1,
  parameter bit INCLUDE_HBM1 = 1'b1
`else
  parameter bit INCLUDE_HBM0 = 1'b0, // HBM0 is connected to platform logic
                                     // (it is excluded by default because HBM is not currently used to implement any platform functions)
  parameter bit INCLUDE_HBM1 = smartnic_322mhz_app_pkg::INCLUDE_HBM // Application-specific HBM controller include/exclude
                                     // HBM1 controller is connected to application logic
                                     // (can be excluded for non-HBM applications to optimize resources/complexity)
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

  output               [15:0] div_count,
  output               [15:0] burst_count,

  input                       axil_aclk,
  input                       axis_aclk,
  input [NUM_CMAC-1:0]        cmac_clk
);

   // Imports
   import axi4s_pkg::*;
   import smartnic_322mhz_reg_pkg::*;

   // Signals
   wire                       axil_aresetn;
   wire [NUM_CMAC-1:0]        cmac_rstn;

   wire                       core_rstn;
   wire                       core_clk;

   wire                       clk_100mhz;
   wire                       hbm_ref_clk;


  // Reset is clocked by the 125MHz AXI-Lite clock

  smartnic_322mhz_reset #(
    .NUM_CMAC (NUM_CMAC)
  ) reset_inst (
    .mod_rstn     (mod_rstn),
    .mod_rst_done (mod_rst_done),

    .axil_aresetn (axil_aresetn),
    .cmac_rstn    (cmac_rstn),
    .axil_aclk    (axil_aclk),
    .cmac_clk     (cmac_clk),

    .core_rstn    (core_rstn),
    .core_clk     (core_clk),

    .clk_100mhz   (clk_100mhz),
    .hbm_ref_clk  (hbm_ref_clk)
  );

   // ----------------------------------------------------------------
   //  axil interface instantiation and regmap logic
   // ----------------------------------------------------------------

   axi4l_intf   s_axil_if                   ();
   axi4l_intf   axil_to_regif               ();
   axi4l_intf   axil_to_endian_check        ();
   axi4l_intf   axil_to_hbm_0               ();
   axi4l_intf   axil_to_hbm_1               ();
   axi4l_intf   axil_to_app_decoder__demarc ();
   axi4l_intf   axil_to_app_decoder         ();
   axi4l_intf   axil_to_app                 ();
   axi4l_intf   axil_to_sdnet               ();

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

   axi4l_intf   axil_to_core_to_app                ();
   axi4l_intf   axil_to_app_to_core                ();

   smartnic_322mhz_reg_intf   smartnic_322mhz_regs();


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

   // smartnic_322mhz top-level decoder
   smartnic_322mhz_decoder smartnic_322mhz_axil_decoder_0 (
      .axil_if                         (s_axil_if),
      .regif_axil_if                   (axil_to_regif),
      .endian_check_axil_if            (axil_to_endian_check),
      .probe_from_cmac_0_axil_if       (axil_to_probe_from_cmac[0]),
      .drops_ovfl_from_cmac_0_axil_if  (axil_to_ovfl_from_cmac[0]),
      .drops_err_from_cmac_0_axil_if   (axil_to_err_from_cmac[0]),
      .probe_from_cmac_1_axil_if       (axil_to_probe_from_cmac[1]),
      .drops_ovfl_from_cmac_1_axil_if  (axil_to_ovfl_from_cmac[1]),
      .drops_err_from_cmac_1_axil_if   (axil_to_err_from_cmac[1]),
      .probe_from_host_0_axil_if       (axil_to_probe_from_host[0]),
      .probe_from_host_1_axil_if       (axil_to_probe_from_host[1]),
      .probe_core_to_app_axil_if       (axil_to_core_to_app),
      .probe_app_to_core_axil_if       (axil_to_app_to_core),
      .probe_to_cmac_0_axil_if         (axil_to_probe_to_cmac[0]),
      .drops_ovfl_to_cmac_0_axil_if    (axil_to_ovfl_to_cmac[0]),
      .probe_to_cmac_1_axil_if         (axil_to_probe_to_cmac[1]),
      .drops_ovfl_to_cmac_1_axil_if    (axil_to_ovfl_to_cmac[1]),
      .probe_to_host_0_axil_if         (axil_to_probe_to_host[0]),
      .drops_ovfl_to_host_0_axil_if    (axil_to_ovfl_to_host[0]),
      .probe_to_host_1_axil_if         (axil_to_probe_to_host[1]),
      .drops_ovfl_to_host_1_axil_if    (axil_to_ovfl_to_host[1]),
      .fifo_to_host_0_axil_if          (axil_to_fifo_to_host[0]),
      .hbm_0_axil_if                   (axil_to_hbm_0),
      .hbm_1_axil_if                   (axil_to_hbm_1),
      .smartnic_322mhz_app_axil_if     (axil_to_app_decoder__demarc)
   );

   // AXI-L interface synchronizer
   axi4l_intf axil_to_regif__core_clk ();

   axi4l_intf_cdc axil_to_regif_cdc (
      .axi4l_if_from_controller  ( axil_to_regif ),
      .clk_to_peripheral         ( core_clk ),
      .axi4l_if_to_peripheral    ( axil_to_regif__core_clk )
   );

   // smartnic_322mhz register block
   smartnic_322mhz_reg_blk     smartnic_322mhz_reg_blk_0
   (
    .axil_if    (axil_to_regif__core_clk),
    .reg_blk_if (smartnic_322mhz_regs)
   );

   // Endian check reg block
   reg_endian_check reg_endian_check_0 (
       .axil_if (axil_to_endian_check)
   );

   // Timestamp counter and access logic
   logic [63:0] timestamp;

   smartnic_322mhz_timestamp  smartnic_322mhz_timestamp_0 (
     .clk               (core_clk),
     .rstn              (core_rstn),
     .timestamp         (timestamp),
     .smartnic_322mhz_regs (smartnic_322mhz_regs)
   );

   // Sample and sync outgoing div_count and burst_count register signals.
   sync_bus_sampled #(
      .DATA_T   ( logic [15:0] )
   ) i_sync_bus_sampled__div_count (
      .clk_in   ( core_clk ),
      .rst_in   ( ~core_rstn ),
      .data_in  ( smartnic_322mhz_regs.div_count[15:0] ),
      .clk_out  ( axis_aclk ),
      .rst_out  ( 1'b0 ),
      .data_out ( div_count )
   );

   sync_bus_sampled #(
      .DATA_T   ( logic [15:0] )
   ) i_sync_bus_sampled__burst_count (
      .clk_in   ( core_clk ),
      .rst_in   ( ~core_rstn ),
      .data_in  ( smartnic_322mhz_regs.burst_count[15:0] ),
      .clk_out  ( axis_aclk ),
      .rst_out  ( 1'b0 ),
      .data_out ( burst_count )
   );


   // ----------------------------------------------------------------
   //  HBM0 (Left stack, 4GB)
   //
   //  (Optionally) used by platform
   // ----------------------------------------------------------------
   generate
       if (INCLUDE_HBM0) begin : g__hbm_0
           // Include memory controller for 'Left' HBM stack (4GB)

           // (Local) interfaces
           axi3_intf   #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_if[16] ();

           // HBM controller
           smartnic_322mhz_hbm #(
             .HBM_STACK   (0)
           ) smartnic_322mhz_hbm_0 (
             .clk         (core_clk),
             .rstn        (core_rstn),
             .hbm_ref_clk (hbm_ref_clk),
             .clk_100mhz  (clk_100mhz),
             .axil_if     (axil_to_hbm_0),
             .axi_if      (axi_if)
           );

           for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
               // For now, terminate HBM1 memory interfaces (unused)
               axi3_intf_controller_term axi_to_hbm_0_term (.axi3_if(axi_if[g_hbm_if]));
           end : g__hbm_if
       end : g__hbm_0
       else begin : g__no_hbm_0
           // No HBM 0 controller

           // Terminate AXI-L interface
           axi4l_intf_peripheral_term i_axi4l_peripheral_term (.axi4l_if (axil_to_hbm_0));
       end : g__no_hbm_0
   endgenerate

   // ----------------------------------------------------------------
   //  HBM1 (Right stack, 4GB)
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
       if (INCLUDE_HBM1) begin : g__hbm_1
           // Include memory controller for 'Right' HBM stack (4GB)

           // (Local) interfaces
           axi3_intf   #(.DATA_BYTE_WID(32), .ADDR_WID(33), .ID_T(logic[5:0])) axi_if[16] ();

           // HBM controller
           smartnic_322mhz_hbm #(
             .HBM_STACK   (1)
           ) smartnic_322mhz_hbm_1 (
             .clk         (core_clk),
             .rstn        (core_rstn),
             .hbm_ref_clk (hbm_ref_clk),
             .clk_100mhz  (clk_100mhz),
             .axil_if     (axil_to_hbm_1),
             .axi_if      (axi_if)
           );

           //  Map HBM1 memory interface signals into interface representation
           for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
               axi3_intf_from_signals #(
                   .DATA_BYTE_WID(32),
                   .ADDR_WID     (33),
                   .ID_T         (logic[5:0])
               ) axi3_intf_from_signals__hbm (
                   .aclk     ( axi_app_to_hbm_aclk    [g_hbm_if] ),
                   .aresetn  ( axi_app_to_hbm_aresetn [g_hbm_if] ),
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
                   .axi3_if  ( axi_if[g_hbm_if] )
               );

               assign axi_app_to_hbm_aclk[g_hbm_if] = core_clk;
               assign axi_app_to_hbm_aresetn[g_hbm_if] = core_rstn;

               assign axi_app_to_hbm_buser[g_hbm_if] = '0;
               assign axi_app_to_hbm_ruser[g_hbm_if] = '0;
            end : g__hbm_if
       end : g__hbm_1
       else begin : g__no_hbm_1
           // No HBM 1 controller

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
           axi4l_intf_peripheral_term i_axi4l_peripheral_term (.axi4l_if (axil_to_hbm_1));
       end : g__no_hbm_1
   endgenerate

   // ----------------------------------------------------------------
   //  axi4s interface instantiations
   // ----------------------------------------------------------------

   axi4s_intf  #(.MODE(IGNORES_TREADY), .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t),
                 .TUSER_T(bit), .TUSER_MODE(PKT_ERROR))                axis_from_cmac    [NUM_CMAC] ();

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_from_host    [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_to_cmac      [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_to_host      [NUM_CMAC] ();

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_cmac_to_core [NUM_CMAC] ();
   axi4s_intf  #(.MODE(IGNORES_TREADY), .DATA_BYTE_WID(64),
                 .TID_T(port_t), .TDEST_T(port_t))                     axis_core_to_cmac [NUM_CMAC] ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_core_to_host_0 ();
   axi4s_intf  #(.MODE(IGNORES_TREADY), .DATA_BYTE_WID(64),
                 .TID_T(port_t), .TDEST_T(port_t))                     axis_core_to_host [NUM_CMAC] ();

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_host_to_core [NUM_CMAC] ();

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_core_to_app ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_app_to_core ();

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_to_app ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_from_app ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_to_app_host_0 ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_from_app_host_0 ();

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_to_app__demarc ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_from_app__demarc ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_to_app_host_0__demarc ();
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)) axis_from_app_host_0__demarc ();

   // ----------------------------------------------------------------
   //  HBM AXI-3 signals/interfaces
   // ----------------------------------------------------------------

   // ----------------------------------------------------------------
   // fifos to go from independent CMAC clock domains to a single
   // core clock domain
   // ----------------------------------------------------------------

   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__fifo

      //------------------------ from cmac to core --------------
      port_t s_axis_cmac_rx_322mhz_tid [NUM_CMAC];
      assign s_axis_cmac_rx_322mhz_tid[i] = i;

      axi4s_intf_from_signals #(
        .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)
      ) axis_from_cmac_from_signals (
        .aclk     (cmac_clk[i]),
        .aresetn  (cmac_rstn[i]),
        .tvalid   (s_axis_cmac_rx_322mhz_tvalid[i]),
        .tready   (s_axis_cmac_rx_322mhz_tready[i]),               // NOTE: tready signal is ignored by open-nic-shell.
        .tdata    (s_axis_cmac_rx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (s_axis_cmac_rx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (s_axis_cmac_rx_322mhz_tlast[i]),
        .tid      (s_axis_cmac_rx_322mhz_tid[i]),
        .tdest    (s_axis_cmac_rx_322mhz_tdest[`getvec(2, i)]),
        .tuser    (s_axis_cmac_rx_322mhz_tuser_err[i]),

        .axi4s_if (axis_from_cmac[i])
      );

      // axi4s_ila axi4s_ila_0 (.axis_in(axis_from_cmac[i]));

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
        .axi4s_out      (axis_to_cmac[i]),
        .axil_to_probe  (axil_to_probe_to_cmac[i]),
        .axil_to_ovfl   (axil_to_ovfl_to_cmac[i]),
        .axil_if        (axil_to_fifo_to_cmac[i])
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
      if (i==0) begin : g__fifo_host_0
         axi4s_pkt_fifo_async #(
           .FIFO_DEPTH     (1024),
           .MAX_PKT_LEN    (MAX_PKT_LEN)
         ) fifo_to_host (
           .axi4s_in       (axis_core_to_host_0),
           .clk_out        (cmac_clk[i]),
           .axi4s_out      (axis_to_host[i]),
           .axil_to_probe  (axil_to_probe_to_host[i]),
           .axil_to_ovfl   (axil_to_ovfl_to_host[i]),
           .axil_if        (axil_to_fifo_to_host[i])
         );
      end : g__fifo_host_0
      else begin : g__fifo_host
         axi4s_pkt_fifo_async #(
           .FIFO_DEPTH     (1024),
           .MAX_PKT_LEN    (MAX_PKT_LEN)
         ) fifo_to_host (
           .axi4s_in       (axis_core_to_host[i]),
           .clk_out        (cmac_clk[i]),
           .axi4s_out      (axis_to_host[i]),
           .axil_to_probe  (axil_to_probe_to_host[i]),
           .axil_to_ovfl   (axil_to_ovfl_to_host[i]),
           .axil_if        (axil_to_fifo_to_host[i])
         );

         // Terminate unused AXI-L interface
         axi4l_intf_controller_term axi4l_fifo_to_host_term (.axi4l_if (axil_to_fifo_to_host[i]));
      end : g__fifo_host


      axi4s_intf_to_signals #(
        .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)
      ) axis_to_host_to_signals (
        .aclk     (),
        .aresetn  (),
        .tvalid   (m_axis_adpt_rx_322mhz_tvalid[i]),
        .tready   (m_axis_adpt_rx_322mhz_tready[i]),   // tied high in opennic box322mhz instantiation.
        .tdata    (m_axis_adpt_rx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (m_axis_adpt_rx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (m_axis_adpt_rx_322mhz_tlast[i]),
        .tid      (),
        .tdest    (m_axis_adpt_rx_322mhz_tdest[`getvec(2, i)]),
        .tuser    (m_axis_adpt_rx_322mhz_tuser_err[i]),

        .axi4s_if (axis_to_host[i])
      );


      //------------------------ from host to core --------------
      port_t s_axis_adpt_tx_322mhz_tid [NUM_CMAC];
      assign s_axis_adpt_tx_322mhz_tid[i] = NUM_CMAC+i;

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
        .tid      (s_axis_adpt_tx_322mhz_tid[i]),
        .tdest    (s_axis_adpt_tx_322mhz_tdest[`getvec(2, i)]),
        .tuser    (s_axis_adpt_tx_322mhz_tuser_err[i]),       // this is a deadend for now. No use in smartnic_322mhz

        .axi4s_if (axis_from_host[i])
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


   logic axis_core_to_app_tvalid;

   axis_switch_ingress axis_switch_ingress
   (
    .aclk    ( core_clk ),
    .aresetn ( core_rstn ),
    .s_req_suppress ( 3'h0 ),

    .m_axis_tdata  ( axis_core_to_app.tdata ),
    .m_axis_tkeep  ( axis_core_to_app.tkeep ),
    .m_axis_tlast  ( axis_core_to_app.tlast ),
    .m_axis_tid    ( axis_core_to_app.tid ),
    .m_axis_tdest  ( axis_core_to_app.tdest ),
    .m_axis_tready ( axis_core_to_app.tready && !smartnic_322mhz_regs.port_config.app_tpause),
    .m_axis_tvalid ( axis_core_to_app_tvalid ),

    .s_axis_tdata  ({ axis_host_to_core[1].tdata  , axis_cmac_to_core[1].tdata  , axis_cmac_to_core[0].tdata  }),
    .s_axis_tkeep  ({ axis_host_to_core[1].tkeep  , axis_cmac_to_core[1].tkeep  , axis_cmac_to_core[0].tkeep  }),
    .s_axis_tlast  ({ axis_host_to_core[1].tlast  , axis_cmac_to_core[1].tlast  , axis_cmac_to_core[0].tlast  }),
    .s_axis_tid    ({ axis_host_to_core[1].tid    , axis_cmac_to_core[1].tid    , axis_cmac_to_core[0].tid    }),
    .s_axis_tdest  ({ axis_host_to_core[1].tdest  , axis_cmac_to_core[1].tdest  , axis_cmac_to_core[0].tdest  }),
    .s_axis_tready ({ axis_host_to_core[1].tready , axis_cmac_to_core[1].tready , axis_cmac_to_core[0].tready }),
    .s_axis_tvalid ({ axis_host_to_core[1].tvalid , axis_cmac_to_core[1].tvalid , axis_cmac_to_core[0].tvalid }),

    .s_decode_err  ()
   );

   assign axis_core_to_app.aclk = core_clk;
   assign axis_core_to_app.aresetn = core_rstn;
   assign axis_core_to_app.tvalid = axis_core_to_app_tvalid && !smartnic_322mhz_regs.port_config.app_tpause;

   // smartnic_322mhz_app core bypass logic
   axi4s_intf_bypass_mux #(
     .PIPE_STAGES(1), .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)
   ) bypass_mux_to_switch (
     .axi4s_in         (axis_core_to_app),
     .axi4s_to_block   (axis_to_app__demarc),
     .axi4s_from_block (axis_from_app__demarc),
     .axi4s_out        (axis_app_to_core),
     .bypass           (smartnic_322mhz_regs.port_config.app_bypass)
   );

   axi4s_intf_bypass_mux #(
     .PIPE_STAGES(1), .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t)
   ) bypass_mux_to_host_0 (
     .axi4s_in         (axis_host_to_core[0]),
     .axi4s_to_block   (axis_to_app_host_0__demarc),
     .axi4s_from_block (axis_from_app_host_0__demarc),
     .axi4s_out        (axis_core_to_host_0),
     .bypass           (smartnic_322mhz_regs.port_config.app_bypass)
   );


   // output port configuration logic
   logic [1:0] egress_dest;

   always_comb begin
      egress_dest = 0;

      if (smartnic_322mhz_regs.port_config.output_enable == PORT_CONFIG_OUTPUT_ENABLE_PORT0)      egress_dest = 0;
      if (smartnic_322mhz_regs.port_config.output_enable == PORT_CONFIG_OUTPUT_ENABLE_PORT1)      egress_dest = 1;
      if (smartnic_322mhz_regs.port_config.output_enable == PORT_CONFIG_OUTPUT_ENABLE_C2H)        egress_dest = 3;
      if (smartnic_322mhz_regs.port_config.output_enable == PORT_CONFIG_OUTPUT_ENABLE_USE_META)
          egress_dest = axis_app_to_core.tdest;
   end


   axis_switch_egress axis_switch_egress
   (
    .aclk    ( core_clk ),
    .aresetn ( core_rstn ),

    .m_axis_tdata  ({ axis_core_to_host[1].tdata  , axis_core_to_cmac[1].tdata  , axis_core_to_cmac[0].tdata }),
    .m_axis_tkeep  ({ axis_core_to_host[1].tkeep  , axis_core_to_cmac[1].tkeep  , axis_core_to_cmac[0].tkeep  }),
    .m_axis_tlast  ({ axis_core_to_host[1].tlast  , axis_core_to_cmac[1].tlast  , axis_core_to_cmac[0].tlast  }),
    .m_axis_tid    ({ axis_core_to_host[1].tid    , axis_core_to_cmac[1].tid    , axis_core_to_cmac[0].tid    }),
    .m_axis_tdest  ({ axis_core_to_host[1].tdest  , axis_core_to_cmac[1].tdest  , axis_core_to_cmac[0].tdest  }),
    .m_axis_tready ({ axis_core_to_host[1].tready , axis_core_to_cmac[1].tready , axis_core_to_cmac[0].tready }),
    .m_axis_tvalid ({ axis_core_to_host[1].tvalid , axis_core_to_cmac[1].tvalid , axis_core_to_cmac[0].tvalid }),

    .s_axis_tdata  ( axis_app_to_core.tdata ),
    .s_axis_tdest  ( egress_dest ),
    .s_axis_tkeep  ( axis_app_to_core.tkeep ),
    .s_axis_tlast  ( axis_app_to_core.tlast ),
    .s_axis_tid    ( axis_app_to_core.tid ),
    .s_axis_tready ( axis_app_to_core.tready ),
    .s_axis_tvalid ( axis_app_to_core.tvalid ),

    .s_decode_err ()
   );

   assign axis_core_to_cmac[0].aclk = core_clk;
   assign axis_core_to_cmac[0].aresetn = core_rstn;
   assign axis_core_to_cmac[1].aclk = core_clk;
   assign axis_core_to_cmac[1].aresetn = core_rstn;
   assign axis_core_to_host[1].aclk = core_clk;
   assign axis_core_to_host[1].aresetn = core_rstn;

   // ----------------------------------------------------------------
   // AXI register slices
   // ----------------------------------------------------------------
   // - demarcate physical boundary between SmartNIC platform and application
   //   and support efficient pipelining between SLRs

   // AXI-L interface
   axi4l_reg_slice #(
       .CONFIG (axi4l_pkg::REG_SLICE_SLR_CROSSING)
   ) i_axi4l_reg_slice__core_to_app (
       .axi4l_if_from_controller ( axil_to_app_decoder__demarc ),
       .axi4l_if_to_peripheral   ( axil_to_app_decoder )
   );

   // AXI-S interfaces
   axi4s_reg_slice #(
       .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .CONFIG(axi4s_pkg::REG_SLICE_SLR_CROSSING)
   ) i_axi4s_reg_slice__core_to_app (
       .axi4s_from_tx (axis_to_app__demarc),
       .axi4s_to_rx   (axis_to_app)
   );

   axi4s_reg_slice #(
       .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .CONFIG(axi4s_pkg::REG_SLICE_SLR_CROSSING)
   ) i_axi4s_reg_slice__host_to_core (
       .axi4s_from_tx (axis_to_app_host_0__demarc),
       .axi4s_to_rx   (axis_to_app_host_0)
   );

   axi4s_reg_slice #(
       .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .CONFIG(axi4s_pkg::REG_SLICE_SLR_CROSSING)
   ) i_axi4s_reg_slice__app_to_core (
       .axi4s_from_tx (axis_from_app),
       .axi4s_to_rx   (axis_from_app__demarc)
   );

   axi4s_reg_slice #(
       .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .CONFIG(axi4s_pkg::REG_SLICE_SLR_CROSSING)
   ) i_axi4s_reg_slice__app_to_host (
       .axi4s_from_tx (axis_from_app_host_0),
       .axi4s_to_rx   (axis_from_app_host_0__demarc)
   );

   // ----------------------------------------------------------------
   // Application Core
   // ----------------------------------------------------------------
   // Provide dedicated AXI-L interfaces for app and sdnet control
   smartnic_322mhz_app_sdnet_decoder smartnic_322mhz_app_sdnet_decoder (
       .axil_if       (axil_to_app_decoder),
       .sdnet_axil_if (axil_to_sdnet),
       .app_axil_if   (axil_to_app)
   );

   smartnic_322mhz_app smartnic_322mhz_app
   (
    .core_clk     (core_clk),
    .core_rstn    (core_rstn),
    .axil_aclk    (axil_aclk),
    .timestamp    (timestamp),
    // AXI-L control interface
    .axil_aresetn (axil_to_app.aresetn),
    .axil_awvalid (axil_to_app.awvalid),
    .axil_awready (axil_to_app.awready),
    .axil_awaddr  (axil_to_app.awaddr),
    .axil_awprot  (axil_to_app.awprot),
    .axil_wvalid  (axil_to_app.wvalid),
    .axil_wready  (axil_to_app.wready),
    .axil_wdata   (axil_to_app.wdata),
    .axil_wstrb   (axil_to_app.wstrb),
    .axil_bvalid  (axil_to_app.bvalid),
    .axil_bready  (axil_to_app.bready),
    .axil_bresp   (axil_to_app.bresp),
    .axil_arvalid (axil_to_app.arvalid),
    .axil_arready (axil_to_app.arready),
    .axil_araddr  (axil_to_app.araddr),
    .axil_arprot  (axil_to_app.arprot),
    .axil_rvalid  (axil_to_app.rvalid),
    .axil_rready  (axil_to_app.rready),
    .axil_rdata   (axil_to_app.rdata),
    .axil_rresp   (axil_to_app.rresp),
    // (SDNet) AXI-L control interface
    .axil_sdnet_aresetn (axil_to_sdnet.aresetn),
    .axil_sdnet_awvalid (axil_to_sdnet.awvalid),
    .axil_sdnet_awready (axil_to_sdnet.awready),
    .axil_sdnet_awaddr  (axil_to_sdnet.awaddr),
    .axil_sdnet_awprot  (axil_to_sdnet.awprot),
    .axil_sdnet_wvalid  (axil_to_sdnet.wvalid),
    .axil_sdnet_wready  (axil_to_sdnet.wready),
    .axil_sdnet_wdata   (axil_to_sdnet.wdata),
    .axil_sdnet_wstrb   (axil_to_sdnet.wstrb),
    .axil_sdnet_bvalid  (axil_to_sdnet.bvalid),
    .axil_sdnet_bready  (axil_to_sdnet.bready),
    .axil_sdnet_bresp   (axil_to_sdnet.bresp),
    .axil_sdnet_arvalid (axil_to_sdnet.arvalid),
    .axil_sdnet_arready (axil_to_sdnet.arready),
    .axil_sdnet_araddr  (axil_to_sdnet.araddr),
    .axil_sdnet_arprot  (axil_to_sdnet.arprot),
    .axil_sdnet_rvalid  (axil_to_sdnet.rvalid),
    .axil_sdnet_rready  (axil_to_sdnet.rready),
    .axil_sdnet_rdata   (axil_to_sdnet.rdata),
    .axil_sdnet_rresp   (axil_to_sdnet.rresp),
    // AXI-S data interface (from switch, to app)
    .axis_from_switch_tvalid ( axis_to_app.tvalid ),
    .axis_from_switch_tready ( axis_to_app.tready ),
    .axis_from_switch_tdata  ( axis_to_app.tdata ),
    .axis_from_switch_tkeep  ( axis_to_app.tkeep ),
    .axis_from_switch_tlast  ( axis_to_app.tlast ),
    .axis_from_switch_tid    ( axis_to_app.tid ),
    .axis_from_switch_tdest  ( axis_to_app.tdest ),
    .axis_from_switch_tuser  ( axis_to_app.tuser ),
    // AXI-S data interface (from app, to switch)
    .axis_to_switch_tvalid ( axis_from_app.tvalid ),
    .axis_to_switch_tready ( axis_from_app.tready ),
    .axis_to_switch_tdata  ( axis_from_app.tdata ),
    .axis_to_switch_tkeep  ( axis_from_app.tkeep ),
    .axis_to_switch_tlast  ( axis_from_app.tlast ),
    .axis_to_switch_tid    ( axis_from_app.tid ),
    .axis_to_switch_tdest  ( axis_from_app.tdest ),
    .axis_to_switch_tuser  ( axis_from_app.tuser ),
    // AXI-S data interface (from host, to app)
    .axis_from_host_tvalid ( axis_to_app_host_0.tvalid ),
    .axis_from_host_tready ( axis_to_app_host_0.tready ),
    .axis_from_host_tdata  ( axis_to_app_host_0.tdata ),
    .axis_from_host_tkeep  ( axis_to_app_host_0.tkeep ),
    .axis_from_host_tlast  ( axis_to_app_host_0.tlast ),
    .axis_from_host_tid    ( axis_to_app_host_0.tid ),
    .axis_from_host_tdest  ( axis_to_app_host_0.tdest ),
    .axis_from_host_tuser  ( axis_to_app_host_0.tuser ),
    // AXI-S data interface (from app, to host)
    .axis_to_host_tvalid ( axis_from_app_host_0.tvalid ),
    .axis_to_host_tready ( axis_from_app_host_0.tready ),
    .axis_to_host_tdata  ( axis_from_app_host_0.tdata ),
    .axis_to_host_tkeep  ( axis_from_app_host_0.tkeep ),
    .axis_to_host_tlast  ( axis_from_app_host_0.tlast ),
    .axis_to_host_tid    ( axis_from_app_host_0.tid ),
    .axis_to_host_tdest  ( axis_from_app_host_0.tdest ),
    .axis_to_host_tuser  ( axis_from_app_host_0.tuser ),
    // AXI3 interfaces to HBM
    // (synchronous to core clock domain)
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

   // Drive AXI-S clock/reset
   assign axis_from_app.aclk = core_clk;
   assign axis_from_app.aresetn = core_rstn;

   assign axis_from_app_host_0.aclk = core_clk;
   assign axis_from_app_host_0.aresetn = core_rstn;

   axi4s_probe axis_probe_app_to_core (
      .axi4l_if  (axil_to_app_to_core),
      .axi4s_if  (axis_app_to_core)
   );

   axi4s_probe axis_probe_core_to_app (
      .axi4l_if  (axil_to_core_to_app),
      .axi4s_if  (axis_core_to_app)
   );

endmodule: smartnic_322mhz
