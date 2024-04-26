module vitisnetp4_egr_extern
    import vitisnetp4_egr_pkg::*;
(
    input   logic clk,
    input   logic rstn,

    input   USER_EXTERN_OUT_T    extern_from_vitisnetp4,
    input   USER_EXTERN_VALID_T  extern_from_vitisnetp4_valid,
    output  USER_EXTERN_IN_T     extern_to_vitisnetp4,
    output  USER_EXTERN_VALID_T  extern_to_vitisnetp4_valid
);

    USER_EXTERN_IN_T     in_pipe;
    USER_EXTERN_VALID_T  in_valid_pipe;

    USER_EXTERN_OUT_T    out_pipe;
    USER_EXTERN_VALID_T  out_valid_pipe;
   
    always_ff @(posedge clk) begin
      in_pipe        <= extern_from_vitisnetp4;
      in_valid_pipe  <= extern_from_vitisnetp4_valid;

      out_pipe       <= in_pipe;
      out_valid_pipe <= in_valid_pipe;
    end

    assign extern_to_vitisnetp4       = out_pipe;
    assign extern_to_vitisnetp4_valid = out_valid_pipe;

endmodule: vitisnetp4_egr_extern
