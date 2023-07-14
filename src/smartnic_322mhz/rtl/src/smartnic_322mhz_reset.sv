module smartnic_322mhz_reset #(
    parameter int NUM_CMAC = 1
) (
    // Generic signal pair for reset
    input  logic                mod_rstn,  // assume async
    output logic                mod_rst_done,

    input  logic                axil_aclk,
    output logic                axil_srstn, // synchronous to axil_aclk (async assert, sync deassert)

    input  logic [NUM_CMAC-1:0] cmac_clk,
    output logic [NUM_CMAC-1:0] cmac_srstn, // synchronous to cmac_clk (async assert, sync deassert)

    output logic                core_clk,  // we synthesize this clock in this block
    output logic                core_srstn, // synchronous to core_clk (async assert, sync deassert)

    output logic                clk_100mhz,
    output logic                hbm_ref_clk
);

    localparam int RESET_DURATION = 100;
    localparam int TIMER_WID = $clog2(RESET_DURATION);

    logic                 srstn;
    logic [TIMER_WID-1:0] reset_timer;

    // Retime module reset to AXI-L clock domain (async assert, synchronous deassert)
    sync_reset #(
        .OUTPUT_ACTIVE_LOW (1)
    ) sync_reset__axil (
        .rst_in    (mod_rstn),
        .clk_out   (axil_aclk),
        .srst_out  (srstn)
    );

    initial reset_timer = '0;
    always @(posedge axil_aclk) begin
        if (!srstn)                            reset_timer <= '0;
        else if (reset_timer < RESET_DURATION) reset_timer <= reset_timer + 1;
    end

    // AXI-L reset is debounced version of synchronized module reset (async assert, sync deassert)
    initial axil_srstn = 1'b0;
    always @(posedge axil_aclk or negedge srstn) begin
        if (!srstn)                             axil_srstn <= 1'b0;
        else if (reset_timer >= RESET_DURATION) axil_srstn <= 1'b1;
    end

    // Signal module reset done (fully synchronous to axil_aclk)
    initial mod_rst_done = 1'b0;
    always @(posedge axil_aclk) begin
        if (!srstn)                             mod_rst_done <= 1'b0;
        else if (reset_timer >= RESET_DURATION) mod_rst_done <= 1'b1;
    end

    // CMAC domain resets are generated from the locally generated AXI-L reset
    generate
        for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__cmac
            sync_reset #(
                .OUTPUT_ACTIVE_LOW (1)
            ) sync_reset__cmac (
                .rst_in  (axil_srstn),
                .clk_out (cmac_clk[i]),
                .srst_out(cmac_srstn[i])
            );
        end : g__cmac
    endgenerate

    // core clock domain reset is generated from the locally generated AXI-L reset
    sync_reset #(
        .OUTPUT_ACTIVE_LOW (1)
    ) sync_reset__core_clk (
        .rst_in   (axil_srstn),
        .clk_out  (core_clk),
        .srst_out (core_srstn)
    );

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

endmodule: smartnic_322mhz_reset
