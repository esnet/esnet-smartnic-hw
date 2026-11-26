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

    logic init_done;
    logic init_error;
    assign ready = init_done || init_error;

    xilinx_alveo_vpd #(
        .CLK_FREQ_HZ          ( 100_000_000 ),
        .CARD_INFO_EN         ( 1'b0 ),
        .APPLICATION_ID      ( "shell" ),
        .BUILD_ID            ( 123 ),
        .BUILD_GIT_REPO      ( "esnet-smartnic-hw" ),
        .BUILD_GIT_HASH      ( "12345678" ),
        .BUILD_TIMESTAMP_STR ( "2026-11-26 00:00:00 UTC" )
    ) i_xilinx_alveo_vpd (
        .clk,
        .srst,
        .cfg_aresetn,
        .cfg_ext_if,
        .init_done,
        .init_error,
        .init_timeout      ( ),
        .init_early_read   ( ),
        .init_time_ms      ( ),
        .init_done_mask    ( 1'b0 ),
        .card_info_vld     ( 1'b0 ),
        .card_info_len     ( 9'b0 ),
        .card_info_rd      ( ),
        .card_info_rd_addr ( ),
        .card_info_rd_data ( 8'b0 ),
        .card_info_rd_vld  ( 1'b0 ),
        .card_info_error   ( 1'b0 )
    );

endmodule : xilinx_alveo_vpd_wrapper
