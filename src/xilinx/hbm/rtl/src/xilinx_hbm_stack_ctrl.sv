module xilinx_hbm_stack_ctrl
    import xilinx_hbm_pkg::*;
#(
    parameter stack_t   STACK = STACK_LEFT,
    parameter density_t DENSITY = DENSITY_4G
) (

    // Clock/reset (memory interface)
    input logic           clk,
    input logic           srst,

    // AXI-L control interface
    axi4l_intf.peripheral axil_if,

    // APB (management) interface
    input logic           apb_clk,
    apb_intf.controller   apb_if,

    // Status monitoring (synchronous with APB PCLK)
    input logic           apb_complete,
    input logic           dram_status_cattrip,
    input logic [6:0]     dram_status_temp,

    // Output (synchronous with clk)
    output logic          init_done,

    // Monitoring
    input logic            wr_done        [PSEUDO_CHANNELS_PER_STACK],
    input axi3_pkg::resp_t wr_status      [PSEUDO_CHANNELS_PER_STACK],
    input logic            wr_timeout     [PSEUDO_CHANNELS_PER_STACK],
    input logic [9:0]      wr_latency     [PSEUDO_CHANNELS_PER_STACK],
    input logic            wr_timer_oflow [PSEUDO_CHANNELS_PER_STACK],
    input logic            wr_timer_uflow [PSEUDO_CHANNELS_PER_STACK],
    input logic            rd_done        [PSEUDO_CHANNELS_PER_STACK],
    input axi3_pkg::resp_t rd_status      [PSEUDO_CHANNELS_PER_STACK],
    input logic            rd_timeout     [PSEUDO_CHANNELS_PER_STACK],
    input logic [9:0]      rd_latency     [PSEUDO_CHANNELS_PER_STACK],
    input logic            rd_timer_oflow [PSEUDO_CHANNELS_PER_STACK],
    input logic            rd_timer_uflow [PSEUDO_CHANNELS_PER_STACK]
);

    // -----------------------------
    // Parameters
    // -----------------------------
    localparam int AXI_ADDR_WID = get_addr_wid(DENSITY);

    // -----------------------------
    // Typedefs
    // -----------------------------
    typedef struct packed {
        logic       init_done;
        logic [6:0] temp;
        logic       cattrip;
    } dram_status_t;

    // -----------------------------
    // Signals
    // -----------------------------
    logic         local_srst;

    dram_status_t dram_status__apb_clk;
    dram_status_t dram_status__clk;

    // -----------------------------
    // Interfaces
    // -----------------------------
    axi4l_intf hbm_axil_if ();
    axi4l_intf hbm_axil_if__clk ();
    axi4l_intf hbm_apb_proxy_axil_if ();
    axi4l_intf hbm_apb_proxy_axil_if__apb_clk ();

    apb_intf hbm_channel_apb_if ();

    xilinx_hbm_reg_intf reg_if ();

    // -----------------------------
    // Terminate AXI-L control interface
    // -----------------------------
    // Top-level decoder
    xilinx_hbm_decoder i_xilinx_hbm_decoder (
        .axil_if                      ( axil_if ),
        .xilinx_hbm_axil_if           ( hbm_axil_if ),
        .xilinx_hbm_apb_proxy_axil_if ( hbm_apb_proxy_axil_if )
    );

    // CDC
    axi4l_intf_cdc i_axi4l_intf_cdc__hbm (
        .axi4l_if_from_controller( hbm_axil_if ),
        .clk_to_peripheral       ( clk ),
        .axi4l_if_to_peripheral  ( hbm_axil_if__clk )
    );

    // HBM main control
    xilinx_hbm_reg_blk i_xilinx_hbm_reg_blk (
        .axil_if    ( hbm_axil_if__clk ),
        .reg_blk_if ( reg_if )
    );

    // Block-level reset control
    initial local_srst = 1'b1;
    always @(posedge clk) begin
        if (srst || reg_if.control.reset) local_srst <= 1'b1;
        else                              local_srst <= 1'b0;
    end

    // CDC (cross status signals from APB to clk clock domain)
    assign dram_status__apb_clk.init_done = apb_complete;
    assign dram_status__apb_clk.temp = dram_status_temp;
    assign dram_status__apb_clk.cattrip = dram_status_cattrip;

    sync_bus_sampled #(
        .DATA_WID ( $bits(dram_status_t) )
    ) i_sync_bus_sampled__dram_status (
        .clk_in   ( apb_if.pclk ),
        .rst_in   ( 1'b0 ),
        .data_in  ( dram_status__apb_clk ),
        .clk_out  ( clk ),
        .rst_out  ( 1'b0 ),
        .data_out ( dram_status__clk )
    );

    assign init_done = dram_status__clk.init_done;

    // Report status
    assign reg_if.status_nxt_v = 1'b1;
    assign reg_if.status_nxt.reset = local_srst;
    assign reg_if.status_nxt.init_done = dram_status__clk.init_done;

    assign reg_if.dram_status_nxt_v = 1'b1;
    assign reg_if.dram_status_nxt.cattrip = dram_status__clk.cattrip;
    assign reg_if.dram_status_nxt.temp = dram_status__clk.temp;

    // -----------------------------
    // Transaction monitoring
    // -----------------------------
    generate
        for (genvar g_ch = 0; g_ch < PSEUDO_CHANNELS_PER_STACK; g_ch++) begin : g__ch
            // (Local) signals
            logic wr_okay_flag;
            logic wr_exokay_flag;
            logic wr_slverr_flag;
            logic wr_decerr_flag;
            logic wr_timeout_flag;
            logic wr_timer_oflow_flag;
            logic wr_timer_uflow_flag;
            logic rd_okay_flag;
            logic rd_exokay_flag;
            logic rd_slverr_flag;
            logic rd_decerr_flag;
            logic rd_timeout_flag;
            logic rd_timer_oflow_flag;
            logic rd_timer_uflow_flag;
            logic [9:0] wr_latency_last;
            logic [9:0] wr_latency_min;
            logic [9:0] wr_latency_max;
            logic [9:0] rd_latency_last;
            logic [9:0] rd_latency_min;
            logic [9:0] rd_latency_max;
            logic wr_status_clear;
            logic wr_latency_clear;
            logic rd_status_clear;
            logic rd_latency_clear;

            // Write transaction status
            always_ff @(posedge clk) begin
                if (srst || reg_if.wr_status_rd_evt[g_ch]) wr_status_clear <= 1'b1;
                else wr_status_clear <= 1'b0;
            end

            initial begin
                wr_okay_flag = 1'b0;
                wr_exokay_flag = 1'b0;
                wr_slverr_flag = 1'b0;
                wr_decerr_flag = 1'b0;
                wr_timeout_flag = 1'b0;
            end
            always @(posedge clk) begin
                if (wr_status_clear) begin
                    wr_okay_flag <= 1'b0;
                    wr_exokay_flag <= 1'b0;
                    wr_slverr_flag <= 1'b0;
                    wr_decerr_flag <= 1'b0;
                    wr_timeout_flag <= 1'b0;
                end
                if (wr_done[g_ch]) begin
                   if (wr_status[g_ch] == axi3_pkg::RESP_OKAY)   wr_okay_flag <= 1'b1;
                   if (wr_status[g_ch] == axi3_pkg::RESP_EXOKAY) wr_exokay_flag <= 1'b1;
                   if (wr_status[g_ch] == axi3_pkg::RESP_SLVERR) wr_slverr_flag <= 1'b1;
                   if (wr_status[g_ch] == axi3_pkg::RESP_DECERR) wr_decerr_flag <= 1'b1;
                end
                if (wr_timeout[g_ch]) wr_timeout_flag <= 1'b1;
            end

            assign reg_if.wr_status_nxt_v[g_ch] = 1'b1;
            assign reg_if.wr_status_nxt[g_ch].okay    = wr_okay_flag;
            assign reg_if.wr_status_nxt[g_ch].exokay  = wr_exokay_flag;
            assign reg_if.wr_status_nxt[g_ch].slverr  = wr_slverr_flag;
            assign reg_if.wr_status_nxt[g_ch].decerr  = wr_decerr_flag;
            assign reg_if.wr_status_nxt[g_ch].timeout = wr_timeout_flag;

            // Write latency tracking
            always_ff @(posedge clk) begin
                if (srst || reg_if.wr_latency_rd_evt[g_ch]) wr_latency_clear <= 1'b1;
                else wr_latency_clear <= 1'b0;
            end

            initial begin
                wr_timer_oflow_flag = 1'b0;
                wr_timer_uflow_flag = 1'b0;
                wr_latency_last = '0;
                wr_latency_min = '1;
                wr_latency_max = '0;
            end
            always @(posedge clk) begin
                if (wr_latency_clear) begin
                    wr_timer_oflow_flag <= 1'b0;
                    wr_timer_uflow_flag <= 1'b0;
                    wr_latency_last <= '0;
                    wr_latency_min <= '1;
                    wr_latency_max <= '0;
                end
                if (wr_done[g_ch]) begin
                   wr_latency_last <= wr_latency[g_ch];
                   if (wr_latency[g_ch] < wr_latency_min) wr_latency_min <= wr_latency[g_ch];
                   if (wr_latency[g_ch] > wr_latency_max) wr_latency_max <= wr_latency[g_ch];
                end
                if (wr_timer_oflow[g_ch]) wr_timer_oflow_flag <= 1'b1;
                if (wr_timer_oflow[g_ch]) wr_timer_uflow_flag <= 1'b1;
            end

            assign reg_if.wr_latency_nxt_v[g_ch] = 1'b1;
            assign reg_if.wr_latency_nxt[g_ch].latency_last = wr_latency_last;
            assign reg_if.wr_latency_nxt[g_ch].latency_min  = wr_latency_min;
            assign reg_if.wr_latency_nxt[g_ch].latency_max  = wr_latency_max;
            assign reg_if.wr_latency_nxt[g_ch].timer_oflow  = wr_timer_oflow_flag;
            assign reg_if.wr_latency_nxt[g_ch].timer_uflow  = wr_timer_uflow_flag;

            // Read transaction status
            always_ff @(posedge clk) begin
                if (srst || reg_if.rd_status_rd_evt[g_ch]) rd_status_clear <= 1'b1;
                else rd_status_clear <= 1'b0;
            end

            initial begin
                rd_okay_flag = 1'b0;
                rd_exokay_flag = 1'b0;
                rd_slverr_flag = 1'b0;
                rd_decerr_flag = 1'b0;
                rd_timeout_flag = 1'b0;
            end
            always @(posedge clk) begin
                if (rd_status_clear) begin
                    rd_okay_flag <= 1'b0;
                    rd_exokay_flag <= 1'b0;
                    rd_slverr_flag <= 1'b0;
                    rd_decerr_flag <= 1'b0;
                    rd_timeout_flag <= 1'b0;
                end
                if (rd_done[g_ch]) begin
                   if (rd_status[g_ch] == axi3_pkg::RESP_OKAY)   rd_okay_flag <= 1'b1;
                   if (rd_status[g_ch] == axi3_pkg::RESP_EXOKAY) rd_exokay_flag <= 1'b1;
                   if (rd_status[g_ch] == axi3_pkg::RESP_SLVERR) rd_slverr_flag <= 1'b1;
                   if (rd_status[g_ch] == axi3_pkg::RESP_DECERR) rd_decerr_flag <= 1'b1;
                end
                if (rd_timeout[g_ch]) rd_timeout_flag <= 1'b1;
            end

            assign reg_if.rd_status_nxt_v[g_ch] = 1'b1;
            assign reg_if.rd_status_nxt[g_ch].okay = rd_okay_flag;
            assign reg_if.rd_status_nxt[g_ch].exokay = rd_exokay_flag;
            assign reg_if.rd_status_nxt[g_ch].slverr = rd_slverr_flag;
            assign reg_if.rd_status_nxt[g_ch].decerr = rd_decerr_flag;
            assign reg_if.rd_status_nxt[g_ch].timeout = rd_timeout_flag;

            // Read latency tracking
            always_ff @(posedge clk) begin
                if (srst || reg_if.rd_latency_rd_evt[g_ch]) rd_latency_clear <= 1'b1;
                else rd_latency_clear <= 1'b0;
            end

            initial begin
                rd_timer_oflow_flag = 1'b0;
                rd_timer_uflow_flag = 1'b0;
                rd_latency_last = '0;
                rd_latency_min = '1;
                rd_latency_max = '0;
            end
            always @(posedge clk) begin
                if (rd_latency_clear) begin
                    rd_timer_oflow_flag <= 1'b0;
                    rd_timer_uflow_flag <= 1'b0;
                    rd_latency_last <= '0;
                    rd_latency_min <= '1;
                    rd_latency_max <= '0;
                end
                if (rd_done[g_ch]) begin
                   rd_latency_last <= rd_latency[g_ch];
                   if (rd_latency[g_ch] < rd_latency_min) rd_latency_min <= rd_latency[g_ch];
                   if (rd_latency[g_ch] > rd_latency_max) rd_latency_max <= rd_latency[g_ch];
                end
                if (rd_timer_oflow[g_ch]) rd_timer_oflow_flag <= 1'b1;
                if (rd_timer_oflow[g_ch]) rd_timer_uflow_flag <= 1'b1;
            end

            assign reg_if.rd_latency_nxt_v[g_ch] = 1'b1;
            assign reg_if.rd_latency_nxt[g_ch].latency_last = rd_latency_last;
            assign reg_if.rd_latency_nxt[g_ch].latency_min  = rd_latency_min;
            assign reg_if.rd_latency_nxt[g_ch].latency_max  = rd_latency_max;
            assign reg_if.rd_latency_nxt[g_ch].timer_oflow  = rd_timer_oflow_flag;
            assign reg_if.rd_latency_nxt[g_ch].timer_uflow  = rd_timer_uflow_flag;
        end : g__ch
    endgenerate
    // -----------------------------
    // Drive HBM channel config/status registers
    // -----------------------------
    // CDC
    axi4l_intf_cdc i_axi4l_intf_cdc__hbm_apb (
        .axi4l_if_from_controller( hbm_apb_proxy_axil_if ),
        .clk_to_peripheral       ( apb_clk ),
        .axi4l_if_to_peripheral  ( hbm_apb_proxy_axil_if__apb_clk )
    );

    // Bridge to APB
    axi4l_apb_proxy i_axi4l_apb_proxy (
        .axi4l_if ( hbm_apb_proxy_axil_if__apb_clk ),
        .apb_if   ( apb_if )
    );

endmodule : xilinx_hbm_stack_ctrl
