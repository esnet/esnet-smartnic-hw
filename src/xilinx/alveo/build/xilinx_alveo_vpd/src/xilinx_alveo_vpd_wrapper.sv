module xilinx_alveo_vpd_wrapper (
    input  logic        clk,
    input  logic        srst,
    input  logic        cfg_clk,
    input  logic        cfg_aresetn,
    input  logic        cfg_req,
    input  logic        cfg_wr_rd_n,
    input  logic [9:0]  cfg_register,
    input  logic [7:0]  cfg_func,
    input  logic [31:0] cfg_wr_data,
    input  logic [3:0]  cfg_wr_byte_en,
    output logic [31:0] cfg_rd_data,
    output logic        cfg_rd_vld,
    output logic        ready,
    output logic        pci_rstn_out,
    input  logic        reg_awvalid,
    input  logic [11:0] reg_awaddr,
    output logic        reg_awready,
    input  logic        reg_wvalid,
    input  logic [31:0] reg_wdata,
    input  logic [3:0]  reg_wstrb,
    output logic        reg_wready,
    output logic        reg_bvalid,
    output logic [1:0]  reg_bresp,
    input  logic        reg_bready,
    input  logic        reg_arvalid,
    input  logic [11:0] reg_araddr,
    output logic        reg_arready,
    output logic        reg_rvalid,
    output logic [31:0] reg_rdata,
    output logic [1:0]  reg_rresp,
    input  logic        reg_rready
);

    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(cfg_clk));
    logic cfg_resetn = 1'b0;

    always_ff @(posedge cfg_clk) cfg_resetn <= cfg_aresetn;

    assign cfg_ext_if.req = cfg_req;
    assign cfg_ext_if.wr_rd_n = cfg_wr_rd_n;
    assign cfg_ext_if.register = cfg_register;
    assign cfg_ext_if.func = cfg_func;
    assign cfg_ext_if.wr_data = cfg_wr_data;
    assign cfg_ext_if.wr_byte_en = cfg_wr_byte_en;
    assign cfg_rd_data = cfg_ext_if.rd_data;
    assign cfg_rd_vld = cfg_ext_if.rd_vld;

    axi4l_intf axil_vpd ();
    pci_vpd_card_info_intf card_info_if (.clk(clk));
    assign axil_vpd.aclk = cfg_clk;
    assign axil_vpd.aresetn = cfg_resetn;
    assign axil_vpd.awvalid = reg_awvalid;
    assign axil_vpd.awaddr = {20'b0, reg_awaddr};
    assign axil_vpd.awprot = '0;
    assign reg_awready = axil_vpd.awready;
    assign axil_vpd.wvalid = reg_wvalid;
    assign axil_vpd.wdata = reg_wdata;
    assign axil_vpd.wstrb = reg_wstrb;
    assign reg_wready = axil_vpd.wready;
    assign reg_bvalid = axil_vpd.bvalid;
    assign reg_bresp = axil_vpd.bresp;
    assign axil_vpd.bready = reg_bready;
    assign axil_vpd.arvalid = reg_arvalid;
    assign axil_vpd.araddr = {20'b0, reg_araddr};
    assign axil_vpd.arprot = '0;
    assign reg_arready = axil_vpd.arready;
    assign reg_rvalid = axil_vpd.rvalid;
    assign reg_rdata = axil_vpd.rdata;
    assign reg_rresp = axil_vpd.rresp;
    assign axil_vpd.rready = reg_rready;
    assign card_info_if.srst = srst;
    assign card_info_if.vld = 1'b0;
    assign card_info_if.error = 1'b0;
    assign card_info_if.len = '0;
    assign card_info_if.rd_data = '0;
    assign card_info_if.rd_vld = 1'b0;

    logic cfg_srst;

    sync_areset i_sync_areset__cfg (
        .rst_in  ( cfg_resetn ),
        .clk_out ( clk ),
        .rst_out ( cfg_srst )
    );

    xilinx_jtag_reset_ctrl i_xilinx_jtag_reset_ctrl (
        .debug_clk ( clk ),
        .ready     ( ready ),
        .rstn_in   ( !cfg_srst ),
        .rstn_out  ( pci_rstn_out )
    );

    xilinx_alveo_vpd #(
        .CLK_FREQ_HZ          ( 100_000_000 ),
        .CARD_INFO_EN         ( 1'b0 ),
        .APPLICATION_ID      ( "shell" ),
        .BUILD_ID            ( 123 ),
        .BUILD_GIT_REPO      ( "esnet-smartnic-hw" ),
        .BUILD_GIT_HASH      ( "12345678" ),
        .BUILD_TIMESTAMP_STR ( "2026-11-26 00:00:00 UTC" )
    ) i_xilinx_alveo_vpd (
        .cfg_srst,
        .cfg_ext_if,
        .clk,
        .srst,
        .ready,
        .axil_if ( axil_vpd ),
        .card_info_if
    );

endmodule : xilinx_alveo_vpd_wrapper
