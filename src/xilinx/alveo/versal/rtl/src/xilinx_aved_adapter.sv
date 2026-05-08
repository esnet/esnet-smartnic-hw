module xilinx_aved_adapter (
    // AVED application interface (signals)
    // -- AXI4 interface (signals)
    input  wire        axi_clk,
    input  wire        axi_resetn,
    input  wire [41:0] APP_AXI_araddr,
    input  wire [1:0]  APP_AXI_arburst,
    input  wire [3:0]  APP_AXI_arcache,
    input  wire [7:0]  APP_AXI_arlen,
    input  wire [0:0]  APP_AXI_arlock,
    input  wire [2:0]  APP_AXI_arprot,
    input  wire [3:0]  APP_AXI_arqos,
    output wire        APP_AXI_arready,
    input  wire [2:0]  APP_AXI_arsize,
    input  wire [17:0] APP_AXI_aruser,
    input  wire        APP_AXI_arvalid,
    input  wire [41:0] APP_AXI_awaddr,
    input  wire [1:0]  APP_AXI_awburst,
    input  wire [3:0]  APP_AXI_awcache,
    input  wire [7:0]  APP_AXI_awlen,
    input  wire [0:0]  APP_AXI_awlock,
    input  wire [2:0]  APP_AXI_awprot,
    input  wire [3:0]  APP_AXI_awqos,
    output wire        APP_AXI_awready,
    input  wire [2:0]  APP_AXI_awsize,
    input  wire [17:0] APP_AXI_awuser,
    input  wire        APP_AXI_awvalid,
    input  wire        APP_AXI_bready,
    output wire [1:0]  APP_AXI_bresp,
    output wire        APP_AXI_bvalid,
    output wire [31:0] APP_AXI_rdata,
    output wire        APP_AXI_rlast,
    input  wire        APP_AXI_rready,
    output wire [1:0]  APP_AXI_rresp,
    output wire        APP_AXI_rvalid,
    input  wire [31:0] APP_AXI_wdata,
    input  wire        APP_AXI_wlast,
    output wire        APP_AXI_wready,
    input  wire [3:0]  APP_AXI_wstrb,
    input  wire        APP_AXI_wvalid,

    // AVED application interface
    xilinx_aved_app_intf.aved app_if
);

    // Core clock/reset
    assign app_if.clk = axi_clk;
    assign app_if.srst = ~axi_resetn;
  
    // Convert APP_AXI signals to AXI-L interface
    axi4l_intf_from_signals i_axi4l_intf_from_signals (
        .aclk     ( axi_clk ),
        .aresetn  ( axi_resetn ),
        .awvalid  ( APP_AXI_awvalid ),
        .awready  ( APP_AXI_awready ),
        .awaddr   ( APP_AXI_awaddr[31:0] ),
        .awprot   ( APP_AXI_awprot ),
        .wvalid   ( APP_AXI_wvalid ),
        .wready   ( APP_AXI_wready ),
        .wdata    ( APP_AXI_wdata ),
        .wstrb    ( APP_AXI_wstrb ),
        .bvalid   ( APP_AXI_bvalid ),
        .bready   ( APP_AXI_bready ),
        .bresp    ( APP_AXI_bresp ),
        .arvalid  ( APP_AXI_arvalid ),
        .arready  ( APP_AXI_arready ),
        .araddr   ( APP_AXI_araddr ),
        .arprot   ( APP_AXI_arprot ),
        .rvalid   ( APP_AXI_rvalid ),
        .rready   ( APP_AXI_rready ),
        .rdata    ( APP_AXI_rdata ),
        .rresp    ( APP_AXI_rresp ),
        .axi4l_if ( app_if.axil_if )
    );

    // APP_AXI_awburst (unused)
    // APP_AXI_awcache (unused)
    // APP_AXI_awlen (unused)
    // APP_AXI_awlock (unused)
    // APP_AXI_awqos (unused)
    // APP_AXI_awsize (unused)
    // APP_AXI_awuser (unused)

    // APP_AXI_wlast ignored (AXI-Lite supports burst length == 1 only)

    // APP_AXI_arburst (unused)
    // APP_AXI_arcache (unused)
    // APP_AXI_arlen (unused)
    // APP_AXI_arlock (unused)
    // APP_AXI_arqos (unused)
    // APP_AXI_arsize (unused)
    // APP_AXI_arusuer (unused)

    assign APP_AXI_rlast = 1'b1; // AXI-Lite supports burst length == 1 only

endmodule : xilinx_aved_adapter

