// Xilinx Versal GTM Wrapper
module xilinx_gtm_wrapper (
    // Clocks/resets.
    input  logic        gtwiz_freerun_clk,
    input  logic        QUAD0_GTREFCLK0,

    output logic        QUAD0_TX0_outclk,
    output logic        QUAD0_RX0_outclk,

    input  logic        gt_tx_usrclk,
    input  logic        gt_rx_usrclk,

    output logic        INTF0_TX_clr_out,
    output logic        INTF0_TX_clrb_leaf_out,
    output logic        INTF0_RX_clr_out,
    output logic        INTF0_RX_clrb_leaf_out,
    input  logic        INTF0_rst_all_in,
    input  logic        INTF0_rst_tx_datapath_in,
    output logic        INTF0_rst_tx_done_out,
    input  logic        INTF0_rst_rx_datapath_in,
    output logic        INTF0_rst_rx_done_out,

    // Configuration signals.
    input  logic [2:0]  gt_loopback,

    input  logic [7:0]  gt_txrate,
    input  logic [5:0]  gt_txprecursor,
    input  logic [5:0]  gt_txpostcursor,
    input  logic [6:0]  gt_txmaincursor,

    input  logic [7:0]  gt_rxrate,
    input  logic        gt_rxcdrhold,

    // Status signals.
    output logic        gtpowergood,

    // Serial IO connections.
    input  logic [3:0]  QUAD0_rxp,
    input  logic [3:0]  QUAD0_rxn,
    output logic [3:0]  QUAD0_txp,
    output logic [3:0]  QUAD0_txn,

    // Internal bus connections.
    input  logic [3:0][255:0] gt_txdata,
    output logic [3:0][255:0] gt_rxdata,

    // AXI-L Interface
    axi4l_intf.peripheral axil_if
);

    // =========================================================================
    // Imports
    // =========================================================================


    // =========================================================================
    // Signals
    // =========================================================================
    //logic          gtpowergood;        // output port
    //logic          gtwiz_freerun_clk;  //  input port
    //logic          QUAD0_GTREFCLK0;    //  input port

    logic          QUAD0_s_axi_lite_resetn;
    logic [17:0]   QUAD0_s_axi_lite_araddr;
    logic          QUAD0_s_axi_lite_arvalid;
    logic          QUAD0_s_axi_lite_arready;
    logic [31:0]   QUAD0_s_axi_lite_rdata;
    logic          QUAD0_s_axi_lite_rvalid;
    logic          QUAD0_s_axi_lite_rready;
    logic [17:0]   QUAD0_s_axi_lite_awaddr;
    logic          QUAD0_s_axi_lite_awvalid;
    logic          QUAD0_s_axi_lite_awready;
    logic [31:0]   QUAD0_s_axi_lite_wdata;
    logic          QUAD0_s_axi_lite_wvalid;
    logic          QUAD0_s_axi_lite_wready;
    logic [1:0]    QUAD0_s_axi_lite_rresp;
    logic [1:0]    QUAD0_s_axi_lite_bresp;
    logic          QUAD0_s_axi_lite_bvalid;
    logic          QUAD0_s_axi_lite_bready;

    // logic          QUAD0_TX0_outclk;  // output port
    // logic          QUAD0_RX0_outclk;  // output port
    // logic [3:0]    QUAD0_rxp;  // input port
    // logic [3:0]    QUAD0_rxn;  // input port
    // logic [3:0]    QUAD0_txp;  // input port
    // logic [3:0]    QUAD0_txn;  // input port

    logic [2:0]    QUAD0_ch0_loopback;
    logic [2:0]    QUAD0_ch1_loopback;
    logic [2:0]    QUAD0_ch2_loopback;
    logic [2:0]    QUAD0_ch3_loopback;
    logic [31:0]   QUAD0_gpi = '0;
    logic [31:0]   QUAD0_gpo;

    logic          QUAD0_TX0_usrclk;
    logic          QUAD0_TX1_usrclk;
    logic          QUAD0_TX2_usrclk;
    logic          QUAD0_TX3_usrclk;
    logic          QUAD0_RX0_usrclk;
    logic          QUAD0_RX1_usrclk;
    logic          QUAD0_RX2_usrclk;
    logic          QUAD0_RX3_usrclk;

    logic [255:0]  INTF0_TX0_ch_txdata;
    logic [6:0]    INTF0_TX0_ch_txmaincursor;
    logic [5:0]    INTF0_TX0_ch_txpostcursor;
    logic [5:0]    INTF0_TX0_ch_txprecursor;
    logic [7:0]    INTF0_TX0_ch_txrate;
    logic [255:0]  INTF0_TX1_ch_txdata;
    logic [6:0]    INTF0_TX1_ch_txmaincursor;
    logic [5:0]    INTF0_TX1_ch_txpostcursor;
    logic [5:0]    INTF0_TX1_ch_txprecursor;
    logic [7:0]    INTF0_TX1_ch_txrate;
    logic [255:0]  INTF0_TX2_ch_txdata;
    logic [6:0]    INTF0_TX2_ch_txmaincursor;
    logic [5:0]    INTF0_TX2_ch_txpostcursor;
    logic [5:0]    INTF0_TX2_ch_txprecursor;
    logic [7:0]    INTF0_TX2_ch_txrate;
    logic [255:0]  INTF0_TX3_ch_txdata;
    logic [6:0]    INTF0_TX3_ch_txmaincursor;
    logic [5:0]    INTF0_TX3_ch_txpostcursor;
    logic [5:0]    INTF0_TX3_ch_txprecursor;
    logic [7:0]    INTF0_TX3_ch_txrate;

    logic          INTF0_RX0_ch_rxcdrhold;
    logic [7:0]    INTF0_RX0_ch_rxrate;
    logic [255:0]  INTF0_RX0_ch_rxdata;
    logic          INTF0_RX1_ch_rxcdrhold;
    logic [7:0]    INTF0_RX1_ch_rxrate;
    logic [255:0]  INTF0_RX1_ch_rxdata;
    logic          INTF0_RX2_ch_rxcdrhold;
    logic [7:0]    INTF0_RX2_ch_rxrate;
    logic [255:0]  INTF0_RX2_ch_rxdata;
    logic          INTF0_RX3_ch_rxcdrhold;
    logic [7:0]    INTF0_RX3_ch_rxrate;
    logic [255:0]  INTF0_RX3_ch_rxdata;

    // logic          INTF0_TX_clr_out;        // output port
    // logic          INTF0_TX_clrb_leaf_out;  // output port
    // logic          INTF0_RX_clr_out;        // output port
    // logic          INTF0_RX_clrb_leaf_out;  // output port
    // logic          INTF0_rst_all_in;        // input port
    logic          INTF0_rst_tx_pll_and_datapath_in;
    // logic          INTF0_rst_tx_datapath_in;  // input port
    // logic          INTF0_rst_tx_done_out;     // output port
    logic          INTF0_rst_rx_pll_and_datapath_in;
    // logic          INTF0_rst_rx_datapath_in;  // input port
    // logic          INTF0_rst_rx_done_out;     // output port


    // =========================================================================
    // Clocks
    // =========================================================================
    assign QUAD0_TX0_usrclk = gt_tx_usrclk;
    assign QUAD0_TX1_usrclk = gt_tx_usrclk;
    assign QUAD0_TX2_usrclk = gt_tx_usrclk;
    assign QUAD0_TX3_usrclk = gt_tx_usrclk;

    assign QUAD0_RX0_usrclk = gt_rx_usrclk;
    assign QUAD0_RX1_usrclk = gt_rx_usrclk;
    assign QUAD0_RX2_usrclk = gt_rx_usrclk;
    assign QUAD0_RX3_usrclk = gt_rx_usrclk;


    // =========================================================================
    // Resets
    // =========================================================================
    assign INTF0_rst_tx_pll_and_datapath_in = '0;
    assign INTF0_rst_rx_pll_and_datapath_in = '0;


    // =========================================================================
    // Configuration assignments
    // =========================================================================
    assign QUAD0_ch0_loopback = gt_loopback;
    assign QUAD0_ch1_loopback = gt_loopback;
    assign QUAD0_ch2_loopback = gt_loopback;
    assign QUAD0_ch3_loopback = gt_loopback;

    assign INTF0_TX0_ch_txrate       = gt_txrate;
    assign INTF0_TX0_ch_txmaincursor = gt_txmaincursor;
    assign INTF0_TX0_ch_txpostcursor = gt_txpostcursor;
    assign INTF0_TX0_ch_txprecursor  = gt_txprecursor;

    assign INTF0_TX1_ch_txrate       = gt_txrate;
    assign INTF0_TX1_ch_txmaincursor = gt_txmaincursor;
    assign INTF0_TX1_ch_txpostcursor = gt_txpostcursor;
    assign INTF0_TX1_ch_txprecursor  = gt_txprecursor;

    assign INTF0_TX2_ch_txrate       = gt_txrate;
    assign INTF0_TX2_ch_txmaincursor = gt_txmaincursor;
    assign INTF0_TX2_ch_txpostcursor = gt_txpostcursor;
    assign INTF0_TX2_ch_txprecursor  = gt_txprecursor;

    assign INTF0_TX3_ch_txrate       = gt_txrate;
    assign INTF0_TX3_ch_txmaincursor = gt_txmaincursor;
    assign INTF0_TX3_ch_txpostcursor = gt_txpostcursor;
    assign INTF0_TX3_ch_txprecursor  = gt_txprecursor;

    assign INTF0_RX0_ch_rxrate       = gt_rxrate;
    assign INTF0_RX0_ch_rxcdrhold    = gt_rxcdrhold;

    assign INTF0_RX1_ch_rxrate       = gt_rxrate;
    assign INTF0_RX1_ch_rxcdrhold    = gt_rxcdrhold;

    assign INTF0_RX2_ch_rxrate       = gt_rxrate;
    assign INTF0_RX2_ch_rxcdrhold    = gt_rxcdrhold;

    assign INTF0_RX3_ch_rxrate       = gt_rxrate;
    assign INTF0_RX3_ch_rxcdrhold    = gt_rxcdrhold;


    // =========================================================================
    // Data bus connections
    // =========================================================================
    assign INTF0_TX0_ch_txdata = gt_txdata[0];
    assign INTF0_TX1_ch_txdata = gt_txdata[1];
    assign INTF0_TX2_ch_txdata = gt_txdata[2];
    assign INTF0_TX3_ch_txdata = gt_txdata[3];

    assign gt_rxdata[0] = INTF0_RX0_ch_rxdata;
    assign gt_rxdata[1] = INTF0_RX1_ch_rxdata;
    assign gt_rxdata[2] = INTF0_RX2_ch_rxdata;
    assign gt_rxdata[3] = INTF0_RX3_ch_rxdata;


    // =========================================================================
    // AXI-L register access
    // =========================================================================
    assign QUAD0_s_axi_lite_resetn  = axil_if.aresetn;          // input wire QUAD0_s_axi_lite_resetn
    assign QUAD0_s_axi_lite_awaddr  = {4'h0, axil_if.awaddr[13:0]};  // input wire [17 : 0] QUAD0_s_axi_lite_awaddr
    assign QUAD0_s_axi_lite_awvalid = axil_if.awvalid;          // input wire QUAD0_s_axi_lite_awvalid
    assign axil_if.awready          = QUAD0_s_axi_lite_awready; // output wire QUAD0_s_axi_lite_awready
    assign QUAD0_s_axi_lite_wdata   = axil_if.wdata;            // input wire [31 : 0] QUAD0_s_axi_lite_wdata
    assign QUAD0_s_axi_lite_wvalid  = axil_if.wvalid;           // input wire QUAD0_s_axi_lite_wvalid
    assign axil_if.wready           = QUAD0_s_axi_lite_wready;  // output wire QUAD0_s_axi_lite_wready
    assign axil_if.bresp            = QUAD0_s_axi_lite_bresp;   // output wire [1 : 0] QUAD0_s_axi_lite_bresp
    assign axil_if.bvalid           = QUAD0_s_axi_lite_bvalid;  // output wire QUAD0_s_axi_lite_bvalid
    assign QUAD0_s_axi_lite_bready  = axil_if.bready;           // input wire QUAD0_s_axi_lite_bready
    assign QUAD0_s_axi_lite_araddr  = {4'h0, axil_if.araddr[13:0]};  // input wire [17 : 0] QUAD0_s_axi_lite_araddr
    assign QUAD0_s_axi_lite_arvalid = axil_if.arvalid;          // input wire QUAD0_s_axi_lite_arvalid
    assign axil_if.arready          = QUAD0_s_axi_lite_arready; // output wire QUAD0_s_axi_lite_arready
    assign axil_if.rdata            = QUAD0_s_axi_lite_rdata;   // output wire [31 : 0] QUAD0_s_axi_lite_rdata
    assign axil_if.rresp            = QUAD0_s_axi_lite_rresp;   // output wire [1 : 0] QUAD0_s_axi_lite_rresp
    assign axil_if.rvalid           = QUAD0_s_axi_lite_rvalid;  // output wire QUAD0_s_axi_lite_rvalid
    assign QUAD0_s_axi_lite_rready  = axil_if.rready;           // input wire QUAD0_s_axi_lite_rready


    // =========================================================================
    // GT IP instantiation
    // =========================================================================

    // NOTE: Use instantiation template exactly as provided in IP (including whitespace, but with
    //       generic instance name commented out) to enable trivial diffs to simplify upgrades or changes,
    //       identify added/removed signals, etc.

xilinx_gtm_0 i_xilinx_gtm_0 (
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
//xilinx_gtm_0 your_instance_name (
  .gtpowergood(gtpowergood),                                            // output wire gtpowergood
  .gtwiz_freerun_clk(gtwiz_freerun_clk),                                // input wire gtwiz_freerun_clk
  .QUAD0_GTREFCLK0(QUAD0_GTREFCLK0),                                    // input wire QUAD0_GTREFCLK0
  .QUAD0_s_axi_lite_resetn(QUAD0_s_axi_lite_resetn),                    // input wire QUAD0_s_axi_lite_resetn
  .QUAD0_s_axi_lite_araddr(QUAD0_s_axi_lite_araddr),                    // input wire [17 : 0] QUAD0_s_axi_lite_araddr
  .QUAD0_s_axi_lite_arvalid(QUAD0_s_axi_lite_arvalid),                  // input wire QUAD0_s_axi_lite_arvalid
  .QUAD0_s_axi_lite_arready(QUAD0_s_axi_lite_arready),                  // output wire QUAD0_s_axi_lite_arready
  .QUAD0_s_axi_lite_rdata(QUAD0_s_axi_lite_rdata),                      // output wire [31 : 0] QUAD0_s_axi_lite_rdata
  .QUAD0_s_axi_lite_rvalid(QUAD0_s_axi_lite_rvalid),                    // output wire QUAD0_s_axi_lite_rvalid
  .QUAD0_s_axi_lite_rready(QUAD0_s_axi_lite_rready),                    // input wire QUAD0_s_axi_lite_rready
  .QUAD0_s_axi_lite_awaddr(QUAD0_s_axi_lite_awaddr),                    // input wire [17 : 0] QUAD0_s_axi_lite_awaddr
  .QUAD0_s_axi_lite_awvalid(QUAD0_s_axi_lite_awvalid),                  // input wire QUAD0_s_axi_lite_awvalid
  .QUAD0_s_axi_lite_awready(QUAD0_s_axi_lite_awready),                  // output wire QUAD0_s_axi_lite_awready
  .QUAD0_s_axi_lite_wdata(QUAD0_s_axi_lite_wdata),                      // input wire [31 : 0] QUAD0_s_axi_lite_wdata
  .QUAD0_s_axi_lite_wvalid(QUAD0_s_axi_lite_wvalid),                    // input wire QUAD0_s_axi_lite_wvalid
  .QUAD0_s_axi_lite_wready(QUAD0_s_axi_lite_wready),                    // output wire QUAD0_s_axi_lite_wready
  .QUAD0_s_axi_lite_rresp(QUAD0_s_axi_lite_rresp),                      // output wire [1 : 0] QUAD0_s_axi_lite_rresp
  .QUAD0_s_axi_lite_bresp(QUAD0_s_axi_lite_bresp),                      // output wire [1 : 0] QUAD0_s_axi_lite_bresp
  .QUAD0_s_axi_lite_bvalid(QUAD0_s_axi_lite_bvalid),                    // output wire QUAD0_s_axi_lite_bvalid
  .QUAD0_s_axi_lite_bready(QUAD0_s_axi_lite_bready),                    // input wire QUAD0_s_axi_lite_bready
  .QUAD0_TX0_outclk(QUAD0_TX0_outclk),                                  // output wire QUAD0_TX0_outclk
  .QUAD0_RX0_outclk(QUAD0_RX0_outclk),                                  // output wire QUAD0_RX0_outclk
  .QUAD0_rxp(QUAD0_rxp),                                                // input wire [3 : 0] QUAD0_rxp
  .QUAD0_rxn(QUAD0_rxn),                                                // input wire [3 : 0] QUAD0_rxn
  .QUAD0_txp(QUAD0_txp),                                                // output wire [3 : 0] QUAD0_txp
  .QUAD0_txn(QUAD0_txn),                                                // output wire [3 : 0] QUAD0_txn
  .QUAD0_ch0_loopback(QUAD0_ch0_loopback),                              // input wire [2 : 0] QUAD0_ch0_loopback
  .QUAD0_ch1_loopback(QUAD0_ch1_loopback),                              // input wire [2 : 0] QUAD0_ch1_loopback
  .QUAD0_ch2_loopback(QUAD0_ch2_loopback),                              // input wire [2 : 0] QUAD0_ch2_loopback
  .QUAD0_ch3_loopback(QUAD0_ch3_loopback),                              // input wire [2 : 0] QUAD0_ch3_loopback
  .QUAD0_gpi(QUAD0_gpi),                                                // input wire [31 : 0] QUAD0_gpi
  .QUAD0_gpo(QUAD0_gpo),                                                // output wire [31 : 0] QUAD0_gpo
  .QUAD0_TX0_usrclk(QUAD0_TX0_usrclk),                                  // input wire QUAD0_TX0_usrclk
  .QUAD0_TX1_usrclk(QUAD0_TX1_usrclk),                                  // input wire QUAD0_TX1_usrclk
  .QUAD0_TX2_usrclk(QUAD0_TX2_usrclk),                                  // input wire QUAD0_TX2_usrclk
  .QUAD0_TX3_usrclk(QUAD0_TX3_usrclk),                                  // input wire QUAD0_TX3_usrclk
  .QUAD0_RX0_usrclk(QUAD0_RX0_usrclk),                                  // input wire QUAD0_RX0_usrclk
  .QUAD0_RX1_usrclk(QUAD0_RX1_usrclk),                                  // input wire QUAD0_RX1_usrclk
  .QUAD0_RX2_usrclk(QUAD0_RX2_usrclk),                                  // input wire QUAD0_RX2_usrclk
  .QUAD0_RX3_usrclk(QUAD0_RX3_usrclk),                                  // input wire QUAD0_RX3_usrclk
  .INTF0_TX0_ch_txdata(INTF0_TX0_ch_txdata),                            // input wire [255 : 0] INTF0_TX0_ch_txdata
  .INTF0_TX0_ch_txmaincursor(INTF0_TX0_ch_txmaincursor),                // input wire [6 : 0] INTF0_TX0_ch_txmaincursor
  .INTF0_TX0_ch_txpostcursor(INTF0_TX0_ch_txpostcursor),                // input wire [5 : 0] INTF0_TX0_ch_txpostcursor
  .INTF0_TX0_ch_txprecursor(INTF0_TX0_ch_txprecursor),                  // input wire [5 : 0] INTF0_TX0_ch_txprecursor
  .INTF0_TX0_ch_txrate(INTF0_TX0_ch_txrate),                            // input wire [7 : 0] INTF0_TX0_ch_txrate
  .INTF0_TX1_ch_txdata(INTF0_TX1_ch_txdata),                            // input wire [255 : 0] INTF0_TX1_ch_txdata
  .INTF0_TX1_ch_txmaincursor(INTF0_TX1_ch_txmaincursor),                // input wire [6 : 0] INTF0_TX1_ch_txmaincursor
  .INTF0_TX1_ch_txpostcursor(INTF0_TX1_ch_txpostcursor),                // input wire [5 : 0] INTF0_TX1_ch_txpostcursor
  .INTF0_TX1_ch_txprecursor(INTF0_TX1_ch_txprecursor),                  // input wire [5 : 0] INTF0_TX1_ch_txprecursor
  .INTF0_TX1_ch_txrate(INTF0_TX1_ch_txrate),                            // input wire [7 : 0] INTF0_TX1_ch_txrate
  .INTF0_TX2_ch_txdata(INTF0_TX2_ch_txdata),                            // input wire [255 : 0] INTF0_TX2_ch_txdata
  .INTF0_TX2_ch_txmaincursor(INTF0_TX2_ch_txmaincursor),                // input wire [6 : 0] INTF0_TX2_ch_txmaincursor
  .INTF0_TX2_ch_txpostcursor(INTF0_TX2_ch_txpostcursor),                // input wire [5 : 0] INTF0_TX2_ch_txpostcursor
  .INTF0_TX2_ch_txprecursor(INTF0_TX2_ch_txprecursor),                  // input wire [5 : 0] INTF0_TX2_ch_txprecursor
  .INTF0_TX2_ch_txrate(INTF0_TX2_ch_txrate),                            // input wire [7 : 0] INTF0_TX2_ch_txrate
  .INTF0_TX3_ch_txdata(INTF0_TX3_ch_txdata),                            // input wire [255 : 0] INTF0_TX3_ch_txdata
  .INTF0_TX3_ch_txmaincursor(INTF0_TX3_ch_txmaincursor),                // input wire [6 : 0] INTF0_TX3_ch_txmaincursor
  .INTF0_TX3_ch_txpostcursor(INTF0_TX3_ch_txpostcursor),                // input wire [5 : 0] INTF0_TX3_ch_txpostcursor
  .INTF0_TX3_ch_txprecursor(INTF0_TX3_ch_txprecursor),                  // input wire [5 : 0] INTF0_TX3_ch_txprecursor
  .INTF0_TX3_ch_txrate(INTF0_TX3_ch_txrate),                            // input wire [7 : 0] INTF0_TX3_ch_txrate
  .INTF0_RX0_ch_rxcdrhold(INTF0_RX0_ch_rxcdrhold),                      // input wire [0 : 0] INTF0_RX0_ch_rxcdrhold
  .INTF0_RX0_ch_rxrate(INTF0_RX0_ch_rxrate),                            // input wire [7 : 0] INTF0_RX0_ch_rxrate
  .INTF0_RX0_ch_rxdata(INTF0_RX0_ch_rxdata),                            // output wire [255 : 0] INTF0_RX0_ch_rxdata
  .INTF0_RX1_ch_rxcdrhold(INTF0_RX1_ch_rxcdrhold),                      // input wire [0 : 0] INTF0_RX1_ch_rxcdrhold
  .INTF0_RX1_ch_rxrate(INTF0_RX1_ch_rxrate),                            // input wire [7 : 0] INTF0_RX1_ch_rxrate
  .INTF0_RX1_ch_rxdata(INTF0_RX1_ch_rxdata),                            // output wire [255 : 0] INTF0_RX1_ch_rxdata
  .INTF0_RX2_ch_rxcdrhold(INTF0_RX2_ch_rxcdrhold),                      // input wire [0 : 0] INTF0_RX2_ch_rxcdrhold
  .INTF0_RX2_ch_rxrate(INTF0_RX2_ch_rxrate),                            // input wire [7 : 0] INTF0_RX2_ch_rxrate
  .INTF0_RX2_ch_rxdata(INTF0_RX2_ch_rxdata),                            // output wire [255 : 0] INTF0_RX2_ch_rxdata
  .INTF0_RX3_ch_rxcdrhold(INTF0_RX3_ch_rxcdrhold),                      // input wire [0 : 0] INTF0_RX3_ch_rxcdrhold
  .INTF0_RX3_ch_rxrate(INTF0_RX3_ch_rxrate),                            // input wire [7 : 0] INTF0_RX3_ch_rxrate
  .INTF0_RX3_ch_rxdata(INTF0_RX3_ch_rxdata),                            // output wire [255 : 0] INTF0_RX3_ch_rxdata
  .INTF0_TX_clr_out(INTF0_TX_clr_out),                                  // output wire INTF0_TX_clr_out
  .INTF0_TX_clrb_leaf_out(INTF0_TX_clrb_leaf_out),                      // output wire INTF0_TX_clrb_leaf_out
  .INTF0_RX_clr_out(INTF0_RX_clr_out),                                  // output wire INTF0_RX_clr_out
  .INTF0_RX_clrb_leaf_out(INTF0_RX_clrb_leaf_out),                      // output wire INTF0_RX_clrb_leaf_out
  .INTF0_rst_all_in(INTF0_rst_all_in),                                  // input wire INTF0_rst_all_in
  .INTF0_rst_tx_pll_and_datapath_in(INTF0_rst_tx_pll_and_datapath_in),  // input wire INTF0_rst_tx_pll_and_datapath_in
  .INTF0_rst_tx_datapath_in(INTF0_rst_tx_datapath_in),                  // input wire INTF0_rst_tx_datapath_in
  .INTF0_rst_tx_done_out(INTF0_rst_tx_done_out),                        // output wire INTF0_rst_tx_done_out
  .INTF0_rst_rx_pll_and_datapath_in(INTF0_rst_rx_pll_and_datapath_in),  // input wire INTF0_rst_rx_pll_and_datapath_in
  .INTF0_rst_rx_datapath_in(INTF0_rst_rx_datapath_in),                  // input wire INTF0_rst_rx_datapath_in
  .INTF0_rst_rx_done_out(INTF0_rst_rx_done_out)                         // output wire INTF0_rst_rx_done_out
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

endmodule : xilinx_gtm_wrapper
