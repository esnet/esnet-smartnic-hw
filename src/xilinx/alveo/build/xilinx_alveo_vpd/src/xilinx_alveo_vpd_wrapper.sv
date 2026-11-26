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
    output logic        ready
);

    xilinx_pci_cfg_ext_intf cfg_ext_if (.clk(cfg_clk));

    assign cfg_ext_if.req = cfg_req;
    assign cfg_ext_if.wr_rd_n = cfg_wr_rd_n;
    assign cfg_ext_if.register = cfg_register;
    assign cfg_ext_if.func = cfg_func;
    assign cfg_ext_if.wr_data = cfg_wr_data;
    assign cfg_ext_if.wr_byte_en = cfg_wr_byte_en;
    assign cfg_rd_data = cfg_ext_if.rd_data;
    assign cfg_rd_vld = cfg_ext_if.rd_vld;

    pci_vpd_ctrl_intf vpd_ctrl_if ();
    pci_vpd_card_info_intf card_info_if (.clk(clk));
    assign vpd_ctrl_if.clk = clk;
    assign vpd_ctrl_if.srst = srst;
    assign vpd_ctrl_if.init_done_mask = 1'b0;
    assign card_info_if.vld = 1'b0;
    assign card_info_if.error = 1'b0;
    assign card_info_if.len = '0;
    assign card_info_if.rd_data = '0;
    assign card_info_if.rd_vld = 1'b0;
    assign ready = vpd_ctrl_if.init_done || vpd_ctrl_if.init_error;

    xilinx_alveo_vpd #(
        .CLK_FREQ_HZ          ( 100_000_000 ),
        .CARD_INFO_EN         ( 1'b0 ),
        .APPLICATION_ID      ( "shell" ),
        .BUILD_ID            ( 123 ),
        .BUILD_GIT_REPO      ( "esnet-smartnic-hw" ),
        .BUILD_GIT_HASH      ( "12345678" ),
        .BUILD_TIMESTAMP_STR ( "2026-11-26 00:00:00 UTC" )
    ) i_xilinx_alveo_vpd (
        .cfg_aresetn,
        .cfg_ext_if,
        .vpd_ctrl_if,
        .card_info_if
    );

endmodule : xilinx_alveo_vpd_wrapper
