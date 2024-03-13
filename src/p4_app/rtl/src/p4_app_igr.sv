module p4_app_igr
#(
   parameter int N = 2  // Number of ingress/egress axi4s ports.
 ) (
   axi4s_intf.rx     axi4s_in[N],
   axi4s_intf.tx     axi4s_out[N],

   axi4l_intf.peripheral axil_if
);

   p4_app_p2p #(.N(N)) p4_app_p2p_inst ( .axi4s_in(axi4s_in), .axi4s_out(axi4s_out), .axil_if(axil_if) );

endmodule // p4_app_igr
