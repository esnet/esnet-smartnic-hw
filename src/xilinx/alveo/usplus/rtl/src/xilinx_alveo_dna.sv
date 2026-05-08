module xilinx_alveo_dna #(
    parameter bit [95:0] SIM_VALUE = 96'hBBAA_9988_7766_5544_3322_1100
) (
    // Clock/reset
    input  logic        clk,
    input  logic        srst,
    output logic        valid,
    output logic [95:0] dna
);

    // =========================================================================
    // Typedefs
    // =========================================================================
    typedef enum logic [1:0] {
        RESET,
        SHIFT,
        DONE
    } state_t;

    // =========================================================================
    // Signals
    // =========================================================================
    logic dout;
    logic [95:0] dna_reg;

    logic [6:0] bit_cnt;

    state_t state;
    state_t nxt_state;

    logic reset;
    logic shift;
    logic done;

    // =========================================================================
    // DNA access port instantiaton
    // =========================================================================
    DNA_PORTE2 #(
       .SIM_DNA_VALUE(SIM_VALUE)  // Specifies a sample 96-bit DNA value for simulation.
    )
    DNA_PORTE2_0 (
       .DOUT(dout),   // 1-bit output: DNA output data.
       .CLK(clk),     // 1-bit input: Clock input.
       .DIN(1'b0),    // 1-bit input: User data input pin.
       .READ(reset),  // 1-bit input: Active-High load DNA, active-Low read input.
       .SHIFT(shift)  // 1-bit input: Active-High shift enable input.
    );

    // =========================================================================
    // Read state machine
    // =========================================================================
    initial state = RESET;
    always @(posedge clk) begin
        if (srst) state <= RESET;
        else      state <= nxt_state;
    end

    always_comb begin
        nxt_state = state;
        reset = 1'b0;
        shift = 1'b0;
        done = 1'b0;
        case (state)
            RESET : begin
                reset = 1'b1;
                nxt_state = SHIFT;
            end
            SHIFT : begin
                shift = 1'b1;
                if (bit_cnt == 95) nxt_state = DONE;
            end
            DONE : begin
                done = 1'b1;
            end
            default : begin
                nxt_state = RESET;
            end
        endcase
    end

    // =========================================================================
    // Shift counter
    // =========================================================================
    initial bit_cnt = 0;
    always @(posedge clk) begin
        if (reset) bit_cnt <= 0;
        else if (shift) bit_cnt <= bit_cnt + 1;
    end

    // =========================================================================
    // DNA read shift register
    // =========================================================================
    initial dna_reg = '0;
    always @(posedge clk) begin
        if (reset) dna_reg <= '0;
        else if (shift) dna_reg <= {dout, dna_reg[95:1]};
    end

    assign dna = dna_reg;
    assign valid = done;


endmodule : xilinx_alveo_dna
