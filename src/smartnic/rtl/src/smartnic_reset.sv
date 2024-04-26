module smartnic_reset #(
    parameter int NUM_CMAC = 1
) (
    input  logic                mod_rstn,     // Module reset pair from open-nic-shell
    output logic                mod_rst_done, // (synchronized to axil_aclk) 

    input  logic                axil_aclk,
    output logic                axil_aresetn, // synchronous to axil_aclk (async assert, sync deassert)

    input  logic [NUM_CMAC-1:0] cmac_clk,
    output logic [NUM_CMAC-1:0] cmac_srstn, // synchronous to cmac_clk (async assert, sync deassert)

    output logic                core_clk,  // we synthesize this clock in this block
    output logic                core_srstn, // synchronous to core_clk (async assert, sync deassert)

    output logic                clk_100mhz,
    output logic                hbm_ref_clk
);

    // ----------------------------------------------------------------
    //  Parameters
    // ----------------------------------------------------------------
    localparam int RESET_DURATION = 100;
    localparam int TIMER_WID = $clog2(RESET_DURATION);

    // ----------------------------------------------------------------
    //  Typedefs
    // ----------------------------------------------------------------
    typedef enum logic [1:0] {
        RESET,
        RESET_WAIT,
        RESET_DONE
    } state_t;

    // ----------------------------------------------------------------
    //  Signals
    // ----------------------------------------------------------------
    state_t state;
    state_t nxt_state;

    logic [TIMER_WID-1:0] timer;
    logic                 timer_reset;
    logic                 timer_inc;

    // ----------------------------------------------------------------
    //  Resets
    // ----------------------------------------------------------------
    // Enforce minimum reset assertion time
    initial state = RESET;
    always @(posedge axil_aclk or negedge mod_rstn) begin
        if (!mod_rstn) state <= RESET;
        else           state <= nxt_state;
    end

    always_comb begin
        nxt_state = state;
        timer_reset = 1'b0;
        timer_inc = 1'b0;
        mod_rst_done = 1'b0;
        case (state)
            RESET : begin
                timer_reset = 1'b1;
                nxt_state = RESET_WAIT;
            end
            RESET_WAIT : begin
                timer_inc = 1'b1;
                if (timer == RESET_DURATION-1) nxt_state = RESET_DONE;
            end
            RESET_DONE : begin
                mod_rst_done = 1'b1;
            end
            default : nxt_state = RESET;
        endcase
    end

    // Reset timer
    initial timer = 0;
    always @(posedge axil_aclk) begin
        if (timer_reset) timer <= 0;
        else if (timer_inc) timer <= timer + 1;
    end

    // Drive AXI-L reset output
    initial axil_aresetn = 1'b0;
    always @(posedge axil_aclk) axil_aresetn <= mod_rst_done;

    // CMAC domain resets are generated from the locally generated AXI-L reset
    generate
        for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__cmac
            sync_reset #(
                .OUTPUT_ACTIVE_LOW (1)
            ) sync_reset__cmac (
                .clk_in  (axil_aclk),
                .rst_in  (axil_aresetn),
                .clk_out (cmac_clk[i]),
                .rst_out (cmac_srstn[i])
            );
        end : g__cmac
    endgenerate

    // core clock domain reset is generated from the locally generated AXI-L reset
    sync_reset #(
        .OUTPUT_ACTIVE_LOW (1)
    ) sync_reset__core_clk (
        .clk_in  (axil_aclk),
        .rst_in  (axil_aresetn),
        .clk_out (core_clk),
        .rst_out (core_srstn)
    );

    // ----------------------------------------------------------------
    //  Clocks
    // ----------------------------------------------------------------
    // core clock domain is asynchronous wrt. CMAC domains, and is derived from the AXI-L clock via a PLL
    clk_wiz_0 axi_to_core_clk(
         .clk_in1  ( axil_aclk ),
         .clk_out1 ( core_clk )
    );

    // Synthesize 100MHz clock
    clk_wiz_1 axi_to_clk_100mhz (
        .clk_in1    ( axil_aclk ),
        .clk_100mhz ( clk_100mhz ),
        .hbm_ref_clk( hbm_ref_clk )
    );

endmodule: smartnic_reset
