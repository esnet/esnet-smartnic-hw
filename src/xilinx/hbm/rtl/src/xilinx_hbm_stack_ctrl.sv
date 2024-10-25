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

    // AXI3 memory channel interfaces
    axi3_intf.controller  axi_if [PSEUDO_CHANNELS_PER_STACK],
    
    // APB (management) interface
    input logic           apb_clk,
    apb_intf.controller   apb_if,

    // Status
    input logic           init_done,
    
    // DRAM status monitoring
    input logic           dram_status_cattrip,
    input logic [6:0]     dram_status_temp
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
    axi4l_intf ch_axil_if [PSEUDO_CHANNELS_PER_STACK] ();

    apb_intf hbm_channel_apb_if ();

    xilinx_hbm_reg_intf reg_if ();

    // -----------------------------
    // Terminate AXI-L control interface
    // -----------------------------
    // Top-level decoder
    xilinx_hbm_decoder i_xilinx_hbm_decoder (
        .axil_if                      ( axil_if ),
        .xilinx_hbm_axil_if           ( hbm_axil_if ),
        .xilinx_hbm_apb_proxy_axil_if ( hbm_apb_proxy_axil_if ),
        .ch0_axil_if                  ( ch_axil_if[0] ),
        .ch1_axil_if                  ( ch_axil_if[1] ),
        .ch2_axil_if                  ( ch_axil_if[2] ),
        .ch3_axil_if                  ( ch_axil_if[3] ),
        .ch4_axil_if                  ( ch_axil_if[4] ),
        .ch5_axil_if                  ( ch_axil_if[5] ),
        .ch6_axil_if                  ( ch_axil_if[6] ),
        .ch7_axil_if                  ( ch_axil_if[7] ),
        .ch8_axil_if                  ( ch_axil_if[8] ),
        .ch9_axil_if                  ( ch_axil_if[9] ),
        .ch10_axil_if                 ( ch_axil_if[10] ),
        .ch11_axil_if                 ( ch_axil_if[11] ),
        .ch12_axil_if                 ( ch_axil_if[12] ),
        .ch13_axil_if                 ( ch_axil_if[13] ),
        .ch14_axil_if                 ( ch_axil_if[14] ),
        .ch15_axil_if                 ( ch_axil_if[15] )
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
    assign dram_status__apb_clk.init_done = init_done;
    assign dram_status__apb_clk.temp = dram_status_temp;
    assign dram_status__apb_clk.cattrip = dram_status_cattrip;

    sync_bus_sampled #(
        .DATA_T   ( dram_status_t )
    ) i_sync_bus_sampled__dram_status (
        .clk_in   ( apb_if.pclk ),
        .rst_in   ( 1'b0 ),
        .data_in  ( dram_status__apb_clk ),
        .clk_out  ( clk ),
        .rst_out  ( 1'b0 ),
        .data_out ( dram_status__clk )
    );

    // Report status
    assign reg_if.status_nxt_v = 1'b1;
    assign reg_if.status_nxt.reset = local_srst;
    assign reg_if.status_nxt.init_done = dram_status__clk.init_done;

    assign reg_if.dram_status_nxt_v = 1'b1;
    assign reg_if.dram_status_nxt.cattrip = dram_status__clk.cattrip;
    assign reg_if.dram_status_nxt.temp = dram_status__clk.temp;

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

    // -----------------------------
    // AXI-3 pseudo channels
    // -----------------------------
    generate
        for (genvar g_ch = 0; g_ch < PSEUDO_CHANNELS_PER_STACK; g_ch++) begin : g__ch
            // (Local) Interfaces
            mem_wr_intf #(.ADDR_WID(AXI_ADDR_WID), .DATA_WID(AXI_DATA_WID)) __mem_wr_if (.clk(clk));
            mem_rd_intf #(.ADDR_WID(AXI_ADDR_WID), .DATA_WID(AXI_DATA_WID)) __mem_rd_if (.clk(clk));

            // Memory register proxy
            // (drive AXI-3 memory interfaces from register proxy controller)
            mem_proxy       #(
                .ADDR_T      ( logic[AXI_ADDR_WID-1:0] ),
                .DATA_T      ( logic[AXI_DATA_WID-1:0] ),
                .BURST_LEN   ( 1 ),
                .ACCESS_TYPE ( mem_pkg::ACCESS_READ_WRITE ),
                .MEM_TYPE    ( mem_pkg::MEM_TYPE_HBM )
            ) i_mem_proxy (
                .clk         ( clk ),
                .srst        ( local_srst ),
                .init_done   ( ),
                .axil_if     ( ch_axil_if [g_ch] ),
                .mem_wr_if   ( __mem_wr_if ),
                .mem_rd_if   ( __mem_rd_if )
            );

            axi3_mem_adapter #(
                .SIZE ( axi3_pkg::SIZE_32BYTES ),
                .WR_TIMEOUT ( 0 ),
                .RD_TIMEOUT ( 0 )
            ) i_axi3_mem_adapter (
                .clk           ( clk ),
                .srst          ( local_srst ),
                .init_done     ( ),
                .mem_wr_if     ( __mem_wr_if ),
                .mem_rd_if     ( __mem_rd_if ),
                .axi3_if       ( axi_if [g_ch ] )
            );
        end : g__ch
    endgenerate

endmodule : xilinx_hbm_stack_ctrl
