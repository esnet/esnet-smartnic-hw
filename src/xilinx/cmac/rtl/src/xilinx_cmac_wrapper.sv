// Xilinx US+ Integrated 100G Ethernet Subsystem Wrapper
//
// See: https://docs.xilinx.com/r/en-US/pg203-cmac-usplus
module xilinx_cmac_wrapper #(
    parameter int PORT_ID = 0
) (
    // Clock/reset
    input  logic          clk,
    input  logic          srst,

    // From/to pins
    // -- QSFP
    input  logic          qsfp_refclk_p,
    input  logic          qsfp_refclk_n,
    input  logic [3:0]    qsfp_rxp,
    input  logic [3:0]    qsfp_rxn,
    output logic [3:0]    qsfp_txp,
    output logic [3:0]    qsfp_txn,

    // From/to core
    // -- AXI-S
    axi4s_intf.tx         axis_rx,
    axi4s_intf.rx_async   axis_tx,
    // -- AXI-L
    axi4l_intf.peripheral axil_if
);
    // =========================================================================
    // Imports
    // =========================================================================
    import xilinx_cmac_pkg::*;

    // =========================================================================
    // Signals
    // =========================================================================
    // (Local) signals
    logic __cmac_clk;

    // CMAC ports
    logic [3 : 0] gt_txp_out;
    logic [3 : 0] gt_txn_out;
    logic [3 : 0] gt_rxp_in;
    logic [3 : 0] gt_rxn_in;
    logic gt_txusrclk2;
    logic [11 : 0] gt_loopback_in;
    logic gt_ref_clk_out;
    logic [3 : 0] gt_rxrecclkout;
    logic [3 : 0] gt_powergoodout;
    logic gtwiz_reset_tx_datapath;
    logic gtwiz_reset_rx_datapath;
    logic s_axi_aclk;
    logic s_axi_sreset;
    logic pm_tick;
    logic [31 : 0] s_axi_awaddr;
    logic s_axi_awvalid;
    logic s_axi_awready;
    logic [31 : 0] s_axi_wdata;
    logic [3 : 0] s_axi_wstrb;
    logic s_axi_wvalid;
    logic s_axi_wready;
    logic [1 : 0] s_axi_bresp;
    logic s_axi_bvalid;
    logic s_axi_bready;
    logic [31 : 0] s_axi_araddr;
    logic s_axi_arvalid;
    logic s_axi_arready;
    logic [31 : 0] s_axi_rdata;
    logic [1 : 0] s_axi_rresp;
    logic s_axi_rvalid;
    logic s_axi_rready;
    logic stat_rx_rsfec_am_lock0;
    logic stat_rx_rsfec_am_lock1;
    logic stat_rx_rsfec_am_lock2;
    logic stat_rx_rsfec_am_lock3;
    logic stat_rx_rsfec_corrected_cw_inc;
    logic stat_rx_rsfec_cw_inc;
    logic [2 : 0] stat_rx_rsfec_err_count0_inc;
    logic [2 : 0] stat_rx_rsfec_err_count1_inc;
    logic [2 : 0] stat_rx_rsfec_err_count2_inc;
    logic [2 : 0] stat_rx_rsfec_err_count3_inc;
    logic stat_rx_rsfec_hi_ser;
    logic stat_rx_rsfec_lane_alignment_status;
    logic [13 : 0] stat_rx_rsfec_lane_fill_0;
    logic [13 : 0] stat_rx_rsfec_lane_fill_1;
    logic [13 : 0] stat_rx_rsfec_lane_fill_2;
    logic [13 : 0] stat_rx_rsfec_lane_fill_3;
    logic [7 : 0] stat_rx_rsfec_lane_mapping;
    logic stat_rx_rsfec_uncorrected_cw_inc;
    logic [31 : 0] user_reg0;
    logic sys_reset;
    logic gt_ref_clk_p;
    logic gt_ref_clk_n;
    logic init_clk;
    logic rx_axis_tvalid;
    logic [511 : 0] rx_axis_tdata;
    logic rx_axis_tlast;
    logic [63 : 0] rx_axis_tkeep;
    logic rx_axis_tuser;
    logic [7 : 0] rx_otn_bip8_0;
    logic [7 : 0] rx_otn_bip8_1;
    logic [7 : 0] rx_otn_bip8_2;
    logic [7 : 0] rx_otn_bip8_3;
    logic [7 : 0] rx_otn_bip8_4;
    logic [65 : 0] rx_otn_data_0;
    logic [65 : 0] rx_otn_data_1;
    logic [65 : 0] rx_otn_data_2;
    logic [65 : 0] rx_otn_data_3;
    logic [65 : 0] rx_otn_data_4;
    logic rx_otn_ena;
    logic rx_otn_lane0;
    logic rx_otn_vlmarker;
    logic [55 : 0] rx_preambleout;
    logic usr_rx_reset;
    logic gt_rxusrclk2;
    logic stat_rx_aligned;
    logic stat_rx_aligned_err;
    logic [2 : 0] stat_rx_bad_code;
    logic [2 : 0] stat_rx_bad_fcs;
    logic stat_rx_bad_preamble;
    logic stat_rx_bad_sfd;
    logic stat_rx_bip_err_0;
    logic stat_rx_bip_err_1;
    logic stat_rx_bip_err_10;
    logic stat_rx_bip_err_11;
    logic stat_rx_bip_err_12;
    logic stat_rx_bip_err_13;
    logic stat_rx_bip_err_14;
    logic stat_rx_bip_err_15;
    logic stat_rx_bip_err_16;
    logic stat_rx_bip_err_17;
    logic stat_rx_bip_err_18;
    logic stat_rx_bip_err_19;
    logic stat_rx_bip_err_2;
    logic stat_rx_bip_err_3;
    logic stat_rx_bip_err_4;
    logic stat_rx_bip_err_5;
    logic stat_rx_bip_err_6;
    logic stat_rx_bip_err_7;
    logic stat_rx_bip_err_8;
    logic stat_rx_bip_err_9;
    logic [19 : 0] stat_rx_block_lock;
    logic stat_rx_broadcast;
    logic [2 : 0] stat_rx_fragment;
    logic [1 : 0] stat_rx_framing_err_0;
    logic [1 : 0] stat_rx_framing_err_1;
    logic [1 : 0] stat_rx_framing_err_10;
    logic [1 : 0] stat_rx_framing_err_11;
    logic [1 : 0] stat_rx_framing_err_12;
    logic [1 : 0] stat_rx_framing_err_13;
    logic [1 : 0] stat_rx_framing_err_14;
    logic [1 : 0] stat_rx_framing_err_15;
    logic [1 : 0] stat_rx_framing_err_16;
    logic [1 : 0] stat_rx_framing_err_17;
    logic [1 : 0] stat_rx_framing_err_18;
    logic [1 : 0] stat_rx_framing_err_19;
    logic [1 : 0] stat_rx_framing_err_2;
    logic [1 : 0] stat_rx_framing_err_3;
    logic [1 : 0] stat_rx_framing_err_4;
    logic [1 : 0] stat_rx_framing_err_5;
    logic [1 : 0] stat_rx_framing_err_6;
    logic [1 : 0] stat_rx_framing_err_7;
    logic [1 : 0] stat_rx_framing_err_8;
    logic [1 : 0] stat_rx_framing_err_9;
    logic stat_rx_framing_err_valid_0;
    logic stat_rx_framing_err_valid_1;
    logic stat_rx_framing_err_valid_10;
    logic stat_rx_framing_err_valid_11;
    logic stat_rx_framing_err_valid_12;
    logic stat_rx_framing_err_valid_13;
    logic stat_rx_framing_err_valid_14;
    logic stat_rx_framing_err_valid_15;
    logic stat_rx_framing_err_valid_16;
    logic stat_rx_framing_err_valid_17;
    logic stat_rx_framing_err_valid_18;
    logic stat_rx_framing_err_valid_19;
    logic stat_rx_framing_err_valid_2;
    logic stat_rx_framing_err_valid_3;
    logic stat_rx_framing_err_valid_4;
    logic stat_rx_framing_err_valid_5;
    logic stat_rx_framing_err_valid_6;
    logic stat_rx_framing_err_valid_7;
    logic stat_rx_framing_err_valid_8;
    logic stat_rx_framing_err_valid_9;
    logic stat_rx_got_signal_os;
    logic stat_rx_hi_ber;
    logic stat_rx_inrangeerr;
    logic stat_rx_internal_local_fault;
    logic stat_rx_jabber;
    logic stat_rx_local_fault;
    logic [19 : 0] stat_rx_mf_err;
    logic [19 : 0] stat_rx_mf_len_err;
    logic [19 : 0] stat_rx_mf_repeat_err;
    logic stat_rx_misaligned;
    logic stat_rx_multicast;
    logic stat_rx_oversize;
    logic stat_rx_packet_1024_1518_bytes;
    logic stat_rx_packet_128_255_bytes;
    logic stat_rx_packet_1519_1522_bytes;
    logic stat_rx_packet_1523_1548_bytes;
    logic stat_rx_packet_1549_2047_bytes;
    logic stat_rx_packet_2048_4095_bytes;
    logic stat_rx_packet_256_511_bytes;
    logic stat_rx_packet_4096_8191_bytes;
    logic stat_rx_packet_512_1023_bytes;
    logic stat_rx_packet_64_bytes;
    logic stat_rx_packet_65_127_bytes;
    logic stat_rx_packet_8192_9215_bytes;
    logic stat_rx_packet_bad_fcs;
    logic stat_rx_packet_large;
    logic [2 : 0] stat_rx_packet_small;
    logic stat_rx_pause;
    logic [15 : 0] stat_rx_pause_quanta0;
    logic [15 : 0] stat_rx_pause_quanta1;
    logic [15 : 0] stat_rx_pause_quanta2;
    logic [15 : 0] stat_rx_pause_quanta3;
    logic [15 : 0] stat_rx_pause_quanta4;
    logic [15 : 0] stat_rx_pause_quanta5;
    logic [15 : 0] stat_rx_pause_quanta6;
    logic [15 : 0] stat_rx_pause_quanta7;
    logic [15 : 0] stat_rx_pause_quanta8;
    logic [8 : 0] stat_rx_pause_req;
    logic [8 : 0] stat_rx_pause_valid;
    logic stat_rx_user_pause;
    logic core_rx_reset;
    logic rx_clk;
    logic stat_rx_received_local_fault;
    logic stat_rx_remote_fault;
    logic stat_rx_status;
    logic [2 : 0] stat_rx_stomped_fcs;
    logic [19 : 0] stat_rx_synced;
    logic [19 : 0] stat_rx_synced_err;
    logic [2 : 0] stat_rx_test_pattern_mismatch;
    logic stat_rx_toolong;
    logic [6 : 0] stat_rx_total_bytes;
    logic [13 : 0] stat_rx_total_good_bytes;
    logic stat_rx_total_good_packets;
    logic [2 : 0] stat_rx_total_packets;
    logic stat_rx_truncated;
    logic [2 : 0] stat_rx_undersize;
    logic stat_rx_unicast;
    logic stat_rx_vlan;
    logic [19 : 0] stat_rx_pcsl_demuxed;
    logic [4 : 0] stat_rx_pcsl_number_0;
    logic [4 : 0] stat_rx_pcsl_number_1;
    logic [4 : 0] stat_rx_pcsl_number_10;
    logic [4 : 0] stat_rx_pcsl_number_11;
    logic [4 : 0] stat_rx_pcsl_number_12;
    logic [4 : 0] stat_rx_pcsl_number_13;
    logic [4 : 0] stat_rx_pcsl_number_14;
    logic [4 : 0] stat_rx_pcsl_number_15;
    logic [4 : 0] stat_rx_pcsl_number_16;
    logic [4 : 0] stat_rx_pcsl_number_17;
    logic [4 : 0] stat_rx_pcsl_number_18;
    logic [4 : 0] stat_rx_pcsl_number_19;
    logic [4 : 0] stat_rx_pcsl_number_2;
    logic [4 : 0] stat_rx_pcsl_number_3;
    logic [4 : 0] stat_rx_pcsl_number_4;
    logic [4 : 0] stat_rx_pcsl_number_5;
    logic [4 : 0] stat_rx_pcsl_number_6;
    logic [4 : 0] stat_rx_pcsl_number_7;
    logic [4 : 0] stat_rx_pcsl_number_8;
    logic [4 : 0] stat_rx_pcsl_number_9;
    logic stat_tx_bad_fcs;
    logic stat_tx_broadcast;
    logic stat_tx_frame_error;
    logic stat_tx_local_fault;
    logic stat_tx_multicast;
    logic stat_tx_packet_1024_1518_bytes;
    logic stat_tx_packet_128_255_bytes;
    logic stat_tx_packet_1519_1522_bytes;
    logic stat_tx_packet_1523_1548_bytes;
    logic stat_tx_packet_1549_2047_bytes;
    logic stat_tx_packet_2048_4095_bytes;
    logic stat_tx_packet_256_511_bytes;
    logic stat_tx_packet_4096_8191_bytes;
    logic stat_tx_packet_512_1023_bytes;
    logic stat_tx_packet_64_bytes;
    logic stat_tx_packet_65_127_bytes;
    logic stat_tx_packet_8192_9215_bytes;
    logic stat_tx_packet_large;
    logic stat_tx_packet_small;
    logic [5 : 0] stat_tx_total_bytes;
    logic [13 : 0] stat_tx_total_good_bytes;
    logic stat_tx_total_good_packets;
    logic stat_tx_total_packets;
    logic stat_tx_unicast;
    logic stat_tx_vlan;
    logic ctl_tx_send_idle;
    logic ctl_tx_send_rfi;
    logic ctl_tx_send_lfi;
    logic core_tx_reset;
    logic [8 : 0] stat_tx_pause_valid;
    logic stat_tx_pause;
    logic stat_tx_user_pause;
    logic [8 : 0] ctl_tx_pause_req;
    logic ctl_tx_resend_pause;
    logic tx_axis_tready;
    logic tx_axis_tvalid;
    logic [511 : 0] tx_axis_tdata;
    logic tx_axis_tlast;
    logic [63 : 0] tx_axis_tkeep;
    logic tx_axis_tuser;
    logic tx_ovfout;
    logic tx_unfout;
    logic [55 : 0] tx_preamblein;
    logic usr_tx_reset;
    logic core_drp_reset;
    logic drp_clk;
    logic [9 : 0] drp_addr;
    logic [15 : 0] drp_di;
    logic drp_en;
    logic [15 : 0] drp_do;
    logic drp_rdy;
    logic drp_we;

    // =========================================================================
    // Clocks
    // =========================================================================
    assign gt_ref_clk_p = qsfp_refclk_p; // input wire gt_ref_clk_p
    assign gt_ref_clk_n = qsfp_refclk_n; // input wire gt_ref_clk_n

    assign init_clk = axil_if.aclk;      // input wire init_clk

    assign __cmac_clk = gt_txusrclk2;           // output wire gt_txusrclk2

    assign rx_clk = __cmac_clk;            // input wire rx_clk

    // output wire gt_rxusrclk2
    // output wire gt_ref_clk_out
    // output wire [3 : 0] gt_rxrecclkout

    // =========================================================================
    // Resets
    // =========================================================================
    sync_reset #(
        .INPUT_ACTIVE_HIGH ( 1 )
    ) i_sync_reset__sys_reset (
        .clk_in ( clk ),
        .rst_in ( srst ),
        .clk_out ( __cmac_clk ),
        .rst_out ( sys_reset )
    );

    assign core_rx_reset = 1'b0;           // input wire core_rx_reset
    assign core_tx_reset = 1'b0;           // input wire core_tx_reset

    assign gtwiz_reset_tx_datapath = 1'b0; // input wire gtwiz_reset_tx_datapath
    assign gtwiz_reset_rx_datapath = 1'b0; // input wire gtwiz_reset_rx_datapath

    // output wire usr_rx_reset
    // output wire usr_tx_reset

    // =========================================================================
    // CMAC control
    // =========================================================================
    assign ctl_tx_send_idle = 1'b0;    // input wire ctl_tx_send_idle
    assign ctl_tx_send_rfi = 1'b0;     // input wire ctl_tx_send_rfi
    assign ctl_tx_send_lfi = 1'b0;     // input wire ctl_tx_send_lfi
    assign ctl_tx_pause_req = '0;      // input wire [8 : 0] ctl_tx_pause_req
    assign ctl_tx_resend_pause = 1'b0; // input wire ctl_tx_resend_pause
    assign tx_preamblein = '0;         // input wire [55 : 0] tx_preamblein

    // =========================================================================
    // CMAC status
    // =========================================================================
    // output wire [55 : 0] rx_preambleout
    // output wire tx_ovfout
    // output wire tx_unfout

    // =========================================================================
    // PCS status
    // =========================================================================
    // output wire [19 : 0] stat_rx_block_lock
    // output wire stat_rx_status
    // output wire [19 : 0] stat_rx_synced
    // output wire [19 : 0] stat_rx_synced_err
    // output wire stat_rx_hi_ber
    // output wire stat_rx_internal_local_fault

    // =========================================================================
    // Serial interface
    // =========================================================================
    assign qsfp_txp = gt_txp_out; // output wire [3 : 0] gt_txp_out
    assign qsfp_txn = gt_txn_out; // output wire [3 : 0] gt_txn_out
    assign gt_rxp_in = qsfp_rxp;  // input wire [3 : 0] gt_rxp_in
    assign gt_rxn_in = qsfp_rxn;  // input wire [3 : 0] gt_rxn_in

    // =========================================================================
    // AXI-L register access
    // =========================================================================
    assign s_axi_aclk = axil_if.aclk;       // input wire s_axi_aclk
    assign s_axi_sreset = !axil_if.aresetn;  // input wire s_axi_sreset
    assign s_axi_awaddr = axil_if.awaddr;   // input wire [31 : 0] s_axi_awaddr
    assign s_axi_awvalid = axil_if.awvalid; // input wire s_axi_awvalid
    assign axil_if.awready = s_axi_awready; // output wire s_axi_awready
    assign s_axi_wdata = axil_if.wdata;     // input wire [31 : 0] s_axi_wdata
    assign s_axi_wstrb = axil_if.wstrb;     // input wire [3 : 0] s_axi_wstrb
    assign s_axi_wvalid = axil_if.wvalid;   // input wire s_axi_wvalid
    assign axil_if.wready = s_axi_wready;   // output wire s_axi_wready
    assign axil_if.bresp = s_axi_bresp;     // output wire [1 : 0] s_axi_bresp
    assign axil_if.bvalid = s_axi_bvalid;   // output wire s_axi_bvalid
    assign s_axi_bready = axil_if.bready;   // input wire s_axi_bready
    assign s_axi_araddr = axil_if.araddr;   // input wire [31 : 0] s_axi_araddr
    assign s_axi_arvalid = axil_if.arvalid; // input wire s_axi_arvalid
    assign axil_if.arready = s_axi_arready; // output wire s_axi_arready
    assign axil_if.rdata = s_axi_rdata;     // output wire [31 : 0] s_axi_rdata
    assign axil_if.rresp = s_axi_rresp;     // output wire [1 : 0] s_axi_rresp
    assign axil_if.rvalid = s_axi_rvalid;   // output wire s_axi_rvalid
    assign s_axi_rready = axil_if.rready;   // input wire s_axi_rready

    assign pm_tick = 1'b0;                  // input wire pm_tick

    // =========================================================================
    // AXI-S Rx
    // =========================================================================
    // (Local) signals
    axis_tuser_t __axis_rx_tuser;
    axis_tid_t   __axis_rx_tid;

    assign axis_rx.aclk = __cmac_clk;
    assign axis_rx.aresetn = ~sys_reset;
    assign axis_rx.tvalid = rx_axis_tvalid;     // output wire rx_axis_tvalid
    assign axis_rx.tdata = rx_axis_tdata;       // output wire [511 : 0] rx_axis_tdata
    assign axis_rx.tlast = rx_axis_tlast;       // output wire rx_axis_tlast
    assign axis_rx.tkeep = rx_axis_tkeep;       // output wire [63 : 0] rx_axis_tkeep
    
    assign __axis_rx_tuser.err = rx_axis_tuser; // output wire rx_axis_tuser
    assign axis_rx.tuser = __axis_rx_tuser;

    assign __axis_rx_tid.port_id = port_id_t'(PORT_ID);
    assign axis_rx.tid = __axis_rx_tid;

    assign axis_rx.tdest = '0;

    // =========================================================================
    // AXI-S Tx
    // =========================================================================
    // (Local) signals
    axis_tuser_t __axis_tx_tuser;

    assign axis_tx.aclk = __cmac_clk;
    assign axis_tx.aresetn = ~sys_reset;
    assign axis_tx.tready = tx_axis_tready;     // output wire tx_axis_tready
    assign tx_axis_tvalid = axis_tx.tvalid;     // input wire tx_axis_tvalid
    assign tx_axis_tdata = axis_tx.tdata;       // input wire [511 : 0] tx_axis_tdata
    assign tx_axis_tlast = axis_tx.tlast;       // input wire tx_axis_tlast
    assign tx_axis_tkeep = axis_tx.tkeep;       // input wire [63 : 0] tx_axis_tkeep

    assign __axis_tx_tuser = axis_tx.tuser;
    assign tx_axis_tuser = __axis_tx_tuser;     // input wire tx_axis_tuser

    // =========================================================================
    // User reg control
    // =========================================================================
    // output wire [31 : 0] user_reg0

    // =========================================================================
    // GT control
    // =========================================================================
    assign gt_loopback_in = '0;

    // =========================================================================
    // GT status
    // =========================================================================
    // output wire [3 : 0] gt_powergoodout

    // =========================================================================
    // GT DRP
    // =========================================================================
    assign core_drp_reset = 1'b0; // input wire core_drp_reset
    assign drp_clk = 1'b0;        // input wire drp_clk
    assign drp_addr = '0;         // input wire [9 : 0] drp_addr
    assign drp_di = '0;           // input wire [15 : 0] drp_di
    assign drp_en = 1'b0;         // input wire drp_en
                                  // output wire [15 : 0] drp_do
                                  // output wire drp_rdy
    assign drp_we = 1'b0;         // input wire drp_we

