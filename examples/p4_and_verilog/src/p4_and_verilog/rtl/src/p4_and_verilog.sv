module p4_and_verilog
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      core_clk,
    input  logic      core_rstn,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],
    axi4s_intf.tx     axi4s_c2h [NUM_PORTS],

    axi4l_intf.peripheral axil_if
);
    // ----------------------------------------------------------------
    //  Register map block and decoder instantiations
    // ----------------------------------------------------------------
    p4_and_verilog_reg_intf p4_and_verilog_regs ();

    // p4_and_verilog register block
    p4_and_verilog_reg_blk p4_and_verilog_reg_blk (
        .axil_if    (axil_if),
        .reg_blk_if (p4_and_verilog_regs)
    );

    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            // Connect AXI-S interfaces in pass-through
            axi4s_full_pipe axi4s_full_pipe_0 (.from_tx(axi4s_in[g_port]), .to_rx(axi4s_out[g_port]));
            // Tie off C2H interface
            axi4s_intf_tx_term axi4s_intf_tx_term_0 (.to_rx(axi4s_c2h[g_port]));
        end
    endgenerate


endmodule: p4_and_verilog
