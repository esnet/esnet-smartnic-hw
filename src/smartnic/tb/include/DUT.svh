    // Local parameters
    localparam int NUM_CMAC = 2;
    localparam int AXIS_DATA_WID = 512;
    localparam int AXIS_DATA_BYTE_WID = AXIS_DATA_WID/8;

    //===================================
    // Device Under Test
    //===================================

    // Signals
    logic        s_axil_awvalid;
    logic [31:0] s_axil_awaddr;
    logic        s_axil_awready;
    logic        s_axil_wvalid;
    logic [31:0] s_axil_wdata;
    logic        s_axil_wready;
    logic        s_axil_bvalid;
    logic  [1:0] s_axil_bresp;
    logic        s_axil_bready;
    logic        s_axil_arvalid;
    logic [31:0] s_axil_araddr;
    logic        s_axil_arready;
    logic        s_axil_rvalid;
    logic [31:0] s_axil_rdata;
    logic  [1:0] s_axil_rresp;
    logic        s_axil_rready;

    logic       [NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tvalid;
    logic [(512*NUM_CMAC)-1:0] s_axis_adpt_tx_322mhz_tdata;
    logic  [(64*NUM_CMAC)-1:0] s_axis_adpt_tx_322mhz_tkeep;
    logic       [NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tlast;
    logic    [16*NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tid;
    logic     [2*NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tdest;
    logic       [NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tuser_err;
    logic       [NUM_CMAC-1:0] s_axis_adpt_tx_322mhz_tready;

    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tvalid;
    logic [(512*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tdata;
    logic  [(64*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tkeep;
    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tlast;
    logic   [(4*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tdest;
    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tuser_err;
    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tuser_rss_enable;
    logic  [(12*NUM_CMAC)-1:0] m_axis_adpt_rx_322mhz_tuser_rss_entropy;
    logic       [NUM_CMAC-1:0] m_axis_adpt_rx_322mhz_tready;

    logic       [NUM_CMAC-1:0] m_axis_cmac_tx_322mhz_tvalid;
    logic [(512*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tdata;
    logic  [(64*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tkeep;
    logic       [NUM_CMAC-1:0] m_axis_cmac_tx_322mhz_tlast;
    logic   [(4*NUM_CMAC)-1:0] m_axis_cmac_tx_322mhz_tdest;
    logic       [NUM_CMAC-1:0] m_axis_cmac_tx_322mhz_tuser_err;
    logic       [NUM_CMAC-1:0] m_axis_cmac_tx_322mhz_tready;

    logic       [NUM_CMAC-1:0] s_axis_cmac_rx_322mhz_tvalid;
    logic [(512*NUM_CMAC)-1:0] s_axis_cmac_rx_322mhz_tdata;
    logic  [(64*NUM_CMAC)-1:0] s_axis_cmac_rx_322mhz_tkeep;
    logic       [NUM_CMAC-1:0] s_axis_cmac_rx_322mhz_tlast;
    logic   [(2*NUM_CMAC)-1:0] s_axis_cmac_rx_322mhz_tdest;
    logic       [NUM_CMAC-1:0] s_axis_cmac_rx_322mhz_tuser_err;
    logic       [NUM_CMAC-1:0] s_axis_cmac_rx_322mhz_tready;

    logic                      mod_rstn;
    logic                      mod_rst_done;

    logic                      axil_aclk;
    logic       [NUM_CMAC-1:0] cmac_clk;

    // DUT instance
    smartnic #(.NUM_CMAC(NUM_CMAC)) DUT(.*);

    //===================================
    // Local signals
    //===================================

    logic start_rx = 1'b1;

    // Interfaces
    axi4l_intf axil_if ();    

    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(adpt_tx_tid_t), .TDEST_T(igr_tdest_t)) axis_cmac_igr [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t),        .TDEST_T(port_t))      axis_cmac_egr [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(adpt_tx_tid_t), .TDEST_T(igr_tdest_t)) axis_h2c      [NUM_CMAC] ();
    axi4s_intf #(.DATA_BYTE_WID(AXIS_DATA_BYTE_WID), .TID_T(port_t),        .TDEST_T(port_t), 
                 .TUSER_T(tuser_smartnic_meta_t))                                                  axis_c2h      [NUM_CMAC] ();

    // Assign AXI-L control interface
    assign s_axil_awvalid = axil_if.awvalid;
    assign s_axil_awaddr = axil_if.awaddr;
    assign s_axil_wvalid = axil_if.wvalid;
    assign s_axil_wdata = axil_if.wdata;
    assign s_axil_bready = axil_if.bready;
    assign s_axil_arvalid = axil_if.arvalid;
    assign s_axil_araddr = axil_if.araddr;
    assign s_axil_rready = axil_if.rready;
    assign axil_if.awready = s_axil_awready;
    assign axil_if.wready = s_axil_wready;
    assign axil_if.bvalid = s_axil_bvalid;
    assign axil_if.bresp = s_axil_bresp;
    assign axil_if.arready = s_axil_arready;
    assign axil_if.rvalid = s_axil_rvalid;
    assign axil_if.rdata = s_axil_rdata;
    assign axil_if.rresp = s_axil_rresp;

    // Assign AXI-S CMAC input interfaces
    assign s_axis_cmac_rx_322mhz_tvalid[0]    = axis_cmac_igr[0].tvalid;
    assign s_axis_cmac_rx_322mhz_tlast[0]     = axis_cmac_igr[0].tlast;
    assign s_axis_cmac_rx_322mhz_tdest[1:0]   = axis_cmac_igr[0].tdest;
    assign s_axis_cmac_rx_322mhz_tdata[511:0] = axis_cmac_igr[0].tdata;
    assign s_axis_cmac_rx_322mhz_tkeep[63:0]  = axis_cmac_igr[0].tkeep;
    assign s_axis_cmac_rx_322mhz_tuser_err[0] = axis_cmac_igr[0].tuser;
    assign axis_cmac_igr[0].tready = s_axis_cmac_rx_322mhz_tready[0];

    assign s_axis_cmac_rx_322mhz_tvalid[1]    = axis_cmac_igr[1].tvalid;
    assign s_axis_cmac_rx_322mhz_tlast[1]     = axis_cmac_igr[1].tlast;
    assign s_axis_cmac_rx_322mhz_tdest[3:2]   = axis_cmac_igr[1].tdest;
    assign s_axis_cmac_rx_322mhz_tdata[1023:512] = axis_cmac_igr[1].tdata;
    assign s_axis_cmac_rx_322mhz_tkeep[127:64]  = axis_cmac_igr[1].tkeep;
    assign s_axis_cmac_rx_322mhz_tuser_err[1] = axis_cmac_igr[1].tuser;
    assign axis_cmac_igr[1].tready = s_axis_cmac_rx_322mhz_tready[1];

    // Assign AXI-S CMAC output interfaces
    assign axis_cmac_egr[0].tvalid = m_axis_cmac_tx_322mhz_tvalid[0] && start_rx;
    assign axis_cmac_egr[0].tlast  = m_axis_cmac_tx_322mhz_tlast[0];
    assign axis_cmac_egr[0].tdest  = 'hx; // unused by open_nic_shell.
    assign axis_cmac_egr[0].tdata  = m_axis_cmac_tx_322mhz_tdata[511:0];
    assign axis_cmac_egr[0].tkeep  = m_axis_cmac_tx_322mhz_tkeep[63:0];
    assign axis_cmac_egr[0].tuser  = m_axis_cmac_tx_322mhz_tuser_err[0];
    assign m_axis_cmac_tx_322mhz_tready[0] = axis_cmac_egr[0].tready && start_rx;

    assign axis_cmac_egr[1].tvalid = m_axis_cmac_tx_322mhz_tvalid[1] && start_rx;
    assign axis_cmac_egr[1].tlast  = m_axis_cmac_tx_322mhz_tlast[1];
    assign axis_cmac_egr[1].tdest  = 'hx; // unused by open_nic_shell.
    assign axis_cmac_egr[1].tdata  = m_axis_cmac_tx_322mhz_tdata[1023:512];
    assign axis_cmac_egr[1].tkeep  = m_axis_cmac_tx_322mhz_tkeep[127:64];
    assign axis_cmac_egr[1].tuser  = m_axis_cmac_tx_322mhz_tuser_err[1];
    assign m_axis_cmac_tx_322mhz_tready[1] = axis_cmac_egr[1].tready && start_rx;

    // Assign AXI-S ADPT input interfaces
    assign s_axis_adpt_tx_322mhz_tvalid[0]    = axis_h2c[0].tvalid;
    assign s_axis_adpt_tx_322mhz_tlast[0]     = axis_h2c[0].tlast;
    assign s_axis_adpt_tx_322mhz_tid[15:0]    = axis_h2c[0].tid;
    assign s_axis_adpt_tx_322mhz_tdest[1:0]   = axis_h2c[0].tdest;
    assign s_axis_adpt_tx_322mhz_tdata[511:0] = axis_h2c[0].tdata;
    assign s_axis_adpt_tx_322mhz_tkeep[63:0]  = axis_h2c[0].tkeep;
    assign s_axis_adpt_tx_322mhz_tuser_err[0] = axis_h2c[0].tuser;
    assign axis_h2c[0].tready = s_axis_adpt_tx_322mhz_tready[0];

    assign s_axis_adpt_tx_322mhz_tvalid[1]    = axis_h2c[1].tvalid;
    assign s_axis_adpt_tx_322mhz_tlast[1]     = axis_h2c[1].tlast;
    assign s_axis_adpt_tx_322mhz_tid[31:16]   = axis_h2c[1].tid;
    assign s_axis_adpt_tx_322mhz_tdest[3:2]   = axis_h2c[1].tdest;
    assign s_axis_adpt_tx_322mhz_tdata[1023:512] = axis_h2c[1].tdata;
    assign s_axis_adpt_tx_322mhz_tkeep[127:64]  = axis_h2c[1].tkeep;
    assign s_axis_adpt_tx_322mhz_tuser_err[1] = axis_h2c[1].tuser;
    assign axis_h2c[1].tready = s_axis_adpt_tx_322mhz_tready[1];

    // Assign AXI-S ADPT output interfaces
    assign axis_c2h[0].tvalid = m_axis_adpt_rx_322mhz_tvalid[0] && start_rx;
    assign axis_c2h[0].tlast  = m_axis_adpt_rx_322mhz_tlast[0];
    assign axis_c2h[0].tdest  = 'hx; // unused by open_nic_shell.
    assign axis_c2h[0].tdata  = m_axis_adpt_rx_322mhz_tdata[511:0];
    assign axis_c2h[0].tkeep  = m_axis_adpt_rx_322mhz_tkeep[63:0];
    assign axis_c2h[0].tuser.rss_enable  = m_axis_adpt_rx_322mhz_tuser_rss_enable[0];
    assign axis_c2h[0].tuser.rss_entropy = m_axis_adpt_rx_322mhz_tuser_rss_entropy[11:0];
    assign m_axis_adpt_rx_322mhz_tready[0] = axis_c2h[0].tready && start_rx;

    assign axis_c2h[1].tvalid = m_axis_adpt_rx_322mhz_tvalid[1] && start_rx;
    assign axis_c2h[1].tlast  = m_axis_adpt_rx_322mhz_tlast[1];
    assign axis_c2h[1].tdest  = 'hx; // unused by open_nic_shell.
    assign axis_c2h[1].tdata  = m_axis_adpt_rx_322mhz_tdata[1023:512];
    assign axis_c2h[1].tkeep  = m_axis_adpt_rx_322mhz_tkeep[127:64];
    assign axis_c2h[1].tuser.rss_enable  = m_axis_adpt_rx_322mhz_tuser_rss_enable[1];
    assign axis_c2h[1].tuser.rss_entropy = m_axis_adpt_rx_322mhz_tuser_rss_entropy[23:12];
    assign m_axis_adpt_rx_322mhz_tready[1] = axis_c2h[1].tready && start_rx;