// CMAC IP instantiation
//
// NOTE: Use instantiation template exactly as provided in IP (including whitespace, but with
//       generic instance name commented out) to enable trivial diffs to simplify upgrades or changes,
//       identify added/removed signals, etc.
//
generate
    if (PORT_ID == 0) begin : g__cmac_0
xilinx_cmac_0 i_xilinx_cmac_0 (
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
//xilinx_cmac_0 your_instance_name (
  .gt_txp_out(gt_txp_out),                                                    // output wire [3 : 0] gt_txp_out
  .gt_txn_out(gt_txn_out),                                                    // output wire [3 : 0] gt_txn_out
  .gt_rxp_in(gt_rxp_in),                                                      // input wire [3 : 0] gt_rxp_in
  .gt_rxn_in(gt_rxn_in),                                                      // input wire [3 : 0] gt_rxn_in
  .gt_txusrclk2(gt_txusrclk2),                                                // output wire gt_txusrclk2
  .gt_loopback_in(gt_loopback_in),                                            // input wire [11 : 0] gt_loopback_in
  .gt_ref_clk_out(gt_ref_clk_out),                                            // output wire gt_ref_clk_out
  .gt_rxrecclkout(gt_rxrecclkout),                                            // output wire [3 : 0] gt_rxrecclkout
  .gt_powergoodout(gt_powergoodout),                                          // output wire [3 : 0] gt_powergoodout
  .gtwiz_reset_tx_datapath(gtwiz_reset_tx_datapath),                          // input wire gtwiz_reset_tx_datapath
  .gtwiz_reset_rx_datapath(gtwiz_reset_rx_datapath),                          // input wire gtwiz_reset_rx_datapath
  .s_axi_aclk(s_axi_aclk),                                                    // input wire s_axi_aclk
  .s_axi_sreset(s_axi_sreset),                                                // input wire s_axi_sreset
  .pm_tick(pm_tick),                                                          // input wire pm_tick
  .s_axi_awaddr(s_axi_awaddr),                                                // input wire [31 : 0] s_axi_awaddr
  .s_axi_awvalid(s_axi_awvalid),                                              // input wire s_axi_awvalid
  .s_axi_awready(s_axi_awready),                                              // output wire s_axi_awready
  .s_axi_wdata(s_axi_wdata),                                                  // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),                                                  // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(s_axi_wvalid),                                                // input wire s_axi_wvalid
  .s_axi_wready(s_axi_wready),                                                // output wire s_axi_wready
  .s_axi_bresp(s_axi_bresp),                                                  // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),                                                // output wire s_axi_bvalid
  .s_axi_bready(s_axi_bready),                                                // input wire s_axi_bready
  .s_axi_araddr(s_axi_araddr),                                                // input wire [31 : 0] s_axi_araddr
  .s_axi_arvalid(s_axi_arvalid),                                              // input wire s_axi_arvalid
  .s_axi_arready(s_axi_arready),                                              // output wire s_axi_arready
  .s_axi_rdata(s_axi_rdata),                                                  // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),                                                  // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(s_axi_rvalid),                                                // output wire s_axi_rvalid
  .s_axi_rready(s_axi_rready),                                                // input wire s_axi_rready
  .stat_rx_rsfec_am_lock0(stat_rx_rsfec_am_lock0),                            // output wire stat_rx_rsfec_am_lock0
  .stat_rx_rsfec_am_lock1(stat_rx_rsfec_am_lock1),                            // output wire stat_rx_rsfec_am_lock1
  .stat_rx_rsfec_am_lock2(stat_rx_rsfec_am_lock2),                            // output wire stat_rx_rsfec_am_lock2
  .stat_rx_rsfec_am_lock3(stat_rx_rsfec_am_lock3),                            // output wire stat_rx_rsfec_am_lock3
  .stat_rx_rsfec_corrected_cw_inc(stat_rx_rsfec_corrected_cw_inc),            // output wire stat_rx_rsfec_corrected_cw_inc
  .stat_rx_rsfec_cw_inc(stat_rx_rsfec_cw_inc),                                // output wire stat_rx_rsfec_cw_inc
  .stat_rx_rsfec_err_count0_inc(stat_rx_rsfec_err_count0_inc),                // output wire [2 : 0] stat_rx_rsfec_err_count0_inc
  .stat_rx_rsfec_err_count1_inc(stat_rx_rsfec_err_count1_inc),                // output wire [2 : 0] stat_rx_rsfec_err_count1_inc
  .stat_rx_rsfec_err_count2_inc(stat_rx_rsfec_err_count2_inc),                // output wire [2 : 0] stat_rx_rsfec_err_count2_inc
  .stat_rx_rsfec_err_count3_inc(stat_rx_rsfec_err_count3_inc),                // output wire [2 : 0] stat_rx_rsfec_err_count3_inc
  .stat_rx_rsfec_hi_ser(stat_rx_rsfec_hi_ser),                                // output wire stat_rx_rsfec_hi_ser
  .stat_rx_rsfec_lane_alignment_status(stat_rx_rsfec_lane_alignment_status),  // output wire stat_rx_rsfec_lane_alignment_status
  .stat_rx_rsfec_lane_fill_0(stat_rx_rsfec_lane_fill_0),                      // output wire [13 : 0] stat_rx_rsfec_lane_fill_0
  .stat_rx_rsfec_lane_fill_1(stat_rx_rsfec_lane_fill_1),                      // output wire [13 : 0] stat_rx_rsfec_lane_fill_1
  .stat_rx_rsfec_lane_fill_2(stat_rx_rsfec_lane_fill_2),                      // output wire [13 : 0] stat_rx_rsfec_lane_fill_2
  .stat_rx_rsfec_lane_fill_3(stat_rx_rsfec_lane_fill_3),                      // output wire [13 : 0] stat_rx_rsfec_lane_fill_3
  .stat_rx_rsfec_lane_mapping(stat_rx_rsfec_lane_mapping),                    // output wire [7 : 0] stat_rx_rsfec_lane_mapping
  .stat_rx_rsfec_uncorrected_cw_inc(stat_rx_rsfec_uncorrected_cw_inc),        // output wire stat_rx_rsfec_uncorrected_cw_inc
  .user_reg0(user_reg0),                                                      // output wire [31 : 0] user_reg0
  .sys_reset(sys_reset),                                                      // input wire sys_reset
  .gt_ref_clk_p(gt_ref_clk_p),                                                // input wire gt_ref_clk_p
  .gt_ref_clk_n(gt_ref_clk_n),                                                // input wire gt_ref_clk_n
  .init_clk(init_clk),                                                        // input wire init_clk
  .rx_axis_tvalid(rx_axis_tvalid),                                            // output wire rx_axis_tvalid
  .rx_axis_tdata(rx_axis_tdata),                                              // output wire [511 : 0] rx_axis_tdata
  .rx_axis_tlast(rx_axis_tlast),                                              // output wire rx_axis_tlast
  .rx_axis_tkeep(rx_axis_tkeep),                                              // output wire [63 : 0] rx_axis_tkeep
  .rx_axis_tuser(rx_axis_tuser),                                              // output wire rx_axis_tuser
  .rx_otn_bip8_0(rx_otn_bip8_0),                                              // output wire [7 : 0] rx_otn_bip8_0
  .rx_otn_bip8_1(rx_otn_bip8_1),                                              // output wire [7 : 0] rx_otn_bip8_1
  .rx_otn_bip8_2(rx_otn_bip8_2),                                              // output wire [7 : 0] rx_otn_bip8_2
  .rx_otn_bip8_3(rx_otn_bip8_3),                                              // output wire [7 : 0] rx_otn_bip8_3
  .rx_otn_bip8_4(rx_otn_bip8_4),                                              // output wire [7 : 0] rx_otn_bip8_4
  .rx_otn_data_0(rx_otn_data_0),                                              // output wire [65 : 0] rx_otn_data_0
  .rx_otn_data_1(rx_otn_data_1),                                              // output wire [65 : 0] rx_otn_data_1
  .rx_otn_data_2(rx_otn_data_2),                                              // output wire [65 : 0] rx_otn_data_2
  .rx_otn_data_3(rx_otn_data_3),                                              // output wire [65 : 0] rx_otn_data_3
  .rx_otn_data_4(rx_otn_data_4),                                              // output wire [65 : 0] rx_otn_data_4
  .rx_otn_ena(rx_otn_ena),                                                    // output wire rx_otn_ena
  .rx_otn_lane0(rx_otn_lane0),                                                // output wire rx_otn_lane0
  .rx_otn_vlmarker(rx_otn_vlmarker),                                          // output wire rx_otn_vlmarker
  .rx_preambleout(rx_preambleout),                                            // output wire [55 : 0] rx_preambleout
  .usr_rx_reset(usr_rx_reset),                                                // output wire usr_rx_reset
  .gt_rxusrclk2(gt_rxusrclk2),                                                // output wire gt_rxusrclk2
  .stat_rx_aligned(stat_rx_aligned),                                          // output wire stat_rx_aligned
  .stat_rx_aligned_err(stat_rx_aligned_err),                                  // output wire stat_rx_aligned_err
  .stat_rx_bad_code(stat_rx_bad_code),                                        // output wire [2 : 0] stat_rx_bad_code
  .stat_rx_bad_fcs(stat_rx_bad_fcs),                                          // output wire [2 : 0] stat_rx_bad_fcs
  .stat_rx_bad_preamble(stat_rx_bad_preamble),                                // output wire stat_rx_bad_preamble
  .stat_rx_bad_sfd(stat_rx_bad_sfd),                                          // output wire stat_rx_bad_sfd
  .stat_rx_bip_err_0(stat_rx_bip_err_0),                                      // output wire stat_rx_bip_err_0
  .stat_rx_bip_err_1(stat_rx_bip_err_1),                                      // output wire stat_rx_bip_err_1
  .stat_rx_bip_err_10(stat_rx_bip_err_10),                                    // output wire stat_rx_bip_err_10
  .stat_rx_bip_err_11(stat_rx_bip_err_11),                                    // output wire stat_rx_bip_err_11
  .stat_rx_bip_err_12(stat_rx_bip_err_12),                                    // output wire stat_rx_bip_err_12
  .stat_rx_bip_err_13(stat_rx_bip_err_13),                                    // output wire stat_rx_bip_err_13
  .stat_rx_bip_err_14(stat_rx_bip_err_14),                                    // output wire stat_rx_bip_err_14
  .stat_rx_bip_err_15(stat_rx_bip_err_15),                                    // output wire stat_rx_bip_err_15
  .stat_rx_bip_err_16(stat_rx_bip_err_16),                                    // output wire stat_rx_bip_err_16
  .stat_rx_bip_err_17(stat_rx_bip_err_17),                                    // output wire stat_rx_bip_err_17
  .stat_rx_bip_err_18(stat_rx_bip_err_18),                                    // output wire stat_rx_bip_err_18
  .stat_rx_bip_err_19(stat_rx_bip_err_19),                                    // output wire stat_rx_bip_err_19
  .stat_rx_bip_err_2(stat_rx_bip_err_2),                                      // output wire stat_rx_bip_err_2
  .stat_rx_bip_err_3(stat_rx_bip_err_3),                                      // output wire stat_rx_bip_err_3
  .stat_rx_bip_err_4(stat_rx_bip_err_4),                                      // output wire stat_rx_bip_err_4
  .stat_rx_bip_err_5(stat_rx_bip_err_5),                                      // output wire stat_rx_bip_err_5
  .stat_rx_bip_err_6(stat_rx_bip_err_6),                                      // output wire stat_rx_bip_err_6
  .stat_rx_bip_err_7(stat_rx_bip_err_7),                                      // output wire stat_rx_bip_err_7
  .stat_rx_bip_err_8(stat_rx_bip_err_8),                                      // output wire stat_rx_bip_err_8
  .stat_rx_bip_err_9(stat_rx_bip_err_9),                                      // output wire stat_rx_bip_err_9
  .stat_rx_block_lock(stat_rx_block_lock),                                    // output wire [19 : 0] stat_rx_block_lock
  .stat_rx_broadcast(stat_rx_broadcast),                                      // output wire stat_rx_broadcast
  .stat_rx_fragment(stat_rx_fragment),                                        // output wire [2 : 0] stat_rx_fragment
  .stat_rx_framing_err_0(stat_rx_framing_err_0),                              // output wire [1 : 0] stat_rx_framing_err_0
  .stat_rx_framing_err_1(stat_rx_framing_err_1),                              // output wire [1 : 0] stat_rx_framing_err_1
  .stat_rx_framing_err_10(stat_rx_framing_err_10),                            // output wire [1 : 0] stat_rx_framing_err_10
  .stat_rx_framing_err_11(stat_rx_framing_err_11),                            // output wire [1 : 0] stat_rx_framing_err_11
  .stat_rx_framing_err_12(stat_rx_framing_err_12),                            // output wire [1 : 0] stat_rx_framing_err_12
  .stat_rx_framing_err_13(stat_rx_framing_err_13),                            // output wire [1 : 0] stat_rx_framing_err_13
  .stat_rx_framing_err_14(stat_rx_framing_err_14),                            // output wire [1 : 0] stat_rx_framing_err_14
  .stat_rx_framing_err_15(stat_rx_framing_err_15),                            // output wire [1 : 0] stat_rx_framing_err_15
  .stat_rx_framing_err_16(stat_rx_framing_err_16),                            // output wire [1 : 0] stat_rx_framing_err_16
  .stat_rx_framing_err_17(stat_rx_framing_err_17),                            // output wire [1 : 0] stat_rx_framing_err_17
  .stat_rx_framing_err_18(stat_rx_framing_err_18),                            // output wire [1 : 0] stat_rx_framing_err_18
  .stat_rx_framing_err_19(stat_rx_framing_err_19),                            // output wire [1 : 0] stat_rx_framing_err_19
  .stat_rx_framing_err_2(stat_rx_framing_err_2),                              // output wire [1 : 0] stat_rx_framing_err_2
  .stat_rx_framing_err_3(stat_rx_framing_err_3),                              // output wire [1 : 0] stat_rx_framing_err_3
  .stat_rx_framing_err_4(stat_rx_framing_err_4),                              // output wire [1 : 0] stat_rx_framing_err_4
  .stat_rx_framing_err_5(stat_rx_framing_err_5),                              // output wire [1 : 0] stat_rx_framing_err_5
  .stat_rx_framing_err_6(stat_rx_framing_err_6),                              // output wire [1 : 0] stat_rx_framing_err_6
  .stat_rx_framing_err_7(stat_rx_framing_err_7),                              // output wire [1 : 0] stat_rx_framing_err_7
  .stat_rx_framing_err_8(stat_rx_framing_err_8),                              // output wire [1 : 0] stat_rx_framing_err_8
  .stat_rx_framing_err_9(stat_rx_framing_err_9),                              // output wire [1 : 0] stat_rx_framing_err_9
  .stat_rx_framing_err_valid_0(stat_rx_framing_err_valid_0),                  // output wire stat_rx_framing_err_valid_0
  .stat_rx_framing_err_valid_1(stat_rx_framing_err_valid_1),                  // output wire stat_rx_framing_err_valid_1
  .stat_rx_framing_err_valid_10(stat_rx_framing_err_valid_10),                // output wire stat_rx_framing_err_valid_10
  .stat_rx_framing_err_valid_11(stat_rx_framing_err_valid_11),                // output wire stat_rx_framing_err_valid_11
  .stat_rx_framing_err_valid_12(stat_rx_framing_err_valid_12),                // output wire stat_rx_framing_err_valid_12
  .stat_rx_framing_err_valid_13(stat_rx_framing_err_valid_13),                // output wire stat_rx_framing_err_valid_13
  .stat_rx_framing_err_valid_14(stat_rx_framing_err_valid_14),                // output wire stat_rx_framing_err_valid_14
  .stat_rx_framing_err_valid_15(stat_rx_framing_err_valid_15),                // output wire stat_rx_framing_err_valid_15
  .stat_rx_framing_err_valid_16(stat_rx_framing_err_valid_16),                // output wire stat_rx_framing_err_valid_16
  .stat_rx_framing_err_valid_17(stat_rx_framing_err_valid_17),                // output wire stat_rx_framing_err_valid_17
  .stat_rx_framing_err_valid_18(stat_rx_framing_err_valid_18),                // output wire stat_rx_framing_err_valid_18
  .stat_rx_framing_err_valid_19(stat_rx_framing_err_valid_19),                // output wire stat_rx_framing_err_valid_19
  .stat_rx_framing_err_valid_2(stat_rx_framing_err_valid_2),                  // output wire stat_rx_framing_err_valid_2
  .stat_rx_framing_err_valid_3(stat_rx_framing_err_valid_3),                  // output wire stat_rx_framing_err_valid_3
  .stat_rx_framing_err_valid_4(stat_rx_framing_err_valid_4),                  // output wire stat_rx_framing_err_valid_4
  .stat_rx_framing_err_valid_5(stat_rx_framing_err_valid_5),                  // output wire stat_rx_framing_err_valid_5
  .stat_rx_framing_err_valid_6(stat_rx_framing_err_valid_6),                  // output wire stat_rx_framing_err_valid_6
  .stat_rx_framing_err_valid_7(stat_rx_framing_err_valid_7),                  // output wire stat_rx_framing_err_valid_7
  .stat_rx_framing_err_valid_8(stat_rx_framing_err_valid_8),                  // output wire stat_rx_framing_err_valid_8
  .stat_rx_framing_err_valid_9(stat_rx_framing_err_valid_9),                  // output wire stat_rx_framing_err_valid_9
  .stat_rx_got_signal_os(stat_rx_got_signal_os),                              // output wire stat_rx_got_signal_os
  .stat_rx_hi_ber(stat_rx_hi_ber),                                            // output wire stat_rx_hi_ber
  .stat_rx_inrangeerr(stat_rx_inrangeerr),                                    // output wire stat_rx_inrangeerr
  .stat_rx_internal_local_fault(stat_rx_internal_local_fault),                // output wire stat_rx_internal_local_fault
  .stat_rx_jabber(stat_rx_jabber),                                            // output wire stat_rx_jabber
  .stat_rx_local_fault(stat_rx_local_fault),                                  // output wire stat_rx_local_fault
  .stat_rx_mf_err(stat_rx_mf_err),                                            // output wire [19 : 0] stat_rx_mf_err
  .stat_rx_mf_len_err(stat_rx_mf_len_err),                                    // output wire [19 : 0] stat_rx_mf_len_err
  .stat_rx_mf_repeat_err(stat_rx_mf_repeat_err),                              // output wire [19 : 0] stat_rx_mf_repeat_err
  .stat_rx_misaligned(stat_rx_misaligned),                                    // output wire stat_rx_misaligned
  .stat_rx_multicast(stat_rx_multicast),                                      // output wire stat_rx_multicast
  .stat_rx_oversize(stat_rx_oversize),                                        // output wire stat_rx_oversize
  .stat_rx_packet_1024_1518_bytes(stat_rx_packet_1024_1518_bytes),            // output wire stat_rx_packet_1024_1518_bytes
  .stat_rx_packet_128_255_bytes(stat_rx_packet_128_255_bytes),                // output wire stat_rx_packet_128_255_bytes
  .stat_rx_packet_1519_1522_bytes(stat_rx_packet_1519_1522_bytes),            // output wire stat_rx_packet_1519_1522_bytes
  .stat_rx_packet_1523_1548_bytes(stat_rx_packet_1523_1548_bytes),            // output wire stat_rx_packet_1523_1548_bytes
  .stat_rx_packet_1549_2047_bytes(stat_rx_packet_1549_2047_bytes),            // output wire stat_rx_packet_1549_2047_bytes
  .stat_rx_packet_2048_4095_bytes(stat_rx_packet_2048_4095_bytes),            // output wire stat_rx_packet_2048_4095_bytes
  .stat_rx_packet_256_511_bytes(stat_rx_packet_256_511_bytes),                // output wire stat_rx_packet_256_511_bytes
  .stat_rx_packet_4096_8191_bytes(stat_rx_packet_4096_8191_bytes),            // output wire stat_rx_packet_4096_8191_bytes
  .stat_rx_packet_512_1023_bytes(stat_rx_packet_512_1023_bytes),              // output wire stat_rx_packet_512_1023_bytes
  .stat_rx_packet_64_bytes(stat_rx_packet_64_bytes),                          // output wire stat_rx_packet_64_bytes
  .stat_rx_packet_65_127_bytes(stat_rx_packet_65_127_bytes),                  // output wire stat_rx_packet_65_127_bytes
  .stat_rx_packet_8192_9215_bytes(stat_rx_packet_8192_9215_bytes),            // output wire stat_rx_packet_8192_9215_bytes
  .stat_rx_packet_bad_fcs(stat_rx_packet_bad_fcs),                            // output wire stat_rx_packet_bad_fcs
  .stat_rx_packet_large(stat_rx_packet_large),                                // output wire stat_rx_packet_large
  .stat_rx_packet_small(stat_rx_packet_small),                                // output wire [2 : 0] stat_rx_packet_small
  .stat_rx_pause(stat_rx_pause),                                              // output wire stat_rx_pause
  .stat_rx_pause_quanta0(stat_rx_pause_quanta0),                              // output wire [15 : 0] stat_rx_pause_quanta0
  .stat_rx_pause_quanta1(stat_rx_pause_quanta1),                              // output wire [15 : 0] stat_rx_pause_quanta1
  .stat_rx_pause_quanta2(stat_rx_pause_quanta2),                              // output wire [15 : 0] stat_rx_pause_quanta2
  .stat_rx_pause_quanta3(stat_rx_pause_quanta3),                              // output wire [15 : 0] stat_rx_pause_quanta3
  .stat_rx_pause_quanta4(stat_rx_pause_quanta4),                              // output wire [15 : 0] stat_rx_pause_quanta4
  .stat_rx_pause_quanta5(stat_rx_pause_quanta5),                              // output wire [15 : 0] stat_rx_pause_quanta5
  .stat_rx_pause_quanta6(stat_rx_pause_quanta6),                              // output wire [15 : 0] stat_rx_pause_quanta6
  .stat_rx_pause_quanta7(stat_rx_pause_quanta7),                              // output wire [15 : 0] stat_rx_pause_quanta7
  .stat_rx_pause_quanta8(stat_rx_pause_quanta8),                              // output wire [15 : 0] stat_rx_pause_quanta8
  .stat_rx_pause_req(stat_rx_pause_req),                                      // output wire [8 : 0] stat_rx_pause_req
  .stat_rx_pause_valid(stat_rx_pause_valid),                                  // output wire [8 : 0] stat_rx_pause_valid
  .stat_rx_user_pause(stat_rx_user_pause),                                    // output wire stat_rx_user_pause
  .core_rx_reset(core_rx_reset),                                              // input wire core_rx_reset
  .rx_clk(rx_clk),                                                            // input wire rx_clk
  .stat_rx_received_local_fault(stat_rx_received_local_fault),                // output wire stat_rx_received_local_fault
  .stat_rx_remote_fault(stat_rx_remote_fault),                                // output wire stat_rx_remote_fault
  .stat_rx_status(stat_rx_status),                                            // output wire stat_rx_status
  .stat_rx_stomped_fcs(stat_rx_stomped_fcs),                                  // output wire [2 : 0] stat_rx_stomped_fcs
  .stat_rx_synced(stat_rx_synced),                                            // output wire [19 : 0] stat_rx_synced
  .stat_rx_synced_err(stat_rx_synced_err),                                    // output wire [19 : 0] stat_rx_synced_err
  .stat_rx_test_pattern_mismatch(stat_rx_test_pattern_mismatch),              // output wire [2 : 0] stat_rx_test_pattern_mismatch
  .stat_rx_toolong(stat_rx_toolong),                                          // output wire stat_rx_toolong
  .stat_rx_total_bytes(stat_rx_total_bytes),                                  // output wire [6 : 0] stat_rx_total_bytes
  .stat_rx_total_good_bytes(stat_rx_total_good_bytes),                        // output wire [13 : 0] stat_rx_total_good_bytes
  .stat_rx_total_good_packets(stat_rx_total_good_packets),                    // output wire stat_rx_total_good_packets
  .stat_rx_total_packets(stat_rx_total_packets),                              // output wire [2 : 0] stat_rx_total_packets
  .stat_rx_truncated(stat_rx_truncated),                                      // output wire stat_rx_truncated
  .stat_rx_undersize(stat_rx_undersize),                                      // output wire [2 : 0] stat_rx_undersize
  .stat_rx_unicast(stat_rx_unicast),                                          // output wire stat_rx_unicast
  .stat_rx_vlan(stat_rx_vlan),                                                // output wire stat_rx_vlan
  .stat_rx_pcsl_demuxed(stat_rx_pcsl_demuxed),                                // output wire [19 : 0] stat_rx_pcsl_demuxed
  .stat_rx_pcsl_number_0(stat_rx_pcsl_number_0),                              // output wire [4 : 0] stat_rx_pcsl_number_0
  .stat_rx_pcsl_number_1(stat_rx_pcsl_number_1),                              // output wire [4 : 0] stat_rx_pcsl_number_1
  .stat_rx_pcsl_number_10(stat_rx_pcsl_number_10),                            // output wire [4 : 0] stat_rx_pcsl_number_10
  .stat_rx_pcsl_number_11(stat_rx_pcsl_number_11),                            // output wire [4 : 0] stat_rx_pcsl_number_11
  .stat_rx_pcsl_number_12(stat_rx_pcsl_number_12),                            // output wire [4 : 0] stat_rx_pcsl_number_12
  .stat_rx_pcsl_number_13(stat_rx_pcsl_number_13),                            // output wire [4 : 0] stat_rx_pcsl_number_13
  .stat_rx_pcsl_number_14(stat_rx_pcsl_number_14),                            // output wire [4 : 0] stat_rx_pcsl_number_14
  .stat_rx_pcsl_number_15(stat_rx_pcsl_number_15),                            // output wire [4 : 0] stat_rx_pcsl_number_15
  .stat_rx_pcsl_number_16(stat_rx_pcsl_number_16),                            // output wire [4 : 0] stat_rx_pcsl_number_16
  .stat_rx_pcsl_number_17(stat_rx_pcsl_number_17),                            // output wire [4 : 0] stat_rx_pcsl_number_17
  .stat_rx_pcsl_number_18(stat_rx_pcsl_number_18),                            // output wire [4 : 0] stat_rx_pcsl_number_18
  .stat_rx_pcsl_number_19(stat_rx_pcsl_number_19),                            // output wire [4 : 0] stat_rx_pcsl_number_19
  .stat_rx_pcsl_number_2(stat_rx_pcsl_number_2),                              // output wire [4 : 0] stat_rx_pcsl_number_2
  .stat_rx_pcsl_number_3(stat_rx_pcsl_number_3),                              // output wire [4 : 0] stat_rx_pcsl_number_3
  .stat_rx_pcsl_number_4(stat_rx_pcsl_number_4),                              // output wire [4 : 0] stat_rx_pcsl_number_4
  .stat_rx_pcsl_number_5(stat_rx_pcsl_number_5),                              // output wire [4 : 0] stat_rx_pcsl_number_5
  .stat_rx_pcsl_number_6(stat_rx_pcsl_number_6),                              // output wire [4 : 0] stat_rx_pcsl_number_6
  .stat_rx_pcsl_number_7(stat_rx_pcsl_number_7),                              // output wire [4 : 0] stat_rx_pcsl_number_7
  .stat_rx_pcsl_number_8(stat_rx_pcsl_number_8),                              // output wire [4 : 0] stat_rx_pcsl_number_8
  .stat_rx_pcsl_number_9(stat_rx_pcsl_number_9),                              // output wire [4 : 0] stat_rx_pcsl_number_9
  .stat_tx_bad_fcs(stat_tx_bad_fcs),                                          // output wire stat_tx_bad_fcs
  .stat_tx_broadcast(stat_tx_broadcast),                                      // output wire stat_tx_broadcast
  .stat_tx_frame_error(stat_tx_frame_error),                                  // output wire stat_tx_frame_error
  .stat_tx_local_fault(stat_tx_local_fault),                                  // output wire stat_tx_local_fault
  .stat_tx_multicast(stat_tx_multicast),                                      // output wire stat_tx_multicast
  .stat_tx_packet_1024_1518_bytes(stat_tx_packet_1024_1518_bytes),            // output wire stat_tx_packet_1024_1518_bytes
  .stat_tx_packet_128_255_bytes(stat_tx_packet_128_255_bytes),                // output wire stat_tx_packet_128_255_bytes
  .stat_tx_packet_1519_1522_bytes(stat_tx_packet_1519_1522_bytes),            // output wire stat_tx_packet_1519_1522_bytes
  .stat_tx_packet_1523_1548_bytes(stat_tx_packet_1523_1548_bytes),            // output wire stat_tx_packet_1523_1548_bytes
  .stat_tx_packet_1549_2047_bytes(stat_tx_packet_1549_2047_bytes),            // output wire stat_tx_packet_1549_2047_bytes
  .stat_tx_packet_2048_4095_bytes(stat_tx_packet_2048_4095_bytes),            // output wire stat_tx_packet_2048_4095_bytes
  .stat_tx_packet_256_511_bytes(stat_tx_packet_256_511_bytes),                // output wire stat_tx_packet_256_511_bytes
  .stat_tx_packet_4096_8191_bytes(stat_tx_packet_4096_8191_bytes),            // output wire stat_tx_packet_4096_8191_bytes
  .stat_tx_packet_512_1023_bytes(stat_tx_packet_512_1023_bytes),              // output wire stat_tx_packet_512_1023_bytes
  .stat_tx_packet_64_bytes(stat_tx_packet_64_bytes),                          // output wire stat_tx_packet_64_bytes
  .stat_tx_packet_65_127_bytes(stat_tx_packet_65_127_bytes),                  // output wire stat_tx_packet_65_127_bytes
  .stat_tx_packet_8192_9215_bytes(stat_tx_packet_8192_9215_bytes),            // output wire stat_tx_packet_8192_9215_bytes
  .stat_tx_packet_large(stat_tx_packet_large),                                // output wire stat_tx_packet_large
  .stat_tx_packet_small(stat_tx_packet_small),                                // output wire stat_tx_packet_small
  .stat_tx_total_bytes(stat_tx_total_bytes),                                  // output wire [5 : 0] stat_tx_total_bytes
  .stat_tx_total_good_bytes(stat_tx_total_good_bytes),                        // output wire [13 : 0] stat_tx_total_good_bytes
  .stat_tx_total_good_packets(stat_tx_total_good_packets),                    // output wire stat_tx_total_good_packets
  .stat_tx_total_packets(stat_tx_total_packets),                              // output wire stat_tx_total_packets
  .stat_tx_unicast(stat_tx_unicast),                                          // output wire stat_tx_unicast
  .stat_tx_vlan(stat_tx_vlan),                                                // output wire stat_tx_vlan
  .ctl_tx_send_idle(ctl_tx_send_idle),                                        // input wire ctl_tx_send_idle
  .ctl_tx_send_rfi(ctl_tx_send_rfi),                                          // input wire ctl_tx_send_rfi
  .ctl_tx_send_lfi(ctl_tx_send_lfi),                                          // input wire ctl_tx_send_lfi
  .core_tx_reset(core_tx_reset),                                              // input wire core_tx_reset
  .stat_tx_pause_valid(stat_tx_pause_valid),                                  // output wire [8 : 0] stat_tx_pause_valid
  .stat_tx_pause(stat_tx_pause),                                              // output wire stat_tx_pause
  .stat_tx_user_pause(stat_tx_user_pause),                                    // output wire stat_tx_user_pause
  .ctl_tx_pause_req(ctl_tx_pause_req),                                        // input wire [8 : 0] ctl_tx_pause_req
  .ctl_tx_resend_pause(ctl_tx_resend_pause),                                  // input wire ctl_tx_resend_pause
  .tx_axis_tready(tx_axis_tready),                                            // output wire tx_axis_tready
  .tx_axis_tvalid(tx_axis_tvalid),                                            // input wire tx_axis_tvalid
  .tx_axis_tdata(tx_axis_tdata),                                              // input wire [511 : 0] tx_axis_tdata
  .tx_axis_tlast(tx_axis_tlast),                                              // input wire tx_axis_tlast
  .tx_axis_tkeep(tx_axis_tkeep),                                              // input wire [63 : 0] tx_axis_tkeep
  .tx_axis_tuser(tx_axis_tuser),                                              // input wire tx_axis_tuser
  .tx_ovfout(tx_ovfout),                                                      // output wire tx_ovfout
  .tx_unfout(tx_unfout),                                                      // output wire tx_unfout
  .tx_preamblein(tx_preamblein),                                              // input wire [55 : 0] tx_preamblein
  .usr_tx_reset(usr_tx_reset),                                                // output wire usr_tx_reset
  .core_drp_reset(core_drp_reset),                                            // input wire core_drp_reset
  .drp_clk(drp_clk),                                                          // input wire drp_clk
  .drp_addr(drp_addr),                                                        // input wire [9 : 0] drp_addr
  .drp_di(drp_di),                                                            // input wire [15 : 0] drp_di
  .drp_en(drp_en),                                                            // input wire drp_en
  .drp_do(drp_do),                                                            // output wire [15 : 0] drp_do
  .drp_rdy(drp_rdy),                                                          // output wire drp_rdy
  .drp_we(drp_we)                                                            // input wire drp_we
);
// INST_TAG_END ------ End INSTANTIATION Template ---------
    end : g__cmac_0
    else if (PORT_ID == 1) begin : g__cmac_1
