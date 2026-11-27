module xilinx_jtag_reset_ctrl (
    input  wire logic debug_clk, // Free-running (debug) clock
    input  wire logic ready,     // Initialization status (forwarded to JTAG)
    input  wire logic rstn_in,   // Incoming (raw) reset

    output wire logic rstn_out   // Outgoing reset (potentially overridden by JTAG)
);
    logic jtag_reset;
    logic rstn_in_sync;
    logic resetn_async;
    logic [2:0] status_async;
    logic [2:0] status_sync;

    // Independent status levels for observation only; short pulses may be missed.
    // Keep these synchronizers running while the functional reset is asserted.
    // Observe the normalized input so the raw reset has only one CDC boundary.
    assign status_async = {ready, rstn_out, rstn_in_sync};
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

    // Normalize the incoming reset before combining it with debug-domain
    // controls. It may originate in another fabric clock domain.
    sync_areset #(
        .INPUT_ACTIVE_HIGH ( 0 ),
        .OUTPUT_ACTIVE_LOW ( 1 )
    ) i_sync_areset__rstn_in (
        .rst_in  ( rstn_in      ),
        .clk_out ( debug_clk    ),
        .rst_out ( rstn_in_sync )
    );

    assign resetn_async = rstn_in_sync & !jtag_reset;

    // Assert immediately, including while the debug clock is stopped. Release
    // synchronously so downstream reset synchronizers see a registered source.
    sync_areset #(
        .INPUT_ACTIVE_HIGH ( 0 ),
        .OUTPUT_ACTIVE_LOW ( 1 )
    ) i_sync_areset__rstn_out (
        .rst_in  ( resetn_async ),
        .clk_out ( debug_clk    ),
        .rst_out ( rstn_out     )
    );

endmodule : xilinx_jtag_reset_ctrl
