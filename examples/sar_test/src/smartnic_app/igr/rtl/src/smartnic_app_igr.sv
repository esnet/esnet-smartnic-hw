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
    //  AXI-S pass-through (unused datapath)
    // ----------------------------------------------------------------
    logic srst;
    assign srst = core_srst;

    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            axi4s_full_pipe axi4s_full_pipe_0 (.srst, .from_tx(axi4s_in[g_port]), .to_rx(axi4s_out[g_port]));
            axi4s_intf_tx_term axi4s_intf_tx_term_0 (.to_rx(axi4s_c2h[g_port]));
        end
    endgenerate

    // ----------------------------------------------------------------
    //  Connect sar_test logic
    // ----------------------------------------------------------------
    logic  clk;
    assign clk  = axil_if.aclk;  // Temporarily use AXI-L clock (125 MHz) for timing closure

    logic  axil_srst;
    assign axil_srst = ~axil_if.aresetn;

    sar_test sar_test_0 (
        .clk     ( clk       ),
        .srst    ( axil_srst ),
        .axil_if ( axil_if   )
    );

endmodule : smartnic_app_igr
