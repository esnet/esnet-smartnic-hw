module sdnet_igr_extern
    import sdnet_igr_pkg::*;
(
    input   logic clk,
    input   logic rstn,

    input   USER_EXTERN_OUT_T    extern_from_sdnet,
    input   USER_EXTERN_VALID_T  extern_from_sdnet_valid,
    output  USER_EXTERN_IN_T     extern_to_sdnet,
    output  USER_EXTERN_VALID_T  extern_to_sdnet_valid
);

    USER_EXTERN_IN_T     data_pipe  [16];
    USER_EXTERN_VALID_T  valid_pipe [16];

    always_ff @(posedge clk) begin
      data_pipe[15]  <= extern_from_sdnet;
      valid_pipe[15] <= extern_from_sdnet_valid;

      for (int i=0; i<15; i++) begin
         data_pipe[i]  <= data_pipe[i+1];
         valid_pipe[i] <= valid_pipe[i+1];
      end
    end

    assign extern_to_sdnet       = data_pipe[0];
    assign extern_to_sdnet_valid = valid_pipe[0];

endmodule: sdnet_igr_extern
