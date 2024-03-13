module sdnet_stub (
    // Clock/reset
    input logic           core_clk,
    input logic           core_rstn,

    // AXI-L
    axi4l_intf.peripheral axil_if,

    // AXI
    axi4s_intf.rx         axis_rx,
    axi4s_intf.tx         axis_tx,

    // Metadata
    input  logic  user_metadata_in_valid,
    input  logic  user_metadata_in,
    output logic  user_metadata_out_valid,
    output logic  user_metadata_out,

    // HBM AXI3
    axi3_intf.controller  axi_to_hbm [16]
);

    axi4l_intf_peripheral_term axi4l_intf_peripheral_term_inst (.axi4l_if (axil_if));

    axi4s_intf_tx_term  axis_tx_term  (.axi4s_if(axis_tx));
    axi4s_intf_rx_block axis_rx_block (.axi4s_if(axis_rx));

    assign user_metadata_out_valid = 1'b0;
    assign user_metadata_out       = 1'b0;

    generate 
       for (genvar g_hbm_if = 0; g_hbm_if < 16; g_hbm_if++) begin : g__hbm_if
           axi3_intf_controller_term axi_to_hbm_term (.axi3_if(axi_to_hbm[g_hbm_if]));
       end : g__hbm_if
    endgenerate 

endmodule : sdnet_stub
