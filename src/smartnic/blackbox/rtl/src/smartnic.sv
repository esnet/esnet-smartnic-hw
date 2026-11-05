// smartnic module black box. Used for platform level builds.
(*black_box*) module smartnic
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
  input [NUM_CMAC-1:0]        cmac_clk,
  output                      core_clk
);

endmodule: smartnic
