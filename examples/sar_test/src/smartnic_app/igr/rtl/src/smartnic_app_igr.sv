module smartnic_app_igr
#(
    parameter int NUM_PORTS = 2
) (
    input  logic      core_clk,
    input  logic      core_srst,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],
    axi4s_intf.tx     axi4s_c2h [NUM_PORTS],

    axi4l_intf.peripheral axil_if
);
    // ----------------------------------------------------------------
    //  Connect sar_test logic
    // ----------------------------------------------------------------
    logic  clk;
    assign clk  = core_clk;

    logic  srst;
    assign srst = core_srst;

    sar_test sar_test_0 (.*);

endmodule : smartnic_app_igr
