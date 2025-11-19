module smartnic_250mhz_reset (
    input  logic mod_rstn,     // Module reset pair from open-nic-shell
    output logic mod_rst_done, // (synchronized to axil_aclk)

    input  logic axis_aclk,

    input  logic axil_aclk,
    output logic axil_aresetn,

    output logic core_srst,
    output logic core_clk
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
    //  Clocks
    // ----------------------------------------------------------------
    assign core_clk = axis_aclk;

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

    // Synchronize reset to core_clk domain
    sync_reset i_sync_reset_core_clk (
        .clk_in  ( axil_aclk ),
        .rst_in  ( axil_aresetn ),
        .clk_out ( core_clk ),
        .rst_out ( core_srst )
    );

endmodule: smartnic_250mhz_reset
