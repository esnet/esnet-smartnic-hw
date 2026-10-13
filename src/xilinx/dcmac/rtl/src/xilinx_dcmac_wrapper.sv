// Xilinx Versal Integrated 600G Ethernet Subsystem Wrapper
//
// See: https://docs.xilinx.com/r/en-US/pg369-dcmac
module xilinx_dcmac_wrapper (
    // Clocks/resets
    input  logic  [1:0] tx_usrclk,
    input  logic  [1:0] rx_usrclk,
    input  logic  [1:0] tx_usrclk2,
    input  logic  [1:0] rx_usrclk2,
    input  logic  core_clk,
    input  logic  ts_clk_0,

    input  logic  [5:0] tx_serdes_reset,
    input  logic  [5:0] rx_serdes_reset,
    input  logic  tx_core_reset,
    input  logic  rx_core_reset,

    // -- GT i/f
    input  logic [7:0][255:0] rxdata_in,
    output logic [7:0][255:0] txdata_out,

    // -- AXI-S
    axi4s_intf.tx axis_rx [2],
    axi4s_intf.rx axis_tx [2],

    // -- AXI-L
    axi4l_intf.peripheral axil_if
);
    // =========================================================================
    // Imports
    // =========================================================================

    // =========================================================================
    // Signals
    // =========================================================================
    logic s_axi_aclk;
    logic s_axi_aresetn;
    logic [31:0] s_axi_awaddr;
    logic s_axi_awvalid;
    logic s_axi_awready;
    logic [31:0] s_axi_wdata;
    logic s_axi_wvalid;
    logic s_axi_wready;
    logic [1:0] s_axi_bresp;
    logic s_axi_bvalid;
    logic s_axi_bready;
    logic [31:0] s_axi_araddr;
    logic s_axi_arvalid;
    logic s_axi_arready;
    logic [31:0] s_axi_rdata;
    logic [1:0] s_axi_rresp;
    logic s_axi_rvalid;
    logic s_axi_rready;
    logic fec_tx_dout_start_0; // -------------- omitted from example design - begin
    logic fec_tx_dout_start_0_bh;
    logic fec_tx_dout_start_1;
    logic fec_tx_dout_start_1_bh;
    logic fec_tx_dout_start_2;
    logic fec_tx_dout_start_2_bh;
    logic fec_tx_dout_start_3;
    logic fec_tx_dout_start_3_bh;
    logic fec_tx_dout_start_4;
    logic fec_tx_dout_start_4_bh;
    logic fec_tx_dout_start_5;
    logic fec_tx_dout_start_5_bh;
    logic [59:0] rsvd_out;
    logic [28:0] rsvd_out_rx_mac;
    logic [130:0] rsvd_out_rx_phy;
    logic [66:0] rsvd_out_tx_mac;
    logic [64:0] rsvd_out_tx_phy;
    logic rx_all_channel_mac_pm_rdy; // -------- omitted from example design - end
    logic [127:0] rx_axis_tdata0;
    logic [127:0] rx_axis_tdata1;
    logic [127:0] rx_axis_tdata2;
    logic [127:0] rx_axis_tdata3;
    logic [127:0] rx_axis_tdata4;
    logic [127:0] rx_axis_tdata5;
    logic [127:0] rx_axis_tdata6;
    logic [127:0] rx_axis_tdata7;
    logic rx_axis_tuser_ena0;
    logic rx_axis_tuser_ena1;
    logic rx_axis_tuser_ena2;
    logic rx_axis_tuser_ena3;
    logic rx_axis_tuser_ena4;
    logic rx_axis_tuser_ena5;
    logic rx_axis_tuser_ena6;
    logic rx_axis_tuser_ena7;
    logic rx_axis_tuser_eop0;
    logic rx_axis_tuser_eop1;
    logic rx_axis_tuser_eop2;
    logic rx_axis_tuser_eop3;
    logic rx_axis_tuser_eop4;
    logic rx_axis_tuser_eop5;
    logic rx_axis_tuser_eop6;
    logic rx_axis_tuser_eop7;
    logic rx_axis_tuser_err0;
    logic rx_axis_tuser_err1;
    logic rx_axis_tuser_err2;
    logic rx_axis_tuser_err3;
    logic rx_axis_tuser_err4;
    logic rx_axis_tuser_err5;
    logic rx_axis_tuser_err6;
    logic rx_axis_tuser_err7;
    logic [3:0] rx_axis_tuser_mty0;
    logic [3:0] rx_axis_tuser_mty1;
    logic [3:0] rx_axis_tuser_mty2;
    logic [3:0] rx_axis_tuser_mty3;
    logic [3:0] rx_axis_tuser_mty4;
    logic [3:0] rx_axis_tuser_mty5;
    logic [3:0] rx_axis_tuser_mty6;
    logic [3:0] rx_axis_tuser_mty7;
    logic rx_axis_tuser_sop0;
    logic rx_axis_tuser_sop1;
    logic rx_axis_tuser_sop2;
    logic rx_axis_tuser_sop3;
    logic rx_axis_tuser_sop4;
    logic rx_axis_tuser_sop5;
    logic rx_axis_tuser_sop6;
    logic rx_axis_tuser_sop7;
    logic rx_axis_tvalid_0;
    logic rx_axis_tvalid_2;
    logic [6:0] rx_lane_aligner_fill;
    logic rx_lane_aligner_fill_start;
    logic rx_lane_aligner_fill_valid;
    logic [43:0] rx_pcs_tdm_stats_data;
    logic rx_pcs_tdm_stats_start;
    logic rx_pcs_tdm_stats_valid;
    logic [5:0] rx_port_pm_rdy;
    logic [55:0] rx_preambleout_0;
    logic [55:0] rx_preambleout_2;
    logic rx_serdes_albuf_restart_0;
    logic rx_serdes_albuf_restart_1;
    logic rx_serdes_albuf_restart_2;
    logic rx_serdes_albuf_restart_3;
    logic rx_serdes_albuf_restart_4;
    logic rx_serdes_albuf_restart_5;
    logic rx_serdes_albuf_slip_0;
    logic rx_serdes_albuf_slip_1;
    logic rx_serdes_albuf_slip_2;
    logic rx_serdes_albuf_slip_3;
    logic rx_serdes_albuf_slip_4;
    logic rx_serdes_albuf_slip_5;
    logic rx_serdes_albuf_slip_6;
    logic rx_serdes_albuf_slip_7;
    logic rx_serdes_albuf_slip_8;
    logic rx_serdes_albuf_slip_9;
    logic rx_serdes_albuf_slip_10;
    logic rx_serdes_albuf_slip_11;
    logic rx_serdes_albuf_slip_12;
    logic rx_serdes_albuf_slip_13;
    logic rx_serdes_albuf_slip_14;
    logic rx_serdes_albuf_slip_15;
    logic rx_serdes_albuf_slip_16;
    logic rx_serdes_albuf_slip_17;
    logic rx_serdes_albuf_slip_18;
    logic rx_serdes_albuf_slip_19;
    logic rx_serdes_albuf_slip_20;
    logic rx_serdes_albuf_slip_21;
    logic rx_serdes_albuf_slip_22;
    logic rx_serdes_albuf_slip_23;
    logic rx_serdes_fifo_flagout_0;
    logic rx_serdes_fifo_flagout_1;
    logic rx_serdes_fifo_flagout_2;
    logic rx_serdes_fifo_flagout_3;
    logic rx_serdes_fifo_flagout_4;
    logic rx_serdes_fifo_flagout_5;
    logic [78:0] rx_tsmac_tdm_stats_data;
    logic [5:0] rx_tsmac_tdm_stats_id;
    logic rx_tsmac_tdm_stats_valid;
    logic [15:0] c0_stat_rx_corrected_lane_delay_0;
    logic [15:0] c0_stat_rx_corrected_lane_delay_1;
    logic [15:0] c0_stat_rx_corrected_lane_delay_2;
    logic [15:0] c0_stat_rx_corrected_lane_delay_3;
    logic c0_stat_rx_corrected_lane_delay_valid;
    logic [15:0] c1_stat_rx_corrected_lane_delay_0;
    logic [15:0] c1_stat_rx_corrected_lane_delay_1;
    logic [15:0] c1_stat_rx_corrected_lane_delay_2;
    logic [15:0] c1_stat_rx_corrected_lane_delay_3;
    logic c1_stat_rx_corrected_lane_delay_valid;
    logic [15:0] c2_stat_rx_corrected_lane_delay_0;
    logic [15:0] c2_stat_rx_corrected_lane_delay_1;
    logic [15:0] c2_stat_rx_corrected_lane_delay_2;
    logic [15:0] c2_stat_rx_corrected_lane_delay_3;
    logic c2_stat_rx_corrected_lane_delay_valid;
    logic [15:0] c3_stat_rx_corrected_lane_delay_0;
    logic [15:0] c3_stat_rx_corrected_lane_delay_1;
    logic [15:0] c3_stat_rx_corrected_lane_delay_2;
    logic [15:0] c3_stat_rx_corrected_lane_delay_3;
    logic c3_stat_rx_corrected_lane_delay_valid;
    logic [15:0] c4_stat_rx_corrected_lane_delay_0;
    logic [15:0] c4_stat_rx_corrected_lane_delay_1;
    logic [15:0] c4_stat_rx_corrected_lane_delay_2;
    logic [15:0] c4_stat_rx_corrected_lane_delay_3;
    logic c4_stat_rx_corrected_lane_delay_valid;
    logic [15:0] c5_stat_rx_corrected_lane_delay_0;
    logic [15:0] c5_stat_rx_corrected_lane_delay_1;
    logic [15:0] c5_stat_rx_corrected_lane_delay_2;
    logic [15:0] c5_stat_rx_corrected_lane_delay_3;
    logic c5_stat_rx_corrected_lane_delay_valid;
    logic tx_all_channel_mac_pm_rdy;
    logic tx_axis_taf_0;
    logic tx_axis_taf_2;
    logic tx_axis_tready_0;
    logic tx_axis_tready_2;
    logic [21:0] tx_pcs_tdm_stats_data;
    logic tx_pcs_tdm_stats_start;
    logic tx_pcs_tdm_stats_valid;
    logic [5:0] tx_port_pm_rdy;
    logic [255:0] txdata_out_0;
    logic [255:0] txdata_out_1;
    logic [255:0] txdata_out_2;
    logic [255:0] txdata_out_3;
    logic [255:0] txdata_out_4;
    logic [255:0] txdata_out_5;
    logic [255:0] txdata_out_6;
    logic [255:0] txdata_out_7;
    logic tx_serdes_is_am_0;
    logic tx_serdes_is_am_1;
    logic tx_serdes_is_am_2;
    logic tx_serdes_is_am_3;
    logic tx_serdes_is_am_4;
    logic tx_serdes_is_am_5;
    logic tx_serdes_is_am_prefifo_0;
    logic tx_serdes_is_am_prefifo_1;
    logic tx_serdes_is_am_prefifo_2;
    logic tx_serdes_is_am_prefifo_3;
    logic tx_serdes_is_am_prefifo_4;
    logic tx_serdes_is_am_prefifo_5;
    logic [55:0] tx_tsmac_tdm_stats_data;
    logic [5:0] tx_tsmac_tdm_stats_id;
    logic tx_tsmac_tdm_stats_valid;
    logic c0_ctl_tx_lane0_vlm_bip7_override = '0;
    logic [7:0] c0_ctl_tx_lane0_vlm_bip7_override_value = '0;
    logic c0_ctl_tx_send_idle_pin    = '0;
    logic c0_ctl_tx_send_lfi_pin     = '0;
    logic c0_ctl_tx_send_rfi_pin     = '0;
    logic c1_ctl_tx_lane0_vlm_bip7_override = '0;
    logic [7:0] c1_ctl_tx_lane0_vlm_bip7_override_value = '0;
    logic c1_ctl_tx_send_idle_pin    = '0;
    logic c1_ctl_tx_send_lfi_pin     = '0;
    logic c1_ctl_tx_send_rfi_pin     = '0;
    logic c2_ctl_tx_lane0_vlm_bip7_override = '0;
    logic [7:0] c2_ctl_tx_lane0_vlm_bip7_override_value = '0;
    logic c2_ctl_tx_send_idle_pin    = '0;
    logic c2_ctl_tx_send_lfi_pin     = '0;
    logic c2_ctl_tx_send_rfi_pin     = '0;
    logic c3_ctl_tx_lane0_vlm_bip7_override = '0;
    logic [7:0] c3_ctl_tx_lane0_vlm_bip7_override_value = '0;
    logic c3_ctl_tx_send_idle_pin    = '0;
    logic c3_ctl_tx_send_lfi_pin     = '0;
    logic c3_ctl_tx_send_rfi_pin     = '0;
    logic c4_ctl_tx_lane0_vlm_bip7_override = '0;
    logic [7:0] c4_ctl_tx_lane0_vlm_bip7_override_value = '0;
    logic c4_ctl_tx_send_idle_pin    = '0;
    logic c4_ctl_tx_send_lfi_pin     = '0;
    logic c4_ctl_tx_send_rfi_pin     = '0;
    logic c5_ctl_tx_lane0_vlm_bip7_override = '0;
    logic [7:0] c5_ctl_tx_lane0_vlm_bip7_override_value = '0;
    logic c5_ctl_tx_send_idle_pin    = '0;
    logic c5_ctl_tx_send_lfi_pin     = '0;
    logic c5_ctl_tx_send_rfi_pin     = '0;
    logic [119:0] ctl_rsvd_in        = '0;
    logic [15:0] ctl_rx_custom_vl_length_minus1 = 16'd256;  // 100GE:255, 200GE:256, 400GE:256
    logic [15:0] ctl_tx_custom_vl_length_minus1 = 16'd256;  // 100GE:255, 200GE:256, 400GE:256
    logic [63:0] ctl_vl_marker_id0   = 64'hc16821003e97de00; // 100GE
    logic [63:0] ctl_vl_marker_id1   = 64'h9d718e00628e7100; // 100GE
    logic [63:0] ctl_vl_marker_id2   = 64'h594be800a6b41700; // 100GE
    logic [63:0] ctl_vl_marker_id3   = 64'h4d957b00b26a8400; // 100GE
    logic [63:0] ctl_vl_marker_id4   = 64'hf50709000af8f600; // 100GE
    logic [63:0] ctl_vl_marker_id5   = 64'hdd14c20022eb3d00; // 100GE
    logic [63:0] ctl_vl_marker_id6   = 64'h9a4a260065b5d900; // 100GE
    logic [63:0] ctl_vl_marker_id7   = 64'h7b45660084ba9900; // 100GE
    logic [63:0] ctl_vl_marker_id8   = 64'ha02476005fdb8900; // 100GE
    logic [63:0] ctl_vl_marker_id9   = 64'h68c9fb0097360400; // 100GE
    logic [63:0] ctl_vl_marker_id10  = 64'hfd6c990002936600; // 100GE
    logic [63:0] ctl_vl_marker_id11  = 64'hb9915500466eaa00; // 100GE
    logic [63:0] ctl_vl_marker_id12  = 64'h5cb9b200a3464d00; // 100GE
    logic [63:0] ctl_vl_marker_id13  = 64'h1af8bd00e5074200; // 100GE
    logic [63:0] ctl_vl_marker_id14  = 64'h83c7ca007c383500; // 100GE
    logic [63:0] ctl_vl_marker_id15  = 64'h3536cd00cac93200; // 100GE
    logic [63:0] ctl_vl_marker_id16  = 64'hc4314c003bceb300; // 100GE
    logic [63:0] ctl_vl_marker_id17  = 64'hadd6b70052294800; // 100GE
    logic [63:0] ctl_vl_marker_id18  = 64'h5f662a00a099d500; // 100GE
    logic [63:0] ctl_vl_marker_id19  = 64'hc0f0e5003f0f1a00; // 100GE
    logic [7:0] rsvd_in_rx_mac       = '0;
    logic [7:0] rsvd_in_rx_phy       = '0;
    logic rx_all_channel_mac_pm_tick = '0;
    logic [5:0] rx_alt_serdes_clk;
    logic rx_axi_clk;
    logic [5:0] rx_port_pm_tick      = '0;
    logic [5:0] rx_channel_flush     = '0;
    logic rx_core_clk;
    //logic rx_core_reset;  // input port
    logic [5:0] rx_flexif_clk        = '0;
    logic rx_macif_clk               = 1'b0;
    logic [5:0] rx_serdes_clk;
    logic [255:0] rxdata_in_0;
    logic [255:0] rxdata_in_1;
    logic [255:0] rxdata_in_2;
    logic [255:0] rxdata_in_3;
    logic [255:0] rxdata_in_4;
    logic [255:0] rxdata_in_5;
    logic [255:0] rxdata_in_6;
    logic [255:0] rxdata_in_7;
    logic rx_serdes_fifo_flagin_0    = '0;
    logic rx_serdes_fifo_flagin_1    = '0;
    logic rx_serdes_fifo_flagin_2    = '0;
    logic rx_serdes_fifo_flagin_3    = '0;
    logic rx_serdes_fifo_flagin_4    = '0;
    logic rx_serdes_fifo_flagin_5    = '0;
    //logic [5:0] rx_serdes_reset;  // input port
    logic [5:0] ts_clk;
    logic tx_all_channel_mac_pm_tick = '0;
    logic [5:0] tx_alt_serdes_clk;
    logic [127:0] tx_axis_tdata0;
    logic [127:0] tx_axis_tdata1;
    logic [127:0] tx_axis_tdata2;
    logic [127:0] tx_axis_tdata3;
    logic [127:0] tx_axis_tdata4;
    logic [127:0] tx_axis_tdata5;
    logic [127:0] tx_axis_tdata6;
    logic [127:0] tx_axis_tdata7;
    logic tx_axis_tuser_ena0;
    logic tx_axis_tuser_ena1;
    logic tx_axis_tuser_ena2;
    logic tx_axis_tuser_ena3;
    logic tx_axis_tuser_ena4;
    logic tx_axis_tuser_ena5;
    logic tx_axis_tuser_ena6;
    logic tx_axis_tuser_ena7;
    logic tx_axis_tuser_eop0;
    logic tx_axis_tuser_eop1;
    logic tx_axis_tuser_eop2;
    logic tx_axis_tuser_eop3;
    logic tx_axis_tuser_eop4;
    logic tx_axis_tuser_eop5;
    logic tx_axis_tuser_eop6;
    logic tx_axis_tuser_eop7;
    logic tx_axis_tuser_err0;
    logic tx_axis_tuser_err1;
    logic tx_axis_tuser_err2;
    logic tx_axis_tuser_err3;
    logic tx_axis_tuser_err4;
    logic tx_axis_tuser_err5;
    logic tx_axis_tuser_err6;
    logic tx_axis_tuser_err7;
    logic [3:0] tx_axis_tuser_mty0;
    logic [3:0] tx_axis_tuser_mty1;
    logic [3:0] tx_axis_tuser_mty2;
    logic [3:0] tx_axis_tuser_mty3;
    logic [3:0] tx_axis_tuser_mty4;
    logic [3:0] tx_axis_tuser_mty5;
    logic [3:0] tx_axis_tuser_mty6;
    logic [3:0] tx_axis_tuser_mty7;
    logic tx_axis_tuser_sop0;
    logic tx_axis_tuser_sop1;
    logic tx_axis_tuser_sop2;
    logic tx_axis_tuser_sop3;
    logic tx_axis_tuser_sop4;
    logic tx_axis_tuser_sop5;
    logic tx_axis_tuser_sop6;
    logic tx_axis_tuser_sop7;
    logic tx_axis_tvalid_0;
    logic tx_axis_tvalid_2;
    logic tx_axi_clk;
    logic [5:0] tx_channel_flush = '0;
    logic tx_core_clk;
    //logic tx_core_reset;  // input port
    logic [5:0] tx_flexif_clk    = '0;
    logic tx_macif_clk           = '0;
    logic [5:0] tx_port_pm_tick  = '0;
    logic [55:0] tx_preamblein_0 = '0; // todo: compare to example design. Check doc. 56'h55555555555555 for Ethernet?
    logic [55:0] tx_preamblein_2 = '0;
    logic [5:0] tx_serdes_clk;
    //logic [5:0] tx_serdes_reset;  // input port


    // =========================================================================
    // Clocks
    // =========================================================================
    assign tx_serdes_clk[0]   = tx_usrclk[0];
    assign tx_serdes_clk[1]   = tx_usrclk[0];
    assign tx_serdes_clk[2]   = tx_usrclk[1];
    assign tx_serdes_clk[3]   = tx_usrclk[1];
    assign tx_serdes_clk[5:4] = '0;
    assign rx_serdes_clk[0]   = rx_usrclk[0];
    assign rx_serdes_clk[1]   = rx_usrclk[0];
    assign rx_serdes_clk[2]   = rx_usrclk[1];
    assign rx_serdes_clk[3]   = rx_usrclk[1];
    assign rx_serdes_clk[5:4] = '0;
 
    assign tx_alt_serdes_clk[0]   = tx_usrclk2[0];
    assign tx_alt_serdes_clk[1]   = tx_usrclk2[0];
    assign tx_alt_serdes_clk[2]   = tx_usrclk2[1];
    assign tx_alt_serdes_clk[3]   = tx_usrclk2[1];
    assign tx_alt_serdes_clk[5:4] = '0;
    assign rx_alt_serdes_clk[0]   = rx_usrclk2[0];
    assign rx_alt_serdes_clk[1]   = rx_usrclk2[0];
    assign rx_alt_serdes_clk[2]   = rx_usrclk2[1];
    assign rx_alt_serdes_clk[3]   = rx_usrclk2[1];
    assign rx_alt_serdes_clk[5:4] = '0;
 
    assign tx_core_clk = core_clk;
    assign rx_core_clk = core_clk;
 
    assign ts_clk[0]   = ts_clk_0;
    assign ts_clk[1]   = ts_clk_0;
    assign ts_clk[2]   = ts_clk_0;
    assign ts_clk[3]   = ts_clk_0;
    assign ts_clk[4]   = ts_clk_0;
    assign ts_clk[5]   = ts_clk_0;
 
 
    // =========================================================================
    // GT Interface
    // =========================================================================
    assign rxdata_in_0 = rxdata_in[0];
    assign rxdata_in_1 = rxdata_in[1];
    assign rxdata_in_2 = rxdata_in[2];
    assign rxdata_in_3 = rxdata_in[3];
    assign rxdata_in_4 = rxdata_in[4];
    assign rxdata_in_5 = rxdata_in[5];
    assign rxdata_in_6 = rxdata_in[6];
    assign rxdata_in_7 = rxdata_in[7];

    assign txdata_out[0] = txdata_out_0;
    assign txdata_out[1] = txdata_out_1;
    assign txdata_out[2] = txdata_out_2;
    assign txdata_out[3] = txdata_out_3;
    assign txdata_out[4] = txdata_out_4;
    assign txdata_out[5] = txdata_out_5;
    assign txdata_out[6] = txdata_out_6;
    assign txdata_out[7] = txdata_out_7;


    // =========================================================================
    // AXI-L register access
    // =========================================================================
    assign s_axi_aclk = axil_if.aclk;       // input wire s_axi_aclk
    assign s_axi_aresetn = axil_if.aresetn; // input wire s_axi_sreset
    assign s_axi_awaddr = axil_if.awaddr;   // input wire [31 : 0] s_axi_awaddr
    assign s_axi_awvalid = axil_if.awvalid; // input wire s_axi_awvalid
    assign axil_if.awready = s_axi_awready; // output wire s_axi_awready
    assign s_axi_wdata = axil_if.wdata;     // input wire [31 : 0] s_axi_wdata
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


    // =========================================================================
    // AXI-S Rx
    // =========================================================================
    // Note: No 'rx_axis_tready' signal i.e. no back-pressure
    assign rx_axi_clk = axis_rx[0].aclk;

    // Convert mty (empty) signal to tkeep vector (per segment).
    function automatic logic [15:0] mty_to_tkeep(input logic [3:0] mty);
        for (int i = 0; i < 16; i++) mty_to_tkeep[i] = (mty <= 15-i) ? 1'b1 : 1'b0;
    endfunction

    // Port 0
    assign axis_rx[0].tvalid = rx_axis_tvalid_0;
    assign axis_rx[0].tdata  = {rx_axis_tdata3, rx_axis_tdata2, rx_axis_tdata1, rx_axis_tdata0};
    assign axis_rx[0].tlast  = rx_axis_tuser_eop3 || rx_axis_tuser_eop2 || rx_axis_tuser_eop1 || rx_axis_tuser_eop0;
    assign axis_rx[0].tkeep  = {
        rx_axis_tuser_eop3 ? mty_to_tkeep(rx_axis_tuser_mty3) : rx_axis_tuser_ena3 ? 16'hFFFF : 16'h0000,
        rx_axis_tuser_eop2 ? mty_to_tkeep(rx_axis_tuser_mty2) : rx_axis_tuser_ena2 ? 16'hFFFF : 16'h0000,
        rx_axis_tuser_eop1 ? mty_to_tkeep(rx_axis_tuser_mty1) : rx_axis_tuser_ena1 ? 16'hFFFF : 16'h0000,
        rx_axis_tuser_eop0 ? mty_to_tkeep(rx_axis_tuser_mty0) : rx_axis_tuser_ena0 ? 16'hFFFF : 16'h0000
    };
    assign axis_rx[0].tuser  = rx_axis_tuser_err3 || rx_axis_tuser_err2 || rx_axis_tuser_err1 || rx_axis_tuser_err0;
    assign axis_rx[0].tid    = '0;
    assign axis_rx[0].tdest  = '0;

    // Port 1
    assign axis_rx[1].tvalid = rx_axis_tvalid_2;
    assign axis_rx[1].tdata  = {rx_axis_tdata7, rx_axis_tdata6, rx_axis_tdata5, rx_axis_tdata4};
    assign axis_rx[1].tlast  = rx_axis_tuser_eop7 || rx_axis_tuser_eop6 || rx_axis_tuser_eop5 || rx_axis_tuser_eop4;
    assign axis_rx[1].tkeep  = {
        rx_axis_tuser_eop7 ? mty_to_tkeep(rx_axis_tuser_mty7) : rx_axis_tuser_ena7 ? 16'hFFFF : 16'h0000,
        rx_axis_tuser_eop6 ? mty_to_tkeep(rx_axis_tuser_mty6) : rx_axis_tuser_ena6 ? 16'hFFFF : 16'h0000,
        rx_axis_tuser_eop5 ? mty_to_tkeep(rx_axis_tuser_mty5) : rx_axis_tuser_ena5 ? 16'hFFFF : 16'h0000,
        rx_axis_tuser_eop4 ? mty_to_tkeep(rx_axis_tuser_mty4) : rx_axis_tuser_ena4 ? 16'hFFFF : 16'h0000
    };
    assign axis_rx[1].tuser  = rx_axis_tuser_err7 || rx_axis_tuser_err6 || rx_axis_tuser_err5 || rx_axis_tuser_err4;
    assign axis_rx[1].tid    = '0;
    assign axis_rx[1].tdest  = '0;


    // =========================================================================
    // AXI-S Tx
    // =========================================================================
    assign tx_axi_clk = axis_tx[0].aclk;

    // Convert 16-bit per-segment tkeep to 4-bit mty (count of trailing zero bits).
    function automatic logic [3:0] tkeep_to_mty(input logic [15:0] tkeep);
        tkeep_to_mty = '0;
        for (int i = 0; i < 16; i++) if (!tkeep[i]) tkeep_to_mty++;
    endfunction

    // Port 0 — track sop: asserted on first beat of each frame, deasserted after.
    logic axis_tx_sop = 1'b1;
    always_ff @(posedge axis_tx[0].aclk) begin
        if (axis_tx[0].tvalid && axis_tx[0].tready) axis_tx_sop <= axis_tx[0].tlast;
    end

    assign axis_tx[0].tready  = tx_axis_tready_0;
    assign tx_axis_tvalid_0   = axis_tx[0].tvalid;

    assign tx_axis_tdata0 = axis_tx[0].tdata[15:0];
    assign tx_axis_tdata1 = axis_tx[0].tdata[31:16];
    assign tx_axis_tdata2 = axis_tx[0].tdata[47:32];
    assign tx_axis_tdata3 = axis_tx[0].tdata[63:48];

    assign tx_axis_tuser_ena0 = axis_tx[0].tvalid && |axis_tx[0].tkeep[15:0];
    assign tx_axis_tuser_ena1 = axis_tx[0].tvalid && |axis_tx[0].tkeep[31:16];
    assign tx_axis_tuser_ena2 = axis_tx[0].tvalid && |axis_tx[0].tkeep[47:32];
    assign tx_axis_tuser_ena3 = axis_tx[0].tvalid && |axis_tx[0].tkeep[63:48];

    assign tx_axis_tuser_sop0 = axis_tx_sop;
    assign tx_axis_tuser_sop1 = 1'b0;
    assign tx_axis_tuser_sop2 = 1'b0;
    assign tx_axis_tuser_sop3 = 1'b0;

    assign tx_axis_tuser_eop0 = axis_tx[0].tlast && !tx_axis_tuser_ena3 && !tx_axis_tuser_ena2 && !tx_axis_tuser_ena1;
    assign tx_axis_tuser_eop1 = axis_tx[0].tlast && !tx_axis_tuser_ena3 && !tx_axis_tuser_ena2 &&  tx_axis_tuser_ena1;
    assign tx_axis_tuser_eop2 = axis_tx[0].tlast && !tx_axis_tuser_ena3 &&  tx_axis_tuser_ena2;
    assign tx_axis_tuser_eop3 = axis_tx[0].tlast &&  tx_axis_tuser_ena3;

    assign tx_axis_tuser_mty0 = tkeep_to_mty(axis_tx[0].tkeep[15:0]);
    assign tx_axis_tuser_mty1 = tkeep_to_mty(axis_tx[0].tkeep[31:16]);
    assign tx_axis_tuser_mty2 = tkeep_to_mty(axis_tx[0].tkeep[47:32]);
    assign tx_axis_tuser_mty3 = tkeep_to_mty(axis_tx[0].tkeep[63:48]);

    logic axis_tx_tuser;
    assign axis_tx_tuser       = axis_tx[0].tuser;
    assign tx_axis_tuser_err0  = tx_axis_tuser_eop0 && axis_tx_tuser;
    assign tx_axis_tuser_err1  = tx_axis_tuser_eop1 && axis_tx_tuser;
    assign tx_axis_tuser_err2  = tx_axis_tuser_eop2 && axis_tx_tuser;
    assign tx_axis_tuser_err3  = tx_axis_tuser_eop3 && axis_tx_tuser;

    // Port 1 — track sop
    logic axis_tx_1_sop = 1'b1;
    always_ff @(posedge axis_tx[1].aclk) begin
        if (axis_tx[1].tvalid && axis_tx[1].tready) axis_tx_1_sop <= axis_tx[1].tlast;
    end

    assign axis_tx[1].tready  = tx_axis_tready_2;
    assign tx_axis_tvalid_2   = axis_tx[1].tvalid;

    assign tx_axis_tdata4 = axis_tx[1].tdata[15:0];
    assign tx_axis_tdata5 = axis_tx[1].tdata[31:16];
    assign tx_axis_tdata6 = axis_tx[1].tdata[47:32];
    assign tx_axis_tdata7 = axis_tx[1].tdata[63:48];

    assign tx_axis_tuser_ena4 = axis_tx[1].tvalid && |axis_tx[1].tkeep[15:0];
    assign tx_axis_tuser_ena5 = axis_tx[1].tvalid && |axis_tx[1].tkeep[31:16];
    assign tx_axis_tuser_ena6 = axis_tx[1].tvalid && |axis_tx[1].tkeep[47:32];
    assign tx_axis_tuser_ena7 = axis_tx[1].tvalid && |axis_tx[1].tkeep[63:48];

    assign tx_axis_tuser_sop4 = axis_tx_1_sop;
    assign tx_axis_tuser_sop5 = 1'b0;
    assign tx_axis_tuser_sop6 = 1'b0;
    assign tx_axis_tuser_sop7 = 1'b0;

    assign tx_axis_tuser_eop4 = axis_tx[1].tlast && !tx_axis_tuser_ena7 && !tx_axis_tuser_ena6 && !tx_axis_tuser_ena5;
    assign tx_axis_tuser_eop5 = axis_tx[1].tlast && !tx_axis_tuser_ena7 && !tx_axis_tuser_ena6 &&  tx_axis_tuser_ena5;
    assign tx_axis_tuser_eop6 = axis_tx[1].tlast && !tx_axis_tuser_ena7 &&  tx_axis_tuser_ena6;
    assign tx_axis_tuser_eop7 = axis_tx[1].tlast &&  tx_axis_tuser_ena7;

    assign tx_axis_tuser_mty4 = tkeep_to_mty(axis_tx[1].tkeep[15:0]);
    assign tx_axis_tuser_mty5 = tkeep_to_mty(axis_tx[1].tkeep[31:16]);
    assign tx_axis_tuser_mty6 = tkeep_to_mty(axis_tx[1].tkeep[47:32]);
    assign tx_axis_tuser_mty7 = tkeep_to_mty(axis_tx[1].tkeep[63:48]);

    logic axis_tx_1_tuser;
    assign axis_tx_1_tuser     = axis_tx[1].tuser;
    assign tx_axis_tuser_err4  = tx_axis_tuser_eop4 && axis_tx_1_tuser;
    assign tx_axis_tuser_err5  = tx_axis_tuser_eop5 && axis_tx_1_tuser;
    assign tx_axis_tuser_err6  = tx_axis_tuser_eop6 && axis_tx_1_tuser;
    assign tx_axis_tuser_err7  = tx_axis_tuser_eop7 && axis_tx_1_tuser;


