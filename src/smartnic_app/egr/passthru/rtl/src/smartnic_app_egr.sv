module smartnic_app_egr
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      core_clk,
    input  logic      core_rstn,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.rx     axi4s_h2c [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],

    axi4l_intf.peripheral axil_if
);
    logic srst;

    assign srst = !core_rstn;

    // Terminate AXI-L interface
    axi4l_intf_peripheral_term axil_term ( .axi4l_if (axil_if) );

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin : g__port
        // Connect AXI-S interfaces as passthrough
        axi4s_full_pipe axi4s_full_pipe_0 (.srst, .from_tx(axi4s_in[i]), .to_rx(axi4s_out[i]));
        // Terminate H2C interface
        axi4s_intf_rx_sink axi4s_intf_rx_sink_0 (.from_tx(axi4s_h2c[i]));
    end : g__port
    endgenerate

endmodule : smartnic_app_egr
