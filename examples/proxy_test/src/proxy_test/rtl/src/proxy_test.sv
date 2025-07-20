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
    localparam int HBM_NUM_APP_AXI_CHANNELS__LEFT = 5;
    localparam int HBM_NUM_APP_AXI_CHANNELS__RIGHT = 1;

    localparam xilinx_hbm_pkg::density_t HBM_DENSITY = xilinx_hbm_pkg::DENSITY_4G;
    localparam int  HBM_AXI_DATA_BYTE_WID = xilinx_hbm_pkg::AXI_DATA_BYTE_WID;
    localparam int  HBM_AXI_DATA_WID = xilinx_hbm_pkg::AXI_DATA_WID;
    localparam int  HBM_AXI_ADDR_WID = xilinx_hbm_pkg::get_addr_wid(HBM_DENSITY);
    localparam type HBM_AXI_ID_T = logic[xilinx_hbm_pkg::AXI_ID_WID-1:0];

    // ----------------------------------------------------------------
    //  Interfaces
    // ----------------------------------------------------------------
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_T(HBM_AXI_ID_T)) app__axi_if__hbm_left [HBM_NUM_APP_AXI_CHANNELS__LEFT]  (.aclk (clk));
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_T(HBM_AXI_ID_T)) app__axi_if__hbm_right[HBM_NUM_APP_AXI_CHANNELS__RIGHT] (.aclk (clk));
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_T(HBM_AXI_ID_T)) axi_if__hbm_left  [HBM_NUM_AXI_CHANNELS] (.aclk (clk));
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_T(HBM_AXI_ID_T)) axi_if__hbm_right [HBM_NUM_AXI_CHANNELS] (.aclk (clk));

    // ----------------------------------------------------------------
    //  Register map block and decoder instantiations
    // ----------------------------------------------------------------
    axi4l_intf __axil_if ();
    axi4l_intf axil_to_proxy_test ();
    axi4l_intf axil_to_reg_proxy ();
    axi4l_intf axil_to_mem_proxy_4b ();
    axi4l_intf axil_to_mem_proxy_64b ();
    axi4l_intf axil_to_packet_playback ();
    axi4l_intf axil_to_packet_capture ();
    axi4l_intf axil_to_hbm_left ();
    axi4l_intf axil_to_hbm_right ();

    proxy_test_reg_intf  proxy_test_regs();

    axi4l_pipe_slr  i_axi4l_pipe_slr (
        .from_controller ( axil_if ),
        .to_peripheral   ( __axil_if )
    );

    // proxy_test register decoder
    proxy_test_decoder proxy_test_decoder (
        .axil_if                     ( __axil_if ),
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
    logic clk_100mhz;
    logic hbm_ref_clk;

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

    generate
        // Pipeline AXI3 application interfaces
        for (genvar g_ch = 0; g_ch < HBM_NUM_APP_AXI_CHANNELS__LEFT; g_ch++) begin : g__hbm_left_ch_app
            xilinx_axi3_reg_slice #(
                .ADDR_WID      ( HBM_AXI_ADDR_WID ),
                .DATA_BYTE_WID ( HBM_AXI_DATA_BYTE_WID ),
                .ID_T          ( HBM_AXI_ID_T ),
                .CONFIG        ( xilinx_axi_pkg::XILINX_AXI_REG_SLICE_FULL )
            ) i_xilinx_axi3_reg_slice__left (
                .axi3_if_from_controller ( app__axi_if__hbm_left[g_ch] ),
                .axi3_if_to_peripheral   ( axi_if__hbm_left[g_ch] )
            );
        end : g__hbm_left_ch_app
        for (genvar g_ch = 0; g_ch < HBM_NUM_APP_AXI_CHANNELS__RIGHT; g_ch++) begin : g__hbm_right_ch_app
            xilinx_axi3_reg_slice #(
                .ADDR_WID      ( HBM_AXI_ADDR_WID ),
                .DATA_BYTE_WID ( HBM_AXI_DATA_BYTE_WID ),
                .ID_T          ( HBM_AXI_ID_T ),
                .CONFIG        ( xilinx_axi_pkg::XILINX_AXI_REG_SLICE_FULL )
            ) i_xilinx_axi3_reg_slice__right (
                .axi3_if_from_controller ( app__axi_if__hbm_right[g_ch] ),
                .axi3_if_to_peripheral   ( axi_if__hbm_right[g_ch] )
            );
        end : g__hbm_right_ch_app
        // Tie off all other HBM channels
        for (genvar g_ch = HBM_NUM_APP_AXI_CHANNELS__LEFT; g_ch < HBM_NUM_AXI_CHANNELS; g_ch++) begin : g__hbm_left_ch_app_term
            axi3_intf_controller_term i_axi3_intf_controller_term (.axi3_if (axi_if__hbm_left[g_ch]));
        end : g__hbm_left_ch_app_term
        for (genvar g_ch = HBM_NUM_APP_AXI_CHANNELS__RIGHT; g_ch < HBM_NUM_AXI_CHANNELS; g_ch++) begin : g__hbm_right_ch_app_term
            axi3_intf_controller_term i_axi3_intf_controller_term (.axi3_if (axi_if__hbm_right[g_ch]));
        end : g__hbm_right_ch_app_term
    endgenerate

    // ----------------------------------------------------------------
    // Packet proxy
    // ----------------------------------------------------------------
    localparam int PACKET_DATA_BYTE_WID = 64;

    localparam int  PACKET_Q_INPUT_IFS  = 1;
    localparam int  PACKET_Q_OUTPUT_IFS = PACKET_Q_INPUT_IFS;

    localparam int  PACKET_Q_MEM_WR_IFS = 2;
    localparam int  PACKET_Q_MEM_RD_IFS = 2;

    localparam longint  PACKET_Q_CAPACITY = 2*1024**3; // 2GB
    localparam int  PACKET_Q_ADDR_WID = $clog2(PACKET_Q_CAPACITY);
    localparam int  PACKET_Q_ROW_ADDR_WID = PACKET_Q_ADDR_WID - $clog2(HBM_AXI_DATA_BYTE_WID); // Memory interface uses row addressing

    localparam int  PACKET_Q_BUFFER_SIZE = 2048;  // In bytes
    localparam longint __PACKET_Q_BUFFERS = PACKET_Q_CAPACITY / PACKET_Q_BUFFER_SIZE;
    localparam int  PACKET_Q_BUFFERS = int'(__PACKET_Q_BUFFERS);
    localparam int  PACKET_Q_BUFFER_PTR_WID = $clog2(PACKET_Q_BUFFERS);
    localparam type PACKET_Q_BUFFER_PTR_T = logic[PACKET_Q_BUFFER_PTR_WID-1:0];

    packet_intf #(.DATA_BYTE_WID(PACKET_DATA_BYTE_WID), .META_T(HBM_AXI_ID_T)) packet_if__playback [PACKET_Q_INPUT_IFS]  (.clk, .srst);
    packet_intf #(.DATA_BYTE_WID(PACKET_DATA_BYTE_WID), .META_T(HBM_AXI_ID_T)) packet_if__capture  [PACKET_Q_OUTPUT_IFS] (.clk, .srst);

    packet_descriptor_intf #(.ADDR_T(PACKET_Q_BUFFER_PTR_T), .META_T(HBM_AXI_ID_T)) packet_q_desc_in_if  [PACKET_Q_INPUT_IFS] (.clk);
    packet_descriptor_intf #(.ADDR_T(PACKET_Q_BUFFER_PTR_T), .META_T(HBM_AXI_ID_T)) packet_q_desc_out_if [PACKET_Q_OUTPUT_IFS] (.clk);

    mem_wr_intf #(.ADDR_WID(PACKET_Q_ROW_ADDR_WID), .DATA_WID(HBM_AXI_DATA_WID)) packet_q_mem_wr_if [PACKET_Q_MEM_WR_IFS] (.clk);
    mem_rd_intf #(.ADDR_WID(PACKET_Q_ROW_ADDR_WID), .DATA_WID(HBM_AXI_DATA_WID)) packet_q_mem_rd_if [PACKET_Q_MEM_RD_IFS] (.clk);

    mem_wr_intf #(.ADDR_WID(PACKET_Q_BUFFER_PTR_WID), .DATA_WID(HBM_AXI_DATA_WID)) packet_q_desc_mem_wr_if (.clk);
    mem_rd_intf #(.ADDR_WID(PACKET_Q_BUFFER_PTR_WID), .DATA_WID(HBM_AXI_DATA_WID)) packet_q_desc_mem_rd_if (.clk);

    packet_playback i_packet_playback (
        .clk,
        .srst,
        .en (),
        .axil_if ( axil_to_packet_playback ),
        .packet_if ( packet_if__playback[0] )
    );

    packet_q_core       #(
        .NUM_INPUT_IFS   ( PACKET_Q_INPUT_IFS ),
        .NUM_MEM_WR_IFS  ( PACKET_Q_MEM_WR_IFS ),
        .NUM_OUTPUT_IFS  ( PACKET_Q_OUTPUT_IFS ),
        .NUM_MEM_RD_IFS  ( PACKET_Q_MEM_RD_IFS ),
        .MAX_PKT_SIZE    ( 9200 ),
        .BUFFER_SIZE     ( PACKET_Q_BUFFER_SIZE ),
        .PTR_T           ( PACKET_Q_BUFFER_PTR_T ),
        .MAX_RD_LATENCY  ( 48 )
    ) i_packet_q_core (
        .clk,
        .srst,
        .init_done      ( ),
        .packet_in_if   ( packet_if__playback ),
        .desc_mem_wr_if ( packet_q_desc_mem_wr_if ),
        .mem_wr_if      ( packet_q_mem_wr_if ),
        .desc_in_if     ( packet_q_desc_in_if ),
        .desc_out_if    ( packet_q_desc_out_if ),
        .packet_out_if  ( packet_if__capture ),
        .desc_mem_rd_if ( packet_q_desc_mem_rd_if ),
        .mem_rd_if      ( packet_q_mem_rd_if ),
        .mem_init_done  ( 1'b1 )
    );

    packet_capture i_packet_capture (
        .clk,
        .srst,
        .en (),
        .axil_if ( axil_to_packet_capture ),
        .packet_if ( packet_if__capture[0] )
    );

    generate
        for (genvar g_if = 0; g_if < PACKET_Q_MEM_WR_IFS; g_if++) begin : g__mem_wr_if
            mem_rd_intf #(.ADDR_WID(PACKET_Q_ROW_ADDR_WID), .DATA_WID(HBM_AXI_DATA_WID)) mem_rd_if__unused (.clk);
            axi3_from_mem_adapter #(
                .SIZE ( axi3_pkg::SIZE_32BYTES ),
                .WR_TIMEOUT ( 0 ),
                .RD_TIMEOUT ( 0 )
            ) i_axi3_from_mem_adapter (
                .clk,
                .srst,
                .init_done (),
                .mem_wr_if ( packet_q_mem_wr_if [g_if] ),
                .mem_rd_if ( mem_rd_if__unused ),
                .axi3_if   ( app__axi_if__hbm_left[g_if] )
            );
            mem_rd_intf_controller_term i_mem_rd_intf_controller_term (.to_peripheral(mem_rd_if__unused));
        end : g__mem_wr_if
        for (genvar g_if = 0; g_if < PACKET_Q_MEM_RD_IFS; g_if++) begin : g__mem_rd_if
            mem_wr_intf #(.ADDR_WID(PACKET_Q_ROW_ADDR_WID), .DATA_WID(HBM_AXI_DATA_WID)) mem_wr_if__unused (.clk);
            axi3_from_mem_adapter #(
                .SIZE ( axi3_pkg::SIZE_32BYTES ),
                .WR_TIMEOUT ( 0 ),
                .RD_TIMEOUT ( 0 )
            ) i_axi3_from_mem_adapter (
                .clk,
                .srst,
                .init_done (),
                .mem_wr_if ( mem_wr_if__unused ),
                .mem_rd_if ( packet_q_mem_rd_if [g_if] ),
                .axi3_if   ( app__axi_if__hbm_left[PACKET_Q_MEM_WR_IFS+g_if] )
            );
            mem_wr_intf_controller_term i_mem_wr_intf_controller_term (.to_peripheral(mem_wr_if__unused));
        end : g__mem_rd_if
        for (genvar g_if = 0; g_if < PACKET_Q_INPUT_IFS; g_if++) begin : g__if
            packet_descriptor_fifo i_packet_descriptor_fifo (
                .from_tx ( packet_q_desc_in_if[g_if] ),
                .to_rx   ( packet_q_desc_out_if[g_if] )
            );
        end : g__if
    endgenerate

    // Connect descriptor wr/rd interface
    axi3_from_mem_adapter #(
        .SIZE ( axi3_pkg::SIZE_32BYTES ),
        .WR_TIMEOUT ( 0 ),
        .RD_TIMEOUT ( 0 ),
        .BASE_ADDR  ( PACKET_Q_CAPACITY )
    ) i_axi3_from_mem_adapter (
        .clk,
        .srst,
        .init_done (),
        .mem_wr_if ( packet_q_desc_mem_wr_if ),
        .mem_rd_if ( packet_q_desc_mem_rd_if ),
        .axi3_if   ( app__axi_if__hbm_left[PACKET_Q_MEM_WR_IFS+PACKET_Q_MEM_RD_IFS] )
    );

    // Terminate app AXI3 interface to HBM stack 1 (right)
    axi3_intf_controller_term i_axi3_intf_controller_term (.axi3_if (app__axi_if__hbm_right[0]));

    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            // Connect AXI-S interfaces in pass-through
            axi4s_full_pipe axi4s_full_pipe_0 (.axi4s_if_from_tx(axi4s_in[g_port]), .axi4s_if_to_rx(axi4s_out[g_port]));
            // Tie off C2H interface
            axi4s_intf_tx_term axi4s_intf_tx_term_0 (.aclk(clk), .aresetn(~srst), .axi4s_if(axi4s_c2h[g_port]));
        end
    endgenerate

endmodule: proxy_test
