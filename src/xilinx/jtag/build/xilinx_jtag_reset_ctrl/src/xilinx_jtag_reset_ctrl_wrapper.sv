// Cover a fabric-generated reset crossing into the debug domain and a raw
// external reset. Both controllers use the board's generated VIO IP.
module xilinx_jtag_reset_ctrl_wrapper (
    input  logic source_clk, debug_clk,
    input  logic fabric_resetn_in, external_resetn, ready,
    output logic fabric_resetn_out, external_resetn_out
);
    logic fabric_resetn = 1'b0;
    always @(posedge source_clk) fabric_resetn <= fabric_resetn_in;

    xilinx_jtag_reset_ctrl fabric_reset (
        .debug_clk, .ready, .rstn_in(fabric_resetn), .rstn_out(fabric_resetn_out)
    );
    xilinx_jtag_reset_ctrl external_reset (
        .debug_clk, .ready, .rstn_in(external_resetn), .rstn_out(external_resetn_out)
    );
endmodule
