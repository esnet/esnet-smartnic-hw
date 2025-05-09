module `VITISNETP4_EXTERN_NAME
    import smartnic_pkg::*;
#(
    parameter type EXTERN_VALID_T = logic,
    parameter type EXTERN_OUT_T = logic[3:0],
    parameter type EXTERN_IN_T = logic[3:0]
) (
    input   logic clk,
    input   logic rstn,

    input   EXTERN_OUT_T   extern_from_vitisnetp4,
    input   EXTERN_VALID_T extern_from_vitisnetp4_valid,
    output  EXTERN_IN_T    extern_to_vitisnetp4,
    output  EXTERN_VALID_T extern_to_vitisnetp4_valid,

    input   timestamp_t    timestamp,
    input   logic [3:0]    egr_flow_ctl,

    axi4l_intf.peripheral  axil_to_extern,
    axi4s_intf.rx          axis_to_extern,
    axi4s_intf.tx          axis_from_extern
);

    EXTERN_OUT_T    in_pipe;
    EXTERN_VALID_T  in_valid_pipe;

    EXTERN_IN_T     out_pipe;
    EXTERN_VALID_T  out_valid_pipe;
   
    always_ff @(posedge clk) begin
      in_pipe        <= extern_from_vitisnetp4;
      in_valid_pipe  <= extern_from_vitisnetp4_valid;

      out_pipe       <= in_pipe;
      out_valid_pipe <= in_valid_pipe;
    end

    assign extern_to_vitisnetp4       = out_pipe;
    assign extern_to_vitisnetp4_valid = out_valid_pipe;

    axi4l_intf_peripheral_term axil_term ( .axi4l_if(axil_to_extern) );

    axi4s_intf_connector axi4s_extern_connector (.axi4s_from_tx(axis_to_extern), .axi4s_to_rx(axis_from_extern));

endmodule: `VITISNETP4_EXTERN_NAME
