// Tie off unused reset pair status
assign mod_rst_done[7:1] = '1;

smartnic #(
  .NUM_CMAC (NUM_CMAC_PORT),
  .MAX_PKT_LEN (MAX_PKT_LEN)
) smartnic (
  .s_axil_awvalid                  (s_axil_awvalid),
  .s_axil_awaddr                   (s_axil_awaddr),
  .s_axil_awready                  (s_axil_awready),
  .s_axil_wvalid                   (s_axil_wvalid),
  .s_axil_wdata                    (s_axil_wdata),
  .s_axil_wready                   (s_axil_wready),
  .s_axil_bvalid                   (s_axil_bvalid),
  .s_axil_bresp                    (s_axil_bresp),
  .s_axil_bready                   (s_axil_bready),
  .s_axil_arvalid                  (s_axil_arvalid),
  .s_axil_araddr                   (s_axil_araddr),
  .s_axil_arready                  (s_axil_arready),
  .s_axil_rvalid                   (s_axil_rvalid),
  .s_axil_rdata                    (s_axil_rdata),
  .s_axil_rresp                    (s_axil_rresp),
  .s_axil_rready                   (s_axil_rready),

  .s_axis_adpt_tx_322mhz_tvalid    (s_axis_adap_tx_322mhz_tvalid),
  .s_axis_adpt_tx_322mhz_tdata     (s_axis_adap_tx_322mhz_tdata),
  .s_axis_adpt_tx_322mhz_tkeep     (s_axis_adap_tx_322mhz_tkeep),
  .s_axis_adpt_tx_322mhz_tlast     (s_axis_adap_tx_322mhz_tlast),
  .s_axis_adpt_tx_322mhz_tid       (s_axis_adap_tx_322mhz_tid),
  .s_axis_adpt_tx_322mhz_tdest     ({2'b01, 2'b00}),
  .s_axis_adpt_tx_322mhz_tuser_err (s_axis_adap_tx_322mhz_tuser_err),
  .s_axis_adpt_tx_322mhz_tready    (s_axis_adap_tx_322mhz_tready),

  .m_axis_adpt_rx_322mhz_tvalid    (m_axis_adap_rx_322mhz_tvalid),
  .m_axis_adpt_rx_322mhz_tdata     (m_axis_adap_rx_322mhz_tdata),
  .m_axis_adpt_rx_322mhz_tkeep     (m_axis_adap_rx_322mhz_tkeep),
  .m_axis_adpt_rx_322mhz_tlast     (m_axis_adap_rx_322mhz_tlast),
  .m_axis_adpt_rx_322mhz_tdest     (),
  .m_axis_adpt_rx_322mhz_tuser_err (m_axis_adap_rx_322mhz_tuser_err),
  .m_axis_adpt_rx_322mhz_tuser_rss_enable  (m_axis_adap_rx_322mhz_tuser_qid_valid),
  .m_axis_adpt_rx_322mhz_tuser_rss_entropy (m_axis_adap_rx_322mhz_tuser_qid),
  .m_axis_adpt_rx_322mhz_tready    (m_axis_adap_rx_322mhz_tready),

  .m_axis_cmac_tx_322mhz_tvalid           (m_axis_cmac_tx_tvalid),
  .m_axis_cmac_tx_322mhz_tdata            (m_axis_cmac_tx_tdata),
  .m_axis_cmac_tx_322mhz_tkeep            (m_axis_cmac_tx_tkeep),
  .m_axis_cmac_tx_322mhz_tlast            (m_axis_cmac_tx_tlast),
  .m_axis_cmac_tx_322mhz_tdest            (),
  .m_axis_cmac_tx_322mhz_tuser_err        (m_axis_cmac_tx_tuser_err),
  .m_axis_cmac_tx_322mhz_tready           (m_axis_cmac_tx_tready),

  .s_axis_cmac_rx_322mhz_tvalid           (s_axis_cmac_rx_tvalid),
  .s_axis_cmac_rx_322mhz_tdata            (s_axis_cmac_rx_tdata),
  .s_axis_cmac_rx_322mhz_tkeep            (s_axis_cmac_rx_tkeep),
  .s_axis_cmac_rx_322mhz_tlast            (s_axis_cmac_rx_tlast),
  .s_axis_cmac_rx_322mhz_tdest            ('0),
  .s_axis_cmac_rx_322mhz_tuser_err        (s_axis_cmac_rx_tuser_err),
  .s_axis_cmac_rx_322mhz_tready           (),

  .mod_rstn                        (mod_rstn[0]),
  .mod_rst_done                    (mod_rst_done[0]),

  .axil_aclk                       (axil_aclk),
  .cmac_clk                        (cmac_clk)
);
