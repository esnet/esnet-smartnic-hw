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

import smartnic_322mhz_reg_pkg::*;
import smartnic_322mhz_pkg::*;

module smartnic_322mhz #(
  parameter int NUM_CMAC = 2,
  parameter int MAX_PKT_LEN = 9100
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

  input                       axil_aclk,
  input [NUM_CMAC-1:0]        cmac_clk
);
   import axi4s_pkg::*;

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
      .hbm_left_axil_if                (axil_to_hbm_0),
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

   // ----------------------------------------------------------------
   //  HBM
   // ----------------------------------------------------------------
   // 'Left' stack (4GB)
   smartnic_322mhz_hbm_left smartnic_322mhz_hbm_0 (
     .clk         (core_clk),
     .rstn        (core_rstn),
     .hbm_ref_clk (hbm_ref_clk),
     .clk_100mhz  (clk_100mhz),
     .axil_if     (axil_to_hbm_0)
   );

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
   // fifos to go from independent CMAC clock domains to a single
   // core clock domain
   // ----------------------------------------------------------------

   (* mark_debug="true" *)  logic [511:0]  tdata  [NUM_CMAC];
   (* mark_debug="true" *)  logic          tvalid [NUM_CMAC];
   (* mark_debug="true" *)  logic          tlast  [NUM_CMAC];
   (* mark_debug="true" *)  logic [63:0]   tkeep  [NUM_CMAC];
   (* mark_debug="true" *)  logic          tready [NUM_CMAC];

   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__fifo

      //------------------------ from cmac to core --------------
      port_t s_axis_cmac_rx_322mhz_tid [NUM_CMAC];
      assign s_axis_cmac_rx_322mhz_tid[i] = i;

      assign tdata[i]  = s_axis_cmac_rx_322mhz_tdata[`getvec(512, i)];
      assign tvalid[i] = s_axis_cmac_rx_322mhz_tvalid[i];
      assign tlast[i]  = s_axis_cmac_rx_322mhz_tlast[i];
      assign tkeep[i]  = {'0, s_axis_cmac_rx_322mhz_tuser_err[i]};
      assign tready[i] = s_axis_cmac_rx_322mhz_tready[i];

      ila_axi4s ila_axi4s (
         .clk    (cmac_clk[i]),
         .probe0 (tdata[i]),
         .probe1 (tvalid[i]),
         .probe2 (tlast[i]),
         .probe3 (tkeep[i]),
         .probe4 (tready[i])
      );

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

      axi4s_probe #( .MODE(ERRORS) ) axi4s_err_from_cmac (
            .axi4l_if  (axil_to_err_from_cmac[i]),
            .axi4s_if  (axis_from_cmac[i])
         );

      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (128),
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
        .FIFO_DEPTH     (128),
        .MAX_PKT_LEN    (MAX_PKT_LEN)
      ) fifo_to_cmac (
        .axi4s_in       (axis_core_to_cmac[i]),
        .clk_out        (cmac_clk[i]),
        .axi4s_out      (axis_to_cmac[i]),
        .axil_to_probe  (axil_to_probe_to_cmac[i]),
        .axil_to_ovfl   (axil_to_ovfl_to_cmac[i]),
        .axil_if        (axil_to_fifo_to_cmac[i])
      );

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
           .FIFO_DEPTH     (128),
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
           .FIFO_DEPTH     (128),
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
    .axis_to_host_tuser  ( axis_from_app_host_0.tuser )
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
