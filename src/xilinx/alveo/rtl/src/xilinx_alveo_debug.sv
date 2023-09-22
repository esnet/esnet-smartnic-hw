module xilinx_alveo_debug (
    // Clock (to debug core)
    input  logic  clk,
    // Inputs (to JTAG VIO)
    input  logic  reset_in,
    // Outputs (from JTAG VIO)
    output logic  reset_out
);

    xilinx_alveo_vio i_xilinx_alveo (
        .clk(clk),               // input wire clk
        .probe_in0(reset_in),    // input wire [0 : 0] probe_in0
        .probe_out0(reset_out)   // output wire [0 : 0] probe_out0
    );

endmodule : xilinx_alveo_debug
