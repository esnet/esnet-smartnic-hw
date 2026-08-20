module vitisnetp4_igr_extern
    import vitisnetp4_igr_pkg::*;
    import smartnic_pkg::*;
(
    input   logic clk,
    input   logic srst,

    input   USER_EXTERN_OUT_T    extern_from_vitisnetp4,
    input   USER_EXTERN_VALID_T  extern_from_vitisnetp4_valid,
    output  USER_EXTERN_IN_T     extern_to_vitisnetp4,
    output  USER_EXTERN_VALID_T  extern_to_vitisnetp4_valid,

    input   timestamp_t    timestamp,
    input   logic [3:0]    egr_flow_ctl,

    axi4l_intf.peripheral  axil_to_extern,
    axi4s_intf.rx          axis_to_extern,
    axi4s_intf.tx          axis_from_extern
);

    USER_EXTERN_IN_T     data_pipe  [16];
    USER_EXTERN_VALID_T  valid_pipe [16];

    always_ff @(posedge clk) begin
      data_pipe[15]  <= extern_from_vitisnetp4;
      valid_pipe[15] <= extern_from_vitisnetp4_valid;

      for (int i=0; i<15; i++) begin
         data_pipe[i]  <= data_pipe[i+1];
         valid_pipe[i] <= valid_pipe[i+1];
      end
    end

    assign extern_to_vitisnetp4       = data_pipe[0];
    assign extern_to_vitisnetp4_valid = valid_pipe[0];


    axi4l_intf_peripheral_term axil_term ( .axi4l_if(axil_to_extern) );

    axi4s_intf_tx_term axis_from_extern_term ( .to_rx(axis_from_extern) );

    axi4s_intf_rx_sink axis_to_extern_sink ( .from_tx(axis_to_extern) );

endmodule: vitisnetp4_igr_extern
