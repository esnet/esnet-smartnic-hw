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
    // P2P logic
    p2p p2p_0 (
        .core_clk,
        .core_rstn,
        .axil_if,
        .axis_in  (axi4s_in[0]),
        .axis_out (axi4s_out[0])
    );

    axi4s_intf_connector axi4s_intf_connector (.from_tx(axi4s_in[1]), .to_rx(axi4s_out[1]));
    axi4s_intf_tx_term axi4s_intf_tx_term_ch2_0 (.to_rx(axi4s_c2h[0]));
    axi4s_intf_tx_term axi4s_intf_tx_term_ch2_1 (.to_rx(axi4s_c2h[1]));

endmodule // smartnic_app_igr
