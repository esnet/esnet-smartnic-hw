module xilinx_jtag_reset_ctrl (
    input  wire logic debug_clk, // Free-running (debug) clock
    input  wire logic ready,     // Reset indication (forwarded to JTAG)
    input  wire logic rstn_clk,  // Retime reset to this clock
    input  wire logic rstn_in,   // Incoming (raw) reset

    output logic rstn_out // Outgoing reset (potentially overridden by JTAG)
);
    logic jtag_reset;

    xilinx_jtag_reset_vio i_xilinx_jtag_reset_vio (
        .clk        ( debug_clk ),
        .probe_in0  ( rstn_in   ),
        .probe_in1  ( rstn_out  ),
        .probe_in2  ( ready     ),
        .probe_out0 ( jtag_reset ) // Active-high
    );

    always @(posedge rstn_clk or negedge rstn_in) begin
        if (!rstn_in) rstn_out <= 1'b0;
        else          rstn_out <= !jtag_reset;
    end

endmodule : xilinx_jtag_reset_ctrl
