module smartnic_app_igr
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
    // Terminate AXI-L interface
    axi4l_intf_peripheral_term axil_term ( .axi4l_if (axil_if) );

    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        // Connect AXI-S interfaces as passthrough
        axi4s_full_pipe axi4s_full_pipe_0 (.axi4s_if_from_tx(axi4s_in[i]), .axi4s_if_to_rx(axi4s_out[i]));
        // Terminate C2H interface
        axi4s_intf_tx_term axi4s_intf_tx_term_0 (.aclk(core_clk), .aresetn(core_rstn), .axi4s_if(axi4s_c2h[i]));
    end endgenerate

endmodule : smartnic_app_igr
