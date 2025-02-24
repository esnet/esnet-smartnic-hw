initial begin
  if (NUM_PHYS_FUNC == 0) begin
    $fatal("No implementation for NUM_PHYS_FUNC = 0.");
  end
end

// Tie off unused reset pair status
assign mod_rst_done[15:1] = '1;

smartnic_250mhz #(
  .NUM_INTF (NUM_PHYS_FUNC)
) smartnic_250mhz_inst (
  .s_axil_awvalid                   (s_axil_awvalid),
  .s_axil_awaddr                    (s_axil_awaddr),
  .s_axil_awready                   (s_axil_awready),
  .s_axil_wvalid                    (s_axil_wvalid),
  .s_axil_wdata                     (s_axil_wdata),
  .s_axil_wready                    (s_axil_wready),
  .s_axil_bvalid                    (s_axil_bvalid),
  .s_axil_bresp                     (s_axil_bresp),
  .s_axil_bready                    (s_axil_bready),
  .s_axil_arvalid                   (s_axil_arvalid),
  .s_axil_araddr                    (s_axil_araddr),
  .s_axil_arready                   (s_axil_arready),
  .s_axil_rvalid                    (s_axil_rvalid),
  .s_axil_rdata                     (s_axil_rdata),
  .s_axil_rresp                     (s_axil_rresp),
  .s_axil_rready                    (s_axil_rready),

  .s_axis_qdma_h2c_tvalid           (s_axis_qdma_h2c_tvalid),
  .s_axis_qdma_h2c_tdata            (s_axis_qdma_h2c_tdata),
  .s_axis_qdma_h2c_tkeep            (s_axis_qdma_h2c_tkeep),
  .s_axis_qdma_h2c_tlast            (s_axis_qdma_h2c_tlast),
  .s_axis_qdma_h2c_tuser_size       (s_axis_qdma_h2c_tuser_size),
  .s_axis_qdma_h2c_tuser_src        (s_axis_qdma_h2c_tuser_src),
  .s_axis_qdma_h2c_tuser_dst        (s_axis_qdma_h2c_tuser_dst),
  .s_axis_qdma_h2c_tready           (s_axis_qdma_h2c_tready),

  .m_axis_qdma_c2h_tvalid           (m_axis_qdma_c2h_tvalid),
  .m_axis_qdma_c2h_tdata            (m_axis_qdma_c2h_tdata),
  .m_axis_qdma_c2h_tkeep            (m_axis_qdma_c2h_tkeep),
  .m_axis_qdma_c2h_tlast            (m_axis_qdma_c2h_tlast),
  .m_axis_qdma_c2h_tuser_size       (m_axis_qdma_c2h_tuser_size),
  .m_axis_qdma_c2h_tuser_src        (m_axis_qdma_c2h_tuser_src),
  .m_axis_qdma_c2h_tuser_dst        (m_axis_qdma_c2h_tuser_dst),
  .m_axis_qdma_c2h_tuser_rss_hash_valid  (m_axis_qdma_c2h_tuser_qid_valid),
  .m_axis_qdma_c2h_tuser_rss_hash        (m_axis_qdma_c2h_tuser_qid),
  .m_axis_qdma_c2h_tready           (m_axis_qdma_c2h_tready),

  .m_axis_adap_tx_250mhz_tvalid     (m_axis_adap_tx_250mhz_tvalid),
  .m_axis_adap_tx_250mhz_tdata      (m_axis_adap_tx_250mhz_tdata),
  .m_axis_adap_tx_250mhz_tkeep      (m_axis_adap_tx_250mhz_tkeep),
  .m_axis_adap_tx_250mhz_tlast      (m_axis_adap_tx_250mhz_tlast),
  .m_axis_adap_tx_250mhz_tuser_size (m_axis_adap_tx_250mhz_tuser_size),
  .m_axis_adap_tx_250mhz_tuser_src  (m_axis_adap_tx_250mhz_tuser_src),
  .m_axis_adap_tx_250mhz_tuser_dst  (m_axis_adap_tx_250mhz_tuser_dst),
  .m_axis_adap_tx_250mhz_tready     (m_axis_adap_tx_250mhz_tready),

  .s_axis_adap_rx_250mhz_tvalid     (s_axis_adap_rx_250mhz_tvalid),
  .s_axis_adap_rx_250mhz_tdata      (s_axis_adap_rx_250mhz_tdata),
  .s_axis_adap_rx_250mhz_tkeep      (s_axis_adap_rx_250mhz_tkeep),
  .s_axis_adap_rx_250mhz_tlast      (s_axis_adap_rx_250mhz_tlast),
  .s_axis_adap_rx_250mhz_tuser_size (s_axis_adap_rx_250mhz_tuser_size),
  .s_axis_adap_rx_250mhz_tuser_src  (s_axis_adap_rx_250mhz_tuser_src),
  .s_axis_adap_rx_250mhz_tuser_dst  (s_axis_adap_rx_250mhz_tuser_dst),
  .s_axis_adap_rx_250mhz_tuser_rss_hash_valid  (s_axis_adap_rx_250mhz_tuser_qid_valid),
  .s_axis_adap_rx_250mhz_tuser_rss_hash        (s_axis_adap_rx_250mhz_tuser_qid),
  .s_axis_adap_rx_250mhz_tready     (s_axis_adap_rx_250mhz_tready),

  .mod_rstn                         (mod_rstn[0]),
  .mod_rst_done                     (mod_rst_done[0]),

`ifdef __au55n__
  .ref_clk_100mhz                   (ref_clk_100mhz),
`elsif __au55c_
  .ref_clk_100mhz                   (ref_clk_100mhz),
`elsif __au50__
  .ref_clk_100mhz                   (ref_clk_100mhz),
`elsif __au280__
  .ref_clk_100mhz                   (ref_clk_100mhz),
`endif

  .axil_aclk                        (axil_aclk),
  .axis_aclk                        (axis_aclk)
);
