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

    // AXI3 memory control channel interface
    axi3_intf.controller  control_proxy_axi_if,
    
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
    axi4l_intf control_proxy_axil_if ();

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
        .control_proxy_axil_if        ( control_proxy_axil_if )
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
        .DATA_WID ( $bits(dram_status_t) )
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
    // AXI-3 control proxy
    // -----------------------------
    // (Local) parameters
    localparam int MEM_ADDR_WID = AXI_ADDR_WID - $clog2(AXI_DATA_BYTE_WID); // Memory interface uses row addressing

    // (Local) Interfaces
    mem_intf #(.ADDR_WID(MEM_ADDR_WID), .DATA_WID(AXI_DATA_WID)) __mem_if (.clk(clk));
    mem_wr_intf #(.ADDR_WID(MEM_ADDR_WID), .DATA_WID(AXI_DATA_WID)) __mem_wr_if (.clk(clk));
    mem_rd_intf #(.ADDR_WID(MEM_ADDR_WID), .DATA_WID(AXI_DATA_WID)) __mem_rd_if (.clk(clk));

    // Memory register proxy
    // (drive AXI-3 memory interface from register proxy controller)
    mem_proxy       #(
        .ACCESS_TYPE ( mem_pkg::ACCESS_READ_WRITE ),
        .MEM_TYPE    ( mem_pkg::MEM_TYPE_HBM )
    ) i_mem_proxy__control (
        .clk         ( clk ),
        .srst        ( local_srst ),
        .init_done   ( ),
        .axil_if     ( control_proxy_axil_if ),
        .mem_if      ( __mem_if )
    );

    mem_sp_to_sdp_adapter i_mem_sp_to_sdp_adapter__hbm (
        .mem_if ( __mem_if ),
        .mem_wr_if ( __mem_wr_if ),
        .mem_rd_if ( __mem_rd_if )
    );

    axi3_from_mem_adapter #(
        .SIZE ( axi3_pkg::SIZE_32BYTES ),
        .WR_TIMEOUT ( 0 ),
        .RD_TIMEOUT ( 0 )
    ) i_axi3_from_mem_adapter (
        .clk           ( clk ),
        .srst          ( local_srst ),
        .init_done     ( ),
        .mem_wr_if     ( __mem_wr_if ),
        .mem_rd_if     ( __mem_rd_if ),
        .axi3_if       ( control_proxy_axi_if )
    );

endmodule : xilinx_hbm_stack_ctrl
