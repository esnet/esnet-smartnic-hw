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
  input [NUM_CMAC-1:0]        cmac_clk,
  output                      core_clk
);

    // Interfaces
    axi4l_intf axil_if ();

    // -------------------------------------------------------------------------------------------------------
    // MAP FROM 'FLAT' SIGNAL REPRESENTATION TO INTERFACE REPRESENTATION
    // -------------------------------------------------------------------------------------------------------
    axi4l_intf_from_signals axil_if_from_signals (
        .aclk     ( axil_aclk ),
        .aresetn  ( mod_rstn ),
        .awvalid  ( s_axil_awvalid ),
        .awready  ( s_axil_awready ),
        .awaddr   ( s_axil_awaddr ),
        .awprot   ( 3'b000 ),
        .wvalid   ( s_axil_wvalid ),
        .wready   ( s_axil_wready ),
        .wdata    ( s_axil_wdata ),
        .wstrb    ( 4'hf ),
        .bvalid   ( s_axil_bvalid ),
        .bready   ( s_axil_bready ),
        .bresp    ( s_axil_bresp ),
        .arvalid  ( s_axil_arvalid ),
        .arready  ( s_axil_arready ),
        .araddr   ( s_axil_araddr ),
        .arprot   ( 3'b000 ),
        .rvalid   ( s_axil_rvalid ),
        .rready   ( s_axil_rready ),
        .rdata    ( s_axil_rdata ),
        .rresp    ( s_axil_rresp ),
        .axi4l_if ( axil_if )
    );

    // -------------------------------------------------------------------------------------------------------
    // STUB CONNECTIVITY
    // -------------------------------------------------------------------------------------------------------

    // Terminate AXI-L interface (unused)
    axi4l_intf_peripheral_term axi4l_intf_peripheral_term ( .axi4l_if(axil_if) );

    // Sink all inbound AXI-S streams
    assign s_axis_adpt_tx_322mhz_tready = '1;
    assign s_axis_cmac_rx_322mhz_tready = '1;

    // Terminate all outbound AXI-S streams
    assign m_axis_adpt_rx_322mhz_tvalid           = '0;
    assign m_axis_adpt_rx_322mhz_tdata            = '0;
    assign m_axis_adpt_rx_322mhz_tkeep            = '0;
    assign m_axis_adpt_rx_322mhz_tlast            = '0;
    assign m_axis_adpt_rx_322mhz_tdest            = '0;
    assign m_axis_adpt_rx_322mhz_tuser_err        = '0;
    assign m_axis_adpt_rx_322mhz_tuser_rss_enable = '0;
    assign m_axis_adpt_rx_322mhz_tuser_rss_entropy = '0;

    assign m_axis_cmac_tx_322mhz_tvalid    = '0;
    assign m_axis_cmac_tx_322mhz_tdata     = '0;
    assign m_axis_cmac_tx_322mhz_tkeep     = '0;
    assign m_axis_cmac_tx_322mhz_tlast     = '0;
    assign m_axis_cmac_tx_322mhz_tdest     = '0;
    assign m_axis_cmac_tx_322mhz_tuser_err = '0;

    // Reset handshake and clocking
    assign mod_rst_done = 1'b1;
    assign core_clk     = axil_aclk;

endmodule: smartnic
