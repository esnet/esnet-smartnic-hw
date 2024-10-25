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
    localparam int  DATA_BYTE_WID = axi4s_in[0].DATA_BYTE_WID;
    localparam type TID_T         = axi4s_in[0].TID_T;
    localparam type TDEST_T       = axi4s_in[0].TDEST_T;
    localparam type TUSER_T       = axi4s_in[0].TUSER_T;
 
    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID),
                  .TUSER_T(TUSER_T), .TID_T(TID_T), .TDEST_T(TDEST_T))  mux_in  [NUM_PORTS][2] ();

    axi4s_intf  #(.DATA_BYTE_WID(DATA_BYTE_WID),
                  .TUSER_T(TUSER_T), .TID_T(TID_T), .TDEST_T(TDEST_T))  mux_out [NUM_PORTS]    ();

    // Terminate AXI-L
    axi4l_intf_peripheral_term axil_term ( .axi4l_if (axil_if) );

    // Mux traffic from datapath/host
    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin
        axi4s_intf_pipe axi4s_mux_in_pipe_0 ( .axi4s_if_from_tx(axi4s_in[i]),  .axi4s_if_to_rx(mux_in[i][0]) );
        axi4s_intf_pipe axi4s_mux_in_pipe_1 ( .axi4s_if_from_tx(axi4s_h2c[i]), .axi4s_if_to_rx(mux_in[i][1]) );

        axi4s_mux #(.N(2)) axi4s_mux_inst (
            .axi4s_in  (mux_in[i]),
            .axi4s_out (mux_out[i])
        );

        axi4s_full_pipe axis4s_full_pipe_inst (.axi4s_if_from_tx(mux_out[i]), .axi4s_if_to_rx(axi4s_out[i]));

    end endgenerate

endmodule : smartnic_app_egr
