// smartnic_app_egr_p4 passthru module. Used when no ingress P4 processor is implemented.
module smartnic_app_egr_p4
    import smartnic_pkg::*;
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic          core_clk,
    input  logic          core_rstn,

    input  timestamp_t    timestamp,

    axi4l_intf.peripheral axil_to_p4_proc,
    axi4l_intf.peripheral axil_to_vitisnetp4,
    axi4l_intf.peripheral axil_to_extern,

    input  logic [3:0]    egr_flow_ctl,

    axi4s_intf.rx         axis_in  [NUM_PORTS],
    axi4s_intf.tx         axis_out [NUM_PORTS],
    axi4s_intf.rx         axis_to_extern,
    axi4s_intf.tx         axis_from_extern
);

    // Terminate AXI-L interfaces
    axi4l_intf_peripheral_term axi4l_intf_peripheral_term__p4_proc    (.axi4l_if (axil_to_p4_proc));
    axi4l_intf_peripheral_term axi4l_intf_peripheral_term__vitisnetp4 (.axi4l_if (axil_to_vitisnetp4));
    axi4l_intf_peripheral_term axi4l_intf_peripheral_term__extern     (.axi4l_if (axil_to_extern));

    // Pass datapath AXI-S interface directly from input to output
    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            axi4s_full_pipe axi4s_full_pipe_inst (.axi4s_if_from_tx(axis_in[g_port]), .axi4s_if_to_rx(axis_out[g_port]));
        end : g__port
    endgenerate

    // Terminate extern AXI-S interfaces
    axi4s_intf_rx_sink axi4s_intf_rx_sink_inst (.axi4s_if (axis_to_extern));
    axi4s_intf_tx_term axi4s_intf_tx_term_inst (.axi4s_if (axis_from_extern));

endmodule : smartnic_app_egr_p4
