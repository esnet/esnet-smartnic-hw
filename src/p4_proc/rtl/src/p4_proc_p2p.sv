module p4_proc_p2p
    import smartnic_322mhz_pkg::*;
#(
    parameter int   N = 2  // Number of processor ports.
) (
    input logic        core_clk,
    input logic        core_rstn,
    input timestamp_t  timestamp,

    axi4l_intf.peripheral axil_if,

    axi4s_intf.rx axis_in[N],
    axi4s_intf.tx axis_out[N],

    axi4s_intf.tx axis_to_sdnet,
    axi4s_intf.rx axis_from_sdnet,

    output logic  user_metadata_to_sdnet,
    output logic  user_metadata_to_sdnet_valid,

    input  logic  user_metadata_from_sdnet,
    input  logic  user_metadata_from_sdnet_valid
);
   
    axi4l_intf_peripheral_term axi4l_intf_peripheral_term_inst (.axi4l_if (axil_if));

    generate for (genvar i = 0; i < N; i += 1) begin
//        axi4s_intf_connector axis4s_intf_connector_inst (.axi4s_from_tx(axis_in[i]), .axi4s_to_rx(axis_out[i]));
        axi4s_full_pipe axis4s_full_pipe_inst (.axi4s_if_from_tx(axis_in[i]), .axi4s_if_to_rx(axis_out[i]));
    end endgenerate

    axi4s_intf_tx_term  axis_to_sdnet_term    (.axi4s_if(axis_to_sdnet));
    axi4s_intf_rx_block axis_from_sdnet_block (.axi4s_if(axis_from_sdnet));

    assign user_metadata_to_sdnet_valid = 1'b0;
    assign user_metadata_to_sdnet       = 1'b0;

endmodule: p4_proc_p2p
