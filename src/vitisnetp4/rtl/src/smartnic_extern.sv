module sdnet_0_extern
    import sdnet_0_pkg::*;
(
    input   logic clk,
    input   logic rstn,

    input   USER_EXTERN_OUT_T    extern_from_sdnet,
    input   USER_EXTERN_VALID_T  extern_from_sdnet_valid,
    output  USER_EXTERN_IN_T     extern_to_sdnet,
    output  USER_EXTERN_VALID_T  extern_to_sdnet_valid
);

    USER_EXTERN_IN_T     in_pipe;
    USER_EXTERN_VALID_T  in_valid_pipe;

    USER_EXTERN_OUT_T    out_pipe;
    USER_EXTERN_VALID_T  out_valid_pipe;
   
    always_ff @(posedge clk) begin
      in_pipe        <= extern_from_sdnet;
      in_valid_pipe  <= extern_from_sdnet_valid;

      out_pipe       <= in_pipe;
      out_valid_pipe <= in_valid_pipe;
    end

    assign extern_to_sdnet       = out_pipe;
    assign extern_to_sdnet_valid = out_valid_pipe;

endmodule: sdnet_0_extern