xilinx_cmac_1 i_xilinx_cmac_1 (
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
//xilinx_cmac_1 your_instance_name (
  .gt_txp_out(gt_txp_out),                                                    // output wire [3 : 0] gt_txp_out
  .gt_txn_out(gt_txn_out),                                                    // output wire [3 : 0] gt_txn_out
  .gt_rxp_in(gt_rxp_in),                                                      // input wire [3 : 0] gt_rxp_in
  .gt_rxn_in(gt_rxn_in),                                                      // input wire [3 : 0] gt_rxn_in
  .gt_txusrclk2(gt_txusrclk2),                                                // output wire gt_txusrclk2
  .gt_loopback_in(gt_loopback_in),                                            // input wire [11 : 0] gt_loopback_in
  .gt_ref_clk_out(gt_ref_clk_out),                                            // output wire gt_ref_clk_out
  .gt_rxrecclkout(gt_rxrecclkout),                                            // output wire [3 : 0] gt_rxrecclkout
  .gt_powergoodout(gt_powergoodout),                                          // output wire [3 : 0] gt_powergoodout
  .gtwiz_reset_tx_datapath(gtwiz_reset_tx_datapath),                          // input wire gtwiz_reset_tx_datapath
  .gtwiz_reset_rx_datapath(gtwiz_reset_rx_datapath),                          // input wire gtwiz_reset_rx_datapath
  .s_axi_aclk(s_axi_aclk),                                                    // input wire s_axi_aclk
  .s_axi_sreset(s_axi_sreset),                                                // input wire s_axi_sreset
  .pm_tick(pm_tick),                                                          // input wire pm_tick
  .s_axi_awaddr(s_axi_awaddr),                                                // input wire [31 : 0] s_axi_awaddr
  .s_axi_awvalid(s_axi_awvalid),                                              // input wire s_axi_awvalid
  .s_axi_awready(s_axi_awready),                                              // output wire s_axi_awready
  .s_axi_wdata(s_axi_wdata),                                                  // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),                                                  // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(s_axi_wvalid),                                                // input wire s_axi_wvalid
  .s_axi_wready(s_axi_wready),                                                // output wire s_axi_wready
  .s_axi_bresp(s_axi_bresp),                                                  // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),                                                // output wire s_axi_bvalid
  .s_axi_bready(s_axi_bready),                                                // input wire s_axi_bready
  .s_axi_araddr(s_axi_araddr),                                                // input wire [31 : 0] s_axi_araddr
  .s_axi_arvalid(s_axi_arvalid),                                              // input wire s_axi_arvalid
  .s_axi_arready(s_axi_arready),                                              // output wire s_axi_arready
  .s_axi_rdata(s_axi_rdata),                                                  // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),                                                  // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(s_axi_rvalid),                                                // output wire s_axi_rvalid
  .s_axi_rready(s_axi_rready),                                                // input wire s_axi_rready
  .stat_rx_rsfec_am_lock0(stat_rx_rsfec_am_lock0),                            // output wire stat_rx_rsfec_am_lock0
  .stat_rx_rsfec_am_lock1(stat_rx_rsfec_am_lock1),                            // output wire stat_rx_rsfec_am_lock1
  .stat_rx_rsfec_am_lock2(stat_rx_rsfec_am_lock2),                            // output wire stat_rx_rsfec_am_lock2
  .stat_rx_rsfec_am_lock3(stat_rx_rsfec_am_lock3),                            // output wire stat_rx_rsfec_am_lock3
  .stat_rx_rsfec_corrected_cw_inc(stat_rx_rsfec_corrected_cw_inc),            // output wire stat_rx_rsfec_corrected_cw_inc
  .stat_rx_rsfec_cw_inc(stat_rx_rsfec_cw_inc),                                // output wire stat_rx_rsfec_cw_inc
  .stat_rx_rsfec_err_count0_inc(stat_rx_rsfec_err_count0_inc),                // output wire [2 : 0] stat_rx_rsfec_err_count0_inc
  .stat_rx_rsfec_err_count1_inc(stat_rx_rsfec_err_count1_inc),                // output wire [2 : 0] stat_rx_rsfec_err_count1_inc
  .stat_rx_rsfec_err_count2_inc(stat_rx_rsfec_err_count2_inc),                // output wire [2 : 0] stat_rx_rsfec_err_count2_inc
  .stat_rx_rsfec_err_count3_inc(stat_rx_rsfec_err_count3_inc),                // output wire [2 : 0] stat_rx_rsfec_err_count3_inc
  .stat_rx_rsfec_hi_ser(stat_rx_rsfec_hi_ser),                                // output wire stat_rx_rsfec_hi_ser
  .stat_rx_rsfec_lane_alignment_status(stat_rx_rsfec_lane_alignment_status),  // output wire stat_rx_rsfec_lane_alignment_status
  .stat_rx_rsfec_lane_fill_0(stat_rx_rsfec_lane_fill_0),                      // output wire [13 : 0] stat_rx_rsfec_lane_fill_0
  .stat_rx_rsfec_lane_fill_1(stat_rx_rsfec_lane_fill_1),                      // output wire [13 : 0] stat_rx_rsfec_lane_fill_1
  .stat_rx_rsfec_lane_fill_2(stat_rx_rsfec_lane_fill_2),                      // output wire [13 : 0] stat_rx_rsfec_lane_fill_2
  .stat_rx_rsfec_lane_fill_3(stat_rx_rsfec_lane_fill_3),                      // output wire [13 : 0] stat_rx_rsfec_lane_fill_3
  .stat_rx_rsfec_lane_mapping(stat_rx_rsfec_lane_mapping),                    // output wire [7 : 0] stat_rx_rsfec_lane_mapping
  .stat_rx_rsfec_uncorrected_cw_inc(stat_rx_rsfec_uncorrected_cw_inc),        // output wire stat_rx_rsfec_uncorrected_cw_inc
  .user_reg0(user_reg0),                                                      // output wire [31 : 0] user_reg0
  .sys_reset(sys_reset),                                                      // input wire sys_reset
  .gt_ref_clk_p(gt_ref_clk_p),                                                // input wire gt_ref_clk_p
  .gt_ref_clk_n(gt_ref_clk_n),                                                // input wire gt_ref_clk_n
  .init_clk(init_clk),                                                        // input wire init_clk
  .rx_axis_tvalid(rx_axis_tvalid),                                            // output wire rx_axis_tvalid
  .rx_axis_tdata(rx_axis_tdata),                                              // output wire [511 : 0] rx_axis_tdata
  .rx_axis_tlast(rx_axis_tlast),                                              // output wire rx_axis_tlast
  .rx_axis_tkeep(rx_axis_tkeep),                                              // output wire [63 : 0] rx_axis_tkeep
  .rx_axis_tuser(rx_axis_tuser),                                              // output wire rx_axis_tuser
  .rx_otn_bip8_0(rx_otn_bip8_0),                                              // output wire [7 : 0] rx_otn_bip8_0
  .rx_otn_bip8_1(rx_otn_bip8_1),                                              // output wire [7 : 0] rx_otn_bip8_1
  .rx_otn_bip8_2(rx_otn_bip8_2),                                              // output wire [7 : 0] rx_otn_bip8_2
  .rx_otn_bip8_3(rx_otn_bip8_3),                                              // output wire [7 : 0] rx_otn_bip8_3
  .rx_otn_bip8_4(rx_otn_bip8_4),                                              // output wire [7 : 0] rx_otn_bip8_4
  .rx_otn_data_0(rx_otn_data_0),                                              // output wire [65 : 0] rx_otn_data_0
  .rx_otn_data_1(rx_otn_data_1),                                              // output wire [65 : 0] rx_otn_data_1
  .rx_otn_data_2(rx_otn_data_2),                                              // output wire [65 : 0] rx_otn_data_2
  .rx_otn_data_3(rx_otn_data_3),                                              // output wire [65 : 0] rx_otn_data_3
  .rx_otn_data_4(rx_otn_data_4),                                              // output wire [65 : 0] rx_otn_data_4
  .rx_otn_ena(rx_otn_ena),                                                    // output wire rx_otn_ena
  .rx_otn_lane0(rx_otn_lane0),                                                // output wire rx_otn_lane0
  .rx_otn_vlmarker(rx_otn_vlmarker),                                          // output wire rx_otn_vlmarker
  .rx_preambleout(rx_preambleout),                                            // output wire [55 : 0] rx_preambleout
  .usr_rx_reset(usr_rx_reset),                                                // output wire usr_rx_reset
  .gt_rxusrclk2(gt_rxusrclk2),                                                // output wire gt_rxusrclk2
  .stat_rx_aligned(stat_rx_aligned),                                          // output wire stat_rx_aligned
  .stat_rx_aligned_err(stat_rx_aligned_err),                                  // output wire stat_rx_aligned_err
  .stat_rx_bad_code(stat_rx_bad_code),                                        // output wire [2 : 0] stat_rx_bad_code
  .stat_rx_bad_fcs(stat_rx_bad_fcs),                                          // output wire [2 : 0] stat_rx_bad_fcs
  .stat_rx_bad_preamble(stat_rx_bad_preamble),                                // output wire stat_rx_bad_preamble
  .stat_rx_bad_sfd(stat_rx_bad_sfd),                                          // output wire stat_rx_bad_sfd
  .stat_rx_bip_err_0(stat_rx_bip_err_0),                                      // output wire stat_rx_bip_err_0
  .stat_rx_bip_err_1(stat_rx_bip_err_1),                                      // output wire stat_rx_bip_err_1
  .stat_rx_bip_err_10(stat_rx_bip_err_10),                                    // output wire stat_rx_bip_err_10
  .stat_rx_bip_err_11(stat_rx_bip_err_11),                                    // output wire stat_rx_bip_err_11
  .stat_rx_bip_err_12(stat_rx_bip_err_12),                                    // output wire stat_rx_bip_err_12
  .stat_rx_bip_err_13(stat_rx_bip_err_13),                                    // output wire stat_rx_bip_err_13
  .stat_rx_bip_err_14(stat_rx_bip_err_14),                                    // output wire stat_rx_bip_err_14
  .stat_rx_bip_err_15(stat_rx_bip_err_15),                                    // output wire stat_rx_bip_err_15
  .stat_rx_bip_err_16(stat_rx_bip_err_16),                                    // output wire stat_rx_bip_err_16
  .stat_rx_bip_err_17(stat_rx_bip_err_17),                                    // output wire stat_rx_bip_err_17
  .stat_rx_bip_err_18(stat_rx_bip_err_18),                                    // output wire stat_rx_bip_err_18
  .stat_rx_bip_err_19(stat_rx_bip_err_19),                                    // output wire stat_rx_bip_err_19
  .stat_rx_bip_err_2(stat_rx_bip_err_2),                                      // output wire stat_rx_bip_err_2
  .stat_rx_bip_err_3(stat_rx_bip_err_3),                                      // output wire stat_rx_bip_err_3
  .stat_rx_bip_err_4(stat_rx_bip_err_4),                                      // output wire stat_rx_bip_err_4
  .stat_rx_bip_err_5(stat_rx_bip_err_5),                                      // output wire stat_rx_bip_err_5
  .stat_rx_bip_err_6(stat_rx_bip_err_6),                                      // output wire stat_rx_bip_err_6
  .stat_rx_bip_err_7(stat_rx_bip_err_7),                                      // output wire stat_rx_bip_err_7
  .stat_rx_bip_err_8(stat_rx_bip_err_8),                                      // output wire stat_rx_bip_err_8
  .stat_rx_bip_err_9(stat_rx_bip_err_9),                                      // output wire stat_rx_bip_err_9
  .stat_rx_block_lock(stat_rx_block_lock),                                    // output wire [19 : 0] stat_rx_block_lock
  .stat_rx_broadcast(stat_rx_broadcast),                                      // output wire stat_rx_broadcast
  .stat_rx_fragment(stat_rx_fragment),                                        // output wire [2 : 0] stat_rx_fragment
  .stat_rx_framing_err_0(stat_rx_framing_err_0),                              // output wire [1 : 0] stat_rx_framing_err_0
  .stat_rx_framing_err_1(stat_rx_framing_err_1),                              // output wire [1 : 0] stat_rx_framing_err_1
  .stat_rx_framing_err_10(stat_rx_framing_err_10),                            // output wire [1 : 0] stat_rx_framing_err_10
  .stat_rx_framing_err_11(stat_rx_framing_err_11),                            // output wire [1 : 0] stat_rx_framing_err_11
  .stat_rx_framing_err_12(stat_rx_framing_err_12),                            // output wire [1 : 0] stat_rx_framing_err_12
  .stat_rx_framing_err_13(stat_rx_framing_err_13),                            // output wire [1 : 0] stat_rx_framing_err_13
  .stat_rx_framing_err_14(stat_rx_framing_err_14),                            // output wire [1 : 0] stat_rx_framing_err_14
  .stat_rx_framing_err_15(stat_rx_framing_err_15),                            // output wire [1 : 0] stat_rx_framing_err_15
  .stat_rx_framing_err_16(stat_rx_framing_err_16),                            // output wire [1 : 0] stat_rx_framing_err_16
  .stat_rx_framing_err_17(stat_rx_framing_err_17),                            // output wire [1 : 0] stat_rx_framing_err_17
  .stat_rx_framing_err_18(stat_rx_framing_err_18),                            // output wire [1 : 0] stat_rx_framing_err_18
  .stat_rx_framing_err_19(stat_rx_framing_err_19),                            // output wire [1 : 0] stat_rx_framing_err_19
  .stat_rx_framing_err_2(stat_rx_framing_err_2),                              // output wire [1 : 0] stat_rx_framing_err_2
  .stat_rx_framing_err_3(stat_rx_framing_err_3),                              // output wire [1 : 0] stat_rx_framing_err_3
  .stat_rx_framing_err_4(stat_rx_framing_err_4),                              // output wire [1 : 0] stat_rx_framing_err_4
  .stat_rx_framing_err_5(stat_rx_framing_err_5),                              // output wire [1 : 0] stat_rx_framing_err_5
  .stat_rx_framing_err_6(stat_rx_framing_err_6),                              // output wire [1 : 0] stat_rx_framing_err_6
  .stat_rx_framing_err_7(stat_rx_framing_err_7),                              // output wire [1 : 0] stat_rx_framing_err_7
  .stat_rx_framing_err_8(stat_rx_framing_err_8),                              // output wire [1 : 0] stat_rx_framing_err_8
  .stat_rx_framing_err_9(stat_rx_framing_err_9),                              // output wire [1 : 0] stat_rx_framing_err_9
  .stat_rx_framing_err_valid_0(stat_rx_framing_err_valid_0),                  // output wire stat_rx_framing_err_valid_0
  .stat_rx_framing_err_valid_1(stat_rx_framing_err_valid_1),                  // output wire stat_rx_framing_err_valid_1
  .stat_rx_framing_err_valid_10(stat_rx_framing_err_valid_10),                // output wire stat_rx_framing_err_valid_10
  .stat_rx_framing_err_valid_11(stat_rx_framing_err_valid_11),                // output wire stat_rx_framing_err_valid_11
  .stat_rx_framing_err_valid_12(stat_rx_framing_err_valid_12),                // output wire stat_rx_framing_err_valid_12
  .stat_rx_framing_err_valid_13(stat_rx_framing_err_valid_13),                // output wire stat_rx_framing_err_valid_13
  .stat_rx_framing_err_valid_14(stat_rx_framing_err_valid_14),                // output wire stat_rx_framing_err_valid_14
  .stat_rx_framing_err_valid_15(stat_rx_framing_err_valid_15),                // output wire stat_rx_framing_err_valid_15
  .stat_rx_framing_err_valid_16(stat_rx_framing_err_valid_16),                // output wire stat_rx_framing_err_valid_16
  .stat_rx_framing_err_valid_17(stat_rx_framing_err_valid_17),                // output wire stat_rx_framing_err_valid_17
  .stat_rx_framing_err_valid_18(stat_rx_framing_err_valid_18),                // output wire stat_rx_framing_err_valid_18
  .stat_rx_framing_err_valid_19(stat_rx_framing_err_valid_19),                // output wire stat_rx_framing_err_valid_19
  .stat_rx_framing_err_valid_2(stat_rx_framing_err_valid_2),                  // output wire stat_rx_framing_err_valid_2
  .stat_rx_framing_err_valid_3(stat_rx_framing_err_valid_3),                  // output wire stat_rx_framing_err_valid_3
  .stat_rx_framing_err_valid_4(stat_rx_framing_err_valid_4),                  // output wire stat_rx_framing_err_valid_4
  .stat_rx_framing_err_valid_5(stat_rx_framing_err_valid_5),                  // output wire stat_rx_framing_err_valid_5
  .stat_rx_framing_err_valid_6(stat_rx_framing_err_valid_6),                  // output wire stat_rx_framing_err_valid_6
  .stat_rx_framing_err_valid_7(stat_rx_framing_err_valid_7),                  // output wire stat_rx_framing_err_valid_7
  .stat_rx_framing_err_valid_8(stat_rx_framing_err_valid_8),                  // output wire stat_rx_framing_err_valid_8
  .stat_rx_framing_err_valid_9(stat_rx_framing_err_valid_9),                  // output wire stat_rx_framing_err_valid_9
  .stat_rx_got_signal_os(stat_rx_got_signal_os),                              // output wire stat_rx_got_signal_os
  .stat_rx_hi_ber(stat_rx_hi_ber),                                            // output wire stat_rx_hi_ber
  .stat_rx_inrangeerr(stat_rx_inrangeerr),                                    // output wire stat_rx_inrangeerr
  .stat_rx_internal_local_fault(stat_rx_internal_local_fault),                // output wire stat_rx_internal_local_fault
  .stat_rx_jabber(stat_rx_jabber),                                            // output wire stat_rx_jabber
  .stat_rx_local_fault(stat_rx_local_fault),                                  // output wire stat_rx_local_fault
  .stat_rx_mf_err(stat_rx_mf_err),                                            // output wire [19 : 0] stat_rx_mf_err
  .stat_rx_mf_len_err(stat_rx_mf_len_err),                                    // output wire [19 : 0] stat_rx_mf_len_err
  .stat_rx_mf_repeat_err(stat_rx_mf_repeat_err),                              // output wire [19 : 0] stat_rx_mf_repeat_err
  .stat_rx_misaligned(stat_rx_misaligned),                                    // output wire stat_rx_misaligned
  .stat_rx_multicast(stat_rx_multicast),                                      // output wire stat_rx_multicast
  .stat_rx_oversize(stat_rx_oversize),                                        // output wire stat_rx_oversize
  .stat_rx_packet_1024_1518_bytes(stat_rx_packet_1024_1518_bytes),            // output wire stat_rx_packet_1024_1518_bytes
  .stat_rx_packet_128_255_bytes(stat_rx_packet_128_255_bytes),                // output wire stat_rx_packet_128_255_bytes
  .stat_rx_packet_1519_1522_bytes(stat_rx_packet_1519_1522_bytes),            // output wire stat_rx_packet_1519_1522_bytes
  .stat_rx_packet_1523_1548_bytes(stat_rx_packet_1523_1548_bytes),            // output wire stat_rx_packet_1523_1548_bytes
  .stat_rx_packet_1549_2047_bytes(stat_rx_packet_1549_2047_bytes),            // output wire stat_rx_packet_1549_2047_bytes
  .stat_rx_packet_2048_4095_bytes(stat_rx_packet_2048_4095_bytes),            // output wire stat_rx_packet_2048_4095_bytes
  .stat_rx_packet_256_511_bytes(stat_rx_packet_256_511_bytes),                // output wire stat_rx_packet_256_511_bytes
  .stat_rx_packet_4096_8191_bytes(stat_rx_packet_4096_8191_bytes),            // output wire stat_rx_packet_4096_8191_bytes
  .stat_rx_packet_512_1023_bytes(stat_rx_packet_512_1023_bytes),              // output wire stat_rx_packet_512_1023_bytes
  .stat_rx_packet_64_bytes(stat_rx_packet_64_bytes),                          // output wire stat_rx_packet_64_bytes
  .stat_rx_packet_65_127_bytes(stat_rx_packet_65_127_bytes),                  // output wire stat_rx_packet_65_127_bytes
  .stat_rx_packet_8192_9215_bytes(stat_rx_packet_8192_9215_bytes),            // output wire stat_rx_packet_8192_9215_bytes
  .stat_rx_packet_bad_fcs(stat_rx_packet_bad_fcs),                            // output wire stat_rx_packet_bad_fcs
  .stat_rx_packet_large(stat_rx_packet_large),                                // output wire stat_rx_packet_large
  .stat_rx_packet_small(stat_rx_packet_small),                                // output wire [2 : 0] stat_rx_packet_small
  .stat_rx_pause(stat_rx_pause),                                              // output wire stat_rx_pause
  .stat_rx_pause_quanta0(stat_rx_pause_quanta0),                              // output wire [15 : 0] stat_rx_pause_quanta0
  .stat_rx_pause_quanta1(stat_rx_pause_quanta1),                              // output wire [15 : 0] stat_rx_pause_quanta1
  .stat_rx_pause_quanta2(stat_rx_pause_quanta2),                              // output wire [15 : 0] stat_rx_pause_quanta2
  .stat_rx_pause_quanta3(stat_rx_pause_quanta3),                              // output wire [15 : 0] stat_rx_pause_quanta3
  .stat_rx_pause_quanta4(stat_rx_pause_quanta4),                              // output wire [15 : 0] stat_rx_pause_quanta4
  .stat_rx_pause_quanta5(stat_rx_pause_quanta5),                              // output wire [15 : 0] stat_rx_pause_quanta5
  .stat_rx_pause_quanta6(stat_rx_pause_quanta6),                              // output wire [15 : 0] stat_rx_pause_quanta6
  .stat_rx_pause_quanta7(stat_rx_pause_quanta7),                              // output wire [15 : 0] stat_rx_pause_quanta7
  .stat_rx_pause_quanta8(stat_rx_pause_quanta8),                              // output wire [15 : 0] stat_rx_pause_quanta8
  .stat_rx_pause_req(stat_rx_pause_req),                                      // output wire [8 : 0] stat_rx_pause_req
  .stat_rx_pause_valid(stat_rx_pause_valid),                                  // output wire [8 : 0] stat_rx_pause_valid
  .stat_rx_user_pause(stat_rx_user_pause),                                    // output wire stat_rx_user_pause
  .core_rx_reset(core_rx_reset),                                              // input wire core_rx_reset
  .rx_clk(rx_clk),                                                            // input wire rx_clk
  .stat_rx_received_local_fault(stat_rx_received_local_fault),                // output wire stat_rx_received_local_fault
  .stat_rx_remote_fault(stat_rx_remote_fault),                                // output wire stat_rx_remote_fault
  .stat_rx_status(stat_rx_status),                                            // output wire stat_rx_status
  .stat_rx_stomped_fcs(stat_rx_stomped_fcs),                                  // output wire [2 : 0] stat_rx_stomped_fcs
  .stat_rx_synced(stat_rx_synced),                                            // output wire [19 : 0] stat_rx_synced
  .stat_rx_synced_err(stat_rx_synced_err),                                    // output wire [19 : 0] stat_rx_synced_err
  .stat_rx_test_pattern_mismatch(stat_rx_test_pattern_mismatch),              // output wire [2 : 0] stat_rx_test_pattern_mismatch
  .stat_rx_toolong(stat_rx_toolong),                                          // output wire stat_rx_toolong
  .stat_rx_total_bytes(stat_rx_total_bytes),                                  // output wire [6 : 0] stat_rx_total_bytes
  .stat_rx_total_good_bytes(stat_rx_total_good_bytes),                        // output wire [13 : 0] stat_rx_total_good_bytes
  .stat_rx_total_good_packets(stat_rx_total_good_packets),                    // output wire stat_rx_total_good_packets
  .stat_rx_total_packets(stat_rx_total_packets),                              // output wire [2 : 0] stat_rx_total_packets
  .stat_rx_truncated(stat_rx_truncated),                                      // output wire stat_rx_truncated
  .stat_rx_undersize(stat_rx_undersize),                                      // output wire [2 : 0] stat_rx_undersize
  .stat_rx_unicast(stat_rx_unicast),                                          // output wire stat_rx_unicast
  .stat_rx_vlan(stat_rx_vlan),                                                // output wire stat_rx_vlan
  .stat_rx_pcsl_demuxed(stat_rx_pcsl_demuxed),                                // output wire [19 : 0] stat_rx_pcsl_demuxed
  .stat_rx_pcsl_number_0(stat_rx_pcsl_number_0),                              // output wire [4 : 0] stat_rx_pcsl_number_0
  .stat_rx_pcsl_number_1(stat_rx_pcsl_number_1),                              // output wire [4 : 0] stat_rx_pcsl_number_1
  .stat_rx_pcsl_number_10(stat_rx_pcsl_number_10),                            // output wire [4 : 0] stat_rx_pcsl_number_10
  .stat_rx_pcsl_number_11(stat_rx_pcsl_number_11),                            // output wire [4 : 0] stat_rx_pcsl_number_11
  .stat_rx_pcsl_number_12(stat_rx_pcsl_number_12),                            // output wire [4 : 0] stat_rx_pcsl_number_12
  .stat_rx_pcsl_number_13(stat_rx_pcsl_number_13),                            // output wire [4 : 0] stat_rx_pcsl_number_13
  .stat_rx_pcsl_number_14(stat_rx_pcsl_number_14),                            // output wire [4 : 0] stat_rx_pcsl_number_14
  .stat_rx_pcsl_number_15(stat_rx_pcsl_number_15),                            // output wire [4 : 0] stat_rx_pcsl_number_15
  .stat_rx_pcsl_number_16(stat_rx_pcsl_number_16),                            // output wire [4 : 0] stat_rx_pcsl_number_16
  .stat_rx_pcsl_number_17(stat_rx_pcsl_number_17),                            // output wire [4 : 0] stat_rx_pcsl_number_17
  .stat_rx_pcsl_number_18(stat_rx_pcsl_number_18),                            // output wire [4 : 0] stat_rx_pcsl_number_18
  .stat_rx_pcsl_number_19(stat_rx_pcsl_number_19),                            // output wire [4 : 0] stat_rx_pcsl_number_19
  .stat_rx_pcsl_number_2(stat_rx_pcsl_number_2),                              // output wire [4 : 0] stat_rx_pcsl_number_2
  .stat_rx_pcsl_number_3(stat_rx_pcsl_number_3),                              // output wire [4 : 0] stat_rx_pcsl_number_3
  .stat_rx_pcsl_number_4(stat_rx_pcsl_number_4),                              // output wire [4 : 0] stat_rx_pcsl_number_4
  .stat_rx_pcsl_number_5(stat_rx_pcsl_number_5),                              // output wire [4 : 0] stat_rx_pcsl_number_5
  .stat_rx_pcsl_number_6(stat_rx_pcsl_number_6),                              // output wire [4 : 0] stat_rx_pcsl_number_6
  .stat_rx_pcsl_number_7(stat_rx_pcsl_number_7),                              // output wire [4 : 0] stat_rx_pcsl_number_7
  .stat_rx_pcsl_number_8(stat_rx_pcsl_number_8),                              // output wire [4 : 0] stat_rx_pcsl_number_8
  .stat_rx_pcsl_number_9(stat_rx_pcsl_number_9),                              // output wire [4 : 0] stat_rx_pcsl_number_9
  .stat_tx_bad_fcs(stat_tx_bad_fcs),                                          // output wire stat_tx_bad_fcs
  .stat_tx_broadcast(stat_tx_broadcast),                                      // output wire stat_tx_broadcast
  .stat_tx_frame_error(stat_tx_frame_error),                                  // output wire stat_tx_frame_error
  .stat_tx_local_fault(stat_tx_local_fault),                                  // output wire stat_tx_local_fault
  .stat_tx_multicast(stat_tx_multicast),                                      // output wire stat_tx_multicast
  .stat_tx_packet_1024_1518_bytes(stat_tx_packet_1024_1518_bytes),            // output wire stat_tx_packet_1024_1518_bytes
  .stat_tx_packet_128_255_bytes(stat_tx_packet_128_255_bytes),                // output wire stat_tx_packet_128_255_bytes
  .stat_tx_packet_1519_1522_bytes(stat_tx_packet_1519_1522_bytes),            // output wire stat_tx_packet_1519_1522_bytes
  .stat_tx_packet_1523_1548_bytes(stat_tx_packet_1523_1548_bytes),            // output wire stat_tx_packet_1523_1548_bytes
  .stat_tx_packet_1549_2047_bytes(stat_tx_packet_1549_2047_bytes),            // output wire stat_tx_packet_1549_2047_bytes
  .stat_tx_packet_2048_4095_bytes(stat_tx_packet_2048_4095_bytes),            // output wire stat_tx_packet_2048_4095_bytes
  .stat_tx_packet_256_511_bytes(stat_tx_packet_256_511_bytes),                // output wire stat_tx_packet_256_511_bytes
  .stat_tx_packet_4096_8191_bytes(stat_tx_packet_4096_8191_bytes),            // output wire stat_tx_packet_4096_8191_bytes
  .stat_tx_packet_512_1023_bytes(stat_tx_packet_512_1023_bytes),              // output wire stat_tx_packet_512_1023_bytes
  .stat_tx_packet_64_bytes(stat_tx_packet_64_bytes),                          // output wire stat_tx_packet_64_bytes
  .stat_tx_packet_65_127_bytes(stat_tx_packet_65_127_bytes),                  // output wire stat_tx_packet_65_127_bytes
  .stat_tx_packet_8192_9215_bytes(stat_tx_packet_8192_9215_bytes),            // output wire stat_tx_packet_8192_9215_bytes
  .stat_tx_packet_large(stat_tx_packet_large),                                // output wire stat_tx_packet_large
  .stat_tx_packet_small(stat_tx_packet_small),                                // output wire stat_tx_packet_small
  .stat_tx_total_bytes(stat_tx_total_bytes),                                  // output wire [5 : 0] stat_tx_total_bytes
  .stat_tx_total_good_bytes(stat_tx_total_good_bytes),                        // output wire [13 : 0] stat_tx_total_good_bytes
  .stat_tx_total_good_packets(stat_tx_total_good_packets),                    // output wire stat_tx_total_good_packets
  .stat_tx_total_packets(stat_tx_total_packets),                              // output wire stat_tx_total_packets
  .stat_tx_unicast(stat_tx_unicast),                                          // output wire stat_tx_unicast
  .stat_tx_vlan(stat_tx_vlan),                                                // output wire stat_tx_vlan
  .ctl_tx_send_idle(ctl_tx_send_idle),                                        // input wire ctl_tx_send_idle
  .ctl_tx_send_rfi(ctl_tx_send_rfi),                                          // input wire ctl_tx_send_rfi
  .ctl_tx_send_lfi(ctl_tx_send_lfi),                                          // input wire ctl_tx_send_lfi
  .core_tx_reset(core_tx_reset),                                              // input wire core_tx_reset
  .stat_tx_pause_valid(stat_tx_pause_valid),                                  // output wire [8 : 0] stat_tx_pause_valid
  .stat_tx_pause(stat_tx_pause),                                              // output wire stat_tx_pause
  .stat_tx_user_pause(stat_tx_user_pause),                                    // output wire stat_tx_user_pause
  .ctl_tx_pause_req(ctl_tx_pause_req),                                        // input wire [8 : 0] ctl_tx_pause_req
  .ctl_tx_resend_pause(ctl_tx_resend_pause),                                  // input wire ctl_tx_resend_pause
  .tx_axis_tready(tx_axis_tready),                                            // output wire tx_axis_tready
  .tx_axis_tvalid(tx_axis_tvalid),                                            // input wire tx_axis_tvalid
  .tx_axis_tdata(tx_axis_tdata),                                              // input wire [511 : 0] tx_axis_tdata
  .tx_axis_tlast(tx_axis_tlast),                                              // input wire tx_axis_tlast
  .tx_axis_tkeep(tx_axis_tkeep),                                              // input wire [63 : 0] tx_axis_tkeep
  .tx_axis_tuser(tx_axis_tuser),                                              // input wire tx_axis_tuser
  .tx_ovfout(tx_ovfout),                                                      // output wire tx_ovfout
  .tx_unfout(tx_unfout),                                                      // output wire tx_unfout
  .tx_preamblein(tx_preamblein),                                              // input wire [55 : 0] tx_preamblein
  .usr_tx_reset(usr_tx_reset),                                                // output wire usr_tx_reset
  .core_drp_reset(core_drp_reset),                                            // input wire core_drp_reset
  .drp_clk(drp_clk),                                                          // input wire drp_clk
  .drp_addr(drp_addr),                                                        // input wire [9 : 0] drp_addr
  .drp_di(drp_di),                                                            // input wire [15 : 0] drp_di
  .drp_en(drp_en),                                                            // input wire drp_en
  .drp_do(drp_do),                                                            // output wire [15 : 0] drp_do
  .drp_rdy(drp_rdy),                                                          // output wire drp_rdy
  .drp_we(drp_we)                                                            // input wire drp_we
);
// INST_TAG_END ------ End INSTANTIATION Template ---------
    end : g__cmac_1
endgenerate

endmodule : xilinx_cmac_wrapper
