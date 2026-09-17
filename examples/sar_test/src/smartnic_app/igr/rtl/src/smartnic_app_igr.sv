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

    // Generate ms_tick entirely in the axil domain to avoid CDC.
    // Divide axil_if.aclk (125 MHz) by 2 to produce a 62.5 MHz tclk.
    // timer_tick with TCLK_PER_TICK=62_500 counts 62,500 rising edges of tclk
    // = 62,500 × 16 ns = 1 ms tick period.
    logic axil_clk_div2;
    always_ff @(posedge axil_if.aclk) begin
        if (axil_srst) axil_clk_div2 <= 1'b0;
        else           axil_clk_div2 <= ~axil_clk_div2;
    end

    logic ms_tick;
    timer_tick #(
        .TCLK_PER_TICK ( 62_500        ),
        .TCLK_DDR      ( 0             )
    ) i_ms_timer_tick (
        .clk    ( axil_if.aclk  ),
        .srst   ( axil_srst     ),
        .squelch( 1'b0          ),
        .tclk   ( axil_clk_div2 ),
        .tick   ( ms_tick       )
    );

    sar_test sar_test_0 (
        .clk     ( clk       ),
        .srst    ( axil_srst ),
        .ms_tick ( ms_tick   ),
        .axil_if ( axil_if   )
    );

endmodule : smartnic_app_igr
