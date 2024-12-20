module proxy_test
#(
    parameter int NUM_PORTS = 2  // Number of ingress/egress axi4s ports.
 ) (
    input  logic      clk,
    input  logic      srst,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],
    axi4s_intf.tx     axi4s_c2h [NUM_PORTS],

    axi4l_intf.peripheral axil_if
);
    // ----------------------------------------------------------------
    //  Parameters
    // ----------------------------------------------------------------
    localparam int HBM_NUM_AXI_CHANNELS = xilinx_hbm_pkg::PSEUDO_CHANNELS_PER_STACK;

    localparam xilinx_hbm_pkg::density_t HBM_DENSITY = xilinx_hbm_pkg::DENSITY_4G;
    localparam int  HBM_AXI_DATA_BYTE_WID = xilinx_hbm_pkg::AXI_DATA_BYTE_WID;
    localparam int  HBM_AXI_ADDR_WID = xilinx_hbm_pkg::get_addr_wid(HBM_DENSITY);
    localparam type HBM_AXI_ID_T = logic[xilinx_hbm_pkg::AXI_ID_WID-1:0];

    // ----------------------------------------------------------------
    //  Interfaces
    // ----------------------------------------------------------------
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_T(HBM_AXI_ID_T)) axi_if__hbm_left  [HBM_NUM_AXI_CHANNELS] ();
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_T(HBM_AXI_ID_T)) axi_if__hbm_right [HBM_NUM_AXI_CHANNELS] ();

    // ----------------------------------------------------------------
    //  Register map block and decoder instantiations
    // ----------------------------------------------------------------
    axi4l_intf axil_to_proxy_test ();
    axi4l_intf axil_to_reg_proxy ();
    axi4l_intf axil_to_mem_proxy_4b ();
    axi4l_intf axil_to_mem_proxy_64b ();
    axi4l_intf axil_to_packet_playback ();
    axi4l_intf axil_to_packet_capture ();
    axi4l_intf axil_to_hbm_left ();
    axi4l_intf axil_to_hbm_right ();

    proxy_test_reg_intf  proxy_test_regs();

    // proxy_test register decoder
    proxy_test_decoder proxy_test_decoder (
        .axil_if                     ( axil_if ),
        .proxy_test_axil_if          ( axil_to_proxy_test ),
        .reg_proxy_axil_if           ( axil_to_reg_proxy ),
        .mem_proxy_4b_axil_if        ( axil_to_mem_proxy_4b ),
        .mem_proxy_64b_axil_if       ( axil_to_mem_proxy_64b ),
        .packet_playback_axil_if     ( axil_to_packet_playback ),
        .packet_capture_axil_if      ( axil_to_packet_capture ),
        .hbm_left_axil_if            ( axil_to_hbm_left ),
        .hbm_right_axil_if           ( axil_to_hbm_right )
    );

    // proxy_test register block
    proxy_test_reg_blk proxy_test_reg_blk
    (
        .axil_if    ( axil_to_proxy_test ),
        .reg_blk_if ( proxy_test_regs )
    );

    // ----------------------------------------------------------------
    //  Register proxy
    // ----------------------------------------------------------------
    axi4l_pkg::resp_t __wr_resp;
    axi4l_pkg::resp_t __rd_resp;

    reg_intf reg_if ();
    axi4l_intf axil_to_indirect ();
    axi4l_intf axil_to_indirect__clk ();
    proxy_test_indirect_reg_intf  indirect_regs();

    reg_proxy i_reg_proxy (
        .axil_if ( axil_to_reg_proxy ),
        .reg_if  ( reg_if )
    );

    // Drive register block with AXI-L
    axi4l_controller i_axi4l_controller (
        .clk     ( reg_if.clk ),
        .srst    ( reg_if.srst ),
        .wr      ( reg_if.wr ),
        .wr_addr ( reg_if.wr_addr ),
        .wr_data ( reg_if.wr_data ),
        .wr_strb ( reg_if.wr_byte_en ),
        .wr_ack  ( reg_if.wr_ack ),
        .wr_resp ( __wr_resp ),
        .rd      ( reg_if.rd ),
        .rd_addr ( reg_if.rd_addr ),
        .rd_data ( reg_if.rd_data ),
        .rd_ack  ( reg_if.rd_ack ),
        .rd_resp ( __rd_resp ),
        .axi4l_if( axil_to_indirect )
    );

    // Pass AXI-L interface from aclk (AXI-L clock) to clk domain
    axi4l_intf_cdc i_axil_intf_cdc__indirect (
        .axi4l_if_from_controller   ( axil_to_indirect ),
        .clk_to_peripheral          ( clk ),
        .axi4l_if_to_peripheral     ( axil_to_indirect__clk )
    );

    assign reg_if.wr_error = (__wr_resp != axi4l_pkg::RESP_OKAY);
    assign reg_if.rd_error = (__rd_resp != axi4l_pkg::RESP_OKAY);

    // Register block
    proxy_test_indirect_reg_blk i_proxy_test_indirect_reg_blk (
        .axil_if    ( axil_to_indirect__clk ),
        .reg_blk_if ( indirect_regs )
    );

    // Read-only info registers
    assign indirect_regs.pre_nxt_v = 1'b1;
    assign indirect_regs.pre_nxt = 'h20505245;  // " PRE"

    assign indirect_regs.post_nxt_v = 1'b1;
    assign indirect_regs.post_nxt = 'h504F5354; // "POST"

    // Capture 'trigger' on write events, and p
    proxy_test_indirect_reg_pkg::reg_status_t reg_status;

    initial reg_status = 0;
    always @(posedge clk) begin
        if (srst) reg_status <= '0;
        else if (indirect_regs.trigger_wr_evt) reg_status.trigger_value <= indirect_regs.trigger.value;
    end

    assign indirect_regs.status_nxt_v = 1'b1;
    assign indirect_regs.status_nxt = reg_status;

    // ----------------------------------------------------------------
    //  Memory proxy (32-bit / 4-byte word size)
    // ----------------------------------------------------------------
    localparam int MEM_SIZE_4B = 32768;
    localparam int MEM_DEPTH_4B = MEM_SIZE_4B / 32;
    localparam int ADDR_WID_4B = $clog2(MEM_DEPTH_4B);
    localparam type ADDR_T_4B = logic[ADDR_WID_4B-1:0];

    localparam mem_pkg::spec_t SPEC_4B = '{
        ADDR_WID  : ADDR_WID_4B,
        DATA_WID  : 32,
        ASYNC     : 0,
        RESET_FSM : 1,
        OPT_MODE  : mem_pkg::OPT_MODE_DEFAULT
    };

    axi4l_intf axil_to_mem_proxy_4b__clk ();
    mem_intf #(.ADDR_T(ADDR_T_4B), .DATA_T(logic[31:0])) mem_4b_if (.clk);

    // Pass AXI-L interface from aclk (AXI-L clock) to clk domain
    axi4l_intf_cdc i_axil_intf_cdc__mem_proxy_4b (
        .axi4l_if_from_controller   ( axil_to_mem_proxy_4b ),
        .clk_to_peripheral          ( clk ),
        .axi4l_if_to_peripheral     ( axil_to_mem_proxy_4b__clk )
    );

    mem_proxy i_mem_proxy_4b (
        .clk,
        .srst,
        .init_done (),
        .axil_if   ( axil_to_mem_proxy_4b__clk ),
        .mem_if    ( mem_4b_if )
    );

    mem_ram_sp #(
        .SPEC ( SPEC_4B )
    ) i_mem_ram_sdp_4b (
        .mem_if ( mem_4b_if )
    );

    // ----------------------------------------------------------------
    //  Memory proxy (512-bit / 64-byte word width)
    // ----------------------------------------------------------------
    localparam int MEM_SIZE_64B = 32768;
    localparam int MEM_DEPTH_64B = MEM_SIZE_64B / 512;
    localparam int ADDR_WID_64B = $clog2(MEM_DEPTH_64B);
    localparam type ADDR_T_64B = logic[ADDR_WID_64B-1:0];

    localparam mem_pkg::spec_t SPEC_64B = '{
        ADDR_WID  : ADDR_WID_64B,
        DATA_WID  : 512,
        ASYNC     : 0,
        RESET_FSM : 1,
        OPT_MODE  : mem_pkg::OPT_MODE_DEFAULT
    };

    axi4l_intf axil_to_mem_proxy_64b__clk ();
    mem_intf #(.ADDR_T(ADDR_T_64B), .DATA_T(logic[511:0])) mem_64b_if (.clk);

    // Pass AXI-L interface from aclk (AXI-L clock) to clk domain
    axi4l_intf_cdc i_axil_intf_cdc__mem_proxy_64b (
        .axi4l_if_from_controller   ( axil_to_mem_proxy_64b ),
        .clk_to_peripheral          ( clk ),
        .axi4l_if_to_peripheral     ( axil_to_mem_proxy_64b__clk )
    );

    mem_proxy i_mem_proxy_64b (
        .clk,
        .srst,
        .init_done (),
        .axil_if   ( axil_to_mem_proxy_64b__clk ),
        .mem_if    ( mem_64b_if )
    );

    mem_ram_sp #(
        .SPEC ( SPEC_64B )
    ) i_mem_ram_sdp_64b (
        .mem_if ( mem_64b_if )
    );

    // ----------------------------------------------------------------
    //  HBM controller instantiation
    // ----------------------------------------------------------------
    proxy_test_clk_wiz i_proxy_test_clk_wiz__hbm (
        .clk_in1     ( axil_if.aclk ),
        .clk_100mhz  ( clk_100mhz ),
        .hbm_ref_clk ( hbm_ref_clk )
    );

    xilinx_hbm_stack #(
        .STACK   ( xilinx_hbm_pkg::STACK_LEFT ),
        .DENSITY ( HBM_DENSITY )
    ) i_xilinx_hbm_stack__left (
        .clk,
        .srst,
        .hbm_ref_clk ( hbm_ref_clk ),
        .clk_100mhz  ( clk_100mhz ),
        .axil_if     ( axil_to_hbm_left ),
        .axi_if      ( axi_if__hbm_left )
    );

    // Tie off AXI3 interfaces for now
    for (genvar g_ch = 0; g_ch < HBM_NUM_AXI_CHANNELS; g_ch++) begin : g__hbm_ch_left
        axi3_intf_controller_term i_axi3_intf_controller_term (.axi3_if (axi_if__hbm_left[g_ch]));
    end : g__hbm_ch_left

    xilinx_hbm_stack #(
        .STACK   ( xilinx_hbm_pkg::STACK_RIGHT ),
        .DENSITY ( HBM_DENSITY )
    ) i_xilinx_hbm_stack__right (
        .clk,
        .srst,
        .hbm_ref_clk ( hbm_ref_clk ),
        .clk_100mhz  ( clk_100mhz ),
        .axil_if     ( axil_to_hbm_right ),
        .axi_if      ( axi_if__hbm_right )
    );

    // Tie off AXI3 interfaces for now
    for (genvar g_ch = 0; g_ch < HBM_NUM_AXI_CHANNELS; g_ch++) begin : g__hbm_ch_right
        axi3_intf_controller_term i_axi3_intf_controller_term (.axi3_if (axi_if__hbm_right[g_ch]));
    end : g__hbm_ch_right

    // ----------------------------------------------------------------
    // Packet proxy
    // ----------------------------------------------------------------
    packet_intf #(.DATA_BYTE_WID(32), .META_T(logic[63:0])) packet_if__playback (.clk, .srst);
    packet_intf #(.DATA_BYTE_WID(32), .META_T(logic[63:0])) packet_if__capture (.clk, .srst);

    packet_playback i_packet_playback (
        .clk,
        .srst,
        .en (),
        .axil_if ( axil_to_packet_playback ),
        .packet_if ( packet_if__playback )
    );

    packet_fifo #(
      .MIN_PKT_SIZE ( 40 ),
      .MAX_PKT_SIZE ( 9200 )
    ) i_packet_fifo (
        .packet_in_if ( packet_if__playback ),
        .packet_out_if ( packet_if__capture )
    );

    packet_capture i_packet_capture (
        .clk,
        .srst,
        .en (),
        .axil_if ( axil_to_packet_capture ),
        .packet_if ( packet_if__capture )
    );


    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            // Connect AXI-S interfaces in pass-through
            axi4s_full_pipe axi4s_full_pipe_0 (.axi4s_if_from_tx(axi4s_in[g_port]), .axi4s_if_to_rx(axi4s_out[g_port]));
            // Tie off C2H interface
            axi4s_intf_tx_term axi4s_intf_tx_term_0 (.aclk(clk), .aresetn(~srst), .axi4s_if(axi4s_c2h[g_port]));
        end
    endgenerate

endmodule: proxy_test
