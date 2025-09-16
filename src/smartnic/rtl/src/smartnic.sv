`define getbit(width, index, offset)    ((index)*(width) + (offset))
`define getvec(width, index)            ((index)*(width)) +: (width)

module smartnic
#(
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
  input [(16*NUM_CMAC)-1:0]   s_axis_adpt_tx_322mhz_tid,
  input [(4*NUM_CMAC)-1:0]    s_axis_adpt_tx_322mhz_tdest,
  input [NUM_CMAC-1:0]        s_axis_adpt_tx_322mhz_tuser_err,
  output [NUM_CMAC-1:0]       s_axis_adpt_tx_322mhz_tready,

  output [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tvalid,
  output [(512*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tdata,
  output [(64*NUM_CMAC)-1:0]  m_axis_adpt_rx_322mhz_tkeep,
  output [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tlast,
  output [(4*NUM_CMAC)-1:0]   m_axis_adpt_rx_322mhz_tdest,
  output [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tuser_err,
  output [NUM_CMAC-1:0]       m_axis_adpt_rx_322mhz_tuser_rss_enable,
  output [(12*NUM_CMAC)-1:0]  m_axis_adpt_rx_322mhz_tuser_rss_entropy,
  input [NUM_CMAC-1:0]        m_axis_adpt_rx_322mhz_tready,

  output [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tvalid,
  output [(512*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tdata,
  output [(64*NUM_CMAC)-1:0]  m_axis_cmac_tx_322mhz_tkeep,
  output [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tlast,
  output [(4*NUM_CMAC)-1:0]   m_axis_cmac_tx_322mhz_tdest,
  output [NUM_CMAC-1:0]       m_axis_cmac_tx_322mhz_tuser_err,
  input [NUM_CMAC-1:0]        m_axis_cmac_tx_322mhz_tready,

  input [NUM_CMAC-1:0]        s_axis_cmac_rx_322mhz_tvalid,
  input [(512*NUM_CMAC)-1:0]  s_axis_cmac_rx_322mhz_tdata,
  input [(64*NUM_CMAC)-1:0]   s_axis_cmac_rx_322mhz_tkeep,
  input [NUM_CMAC-1:0]        s_axis_cmac_rx_322mhz_tlast,
  input [(4*NUM_CMAC)-1:0]    s_axis_cmac_rx_322mhz_tdest,
  input [NUM_CMAC-1:0]        s_axis_cmac_rx_322mhz_tuser_err,
  output [NUM_CMAC-1:0]       s_axis_cmac_rx_322mhz_tready,

  input                       mod_rstn,
  output                      mod_rst_done,

  input                       axil_aclk,
  input [NUM_CMAC-1:0]        cmac_clk
);

  localparam int HOST_NUM_IFS = 3;

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
   axi4l_intf   axil_to_platform            ();
   axi4l_intf   axil_to_regs                ();
   axi4l_intf   axil_to_endian_check        ();
   axi4l_intf   axil_to_app__demarc         ();
   axi4l_intf   axil_to_app                 ();
   axi4l_intf   axil_to_p4__demarc          ();
   axi4l_intf   axil_to_p4                  ();

   axi4l_intf   axil_to_cmac                ();
   axi4l_intf   axil_to_host                ();
   axi4l_intf   axil_to_bypass              ();
   axi4l_intf   axil_to_pkt_playback        ();
   axi4l_intf   axil_to_pkt_capture         ();

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

   axi4l_intf   axil_to_hash2qid        [NUM_CMAC] ();

   axi4l_intf   axil_to_core_to_app     [NUM_CMAC] ();
   axi4l_intf   axil_to_app_to_core     [NUM_CMAC] ();

   axi4l_intf   axil_to_probe_to_bypass [NUM_CMAC] ();
   axi4l_intf   axil_to_drops_to_bypass [NUM_CMAC] ();

   axi4l_intf   axil_from_vf2           [NUM_CMAC] ();
   axi4l_intf   axil_to_vf2             [NUM_CMAC] ();

   axi4l_intf   axil_q_range_fail       [NUM_CMAC] ();

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

   // smartnic top-level (platform/app) decoder
   smartnic_to_app_decoder smartnic_to_app_decoder_0 (
      .axil_if              (s_axil_if),
      .smartnic_axil_if     (axil_to_platform),
      .smartnic_app_axil_if (axil_to_app__demarc)
   );

   // smartnic platform decoder
   smartnic_decoder smartnic_axil_decoder_0 (
      .axil_if                         (axil_to_platform),
      .smartnic_regs_axil_if           (axil_to_regs),
      .endian_check_axil_if            (axil_to_endian_check),
      .fifo_to_host_0_axil_if          (axil_to_fifo_to_host[0]),
      .probe_core_to_app0_axil_if      (axil_to_core_to_app[0]),
      .probe_core_to_app1_axil_if      (axil_to_core_to_app[1]),
      .probe_app0_to_core_axil_if      (axil_to_app_to_core[0]),
      .probe_app1_to_core_axil_if      (axil_to_app_to_core[1]),
      .smartnic_cmac_axil_if           (axil_to_cmac),
      .smartnic_host_axil_if           (axil_to_host),
      .smartnic_bypass_axil_if         (axil_to_bypass),
      .smartnic_pkt_playback_axil_if   (axil_to_pkt_playback),
      .smartnic_pkt_capture_axil_if    (axil_to_pkt_capture),
      .smartnic_hash2qid_0_axil_if     (axil_to_hash2qid[0]),
      .smartnic_hash2qid_1_axil_if     (axil_to_hash2qid[1]),
      .smartnic_p4_axil_if             (axil_to_p4__demarc)
   );

   // smartnic cmac decoder
   smartnic_cmac_decoder smartnic_cmac_decoder_0 (
      .axil_if                         (axil_to_cmac),
      .probe_from_cmac_0_axil_if       (axil_to_probe_from_cmac[0]),
      .drops_ovfl_from_cmac_0_axil_if  (axil_to_ovfl_from_cmac[0]),
      .drops_err_from_cmac_0_axil_if   (axil_to_err_from_cmac[0]),
      .probe_from_cmac_1_axil_if       (axil_to_probe_from_cmac[1]),
      .drops_ovfl_from_cmac_1_axil_if  (axil_to_ovfl_from_cmac[1]),
      .drops_err_from_cmac_1_axil_if   (axil_to_err_from_cmac[1]),
      .probe_to_cmac_0_axil_if         (axil_to_probe_to_cmac[0]),
      .drops_ovfl_to_cmac_0_axil_if    (axil_to_ovfl_to_cmac[0]),
      .probe_to_cmac_1_axil_if         (axil_to_probe_to_cmac[1]),
      .drops_ovfl_to_cmac_1_axil_if    (axil_to_ovfl_to_cmac[1])
   );

   // smartnic host decoder
   smartnic_host_decoder smartnic_host_decoder_0 (
      .axil_if                         (axil_to_host),
      .probe_from_host_0_axil_if       (axil_to_probe_from_host[0]),
      .probe_from_host_1_axil_if       (axil_to_probe_from_host[1]),
      .probe_to_host_0_axil_if         (axil_to_probe_to_host[0]),
      .drops_ovfl_to_host_0_axil_if    (axil_to_ovfl_to_host[0]),
      .probe_to_host_1_axil_if         (axil_to_probe_to_host[1]),
      .drops_ovfl_to_host_1_axil_if    (axil_to_ovfl_to_host[1]),
      .probe_from_pf0_vf2_axil_if      (axil_from_vf2[0]),
      .probe_from_pf1_vf2_axil_if      (axil_from_vf2[1]),
      .probe_to_pf0_vf2_axil_if        (axil_to_vf2[0]),
      .probe_to_pf1_vf2_axil_if        (axil_to_vf2[1]),
      .drops_q_range_fail_0_axil_if    (axil_q_range_fail[0]),
      .drops_q_range_fail_1_axil_if    (axil_q_range_fail[1])
   );

   // smartnic bypass decoder
   smartnic_bypass_decoder smartnic_bypass_decoder_0 (
      .axil_if                         (axil_to_bypass),
      .probe_to_bypass_0_axil_if       (axil_to_probe_to_bypass[0]),
      .drops_to_bypass_0_axil_if       (axil_to_drops_to_bypass[0]),
      .probe_to_bypass_1_axil_if       (axil_to_probe_to_bypass[1]),
      .drops_to_bypass_1_axil_if       (axil_to_drops_to_bypass[1])
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
   logic        timestamp_rd_ack;
   logic [63:0] timestamp_rd;
   logic [63:0] freerun_rd;

   smartnic_timestamp  smartnic_timestamp_0 (
     .clk               (core_clk),
     .rstn              (core_rstn),
     .timestamp,
     .timestamp_incr    (smartnic_regs.timestamp_incr),
     .timestamp_wr_req  (smartnic_regs.timestamp_wr_lower_wr_evt),
     .timestamp_wr      ({smartnic_regs.timestamp_wr_upper, smartnic_regs.timestamp_wr_lower}),
     .timestamp_rd_req  (smartnic_regs.timestamp_rd_latch_wr_evt),
     .timestamp_rd_ack,
     .timestamp_rd,
     .freerun_rd
   );

   assign smartnic_regs.timestamp_rd_upper_nxt_v = timestamp_rd_ack;
   assign smartnic_regs.timestamp_rd_lower_nxt_v = timestamp_rd_ack;
   assign smartnic_regs.timestamp_rd_upper_nxt   = timestamp_rd[63:32];
   assign smartnic_regs.timestamp_rd_lower_nxt   = timestamp_rd[31:0];

   assign smartnic_regs.freerun_rd_upper_nxt_v = timestamp_rd_ack;
   assign smartnic_regs.freerun_rd_lower_nxt_v = timestamp_rd_ack;
   assign smartnic_regs.freerun_rd_upper_nxt   = freerun_rd[63:32];
   assign smartnic_regs.freerun_rd_lower_nxt   = freerun_rd[31:0];

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
   //  axi4s interface instantiations
   // ----------------------------------------------------------------

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_cmac_to_core   [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(ADPT_TX_TID_WID), .TDEST_WID(PORT_WID))  axis_host_to_core   [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         _axis_host_to_core  [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_host_to_core_demux   [NUM_CMAC][2] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_cmac_tid       [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_cmac_tid_p     [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))    axis_core_to_bypass      [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_bypass_to_core      [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_core_to_app         [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_to_app__demarc      [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_to_app              [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_h2c                 [NUM_CMAC][HOST_NUM_IFS] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_h2c_demux__demarc   [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_h2c_demux           [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_h2c_demux_p         [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_c2h                 [NUM_CMAC][HOST_NUM_IFS] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_c2h_mux_out         [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_c2h_mux_out__demarc [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

   tuser_smartnic_meta_t axis_to_app_tuser [NUM_CMAC];
   assign axis_to_app_tuser[0] = axis_to_app[0].tuser;
   assign axis_to_app_tuser[1] = axis_to_app[1].tuser;

   tuser_smartnic_meta_t axis_from_app_tuser [NUM_CMAC];
   assign axis_from_app[0].tuser = axis_from_app_tuser[0];
   assign axis_from_app[1].tuser = axis_from_app_tuser[1];

   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_from_app         [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_from_app__demarc [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_app_to_core      [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_core_to_host     [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         _axis_core_to_host    [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         __axis_core_to_host   [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));
   axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_core_to_host_mux [NUM_CMAC][2] (.aclk(core_clk), .aresetn(core_rstn));

   axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))         axis_core_to_cmac     [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));


   // ----------------------------------------------------------------
   // fifos to go from independent CMAC clock domains to a single
   // core clock domain
   // ----------------------------------------------------------------

   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__fifo
      //------------------------ from cmac to core --------------
      axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID)) _axis_from_cmac (.aclk(cmac_clk[i]), .aresetn(cmac_rstn[i]));
      axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_from_cmac (.aclk(cmac_clk[i]), .aresetn(cmac_rstn[i]));

      axi4s_intf_from_signals #(
        .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID)
      ) axis_from_cmac_from_signals (
        .tvalid   (s_axis_cmac_rx_322mhz_tvalid[i]),
        .tready   (s_axis_cmac_rx_322mhz_tready[i]), // NOTE: tready signal is ignored by open-nic-shell.
        .tdata    (s_axis_cmac_rx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (s_axis_cmac_rx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (s_axis_cmac_rx_322mhz_tlast[i]),
        .tid      (i),
        .tdest    (s_axis_cmac_rx_322mhz_tdest[`getvec(4, i)]),
        .tuser    (s_axis_cmac_rx_322mhz_tuser_err[i]),

        .axi4s_if (_axis_from_cmac)
      );

      // xilinx_axi4s_ila xilinx_axi4s_ila_0 (.axis_in(axis_from_cmac[i]));

      xilinx_axi4s_reg_slice #(
          .CONFIG ( xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_FULLY_REGISTERED )
      ) xilinx_axi4s_reg_slice_from_cmac (
          .from_tx (_axis_from_cmac),
          .to_rx   (axis_from_cmac)
      );

      axi4s_probe #( .MODE(ERRORS), .TUSER_MODE(PKT_ERROR) ) axi4s_err_from_cmac (
            .axi4l_if  (axil_to_err_from_cmac[i]),
            .axi4s_if  (axis_from_cmac)
         );

      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (1024),
        .MAX_PKT_LEN    (MAX_PKT_LEN),
        .IGNORE_TREADY  (1),
        .DROP_ERRORED   (1)
      ) fifo_from_cmac (
        .axi4s_in       (axis_from_cmac),
        .axi4s_out      (axis_cmac_to_core[i]),
        .axil_to_probe  (axil_to_probe_from_cmac[i]),
        .axil_to_ovfl   (axil_to_ovfl_from_cmac[i]),
        .axil_if        (axil_to_fifo_from_cmac[i]),
        .flow_ctl_thresh('0), // Unused
        .flow_ctl       ( )
      );

      // Terminate unused AXI-L interface
      axi4l_intf_controller_term axi4l_fifo_from_cmac_term (.axi4l_if (axil_to_fifo_from_cmac[i]));



      //------------------------ from core to cmac --------------
      axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID)) axis_to_pad   (.aclk(cmac_clk[i]), .aresetn(cmac_rstn[i]));
      axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID)) _axis_to_cmac (.aclk(cmac_clk[i]), .aresetn(cmac_rstn[i]));
      axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID)) axis_to_cmac  (.aclk(cmac_clk[i]), .aresetn(cmac_rstn[i]));

      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (1024),
        .MAX_PKT_LEN    (MAX_PKT_LEN),
        .TX_THRESHOLD   (4),
        .IGNORE_TREADY  (1)
      ) fifo_to_cmac (
        .axi4s_in       (axis_core_to_cmac[i]),
        .axi4s_out      (axis_to_pad),
        .flow_ctl_thresh (smartnic_regs.egr_fc_thresh[i][15:0]),
        .flow_ctl       (egr_flow_ctl[i]),
        .axil_to_probe  (axil_to_probe_to_cmac[i]),
        .axil_to_ovfl   (axil_to_ovfl_to_cmac[i]),
        .axil_if        (axil_to_fifo_to_cmac[i])
      );

      // axi4s pad instantiation.
      axi4s_pad axi4s_pad_0 (
        .axi4s_in    (axis_to_pad),
        .axi4s_out   (_axis_to_cmac)
      );

      xilinx_axi4s_reg_slice #(
          .CONFIG ( xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_FULLY_REGISTERED )
      ) xilinx_axi4s_reg_slice_to_cmac (
          .from_tx (_axis_to_cmac),
          .to_rx   (axis_to_cmac)
      );

      // xilinx_axi4s_ila xilinx_axi4s_ila_1 (.axis_in(axis_core_to_cmac[i]));
      // xilinx_axi4s_ila xilinx_axi4s_ila_2 (.axis_in(axis_to_cmac[i]));

      // Terminate unused AXI-L interface
      axi4l_intf_controller_term axi4l_fifo_to_cmac_term (.axi4l_if (axil_to_fifo_to_cmac[i]));

      axi4s_intf_to_signals #(
        .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID)
      ) axis_to_cmac_to_signals (
        .tvalid   (m_axis_cmac_tx_322mhz_tvalid[i]),
        .tready   (m_axis_cmac_tx_322mhz_tready[i]),
        .tdata    (m_axis_cmac_tx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (m_axis_cmac_tx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (m_axis_cmac_tx_322mhz_tlast[i]),
        .tid      (),
        .tdest    (m_axis_cmac_tx_322mhz_tdest[`getvec(4, i)]),
        .tuser    (m_axis_cmac_tx_322mhz_tuser_err[i]),

        .axi4s_if (axis_to_cmac)
      );


      //------------------------ from core to host --------------
      axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                 .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID)) axis_to_host (.aclk(cmac_clk[i]), .aresetn(cmac_rstn[i]));

      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (1024),
        .MAX_PKT_LEN    (MAX_PKT_LEN),
        .IGNORE_TREADY  (1)
      ) fifo_to_host (
        .axi4s_in       (axis_core_to_host[i]),
        .axi4s_out      (axis_to_host),
        .flow_ctl_thresh (smartnic_regs.egr_fc_thresh[2+i][15:0]),
        .flow_ctl       (egr_flow_ctl[2+i]),
        .axil_to_probe  (axil_to_probe_to_host[i]),
        .axil_to_ovfl   (axil_to_ovfl_to_host[i]),
        .axil_if        (axil_to_fifo_to_host[i])
      );

      // xilinx_axi4s_ila xilinx_axi4s_ila_to_host (.axis_in(axis_to_host));

      // Terminate unused AXI-L interface
      if (i != 0) begin : g__axi4l_fifo_to_host_term
          axi4l_intf_controller_term axi4l_fifo_to_host_term (.axi4l_if (axil_to_fifo_to_host[i]));
      end : g__axi4l_fifo_to_host_term

      axi4s_intf_to_signals #(
        .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID)
      ) axis_to_host_to_signals (
        .tvalid   (),  // see assignment below
        .tready   (m_axis_adpt_rx_322mhz_tready[i] && !axis_to_host_tpause[i]),
        .tdata    (m_axis_adpt_rx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (m_axis_adpt_rx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (m_axis_adpt_rx_322mhz_tlast[i]),
        .tid      (),
        .tdest    (m_axis_adpt_rx_322mhz_tdest[`getvec(4, i)]),
        .tuser    (m_axis_adpt_rx_322mhz_tuser[i]),

        .axi4s_if (axis_to_host)
      );

      assign m_axis_adpt_rx_322mhz_tvalid[i] = axis_to_host.tvalid && !axis_to_host_tpause[i];

      assign m_axis_adpt_rx_322mhz_tuser_err[i] = '0;
      assign m_axis_adpt_rx_322mhz_tuser_rss_enable[i] = m_axis_adpt_rx_322mhz_tuser[i].rss_enable;
      assign m_axis_adpt_rx_322mhz_tuser_rss_entropy[`getvec(12, i)] = m_axis_adpt_rx_322mhz_tuser[i].rss_entropy;


      //------------------------ from host to core --------------
      axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(ADPT_TX_TID_WID), .TDEST_WID(PORT_WID))  axis_from_host (.aclk(cmac_clk[i]), .aresetn(cmac_rstn[i]));

      axi4s_intf_from_signals #(
        .DATA_BYTE_WID(64), .TID_WID(ADPT_TX_TID_WID), .TDEST_WID(PORT_WID)
      ) axis_from_host_from_signals (
        .tvalid   (s_axis_adpt_tx_322mhz_tvalid[i]),
        .tready   (s_axis_adpt_tx_322mhz_tready[i]),
        .tdata    (s_axis_adpt_tx_322mhz_tdata[`getvec(512, i)]),
        .tkeep    (s_axis_adpt_tx_322mhz_tkeep[`getvec(64, i)]),
        .tlast    (s_axis_adpt_tx_322mhz_tlast[i]),
        .tid      (s_axis_adpt_tx_322mhz_tid[`getvec(16, i)]),
        .tdest    (s_axis_adpt_tx_322mhz_tdest[`getvec(4, i)]),
        .tuser    (s_axis_adpt_tx_322mhz_tuser_err[i]),  // this is a deadend for now. no use in smartnic.

        .axi4s_if (axis_from_host)
      );

      axi4s_pkt_fifo_async #(
        .FIFO_DEPTH     (512),
        .MAX_PKT_LEN    (MAX_PKT_LEN)
      ) fifo_from_host (
        .axi4s_in       (axis_from_host),
        .axi4s_out      (axis_host_to_core[i]),
        .axil_to_probe  (axil_to_probe_from_host[i]),
        .axil_to_ovfl   (axil_to_ovfl_from_host[i]),
        .axil_if        (axil_to_fifo_from_host[i]),
        .flow_ctl_thresh('0), // Unused
        .flow_ctl       ( )
      );

      axi4l_intf_controller_term axi4l_ovfl_from_host_term (.axi4l_if (axil_to_ovfl_from_host[i]));
      axi4l_intf_controller_term axi4l_fifo_from_host_term (.axi4l_if (axil_to_fifo_from_host[i]));

   end : g__fifo

   endgenerate


   // cmac tid assignment logic
   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__cmac_tid
       // cmac port tid assignments
       assign axis_cmac_to_core[i].tready = axis_cmac_tid[i].tready;

       assign axis_cmac_tid[i].tvalid  = axis_cmac_to_core[i].tvalid;
       assign axis_cmac_tid[i].tdata   = axis_cmac_to_core[i].tdata;
       assign axis_cmac_tid[i].tkeep   = axis_cmac_to_core[i].tkeep;
       assign axis_cmac_tid[i].tlast   = axis_cmac_to_core[i].tlast;
       assign axis_cmac_tid[i].tdest   = axis_cmac_to_core[i].tdest;
       assign axis_cmac_tid[i].tuser   = axis_cmac_to_core[i].tuser;

       assign axis_cmac_tid[i].tid     = i;

       axi4s_intf_pipe axi4s_cmac_tid_pipe (.from_tx(axis_cmac_tid[i]), .to_rx(axis_cmac_tid_p[i]));
   end : g__cmac_tid
   endgenerate


   // smartnic_mux instantiation.
   smartnic_mux #(
       .NUM_CMAC (NUM_CMAC)
   ) smartnic_mux_inst ( 
       .core_clk            (core_clk),
       .core_rstn           (core_rstn),
       .axis_cmac_to_core   (axis_cmac_tid_p),
       .axis_host_to_core   (_axis_host_to_core),
       .axis_core_to_app    (axis_core_to_app),
       .axis_core_to_bypass (axis_core_to_bypass),
       .smartnic_regs       (smartnic_regs)
   );

   // xilinx_axi4s_ila #(.PIPE_STAGES(2)) xilinx_axi4s_ila_core_to_app  (.axis_in(axis_core_to_app[0]));
   // xilinx_axi4s_ila #(.PIPE_STAGES(2)) xilinx_axi4s_ila_app_to_core  (.axis_in(axis_app_to_core[0]));
   // xilinx_axi4s_ila #(.PIPE_STAGES(2)) xilinx_axi4s_ila_hdr_to_app   (.axis_in(axis_to_app__demarc[0]));
   // xilinx_axi4s_ila #(.PIPE_STAGES(2)) xilinx_axi4s_ila_hdr_from_app (.axis_in(axis_from_app__demarc[0]));

   // smartnic_mux instantiation.
   smartnic_bypass #(
       .NUM_CMAC (NUM_CMAC),
       .MAX_PKT_LEN (MAX_PKT_LEN)
   ) smartnic_bypass_inst ( 
       .core_clk                  (core_clk),
       .core_rstn                 (core_rstn),
       .axis_core_to_bypass       (axis_core_to_bypass),
       .axis_bypass_to_core       (axis_bypass_to_core),
       .axil_to_drops_to_bypass   (axil_to_drops_to_bypass),
       .axil_to_probe_to_bypass   (axil_to_probe_to_bypass),
       .smartnic_regs             (smartnic_regs)
   );

   // smartnic_demux instantiation.
   smartnic_demux #(
       .NUM_CMAC (NUM_CMAC),
       .MAX_PKT_LEN (MAX_PKT_LEN)
   ) smartnic_demux_inst ( 
       .core_clk            (core_clk),
       .core_rstn           (core_rstn),
       .axis_bypass_to_core (axis_bypass_to_core),
       .axis_app_to_core    (axis_app_to_core),
       .axis_core_to_cmac   (axis_core_to_cmac),
       .axis_core_to_host   (_axis_core_to_host),
       .smartnic_regs       (smartnic_regs)
   );

   // smartnic_host instantiation.
   smartnic_host #(
       .NUM_CMAC (NUM_CMAC),
       .HOST_NUM_IFS (HOST_NUM_IFS)
   ) smartnic_host_inst (
       .core_clk                (core_clk),
       .core_rstn               (core_rstn),
       .axis_host_to_core       (axis_host_to_core),
       .axis_core_to_host       (axis_core_to_host),
       .axis_core_to_host_mux   (axis_core_to_host_mux),
       .axis_host_to_core_demux (axis_host_to_core_demux),
       .axil_q_range_fail       (axil_q_range_fail),
       .axil_to_hash2qid        (axil_to_hash2qid),
       .axil_to_pkt_playback    (axil_to_pkt_playback),
       .axil_to_pkt_capture     (axil_to_pkt_capture),
       .smartnic_regs           (smartnic_regs)
   );


   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__host_mux_core  // core-side host mux logic
       tuser_smartnic_meta_t __axis_core_to_host_tuser;
       axi4s_intf_connector host_to_core_demux_pipe_0 (.from_tx(axis_host_to_core_demux[i][0]),
                                                       .to_rx(_axis_host_to_core[i]));
       axi4s_intf_connector host_to_core_demux_pipe_1 (.from_tx(axis_host_to_core_demux[i][1]),
                                                       .to_rx(axis_h2c_demux__demarc[i]));

       axi4s_probe axis_probe_from_vf2 (.axi4l_if(axil_from_vf2[i]), .axi4s_if(_axis_host_to_core[i]));


       axi4s_intf_pipe axis_core_to_app_pipe   (.from_tx(axis_core_to_app[i]),         .to_rx(axis_to_app__demarc[i]));
       axi4s_intf_pipe axis_app_to_core_pipe   (.from_tx(axis_from_app__demarc[i]),    .to_rx(axis_app_to_core[i]));

       axi4s_probe axis_probe_to_vf2 (.axi4l_if(axil_to_vf2[i]), .axi4s_if(_axis_core_to_host[i]));

       assign  _axis_core_to_host[i].tready  = __axis_core_to_host[i].tready;
       assign __axis_core_to_host[i].tvalid  =  _axis_core_to_host[i].tvalid;
       assign __axis_core_to_host[i].tdata   =  _axis_core_to_host[i].tdata;
       assign __axis_core_to_host[i].tkeep   =  _axis_core_to_host[i].tkeep;
       assign __axis_core_to_host[i].tlast   =  _axis_core_to_host[i].tlast;
       assign __axis_core_to_host[i].tid     =  _axis_core_to_host[i].tid;
       assign __axis_core_to_host[i].tdest   =  _axis_core_to_host[i].tdest;

       always_comb begin
           __axis_core_to_host_tuser = _axis_core_to_host[i].tuser;
           __axis_core_to_host_tuser.rss_entropy[11:10] = 2'h3;  // overwrite top bits with PF VF2 id (2'h3).
           __axis_core_to_host[i].tuser = __axis_core_to_host_tuser;
       end

       axi4s_intf_connector core_to_host_mux_pipe_0 (.from_tx(axis_c2h_mux_out__demarc[i]), .to_rx(axis_core_to_host_mux[i][0]));
       axi4s_intf_connector core_to_host_mux_pipe_1 (.from_tx(__axis_core_to_host[i]),      .to_rx(axis_core_to_host_mux[i][1]));

   end : g__host_mux_core
   endgenerate

   h2c_t h2c_demux_sel [NUM_CMAC];
   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__host_mux_app  // app-side host mux logic
       port_t axis_h2c_demux_tid;

       axi4s_mux #(.N(HOST_NUM_IFS)) axis_c2h_mux (
           .axi4s_in   ( axis_c2h[i] ),
           .axi4s_out  ( axis_c2h_mux_out[i] )
       );


       axi4s_intf_pipe axis_h2c_demux_pipe (.from_tx(axis_h2c_demux[i]), .to_rx(axis_h2c_demux_p[i]));

       assign axis_h2c_demux_tid = axis_h2c_demux[i].tid;
       always @(posedge core_clk)
            if (!core_rstn)
                h2c_demux_sel[i] <= H2C_PF;
            else if (axis_h2c_demux[i].tready && axis_h2c_demux[i].tvalid && axis_h2c_demux[i].sop)
                h2c_demux_sel[i] <= (axis_h2c_demux_tid.encoded.typ == PF)  ? H2C_PF :
                                    (axis_h2c_demux_tid.encoded.typ == VF0) ? H2C_VF0 : H2C_VF1;

       axi4s_intf_demux #(.N(HOST_NUM_IFS)) axis_h2c_demux_inst (
           .from_tx ( axis_h2c_demux_p[i] ),
           .to_rx   ( axis_h2c[i] ),
           .sel     ( h2c_demux_sel[i] )
        );

   end :  g__host_mux_app
   endgenerate



   // ----------------------------------------------------------------
   // AXI register slices
   // ----------------------------------------------------------------
   // - demarcate physical boundary between SmartNIC platform and application
   //   and support efficient pipelining between SLRs

   // AXI-L interface
   xilinx_axi4l_reg_slice #(
       .CONFIG (xilinx_axi_pkg::XILINX_AXI_REG_SLICE_SLR_CROSSING)
   ) i_xilinx_axi4l_reg_slice__core_to_p4 (
       .axi4l_if_from_controller ( axil_to_p4__demarc ),
       .axi4l_if_to_peripheral   ( axil_to_p4 )
   );

   // AXI-L interface
   xilinx_axi4l_reg_slice #(
       .CONFIG (xilinx_axi_pkg::XILINX_AXI_REG_SLICE_SLR_CROSSING)
   ) i_xilinx_axi4l_reg_slice__core_to_app (
       .axi4l_if_from_controller ( axil_to_app__demarc ),
       .axi4l_if_to_peripheral   ( axil_to_app )
   );

   generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__reg_slice
       // AXI-S interfaces
       xilinx_axi4s_reg_slice #(
           .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
       ) i_xilinx_axi4s_reg_slice__core_to_app (
           .from_tx (axis_to_app__demarc[i]),
           .to_rx   (axis_to_app[i])
       );

       xilinx_axi4s_reg_slice #(
           .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
       ) i_xilinx_axi4s_reg_slice__app_to_core (
           .from_tx (axis_from_app[i]),
           .to_rx   (axis_from_app__demarc[i])
       );

       xilinx_axi4s_reg_slice #(
           .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
       ) i_xilinx_axi4s_reg_slice__c2h_mux_out (
           .from_tx (axis_c2h_mux_out[i]),
           .to_rx   (axis_c2h_mux_out__demarc[i])
       );

       xilinx_axi4s_reg_slice #(
           .CONFIG(xilinx_axis_pkg::XILINX_AXIS_REG_SLICE_SLR_CROSSING)
       ) i_xilinx_axi4s_reg_slice__h2c_demux_out (
           .from_tx (axis_h2c_demux__demarc[i]),
           .to_rx   (axis_h2c_demux[i])
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
   logic [NUM_CMAC-1:0][3:0]   axis_app_igr_tid;
   logic [NUM_CMAC-1:0][3:0]   axis_app_igr_tdest;

   logic [NUM_CMAC-1:0]        axis_app_egr_tvalid;
   logic [NUM_CMAC-1:0]        axis_app_egr_tready;
   logic [NUM_CMAC-1:0][511:0] axis_app_egr_tdata;
   logic [NUM_CMAC-1:0][63:0]  axis_app_egr_tkeep;
   logic [NUM_CMAC-1:0]        axis_app_egr_tlast;
   logic [NUM_CMAC-1:0][3:0]   axis_app_egr_tid;
   logic [NUM_CMAC-1:0][3:0]   axis_app_egr_tdest;
   logic [NUM_CMAC-1:0]        axis_app_egr_tuser_rss_enable;
   logic [NUM_CMAC-1:0][11:0]  axis_app_egr_tuser_rss_entropy;

   generate
       for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__app_igr_egr
           assign axis_app_igr_tvalid[i]    = axis_to_app[i].tvalid;
           assign axis_to_app[i].tready     = axis_app_igr_tready[i];
           assign axis_app_igr_tdata[i]     = axis_to_app[i].tdata;
           assign axis_app_igr_tkeep[i]     = axis_to_app[i].tkeep;
           assign axis_app_igr_tlast[i]     = axis_to_app[i].tlast;
           assign axis_app_igr_tid[i]       = axis_to_app[i].tid;
           assign axis_app_igr_tdest[i]     = axis_to_app[i].tdest;

           assign axis_from_app[i].tvalid              = axis_app_egr_tvalid[i];
           assign axis_app_egr_tready[i]               = axis_from_app[i].tready;
           assign axis_from_app[i].tdata               = axis_app_egr_tdata[i];
           assign axis_from_app[i].tkeep               = axis_app_egr_tkeep[i];
           assign axis_from_app[i].tlast               = axis_app_egr_tlast[i];
           assign axis_from_app[i].tid                 = axis_app_egr_tid[i];
           assign axis_from_app[i].tdest               = axis_app_egr_tdest[i];
           assign axis_from_app_tuser[i].rss_enable    = axis_app_egr_tuser_rss_enable[i];
           assign axis_from_app_tuser[i].rss_entropy   = axis_app_egr_tuser_rss_entropy[i];
       end : g__app_igr_egr
   endgenerate


   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_h2c_tvalid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_h2c_tready;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][511:0] axis_h2c_tdata;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][63:0]  axis_h2c_tkeep;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_h2c_tlast;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][3:0]   axis_h2c_tid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][3:0]   axis_h2c_tdest;

   tuser_smartnic_meta_t axis_h2c_tuser [NUM_CMAC][HOST_NUM_IFS];

   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tvalid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tready;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][511:0] axis_c2h_tdata;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][63:0]  axis_c2h_tkeep;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tlast;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][3:0]   axis_c2h_tid;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][3:0]   axis_c2h_tdest;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0]        axis_c2h_tuser_rss_enable;
   logic [HOST_NUM_IFS-1:0][NUM_CMAC-1:0][11:0]  axis_c2h_tuser_rss_entropy;

   tuser_smartnic_meta_t axis_c2h_tuser [NUM_CMAC][HOST_NUM_IFS];

   generate
       for (genvar j = 0; j < HOST_NUM_IFS; j += 1) begin : g__h2c_c2h
           for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__cmac_idx
               logic [$clog2(HOST_NUM_IFS)-1:0] host_if_id;

               assign host_if_id = j;

               assign axis_h2c_tvalid[j][i]    = axis_h2c[i][j].tvalid;
               assign axis_h2c[i][j].tready    = axis_h2c_tready[j][i];
               assign axis_h2c_tdata[j][i]     = axis_h2c[i][j].tdata;
               assign axis_h2c_tkeep[j][i]     = axis_h2c[i][j].tkeep;
               assign axis_h2c_tlast[j][i]     = axis_h2c[i][j].tlast;
               assign axis_h2c_tid[j][i]       = axis_h2c[i][j].tid;
               assign axis_h2c_tdest[j][i]     = axis_h2c[i][j].tdest;
               assign axis_h2c_tuser[i][j]     = axis_h2c[i][j].tuser;

               assign axis_c2h[i][j].tvalid              = axis_c2h_tvalid[j][i];
               assign axis_c2h_tready[j][i]              = axis_c2h[i][j].tready;
               assign axis_c2h[i][j].tdata               = axis_c2h_tdata[j][i];
               assign axis_c2h[i][j].tkeep               = axis_c2h_tkeep[j][i];
               assign axis_c2h[i][j].tlast               = axis_c2h_tlast[j][i];
               assign axis_c2h[i][j].tid                 = axis_c2h_tid[j][i];
               assign axis_c2h[i][j].tdest               = axis_c2h_tdest[j][i];
               assign axis_c2h_tuser[i][j].rss_enable    = axis_c2h_tuser_rss_enable[j][i];
               assign axis_c2h_tuser[i][j].rss_entropy   = {host_if_id, axis_c2h_tuser_rss_entropy[j][i][9:0]};
               assign axis_c2h[i][j].tuser               = axis_c2h_tuser[i][j];

           end : g__cmac_idx
       end : g__h2c_c2h
   endgenerate


   smartnic_app smartnic_app (
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
    // AXI-S app_egr interface
    .axis_app_egr_tvalid ( axis_app_egr_tvalid ),
    .axis_app_egr_tready ( axis_app_egr_tready ),
    .axis_app_egr_tdata  ( axis_app_egr_tdata ),
    .axis_app_egr_tkeep  ( axis_app_egr_tkeep ),
    .axis_app_egr_tlast  ( axis_app_egr_tlast ),
    .axis_app_egr_tid    ( axis_app_egr_tid ),
    .axis_app_egr_tdest  ( axis_app_egr_tdest ),
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
    // AXI-S h2c interface 
    .axis_c2h_tvalid     ( axis_c2h_tvalid ),
    .axis_c2h_tready     ( axis_c2h_tready ),
    .axis_c2h_tdata      ( axis_c2h_tdata ),
    .axis_c2h_tkeep      ( axis_c2h_tkeep ),
    .axis_c2h_tlast      ( axis_c2h_tlast ),
    .axis_c2h_tid        ( axis_c2h_tid ),
    .axis_c2h_tdest      ( axis_c2h_tdest ),
    .axis_c2h_tuser_rss_enable  ( axis_c2h_tuser_rss_enable ),
    .axis_c2h_tuser_rss_entropy ( axis_c2h_tuser_rss_entropy ),
    // egress flow control interface
    .egr_flow_ctl            ( egr_flow_ctl_pipe[0] )
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
