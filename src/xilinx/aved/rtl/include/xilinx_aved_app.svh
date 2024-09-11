    // AXI4 interface (signals)
    wire        axi_clk;
    wire        axi_resetn;
    wire [41:0] APP_AXI_araddr;
    wire [1:0]  APP_AXI_arburst;
    wire [3:0]  APP_AXI_arcache;
    wire [7:0]  APP_AXI_arlen;
    wire [0:0]  APP_AXI_arlock;
    wire [2:0]  APP_AXI_arprot;
    wire [3:0]  APP_AXI_arqos;
    wire        APP_AXI_arready;
    wire [2:0]  APP_AXI_arsize;
    wire [17:0] APP_AXI_aruser;
    wire        APP_AXI_arvalid;
    wire [41:0] APP_AXI_awaddr;
    wire [1:0]  APP_AXI_awburst;
    wire [3:0]  APP_AXI_awcache;
    wire [7:0]  APP_AXI_awlen;
    wire [0:0]  APP_AXI_awlock;
    wire [2:0]  APP_AXI_awprot;
    wire [3:0]  APP_AXI_awqos;
    wire        APP_AXI_awready;
    wire [2:0]  APP_AXI_awsize;
    wire [17:0] APP_AXI_awuser;
    wire        APP_AXI_awvalid;
    wire        APP_AXI_bready;
    wire [1:0]  APP_AXI_bresp;
    wire        APP_AXI_bvalid;
    wire [31:0] APP_AXI_rdata;
    wire        APP_AXI_rlast;
    wire        APP_AXI_rready;
    wire [1:0]  APP_AXI_rresp;
    wire        APP_AXI_rvalid;
    wire [31:0] APP_AXI_wdata;
    wire        APP_AXI_wlast;
    wire        APP_AXI_wready;
    wire [3:0]  APP_AXI_wstrb;
    wire        APP_AXI_wvalid;
