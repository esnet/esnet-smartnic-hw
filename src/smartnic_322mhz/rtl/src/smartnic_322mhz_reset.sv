module smartnic_322mhz_reset #(
    parameter int NUM_CMAC = 1
) (
    // Generic signal pair for reset
    input  logic                mod_rstn,
    output logic                mod_rst_done,

    output logic                axil_aresetn,
    output logic [NUM_CMAC-1:0] cmac_rstn,
    input  logic                axil_aclk,
    input  logic [NUM_CMAC-1:0] cmac_clk,

    output logic                core_rstn,
    output logic                core_clk,  // we synthesize this clock in this block

    output logic                clk_100mhz,
    output logic                hbm_ref_clk
);

    localparam int RESET_DURATION = 100;

    logic        rstn;
    logic        reset_in_progress = 1'b0;
    logic [15:0] reset_timer = 0;

    // Local reset `rstn` will be asserted for at least 2 cycles asynchronously,
    // and deasserted synchronously with the clock
    xpm_cdc_async_rst #(
        .DEST_SYNC_FF    (2),
        .INIT_SYNC_FF    (0),
        .RST_ACTIVE_HIGH (0)
    ) axil_rst_inst (
        .src_arst  (mod_rstn),
        .dest_arst (rstn),
        .dest_clk  (axil_aclk)
    );

    initial mod_rst_done = 1'b0;
    always @(posedge axil_aclk) begin
        if (~reset_in_progress && ~rstn) begin
            reset_in_progress <= 1'b1;
            mod_rst_done      <= 1'b0;
        end else if (reset_in_progress && (reset_timer >= RESET_DURATION)) begin
            reset_in_progress <= 1'b0;
            mod_rst_done      <= 1'b1;
        end
    end

    always @(posedge axil_aclk) begin
        if (reset_in_progress) begin
            reset_timer <= reset_timer + 1;
        end else begin
            reset_timer <= 0;
        end
    end

    assign axil_aresetn = ~reset_in_progress;

    // CMAC domain resets are generated from the locally generated AXI-lite reset
    generate
        for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__cmac
        xpm_cdc_async_rst #(
            .DEST_SYNC_FF    (2),
            .INIT_SYNC_FF    (0),
            .RST_ACTIVE_HIGH (0)
        ) cmac_rst_inst (
            .src_arst  (axil_aresetn),
            .dest_arst (cmac_rstn[i]),
            .dest_clk  (cmac_clk[i])
        );
        end : g__cmac
    endgenerate

    // core clock domain resets are generated from the locally generated AXI-lite reset
    xpm_cdc_async_rst #(
        .DEST_SYNC_FF    (2),
        .INIT_SYNC_FF    (0),
        .RST_ACTIVE_HIGH (0)
    ) core_rst_inst (
        .src_arst  (axil_aresetn),
        .dest_arst (core_rstn),
        .dest_clk  (core_clk)
    );

    // core clock domain is asynchronous wrt. CMAC domains, and is derived from AXI-lite via a PLL
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
