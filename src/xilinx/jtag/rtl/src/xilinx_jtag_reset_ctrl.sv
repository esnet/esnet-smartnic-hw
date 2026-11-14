module xilinx_jtag_reset_ctrl (
    input  wire logic debug_clk, // Free-running (debug) clock
    input  wire logic ready,     // Initialization status (forwarded to JTAG)
    input  wire logic rstn_in,   // Incoming (raw) reset

    output wire logic rstn_out   // Outgoing reset (potentially overridden by JTAG)
);
    logic jtag_reset;
    logic [2:0] status_async;
    logic [2:0] status_sync;

    // Independent status levels for observation only; short pulses may be missed.
    // Keep these synchronizers running while the functional reset is asserted.
    assign status_async = {ready, rstn_out, rstn_in};
    for (genvar i = 0; i < 3; i++) begin : g__status_sync
        sync_meta #(
            .RST_VALUE ( 1'b0 ),
            .INPUT_REG ( 0    )
        ) i_sync_meta (
            .clk_in  ( 1'b0            ),
            .rst_in  ( 1'b0            ),
            .sig_in  ( status_async[i] ),
            .clk_out ( debug_clk       ),
            .rst_out ( 1'b0            ),
            .sig_out ( status_sync[i]  )
        );
    end

    xilinx_jtag_reset_vio i_xilinx_jtag_reset_vio (
        .clk        ( debug_clk      ),
        .probe_in0  ( status_sync[0] ),
        .probe_in1  ( status_sync[1] ),
        .probe_in2  ( status_sync[2] ),
        .probe_out0 ( jtag_reset     ) // Active-high
    );

    assign rstn_out = rstn_in & !jtag_reset;

endmodule : xilinx_jtag_reset_ctrl
