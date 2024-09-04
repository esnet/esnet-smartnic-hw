module xilinx_axi4s_ila
   import xilinx_axis_pkg::*;
#(
   parameter xilinx_axis_ila_mode_t MODE = FULL,
   parameter int PIPE_STAGES = 1
) (
   axi4s_intf.prb axis_in
);

  (* mark_debug="true" *)  logic [511:0]  tdata  [PIPE_STAGES+1];
  (* mark_debug="true" *)  logic          tvalid [PIPE_STAGES+1];
  (* mark_debug="true" *)  logic          tlast  [PIPE_STAGES+1];
  (* mark_debug="true" *)  logic [63:0]   tkeep  [PIPE_STAGES+1];
  (* mark_debug="true" *)  logic          tready [PIPE_STAGES+1];
  (* mark_debug="true" *)  logic [31:0]   tuser  [PIPE_STAGES+1];

  assign tdata  [PIPE_STAGES] = axis_in.tdata;
  assign tvalid [PIPE_STAGES] = axis_in.tvalid;
  assign tlast  [PIPE_STAGES] = axis_in.tlast;
  assign tkeep  [PIPE_STAGES] = axis_in.tkeep;
  assign tready [PIPE_STAGES] = axis_in.tready;
  assign tuser  [PIPE_STAGES] = {'0, axis_in.tuser};

  generate
     if (PIPE_STAGES > 0)
       for (genvar i = 0; i < PIPE_STAGES; i++)
         always_ff @(posedge axis_in.aclk) begin
           tdata[i]  <= tdata[i+1];
           tvalid[i] <= tvalid[i+1];
           tlast[i]  <= tlast[i+1];
           tkeep[i]  <= tkeep[i+1];
           tready[i] <= tready[i+1];
           tuser[i]  <= tuser[i+1];
         end
  endgenerate

  generate
      if (MODE == FULL) begin : g__full
         xilinx_axis_ila xilinx_axis_ila_0 (
            .clk(axis_in.aclk),
            .probe0(tdata[0]),
            .probe1(tvalid[0]),
            .probe2(tlast[0]),
            .probe3(tkeep[0]),
            .probe4(tready[0]),
            .probe5(tuser[0]));
      end : g__full

      else if (MODE == LITE) begin : g__lite
         xilinx_axis_ila_lite xilinx_axis_ila_lite_0 (
            .clk(axis_in.aclk),
            .probe0(tdata[0][7:0]),
            .probe1(tvalid[0]),
            .probe2(tlast[0]),
            .probe3(tkeep[0][0]),
            .probe4(tready[0]),
            .probe5(tuser[0][0]));
      end : g__lite
   endgenerate

endmodule : xilinx_axi4s_ila