// DCMAC IP instantiation
//
// NOTE: Use instantiation template exactly as provided in IP (including whitespace, but with
//       generic instance name commented out) to enable trivial diffs to simplify upgrades or changes,
//       identify added/removed signals, etc.
//
xilinx_dcmac_0 i_xilinx_dcmac_0 (
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
//xilinx_dcmac_0 your_instance_name (
  .s_axi_aclk(s_axi_aclk),                                                            // input wire s_axi_aclk
  .s_axi_aresetn(s_axi_aresetn),                                                      // input wire s_axi_aresetn
  .s_axi_awaddr(s_axi_awaddr),                                                        // input wire [31 : 0] s_axi_awaddr
  .s_axi_awvalid(s_axi_awvalid),                                                      // input wire s_axi_awvalid
  .s_axi_awready(s_axi_awready),                                                      // output wire s_axi_awready
  .s_axi_wdata(s_axi_wdata),                                                          // input wire [31 : 0] s_axi_wdata
  .s_axi_wvalid(s_axi_wvalid),                                                        // input wire s_axi_wvalid
  .s_axi_wready(s_axi_wready),                                                        // output wire s_axi_wready
  .s_axi_bresp(s_axi_bresp),                                                          // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),                                                        // output wire s_axi_bvalid
  .s_axi_bready(s_axi_bready),                                                        // input wire s_axi_bready
  .s_axi_araddr(s_axi_araddr),                                                        // input wire [31 : 0] s_axi_araddr
  .s_axi_arvalid(s_axi_arvalid),                                                      // input wire s_axi_arvalid
  .s_axi_arready(s_axi_arready),                                                      // output wire s_axi_arready
  .s_axi_rdata(s_axi_rdata),                                                          // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),                                                          // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(s_axi_rvalid),                                                        // output wire s_axi_rvalid
  .s_axi_rready(s_axi_rready),                                                        // input wire s_axi_rready
  .fec_tx_dout_start_0(fec_tx_dout_start_0),                                          // output wire fec_tx_dout_start_0
  .fec_tx_dout_start_0_bh(fec_tx_dout_start_0_bh),                                    // output wire fec_tx_dout_start_0_bh
  .fec_tx_dout_start_1(fec_tx_dout_start_1),                                          // output wire fec_tx_dout_start_1
  .fec_tx_dout_start_1_bh(fec_tx_dout_start_1_bh),                                    // output wire fec_tx_dout_start_1_bh
  .fec_tx_dout_start_2(fec_tx_dout_start_2),                                          // output wire fec_tx_dout_start_2
  .fec_tx_dout_start_2_bh(fec_tx_dout_start_2_bh),                                    // output wire fec_tx_dout_start_2_bh
  .fec_tx_dout_start_3(fec_tx_dout_start_3),                                          // output wire fec_tx_dout_start_3
  .fec_tx_dout_start_3_bh(fec_tx_dout_start_3_bh),                                    // output wire fec_tx_dout_start_3_bh
  .fec_tx_dout_start_4(fec_tx_dout_start_4),                                          // output wire fec_tx_dout_start_4
  .fec_tx_dout_start_4_bh(fec_tx_dout_start_4_bh),                                    // output wire fec_tx_dout_start_4_bh
  .fec_tx_dout_start_5(fec_tx_dout_start_5),                                          // output wire fec_tx_dout_start_5
  .fec_tx_dout_start_5_bh(fec_tx_dout_start_5_bh),                                    // output wire fec_tx_dout_start_5_bh
  .rsvd_out(rsvd_out),                                                                // output wire [59 : 0] rsvd_out
  .rsvd_out_rx_mac(rsvd_out_rx_mac),                                                  // output wire [28 : 0] rsvd_out_rx_mac
  .rsvd_out_rx_phy(rsvd_out_rx_phy),                                                  // output wire [130 : 0] rsvd_out_rx_phy
  .rsvd_out_tx_mac(rsvd_out_tx_mac),                                                  // output wire [66 : 0] rsvd_out_tx_mac
  .rsvd_out_tx_phy(rsvd_out_tx_phy),                                                  // output wire [64 : 0] rsvd_out_tx_phy
  .rx_all_channel_mac_pm_rdy(rx_all_channel_mac_pm_rdy),                              // output wire rx_all_channel_mac_pm_rdy
  .rx_axis_tdata0(rx_axis_tdata0),                                                    // output wire [127 : 0] rx_axis_tdata0
  .rx_axis_tdata1(rx_axis_tdata1),                                                    // output wire [127 : 0] rx_axis_tdata1
  .rx_axis_tdata2(rx_axis_tdata2),                                                    // output wire [127 : 0] rx_axis_tdata2
  .rx_axis_tdata3(rx_axis_tdata3),                                                    // output wire [127 : 0] rx_axis_tdata3
  .rx_axis_tdata4(rx_axis_tdata4),                                                    // output wire [127 : 0] rx_axis_tdata4
  .rx_axis_tdata5(rx_axis_tdata5),                                                    // output wire [127 : 0] rx_axis_tdata5
  .rx_axis_tdata6(rx_axis_tdata6),                                                    // output wire [127 : 0] rx_axis_tdata6
  .rx_axis_tdata7(rx_axis_tdata7),                                                    // output wire [127 : 0] rx_axis_tdata7
  .rx_axis_tuser_ena0(rx_axis_tuser_ena0),                                            // output wire rx_axis_tuser_ena0
  .rx_axis_tuser_ena1(rx_axis_tuser_ena1),                                            // output wire rx_axis_tuser_ena1
  .rx_axis_tuser_ena2(rx_axis_tuser_ena2),                                            // output wire rx_axis_tuser_ena2
  .rx_axis_tuser_ena3(rx_axis_tuser_ena3),                                            // output wire rx_axis_tuser_ena3
  .rx_axis_tuser_ena4(rx_axis_tuser_ena4),                                            // output wire rx_axis_tuser_ena4
  .rx_axis_tuser_ena5(rx_axis_tuser_ena5),                                            // output wire rx_axis_tuser_ena5
  .rx_axis_tuser_ena6(rx_axis_tuser_ena6),                                            // output wire rx_axis_tuser_ena6
  .rx_axis_tuser_ena7(rx_axis_tuser_ena7),                                            // output wire rx_axis_tuser_ena7
  .rx_axis_tuser_eop0(rx_axis_tuser_eop0),                                            // output wire rx_axis_tuser_eop0
  .rx_axis_tuser_eop1(rx_axis_tuser_eop1),                                            // output wire rx_axis_tuser_eop1
  .rx_axis_tuser_eop2(rx_axis_tuser_eop2),                                            // output wire rx_axis_tuser_eop2
  .rx_axis_tuser_eop3(rx_axis_tuser_eop3),                                            // output wire rx_axis_tuser_eop3
  .rx_axis_tuser_eop4(rx_axis_tuser_eop4),                                            // output wire rx_axis_tuser_eop4
  .rx_axis_tuser_eop5(rx_axis_tuser_eop5),                                            // output wire rx_axis_tuser_eop5
  .rx_axis_tuser_eop6(rx_axis_tuser_eop6),                                            // output wire rx_axis_tuser_eop6
  .rx_axis_tuser_eop7(rx_axis_tuser_eop7),                                            // output wire rx_axis_tuser_eop7
  .rx_axis_tuser_err0(rx_axis_tuser_err0),                                            // output wire rx_axis_tuser_err0
  .rx_axis_tuser_err1(rx_axis_tuser_err1),                                            // output wire rx_axis_tuser_err1
  .rx_axis_tuser_err2(rx_axis_tuser_err2),                                            // output wire rx_axis_tuser_err2
  .rx_axis_tuser_err3(rx_axis_tuser_err3),                                            // output wire rx_axis_tuser_err3
  .rx_axis_tuser_err4(rx_axis_tuser_err4),                                            // output wire rx_axis_tuser_err4
  .rx_axis_tuser_err5(rx_axis_tuser_err5),                                            // output wire rx_axis_tuser_err5
  .rx_axis_tuser_err6(rx_axis_tuser_err6),                                            // output wire rx_axis_tuser_err6
  .rx_axis_tuser_err7(rx_axis_tuser_err7),                                            // output wire rx_axis_tuser_err7
  .rx_axis_tuser_mty0(rx_axis_tuser_mty0),                                            // output wire [3 : 0] rx_axis_tuser_mty0
  .rx_axis_tuser_mty1(rx_axis_tuser_mty1),                                            // output wire [3 : 0] rx_axis_tuser_mty1
  .rx_axis_tuser_mty2(rx_axis_tuser_mty2),                                            // output wire [3 : 0] rx_axis_tuser_mty2
  .rx_axis_tuser_mty3(rx_axis_tuser_mty3),                                            // output wire [3 : 0] rx_axis_tuser_mty3
  .rx_axis_tuser_mty4(rx_axis_tuser_mty4),                                            // output wire [3 : 0] rx_axis_tuser_mty4
  .rx_axis_tuser_mty5(rx_axis_tuser_mty5),                                            // output wire [3 : 0] rx_axis_tuser_mty5
  .rx_axis_tuser_mty6(rx_axis_tuser_mty6),                                            // output wire [3 : 0] rx_axis_tuser_mty6
  .rx_axis_tuser_mty7(rx_axis_tuser_mty7),                                            // output wire [3 : 0] rx_axis_tuser_mty7
  .rx_axis_tuser_sop0(rx_axis_tuser_sop0),                                            // output wire rx_axis_tuser_sop0
  .rx_axis_tuser_sop1(rx_axis_tuser_sop1),                                            // output wire rx_axis_tuser_sop1
  .rx_axis_tuser_sop2(rx_axis_tuser_sop2),                                            // output wire rx_axis_tuser_sop2
  .rx_axis_tuser_sop3(rx_axis_tuser_sop3),                                            // output wire rx_axis_tuser_sop3
  .rx_axis_tuser_sop4(rx_axis_tuser_sop4),                                            // output wire rx_axis_tuser_sop4
  .rx_axis_tuser_sop5(rx_axis_tuser_sop5),                                            // output wire rx_axis_tuser_sop5
  .rx_axis_tuser_sop6(rx_axis_tuser_sop6),                                            // output wire rx_axis_tuser_sop6
  .rx_axis_tuser_sop7(rx_axis_tuser_sop7),                                            // output wire rx_axis_tuser_sop7
  .rx_axis_tvalid_0(rx_axis_tvalid_0),                                                // output wire rx_axis_tvalid_0
  .rx_axis_tvalid_2(rx_axis_tvalid_2),                                                // output wire rx_axis_tvalid_2
  .rx_lane_aligner_fill(rx_lane_aligner_fill),                                        // output wire [6 : 0] rx_lane_aligner_fill
  .rx_lane_aligner_fill_start(rx_lane_aligner_fill_start),                            // output wire rx_lane_aligner_fill_start
  .rx_lane_aligner_fill_valid(rx_lane_aligner_fill_valid),                            // output wire rx_lane_aligner_fill_valid
  .rx_pcs_tdm_stats_data(rx_pcs_tdm_stats_data),                                      // output wire [43 : 0] rx_pcs_tdm_stats_data
  .rx_pcs_tdm_stats_start(rx_pcs_tdm_stats_start),                                    // output wire rx_pcs_tdm_stats_start
  .rx_pcs_tdm_stats_valid(rx_pcs_tdm_stats_valid),                                    // output wire rx_pcs_tdm_stats_valid
  .rx_port_pm_rdy(rx_port_pm_rdy),                                                    // output wire [5 : 0] rx_port_pm_rdy
  .rx_preambleout_0(rx_preambleout_0),                                                // output wire [55 : 0] rx_preambleout_0
  .rx_preambleout_2(rx_preambleout_2),                                                // output wire [55 : 0] rx_preambleout_2
  .rx_serdes_albuf_restart_0(rx_serdes_albuf_restart_0),                              // output wire rx_serdes_albuf_restart_0
  .rx_serdes_albuf_restart_1(rx_serdes_albuf_restart_1),                              // output wire rx_serdes_albuf_restart_1
  .rx_serdes_albuf_restart_2(rx_serdes_albuf_restart_2),                              // output wire rx_serdes_albuf_restart_2
  .rx_serdes_albuf_restart_3(rx_serdes_albuf_restart_3),                              // output wire rx_serdes_albuf_restart_3
  .rx_serdes_albuf_restart_4(rx_serdes_albuf_restart_4),                              // output wire rx_serdes_albuf_restart_4
  .rx_serdes_albuf_restart_5(rx_serdes_albuf_restart_5),                              // output wire rx_serdes_albuf_restart_5
  .rx_serdes_albuf_slip_0(rx_serdes_albuf_slip_0),                                    // output wire rx_serdes_albuf_slip_0
  .rx_serdes_albuf_slip_1(rx_serdes_albuf_slip_1),                                    // output wire rx_serdes_albuf_slip_1
  .rx_serdes_albuf_slip_2(rx_serdes_albuf_slip_2),                                    // output wire rx_serdes_albuf_slip_2
  .rx_serdes_albuf_slip_3(rx_serdes_albuf_slip_3),                                    // output wire rx_serdes_albuf_slip_3
  .rx_serdes_albuf_slip_4(rx_serdes_albuf_slip_4),                                    // output wire rx_serdes_albuf_slip_4
  .rx_serdes_albuf_slip_5(rx_serdes_albuf_slip_5),                                    // output wire rx_serdes_albuf_slip_5
  .rx_serdes_albuf_slip_6(rx_serdes_albuf_slip_6),                                    // output wire rx_serdes_albuf_slip_6
  .rx_serdes_albuf_slip_7(rx_serdes_albuf_slip_7),                                    // output wire rx_serdes_albuf_slip_7
  .rx_serdes_albuf_slip_8(rx_serdes_albuf_slip_8),                                    // output wire rx_serdes_albuf_slip_8
  .rx_serdes_albuf_slip_9(rx_serdes_albuf_slip_9),                                    // output wire rx_serdes_albuf_slip_9
  .rx_serdes_albuf_slip_10(rx_serdes_albuf_slip_10),                                  // output wire rx_serdes_albuf_slip_10
  .rx_serdes_albuf_slip_11(rx_serdes_albuf_slip_11),                                  // output wire rx_serdes_albuf_slip_11
  .rx_serdes_albuf_slip_12(rx_serdes_albuf_slip_12),                                  // output wire rx_serdes_albuf_slip_12
  .rx_serdes_albuf_slip_13(rx_serdes_albuf_slip_13),                                  // output wire rx_serdes_albuf_slip_13
  .rx_serdes_albuf_slip_14(rx_serdes_albuf_slip_14),                                  // output wire rx_serdes_albuf_slip_14
  .rx_serdes_albuf_slip_15(rx_serdes_albuf_slip_15),                                  // output wire rx_serdes_albuf_slip_15
  .rx_serdes_albuf_slip_16(rx_serdes_albuf_slip_16),                                  // output wire rx_serdes_albuf_slip_16
  .rx_serdes_albuf_slip_17(rx_serdes_albuf_slip_17),                                  // output wire rx_serdes_albuf_slip_17
  .rx_serdes_albuf_slip_18(rx_serdes_albuf_slip_18),                                  // output wire rx_serdes_albuf_slip_18
  .rx_serdes_albuf_slip_19(rx_serdes_albuf_slip_19),                                  // output wire rx_serdes_albuf_slip_19
  .rx_serdes_albuf_slip_20(rx_serdes_albuf_slip_20),                                  // output wire rx_serdes_albuf_slip_20
  .rx_serdes_albuf_slip_21(rx_serdes_albuf_slip_21),                                  // output wire rx_serdes_albuf_slip_21
  .rx_serdes_albuf_slip_22(rx_serdes_albuf_slip_22),                                  // output wire rx_serdes_albuf_slip_22
  .rx_serdes_albuf_slip_23(rx_serdes_albuf_slip_23),                                  // output wire rx_serdes_albuf_slip_23
  .rx_serdes_fifo_flagout_0(rx_serdes_fifo_flagout_0),                                // output wire rx_serdes_fifo_flagout_0
  .rx_serdes_fifo_flagout_1(rx_serdes_fifo_flagout_1),                                // output wire rx_serdes_fifo_flagout_1
  .rx_serdes_fifo_flagout_2(rx_serdes_fifo_flagout_2),                                // output wire rx_serdes_fifo_flagout_2
  .rx_serdes_fifo_flagout_3(rx_serdes_fifo_flagout_3),                                // output wire rx_serdes_fifo_flagout_3
  .rx_serdes_fifo_flagout_4(rx_serdes_fifo_flagout_4),                                // output wire rx_serdes_fifo_flagout_4
  .rx_serdes_fifo_flagout_5(rx_serdes_fifo_flagout_5),                                // output wire rx_serdes_fifo_flagout_5
  .rx_tsmac_tdm_stats_data(rx_tsmac_tdm_stats_data),                                  // output wire [78 : 0] rx_tsmac_tdm_stats_data
  .rx_tsmac_tdm_stats_id(rx_tsmac_tdm_stats_id),                                      // output wire [5 : 0] rx_tsmac_tdm_stats_id
  .rx_tsmac_tdm_stats_valid(rx_tsmac_tdm_stats_valid),                                // output wire rx_tsmac_tdm_stats_valid
  .c0_stat_rx_corrected_lane_delay_0(c0_stat_rx_corrected_lane_delay_0),              // output wire [15 : 0] c0_stat_rx_corrected_lane_delay_0
  .c0_stat_rx_corrected_lane_delay_1(c0_stat_rx_corrected_lane_delay_1),              // output wire [15 : 0] c0_stat_rx_corrected_lane_delay_1
  .c0_stat_rx_corrected_lane_delay_2(c0_stat_rx_corrected_lane_delay_2),              // output wire [15 : 0] c0_stat_rx_corrected_lane_delay_2
  .c0_stat_rx_corrected_lane_delay_3(c0_stat_rx_corrected_lane_delay_3),              // output wire [15 : 0] c0_stat_rx_corrected_lane_delay_3
  .c0_stat_rx_corrected_lane_delay_valid(c0_stat_rx_corrected_lane_delay_valid),      // output wire c0_stat_rx_corrected_lane_delay_valid
  .c1_stat_rx_corrected_lane_delay_0(c1_stat_rx_corrected_lane_delay_0),              // output wire [15 : 0] c1_stat_rx_corrected_lane_delay_0
  .c1_stat_rx_corrected_lane_delay_1(c1_stat_rx_corrected_lane_delay_1),              // output wire [15 : 0] c1_stat_rx_corrected_lane_delay_1
  .c1_stat_rx_corrected_lane_delay_2(c1_stat_rx_corrected_lane_delay_2),              // output wire [15 : 0] c1_stat_rx_corrected_lane_delay_2
  .c1_stat_rx_corrected_lane_delay_3(c1_stat_rx_corrected_lane_delay_3),              // output wire [15 : 0] c1_stat_rx_corrected_lane_delay_3
  .c1_stat_rx_corrected_lane_delay_valid(c1_stat_rx_corrected_lane_delay_valid),      // output wire c1_stat_rx_corrected_lane_delay_valid
  .c2_stat_rx_corrected_lane_delay_0(c2_stat_rx_corrected_lane_delay_0),              // output wire [15 : 0] c2_stat_rx_corrected_lane_delay_0
  .c2_stat_rx_corrected_lane_delay_1(c2_stat_rx_corrected_lane_delay_1),              // output wire [15 : 0] c2_stat_rx_corrected_lane_delay_1
  .c2_stat_rx_corrected_lane_delay_2(c2_stat_rx_corrected_lane_delay_2),              // output wire [15 : 0] c2_stat_rx_corrected_lane_delay_2
  .c2_stat_rx_corrected_lane_delay_3(c2_stat_rx_corrected_lane_delay_3),              // output wire [15 : 0] c2_stat_rx_corrected_lane_delay_3
  .c2_stat_rx_corrected_lane_delay_valid(c2_stat_rx_corrected_lane_delay_valid),      // output wire c2_stat_rx_corrected_lane_delay_valid
  .c3_stat_rx_corrected_lane_delay_0(c3_stat_rx_corrected_lane_delay_0),              // output wire [15 : 0] c3_stat_rx_corrected_lane_delay_0
  .c3_stat_rx_corrected_lane_delay_1(c3_stat_rx_corrected_lane_delay_1),              // output wire [15 : 0] c3_stat_rx_corrected_lane_delay_1
  .c3_stat_rx_corrected_lane_delay_2(c3_stat_rx_corrected_lane_delay_2),              // output wire [15 : 0] c3_stat_rx_corrected_lane_delay_2
  .c3_stat_rx_corrected_lane_delay_3(c3_stat_rx_corrected_lane_delay_3),              // output wire [15 : 0] c3_stat_rx_corrected_lane_delay_3
  .c3_stat_rx_corrected_lane_delay_valid(c3_stat_rx_corrected_lane_delay_valid),      // output wire c3_stat_rx_corrected_lane_delay_valid
  .c4_stat_rx_corrected_lane_delay_0(c4_stat_rx_corrected_lane_delay_0),              // output wire [15 : 0] c4_stat_rx_corrected_lane_delay_0
  .c4_stat_rx_corrected_lane_delay_1(c4_stat_rx_corrected_lane_delay_1),              // output wire [15 : 0] c4_stat_rx_corrected_lane_delay_1
  .c4_stat_rx_corrected_lane_delay_2(c4_stat_rx_corrected_lane_delay_2),              // output wire [15 : 0] c4_stat_rx_corrected_lane_delay_2
  .c4_stat_rx_corrected_lane_delay_3(c4_stat_rx_corrected_lane_delay_3),              // output wire [15 : 0] c4_stat_rx_corrected_lane_delay_3
  .c4_stat_rx_corrected_lane_delay_valid(c4_stat_rx_corrected_lane_delay_valid),      // output wire c4_stat_rx_corrected_lane_delay_valid
  .c5_stat_rx_corrected_lane_delay_0(c5_stat_rx_corrected_lane_delay_0),              // output wire [15 : 0] c5_stat_rx_corrected_lane_delay_0
  .c5_stat_rx_corrected_lane_delay_1(c5_stat_rx_corrected_lane_delay_1),              // output wire [15 : 0] c5_stat_rx_corrected_lane_delay_1
  .c5_stat_rx_corrected_lane_delay_2(c5_stat_rx_corrected_lane_delay_2),              // output wire [15 : 0] c5_stat_rx_corrected_lane_delay_2
  .c5_stat_rx_corrected_lane_delay_3(c5_stat_rx_corrected_lane_delay_3),              // output wire [15 : 0] c5_stat_rx_corrected_lane_delay_3
  .c5_stat_rx_corrected_lane_delay_valid(c5_stat_rx_corrected_lane_delay_valid),      // output wire c5_stat_rx_corrected_lane_delay_valid
  .tx_all_channel_mac_pm_rdy(tx_all_channel_mac_pm_rdy),                              // output wire tx_all_channel_mac_pm_rdy
  .tx_axis_taf_0(tx_axis_taf_0),                                                      // output wire tx_axis_taf_0
  .tx_axis_taf_2(tx_axis_taf_2),                                                      // output wire tx_axis_taf_2
  .tx_axis_tready_0(tx_axis_tready_0),                                                // output wire tx_axis_tready_0
  .tx_axis_tready_2(tx_axis_tready_2),                                                // output wire tx_axis_tready_2
  .tx_pcs_tdm_stats_data(tx_pcs_tdm_stats_data),                                      // output wire [21 : 0] tx_pcs_tdm_stats_data
  .tx_pcs_tdm_stats_start(tx_pcs_tdm_stats_start),                                    // output wire tx_pcs_tdm_stats_start
  .tx_pcs_tdm_stats_valid(tx_pcs_tdm_stats_valid),                                    // output wire tx_pcs_tdm_stats_valid
  .tx_port_pm_rdy(tx_port_pm_rdy),                                                    // output wire [5 : 0] tx_port_pm_rdy
  .txdata_out_0(txdata_out_0),                                                        // output wire [255 : 0] txdata_out_0
  .txdata_out_1(txdata_out_1),                                                        // output wire [255 : 0] txdata_out_1
  .txdata_out_2(txdata_out_2),                                                        // output wire [255 : 0] txdata_out_2
  .txdata_out_3(txdata_out_3),                                                        // output wire [255 : 0] txdata_out_3
  .txdata_out_4(txdata_out_4),                                                        // output wire [255 : 0] txdata_out_4
  .txdata_out_5(txdata_out_5),                                                        // output wire [255 : 0] txdata_out_5
  .txdata_out_6(txdata_out_6),                                                        // output wire [255 : 0] txdata_out_6
  .txdata_out_7(txdata_out_7),                                                        // output wire [255 : 0] txdata_out_7
  .tx_serdes_is_am_0(tx_serdes_is_am_0),                                              // output wire tx_serdes_is_am_0
  .tx_serdes_is_am_1(tx_serdes_is_am_1),                                              // output wire tx_serdes_is_am_1
  .tx_serdes_is_am_2(tx_serdes_is_am_2),                                              // output wire tx_serdes_is_am_2
  .tx_serdes_is_am_3(tx_serdes_is_am_3),                                              // output wire tx_serdes_is_am_3
  .tx_serdes_is_am_4(tx_serdes_is_am_4),                                              // output wire tx_serdes_is_am_4
  .tx_serdes_is_am_5(tx_serdes_is_am_5),                                              // output wire tx_serdes_is_am_5
  .tx_serdes_is_am_prefifo_0(tx_serdes_is_am_prefifo_0),                              // output wire tx_serdes_is_am_prefifo_0
  .tx_serdes_is_am_prefifo_1(tx_serdes_is_am_prefifo_1),                              // output wire tx_serdes_is_am_prefifo_1
  .tx_serdes_is_am_prefifo_2(tx_serdes_is_am_prefifo_2),                              // output wire tx_serdes_is_am_prefifo_2
  .tx_serdes_is_am_prefifo_3(tx_serdes_is_am_prefifo_3),                              // output wire tx_serdes_is_am_prefifo_3
  .tx_serdes_is_am_prefifo_4(tx_serdes_is_am_prefifo_4),                              // output wire tx_serdes_is_am_prefifo_4
  .tx_serdes_is_am_prefifo_5(tx_serdes_is_am_prefifo_5),                              // output wire tx_serdes_is_am_prefifo_5
  .tx_tsmac_tdm_stats_data(tx_tsmac_tdm_stats_data),                                  // output wire [55 : 0] tx_tsmac_tdm_stats_data
  .tx_tsmac_tdm_stats_id(tx_tsmac_tdm_stats_id),                                      // output wire [5 : 0] tx_tsmac_tdm_stats_id
  .tx_tsmac_tdm_stats_valid(tx_tsmac_tdm_stats_valid),                                // output wire tx_tsmac_tdm_stats_valid
  .c0_ctl_tx_lane0_vlm_bip7_override(c0_ctl_tx_lane0_vlm_bip7_override),              // input wire c0_ctl_tx_lane0_vlm_bip7_override
  .c0_ctl_tx_lane0_vlm_bip7_override_value(c0_ctl_tx_lane0_vlm_bip7_override_value),  // input wire [7 : 0] c0_ctl_tx_lane0_vlm_bip7_override_value
  .c0_ctl_tx_send_idle_pin(c0_ctl_tx_send_idle_pin),                                  // input wire c0_ctl_tx_send_idle_pin
  .c0_ctl_tx_send_lfi_pin(c0_ctl_tx_send_lfi_pin),                                    // input wire c0_ctl_tx_send_lfi_pin
  .c0_ctl_tx_send_rfi_pin(c0_ctl_tx_send_rfi_pin),                                    // input wire c0_ctl_tx_send_rfi_pin
  .c1_ctl_tx_lane0_vlm_bip7_override(c1_ctl_tx_lane0_vlm_bip7_override),              // input wire c1_ctl_tx_lane0_vlm_bip7_override
  .c1_ctl_tx_lane0_vlm_bip7_override_value(c1_ctl_tx_lane0_vlm_bip7_override_value),  // input wire [7 : 0] c1_ctl_tx_lane0_vlm_bip7_override_value
  .c1_ctl_tx_send_idle_pin(c1_ctl_tx_send_idle_pin),                                  // input wire c1_ctl_tx_send_idle_pin
  .c1_ctl_tx_send_lfi_pin(c1_ctl_tx_send_lfi_pin),                                    // input wire c1_ctl_tx_send_lfi_pin
  .c1_ctl_tx_send_rfi_pin(c1_ctl_tx_send_rfi_pin),                                    // input wire c1_ctl_tx_send_rfi_pin
  .c2_ctl_tx_lane0_vlm_bip7_override(c2_ctl_tx_lane0_vlm_bip7_override),              // input wire c2_ctl_tx_lane0_vlm_bip7_override
  .c2_ctl_tx_lane0_vlm_bip7_override_value(c2_ctl_tx_lane0_vlm_bip7_override_value),  // input wire [7 : 0] c2_ctl_tx_lane0_vlm_bip7_override_value
  .c2_ctl_tx_send_idle_pin(c2_ctl_tx_send_idle_pin),                                  // input wire c2_ctl_tx_send_idle_pin
  .c2_ctl_tx_send_lfi_pin(c2_ctl_tx_send_lfi_pin),                                    // input wire c2_ctl_tx_send_lfi_pin
  .c2_ctl_tx_send_rfi_pin(c2_ctl_tx_send_rfi_pin),                                    // input wire c2_ctl_tx_send_rfi_pin
  .c3_ctl_tx_lane0_vlm_bip7_override(c3_ctl_tx_lane0_vlm_bip7_override),              // input wire c3_ctl_tx_lane0_vlm_bip7_override
  .c3_ctl_tx_lane0_vlm_bip7_override_value(c3_ctl_tx_lane0_vlm_bip7_override_value),  // input wire [7 : 0] c3_ctl_tx_lane0_vlm_bip7_override_value
  .c3_ctl_tx_send_idle_pin(c3_ctl_tx_send_idle_pin),                                  // input wire c3_ctl_tx_send_idle_pin
  .c3_ctl_tx_send_lfi_pin(c3_ctl_tx_send_lfi_pin),                                    // input wire c3_ctl_tx_send_lfi_pin
  .c3_ctl_tx_send_rfi_pin(c3_ctl_tx_send_rfi_pin),                                    // input wire c3_ctl_tx_send_rfi_pin
  .c4_ctl_tx_lane0_vlm_bip7_override(c4_ctl_tx_lane0_vlm_bip7_override),              // input wire c4_ctl_tx_lane0_vlm_bip7_override
  .c4_ctl_tx_lane0_vlm_bip7_override_value(c4_ctl_tx_lane0_vlm_bip7_override_value),  // input wire [7 : 0] c4_ctl_tx_lane0_vlm_bip7_override_value
  .c4_ctl_tx_send_idle_pin(c4_ctl_tx_send_idle_pin),                                  // input wire c4_ctl_tx_send_idle_pin
  .c4_ctl_tx_send_lfi_pin(c4_ctl_tx_send_lfi_pin),                                    // input wire c4_ctl_tx_send_lfi_pin
  .c4_ctl_tx_send_rfi_pin(c4_ctl_tx_send_rfi_pin),                                    // input wire c4_ctl_tx_send_rfi_pin
  .c5_ctl_tx_lane0_vlm_bip7_override(c5_ctl_tx_lane0_vlm_bip7_override),              // input wire c5_ctl_tx_lane0_vlm_bip7_override
  .c5_ctl_tx_lane0_vlm_bip7_override_value(c5_ctl_tx_lane0_vlm_bip7_override_value),  // input wire [7 : 0] c5_ctl_tx_lane0_vlm_bip7_override_value
  .c5_ctl_tx_send_idle_pin(c5_ctl_tx_send_idle_pin),                                  // input wire c5_ctl_tx_send_idle_pin
  .c5_ctl_tx_send_lfi_pin(c5_ctl_tx_send_lfi_pin),                                    // input wire c5_ctl_tx_send_lfi_pin
  .c5_ctl_tx_send_rfi_pin(c5_ctl_tx_send_rfi_pin),                                    // input wire c5_ctl_tx_send_rfi_pin
  .ctl_rsvd_in(ctl_rsvd_in),                                                          // input wire [119 : 0] ctl_rsvd_in
  .ctl_rx_custom_vl_length_minus1(ctl_rx_custom_vl_length_minus1),                    // input wire [15 : 0] ctl_rx_custom_vl_length_minus1
  .ctl_tx_custom_vl_length_minus1(ctl_tx_custom_vl_length_minus1),                    // input wire [15 : 0] ctl_tx_custom_vl_length_minus1
  .ctl_vl_marker_id0(ctl_vl_marker_id0),                                              // input wire [63 : 0] ctl_vl_marker_id0
  .ctl_vl_marker_id1(ctl_vl_marker_id1),                                              // input wire [63 : 0] ctl_vl_marker_id1
  .ctl_vl_marker_id2(ctl_vl_marker_id2),                                              // input wire [63 : 0] ctl_vl_marker_id2
  .ctl_vl_marker_id3(ctl_vl_marker_id3),                                              // input wire [63 : 0] ctl_vl_marker_id3
  .ctl_vl_marker_id4(ctl_vl_marker_id4),                                              // input wire [63 : 0] ctl_vl_marker_id4
  .ctl_vl_marker_id5(ctl_vl_marker_id5),                                              // input wire [63 : 0] ctl_vl_marker_id5
  .ctl_vl_marker_id6(ctl_vl_marker_id6),                                              // input wire [63 : 0] ctl_vl_marker_id6
  .ctl_vl_marker_id7(ctl_vl_marker_id7),                                              // input wire [63 : 0] ctl_vl_marker_id7
  .ctl_vl_marker_id8(ctl_vl_marker_id8),                                              // input wire [63 : 0] ctl_vl_marker_id8
  .ctl_vl_marker_id9(ctl_vl_marker_id9),                                              // input wire [63 : 0] ctl_vl_marker_id9
  .ctl_vl_marker_id10(ctl_vl_marker_id10),                                            // input wire [63 : 0] ctl_vl_marker_id10
  .ctl_vl_marker_id11(ctl_vl_marker_id11),                                            // input wire [63 : 0] ctl_vl_marker_id11
  .ctl_vl_marker_id12(ctl_vl_marker_id12),                                            // input wire [63 : 0] ctl_vl_marker_id12
  .ctl_vl_marker_id13(ctl_vl_marker_id13),                                            // input wire [63 : 0] ctl_vl_marker_id13
  .ctl_vl_marker_id14(ctl_vl_marker_id14),                                            // input wire [63 : 0] ctl_vl_marker_id14
  .ctl_vl_marker_id15(ctl_vl_marker_id15),                                            // input wire [63 : 0] ctl_vl_marker_id15
  .ctl_vl_marker_id16(ctl_vl_marker_id16),                                            // input wire [63 : 0] ctl_vl_marker_id16
  .ctl_vl_marker_id17(ctl_vl_marker_id17),                                            // input wire [63 : 0] ctl_vl_marker_id17
  .ctl_vl_marker_id18(ctl_vl_marker_id18),                                            // input wire [63 : 0] ctl_vl_marker_id18
  .ctl_vl_marker_id19(ctl_vl_marker_id19),                                            // input wire [63 : 0] ctl_vl_marker_id19
  .rsvd_in_rx_mac(rsvd_in_rx_mac),                                                    // input wire [7 : 0] rsvd_in_rx_mac
  .rsvd_in_rx_phy(rsvd_in_rx_phy),                                                    // input wire [7 : 0] rsvd_in_rx_phy
  .rx_all_channel_mac_pm_tick(rx_all_channel_mac_pm_tick),                            // input wire rx_all_channel_mac_pm_tick
  .rx_alt_serdes_clk(rx_alt_serdes_clk),                                              // input wire [5 : 0] rx_alt_serdes_clk
  .rx_axi_clk(rx_axi_clk),                                                            // input wire rx_axi_clk
  .rx_port_pm_tick(rx_port_pm_tick),                                                  // input wire [5 : 0] rx_port_pm_tick
  .rx_channel_flush(rx_channel_flush),                                                // input wire [5 : 0] rx_channel_flush
  .rx_core_clk(rx_core_clk),                                                          // input wire rx_core_clk
  .rx_core_reset(rx_core_reset),                                                      // input wire rx_core_reset
  .rx_flexif_clk(rx_flexif_clk),                                                      // input wire [5 : 0] rx_flexif_clk
  .rx_macif_clk(rx_macif_clk),                                                        // input wire rx_macif_clk
  .rx_serdes_clk(rx_serdes_clk),                                                      // input wire [5 : 0] rx_serdes_clk
  .rxdata_in_0(rxdata_in_0),                                                          // input wire [255 : 0] rxdata_in_0
  .rxdata_in_1(rxdata_in_1),                                                          // input wire [255 : 0] rxdata_in_1
  .rxdata_in_2(rxdata_in_2),                                                          // input wire [255 : 0] rxdata_in_2
  .rxdata_in_3(rxdata_in_3),                                                          // input wire [255 : 0] rxdata_in_3
  .rxdata_in_4(rxdata_in_4),                                                          // input wire [255 : 0] rxdata_in_4
  .rxdata_in_5(rxdata_in_5),                                                          // input wire [255 : 0] rxdata_in_5
  .rxdata_in_6(rxdata_in_6),                                                          // input wire [255 : 0] rxdata_in_6
  .rxdata_in_7(rxdata_in_7),                                                          // input wire [255 : 0] rxdata_in_7
  .rx_serdes_fifo_flagin_0(rx_serdes_fifo_flagin_0),                                  // input wire rx_serdes_fifo_flagin_0
  .rx_serdes_fifo_flagin_1(rx_serdes_fifo_flagin_1),                                  // input wire rx_serdes_fifo_flagin_1
  .rx_serdes_fifo_flagin_2(rx_serdes_fifo_flagin_2),                                  // input wire rx_serdes_fifo_flagin_2
  .rx_serdes_fifo_flagin_3(rx_serdes_fifo_flagin_3),                                  // input wire rx_serdes_fifo_flagin_3
  .rx_serdes_fifo_flagin_4(rx_serdes_fifo_flagin_4),                                  // input wire rx_serdes_fifo_flagin_4
  .rx_serdes_fifo_flagin_5(rx_serdes_fifo_flagin_5),                                  // input wire rx_serdes_fifo_flagin_5
  .rx_serdes_reset(rx_serdes_reset),                                                  // input wire [5 : 0] rx_serdes_reset
  .ts_clk(ts_clk),                                                                    // input wire [5 : 0] ts_clk
  .tx_all_channel_mac_pm_tick(tx_all_channel_mac_pm_tick),                            // input wire tx_all_channel_mac_pm_tick
  .tx_alt_serdes_clk(tx_alt_serdes_clk),                                              // input wire [5 : 0] tx_alt_serdes_clk
  .tx_axis_tdata0(tx_axis_tdata0),                                                    // input wire [127 : 0] tx_axis_tdata0
  .tx_axis_tdata1(tx_axis_tdata1),                                                    // input wire [127 : 0] tx_axis_tdata1
  .tx_axis_tdata2(tx_axis_tdata2),                                                    // input wire [127 : 0] tx_axis_tdata2
  .tx_axis_tdata3(tx_axis_tdata3),                                                    // input wire [127 : 0] tx_axis_tdata3
  .tx_axis_tdata4(tx_axis_tdata4),                                                    // input wire [127 : 0] tx_axis_tdata4
  .tx_axis_tdata5(tx_axis_tdata5),                                                    // input wire [127 : 0] tx_axis_tdata5
  .tx_axis_tdata6(tx_axis_tdata6),                                                    // input wire [127 : 0] tx_axis_tdata6
  .tx_axis_tdata7(tx_axis_tdata7),                                                    // input wire [127 : 0] tx_axis_tdata7
  .tx_axis_tuser_ena0(tx_axis_tuser_ena0),                                            // input wire tx_axis_tuser_ena0
  .tx_axis_tuser_ena1(tx_axis_tuser_ena1),                                            // input wire tx_axis_tuser_ena1
  .tx_axis_tuser_ena2(tx_axis_tuser_ena2),                                            // input wire tx_axis_tuser_ena2
  .tx_axis_tuser_ena3(tx_axis_tuser_ena3),                                            // input wire tx_axis_tuser_ena3
  .tx_axis_tuser_ena4(tx_axis_tuser_ena4),                                            // input wire tx_axis_tuser_ena4
  .tx_axis_tuser_ena5(tx_axis_tuser_ena5),                                            // input wire tx_axis_tuser_ena5
  .tx_axis_tuser_ena6(tx_axis_tuser_ena6),                                            // input wire tx_axis_tuser_ena6
  .tx_axis_tuser_ena7(tx_axis_tuser_ena7),                                            // input wire tx_axis_tuser_ena7
  .tx_axis_tuser_eop0(tx_axis_tuser_eop0),                                            // input wire tx_axis_tuser_eop0
  .tx_axis_tuser_eop1(tx_axis_tuser_eop1),                                            // input wire tx_axis_tuser_eop1
  .tx_axis_tuser_eop2(tx_axis_tuser_eop2),                                            // input wire tx_axis_tuser_eop2
  .tx_axis_tuser_eop3(tx_axis_tuser_eop3),                                            // input wire tx_axis_tuser_eop3
  .tx_axis_tuser_eop4(tx_axis_tuser_eop4),                                            // input wire tx_axis_tuser_eop4
  .tx_axis_tuser_eop5(tx_axis_tuser_eop5),                                            // input wire tx_axis_tuser_eop5
  .tx_axis_tuser_eop6(tx_axis_tuser_eop6),                                            // input wire tx_axis_tuser_eop6
  .tx_axis_tuser_eop7(tx_axis_tuser_eop7),                                            // input wire tx_axis_tuser_eop7
  .tx_axis_tuser_err0(tx_axis_tuser_err0),                                            // input wire tx_axis_tuser_err0
  .tx_axis_tuser_err1(tx_axis_tuser_err1),                                            // input wire tx_axis_tuser_err1
  .tx_axis_tuser_err2(tx_axis_tuser_err2),                                            // input wire tx_axis_tuser_err2
  .tx_axis_tuser_err3(tx_axis_tuser_err3),                                            // input wire tx_axis_tuser_err3
  .tx_axis_tuser_err4(tx_axis_tuser_err4),                                            // input wire tx_axis_tuser_err4
  .tx_axis_tuser_err5(tx_axis_tuser_err5),                                            // input wire tx_axis_tuser_err5
  .tx_axis_tuser_err6(tx_axis_tuser_err6),                                            // input wire tx_axis_tuser_err6
  .tx_axis_tuser_err7(tx_axis_tuser_err7),                                            // input wire tx_axis_tuser_err7
  .tx_axis_tuser_mty0(tx_axis_tuser_mty0),                                            // input wire [3 : 0] tx_axis_tuser_mty0
  .tx_axis_tuser_mty1(tx_axis_tuser_mty1),                                            // input wire [3 : 0] tx_axis_tuser_mty1
  .tx_axis_tuser_mty2(tx_axis_tuser_mty2),                                            // input wire [3 : 0] tx_axis_tuser_mty2
  .tx_axis_tuser_mty3(tx_axis_tuser_mty3),                                            // input wire [3 : 0] tx_axis_tuser_mty3
  .tx_axis_tuser_mty4(tx_axis_tuser_mty4),                                            // input wire [3 : 0] tx_axis_tuser_mty4
  .tx_axis_tuser_mty5(tx_axis_tuser_mty5),                                            // input wire [3 : 0] tx_axis_tuser_mty5
  .tx_axis_tuser_mty6(tx_axis_tuser_mty6),                                            // input wire [3 : 0] tx_axis_tuser_mty6
  .tx_axis_tuser_mty7(tx_axis_tuser_mty7),                                            // input wire [3 : 0] tx_axis_tuser_mty7
  .tx_axis_tuser_sop0(tx_axis_tuser_sop0),                                            // input wire tx_axis_tuser_sop0
  .tx_axis_tuser_sop1(tx_axis_tuser_sop1),                                            // input wire tx_axis_tuser_sop1
  .tx_axis_tuser_sop2(tx_axis_tuser_sop2),                                            // input wire tx_axis_tuser_sop2
  .tx_axis_tuser_sop3(tx_axis_tuser_sop3),                                            // input wire tx_axis_tuser_sop3
  .tx_axis_tuser_sop4(tx_axis_tuser_sop4),                                            // input wire tx_axis_tuser_sop4
  .tx_axis_tuser_sop5(tx_axis_tuser_sop5),                                            // input wire tx_axis_tuser_sop5
  .tx_axis_tuser_sop6(tx_axis_tuser_sop6),                                            // input wire tx_axis_tuser_sop6
  .tx_axis_tuser_sop7(tx_axis_tuser_sop7),                                            // input wire tx_axis_tuser_sop7
  .tx_axis_tvalid_0(tx_axis_tvalid_0),                                                // input wire tx_axis_tvalid_0
  .tx_axis_tvalid_2(tx_axis_tvalid_2),                                                // input wire tx_axis_tvalid_2
  .tx_axi_clk(tx_axi_clk),                                                            // input wire tx_axi_clk
  .tx_channel_flush(tx_channel_flush),                                                // input wire [5 : 0] tx_channel_flush
  .tx_core_clk(tx_core_clk),                                                          // input wire tx_core_clk
  .tx_core_reset(tx_core_reset),                                                      // input wire tx_core_reset
  .tx_flexif_clk(tx_flexif_clk),                                                      // input wire [5 : 0] tx_flexif_clk
  .tx_macif_clk(tx_macif_clk),                                                        // input wire tx_macif_clk
  .tx_port_pm_tick(tx_port_pm_tick),                                                  // input wire [5 : 0] tx_port_pm_tick
  .tx_preamblein_0(tx_preamblein_0),                                                  // input wire [55 : 0] tx_preamblein_0
  .tx_preamblein_2(tx_preamblein_2),                                                  // input wire [55 : 0] tx_preamblein_2
  .tx_serdes_clk(tx_serdes_clk),                                                      // input wire [5 : 0] tx_serdes_clk
  .tx_serdes_reset(tx_serdes_reset)                                                  // input wire [5 : 0] tx_serdes_reset
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

endmodule : xilinx_dcmac_wrapper
