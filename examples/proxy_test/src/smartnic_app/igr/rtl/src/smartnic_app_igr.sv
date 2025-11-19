module smartnic_app_igr
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      core_clk,
    input  logic      core_srst,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],
    axi4s_intf.tx     axi4s_c2h [NUM_PORTS],

    axi4l_intf.peripheral axil_if
);
    // ----------------------------------------------------------------
    //  Connect proxy_test logic
    // ----------------------------------------------------------------
    logic  clk;
    assign clk  = core_clk;

    logic  srst;
    assign srst = core_srst;

    proxy_test proxy_test_0 (.*);

endmodule: smartnic_app_igr
