module smartnic_250mhz_reset (
    input  logic mod_rstn,
    output logic mod_rst_done,

    input  logic axis_aclk,

    input  logic axil_aclk,
    output logic axil_aresetn,

    output logic core_rstn,
    output logic core_clk
);

    // ----------------------------------------------------------------
    //  Parameters
    // ----------------------------------------------------------------
    localparam int RESET_DURATION = 100;
    localparam int TIMER_WID = $clog2(RESET_DURATION+1);

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
    logic __reset;

    state_t state;
    state_t nxt_state;

    logic [TIMER_WID-1:0] timer;
    logic                 timer_reset;
    logic                 timer_inc;

    logic reset_done;

    // ----------------------------------------------------------------
    //  Clocks
    // ----------------------------------------------------------------
    assign core_clk = axis_aclk;

    // ----------------------------------------------------------------
    //  Resets
    // ----------------------------------------------------------------
    // Synchronize module async reset to AXI-L clock domain
    sync_reset i_sync_reset (
        .rst_in   ( mod_rstn ),
        .clk_out  ( axil_aclk ),
        .srst_out ( __reset )
    );

    // Enforce minimum reset assertion time
    initial state = RESET;
    always @(posedge axil_aclk) begin
        if (__reset) state <= RESET;
        else         state <= nxt_state;
    end

    always_comb begin
        nxt_state = state;
        timer_reset = 1'b0;
        timer_inc = 1'b0;
        reset_done = 1'b0;
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
                reset_done = 1'b1;
            end
            default : nxt_state = RESET;
        endcase
    end

    initial timer = 0;
    always @(posedge axil_aclk) begin
        if (timer_reset) timer <= 0;
        else if (timer_inc) timer <= timer + 1;
    end

    // Drive AXI-L reset output
    initial axil_aresetn = 1'b1;
    always @(posedge axil_aclk) axil_aresetn <= reset_done;

    // Synchronize reset to core_clk domain
    sync_reset #(
        .OUTPUT_ACTIVE_LOW ( 1 )
    ) i_sync_reset_core_clk (
        .rst_in   ( axil_aresetn ),
        .clk_out  ( core_clk ),
        .srst_out ( core_rstn )
    );

    // Drive reset done output
    assign mod_rst_done = axil_aresetn;

endmodule: smartnic_250mhz_reset
