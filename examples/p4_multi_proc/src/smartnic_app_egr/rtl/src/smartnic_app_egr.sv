module smartnic_app_egr
#(
   parameter int N = 2  // Number of ingress/egress axi4s ports.
 ) (
   axi4s_intf.rx     axi4s_in[N],
   axi4s_intf.tx     axi4s_out[N],

   axi4l_intf.peripheral axil_if
);

   generate for (genvar i = 0; i < N; i += 1) begin
       axi4s_full_pipe axis4s_full_pipe_inst (.axi4s_if_from_tx(axi4s_in[i]), .axi4s_if_to_rx(axi4s_out[i]));
   end endgenerate

   axi4l_intf_peripheral_term axi4l_intf_peripheral_term_inst (.axi4l_if (axil_if));

endmodule // smartnic_app_egr
