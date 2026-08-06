module sar_test
#(
    parameter int NUM_PORTS = 2
) (
    input  logic      clk,
    input  logic      srst,

    axi4s_intf.rx     axi4s_in  [NUM_PORTS],
    axi4s_intf.tx     axi4s_out [NUM_PORTS],
    axi4s_intf.tx     axi4s_c2h [NUM_PORTS],

    axi4l_intf.peripheral axil_if
);
    // ----------------------------------------------------------------
    //  HBM parameters
    // ----------------------------------------------------------------
    localparam int HBM_NUM_AXI_CHANNELS = xilinx_hbm_pkg::PSEUDO_CHANNELS_PER_STACK;
    localparam int HBM_NUM_APP_AXI_CHANNELS = 2; // ch0: reassembly, ch1: segmentation

    localparam xilinx_hbm_pkg::density_t HBM_DENSITY = xilinx_hbm_pkg::DENSITY_4G;
    localparam int HBM_AXI_DATA_BYTE_WID = xilinx_hbm_pkg::AXI_DATA_BYTE_WID;
    localparam int HBM_AXI_DATA_WID      = xilinx_hbm_pkg::AXI_DATA_WID;
    localparam int HBM_AXI_ADDR_WID      = xilinx_hbm_pkg::get_addr_wid(HBM_DENSITY);
    localparam int HBM_AXI_ID_WID        = xilinx_hbm_pkg::AXI_ID_WID;

    // ----------------------------------------------------------------
    //  SAR parameters
    // ----------------------------------------------------------------
    localparam int SAR_NUM_FRAME_BUFFERS = 4;
    localparam int SAR_MAX_FRAME_SIZE    = 65536;  // 64 KB per frame buffer
    localparam int SAR_MAX_PKT_SIZE      = 9216;   // jumbo packet
    localparam int SAR_TIMER_WID         = 8;
    localparam int SAR_MAX_FRAGMENTS     = 64;
    localparam int SAR_BURST_SIZE        = 8;
    localparam int SAR_MAX_RD_LATENCY    = 48;

    localparam int PACKET_DATA_BYTE_WID  = HBM_AXI_DATA_BYTE_WID; // 32 bytes = 256 bits
    localparam int PACKET_DATA_WID       = PACKET_DATA_BYTE_WID * 8;

    // SAR derived parameters
    localparam int SAR_BUF_ID_WID    = SAR_NUM_FRAME_BUFFERS > 1 ? $clog2(SAR_NUM_FRAME_BUFFERS) : 1;
    localparam int SAR_OFFSET_WID    = $clog2(SAR_MAX_FRAME_SIZE);
    localparam int SAR_FRAME_SIZE_WID = $clog2(SAR_MAX_FRAME_SIZE + 1);

    // Meta carried in packet_intf: {buf_id, offset, last}
    localparam int PLAYBACK_META_WID = SAR_BUF_ID_WID + SAR_OFFSET_WID + 1;

    // HBM memory address width (row-addressed: total_bytes / data_byte_wid)
    localparam longint HBM_CH_CAPACITY  = xilinx_hbm_pkg::get_ps_capacity(HBM_DENSITY);
    localparam int HBM_CH_ADDR_WID      = $clog2(HBM_CH_CAPACITY);
    localparam int SAR_MEM_ADDR_WID     = $clog2(SAR_NUM_FRAME_BUFFERS * SAR_MAX_FRAME_SIZE / PACKET_DATA_BYTE_WID);

    // ----------------------------------------------------------------
    //  AXI3 interfaces to HBM
    // ----------------------------------------------------------------
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_WID(HBM_AXI_ID_WID)) app__axi_if__hbm [HBM_NUM_APP_AXI_CHANNELS] (.aclk(clk));
    axi3_intf #(.DATA_BYTE_WID(HBM_AXI_DATA_BYTE_WID), .ADDR_WID(HBM_AXI_ADDR_WID), .ID_WID(HBM_AXI_ID_WID)) axi_if__hbm     [HBM_NUM_AXI_CHANNELS]     (.aclk(clk));

    // ----------------------------------------------------------------
    //  AXI-L decode
    // ----------------------------------------------------------------
    axi4l_intf __axil_if ();
    axi4l_intf axil_to_sar_test ();
    axi4l_intf axil_to_reassembly_playback ();
    axi4l_intf axil_to_reassembly_mem_proxy ();
    axi4l_intf axil_to_reassembly ();
    axi4l_intf axil_to_segmentation ();
    axi4l_intf axil_to_segmentation_mem_proxy ();
    axi4l_intf axil_to_segmentation_capture ();
    axi4l_intf axil_to_segmentation_ctrl ();
    axi4l_intf axil_to_hbm ();

    axi4l_pipe_slr i_axi4l_pipe_slr (
        .from_controller ( axil_if    ),
        .to_peripheral   ( __axil_if  )
    );

    sar_test_decoder i_sar_test_decoder (
        .axil_if                        ( __axil_if                  ),
        .sar_test_axil_if               ( axil_to_sar_test           ),
        .reassembly_playback_axil_if    ( axil_to_reassembly_playback ),
        .reassembly_mem_proxy_axil_if   ( axil_to_reassembly_mem_proxy ),
        .reassembly_axil_if             ( axil_to_reassembly          ),
        .segmentation_axil_if           ( axil_to_segmentation        ),
        .segmentation_mem_proxy_axil_if ( axil_to_segmentation_mem_proxy ),
        .segmentation_capture_axil_if   ( axil_to_segmentation_capture ),
        .segmentation_ctrl_axil_if      ( axil_to_segmentation_ctrl   ),
        .hbm_axil_if                    ( axil_to_hbm                 )
    );

    // Base register block (id, scratchpad)
    sar_test_reg_intf sar_test_regs ();

    sar_test_reg_blk i_sar_test_reg_blk (
        .axil_if    ( axil_to_sar_test ),
        .reg_blk_if ( sar_test_regs   )
    );

    // ----------------------------------------------------------------
    //  HBM clock generation
    // ----------------------------------------------------------------
    logic clk_100mhz;
    logic hbm_ref_clk;

    sar_test_clk_wiz i_sar_test_clk_wiz (
        .clk_in1    ( axil_if.aclk ),
        .clk_100mhz ( clk_100mhz   ),
        .hbm_ref_clk( hbm_ref_clk  )
    );

    // ----------------------------------------------------------------
    //  HBM stack (LEFT only)
    // ----------------------------------------------------------------
    xilinx_hbm_stack #(
        .STACK   ( xilinx_hbm_pkg::STACK_RIGHT ),
        .DENSITY ( HBM_DENSITY )
    ) i_xilinx_hbm_stack (
        .clk,
        .srst,
        .hbm_ref_clk ( hbm_ref_clk ),
        .clk_100mhz  ( clk_100mhz  ),
        .axil_if     ( axil_to_hbm ),
        .axi_if      ( axi_if__hbm ),
        .init_done   ( )
    );

    logic hbm_init_done;
    assign hbm_init_done = 1'b1; // use mem_init_done=1 for now; tie when HBM is ready

    generate
        for (genvar g_ch = 0; g_ch < HBM_NUM_APP_AXI_CHANNELS; g_ch++) begin : g__hbm_app_ch
            axi3_pipe i_axi3_pipe (
                .srst,
                .from_controller ( app__axi_if__hbm[g_ch] ),
                .to_peripheral   ( axi_if__hbm[g_ch]       )
            );
        end : g__hbm_app_ch
        for (genvar g_ch = HBM_NUM_APP_AXI_CHANNELS; g_ch < HBM_NUM_AXI_CHANNELS; g_ch++) begin : g__hbm_term
            axi3_intf_controller_term i_axi3_term (.to_peripheral(axi_if__hbm[g_ch]));
        end : g__hbm_term
    endgenerate

    // ----------------------------------------------------------------
    //  Millisecond tick (for reassembly timeout)
    // ----------------------------------------------------------------
    logic ms_tick;

    // AXI-L clock (125 MHz); 125,000 cycles per millisecond
    timer_tick #(
        .TCLK_PER_TICK ( 125_000 ),
        .TCLK_DDR      ( 0       )
    ) i_timer_tick (
        .clk    ( clk     ),
        .srst   ( srst    ),
        .squelch( 1'b0    ),
        .tclk   ( clk     ),
        .tick   ( ms_tick )
    );

    // ================================================================
    //  REASSEMBLY PATH (HBM channel 0)
    //  packet_playback -> sar_packet_reassembly -> HBM[0]
    //  mem_proxy -> HBM[0] (read-back)
    // ================================================================

    // --- packet_playback ---
    axi4l_intf axil_to_reassembly_playback__clk ();

    axi4l_intf_cdc i_axil_cdc__reasm_playback (
        .axi4l_if_from_controller ( axil_to_reassembly_playback      ),
        .clk_to_peripheral        ( clk                              ),
        .axi4l_if_to_peripheral   ( axil_to_reassembly_playback__clk )
    );

    packet_intf #(.DATA_BYTE_WID(PACKET_DATA_BYTE_WID), .META_WID(PLAYBACK_META_WID)) packet_if__playback (.clk);

    packet_playback #(
        .PACKET_MEM_SIZE ( SAR_MAX_FRAME_SIZE )
    ) i_packet_playback (
        .clk,
        .srst,
        .en      (),
        .axil_if ( axil_to_reassembly_playback__clk ),
        .packet_if ( packet_if__playback )
    );

    // Unpack meta into SAR sideband: meta[PLAYBACK_META_WID-1:0] = {buf_id, offset, last}
    logic [SAR_BUF_ID_WID-1:0] reasm_packet_buf_id;
    logic [SAR_OFFSET_WID-1:0] reasm_packet_offset;
    logic                       reasm_packet_last;

    assign {reasm_packet_buf_id, reasm_packet_offset, reasm_packet_last} = packet_if__playback.meta;

    // --- sar_packet_reassembly ---
    mem_wr_intf #(.ADDR_WID(SAR_MEM_ADDR_WID), .DATA_WID(PACKET_DATA_WID)) reasm_mem_wr_if (.clk);

    axi4l_intf axil_to_reassembly__clk ();

    axi4l_intf_cdc i_axil_cdc__reasm (
        .axi4l_if_from_controller ( axil_to_reassembly      ),
        .clk_to_peripheral        ( clk                     ),
        .axi4l_if_to_peripheral   ( axil_to_reassembly__clk )
    );

    logic reasm_frame_valid;
    logic reasm_frame_ready;
    logic [SAR_BUF_ID_WID-1:0]    reasm_frame_buf_id;
    logic [SAR_FRAME_SIZE_WID-1:0] reasm_frame_len;

    sar_packet_reassembly #(
        .NUM_FRAME_BUFFERS ( SAR_NUM_FRAME_BUFFERS ),
        .MAX_FRAME_SIZE    ( SAR_MAX_FRAME_SIZE    ),
        .MAX_PKT_SIZE      ( SAR_MAX_PKT_SIZE      ),
        .TIMER_WID         ( SAR_TIMER_WID         ),
        .MAX_FRAGMENTS     ( SAR_MAX_FRAGMENTS     ),
        .BURST_SIZE        ( SAR_BURST_SIZE        )
    ) i_sar_packet_reassembly (
        .clk,
        .srst,
        .init_done     (),
        .packet_buf_id ( reasm_packet_buf_id  ),
        .packet_offset ( reasm_packet_offset  ),
        .packet_last   ( reasm_packet_last    ),
        .packet_if     ( packet_if__playback  ),
        .axil_if       ( axil_to_reassembly__clk ),
        .ms_tick       ( ms_tick             ),
        .frame_ready   ( reasm_frame_ready   ),
        .frame_valid   ( reasm_frame_valid   ),
        .frame_buf_id  ( reasm_frame_buf_id  ),
        .frame_len     ( reasm_frame_len     ),
        .mem_wr_if     ( reasm_mem_wr_if     ),
        .mem_init_done ( hbm_init_done       )
    );

    // Frame completion handshake: always ready (frames are written to HBM, no back-pressure needed here)
    assign reasm_frame_ready = 1'b1;

    // --- mem_proxy for reassembly read-back (ACCESS_READ_ONLY) ---
    axi4l_intf axil_to_reassembly_mem_proxy__clk ();

    axi4l_intf_cdc i_axil_cdc__reasm_proxy (
        .axi4l_if_from_controller ( axil_to_reassembly_mem_proxy      ),
        .clk_to_peripheral        ( clk                               ),
        .axi4l_if_to_peripheral   ( axil_to_reassembly_mem_proxy__clk )
    );

    mem_intf #(.ADDR_WID(SAR_MEM_ADDR_WID), .DATA_WID(PACKET_DATA_WID)) reasm_proxy_mem_if (.clk);
    mem_wr_intf #(.ADDR_WID(SAR_MEM_ADDR_WID), .DATA_WID(PACKET_DATA_WID)) reasm_proxy_mem_wr_if (.clk);
    mem_rd_intf #(.ADDR_WID(SAR_MEM_ADDR_WID), .DATA_WID(PACKET_DATA_WID)) reasm_proxy_mem_rd_if (.clk);

    mem_proxy #(
        .ACCESS_TYPE   ( mem_pkg::ACCESS_READ_ONLY ),
        .MEM_TYPE      ( mem_pkg::MEM_TYPE_HBM     ),
        .BIGENDIAN     ( 1                          )
    ) i_mem_proxy__reassembly (
        .clk,
        .srst,
        .init_done (),
        .axil_if   ( axil_to_reassembly_mem_proxy__clk ),
        .mem_if    ( reasm_proxy_mem_if                 )
    );

    // Split mem_intf into mem_wr_intf + mem_rd_intf
    mem_sp_to_sdp_adapter i_mem_sp_to_sdp__reasm_proxy (
        .mem_if    ( reasm_proxy_mem_if     ),
        .mem_wr_if ( reasm_proxy_mem_wr_if  ),
        .mem_rd_if ( reasm_proxy_mem_rd_if  )
    );

    // Tie off the write side (proxy is read-only)
    mem_wr_intf_peripheral_term i_mem_wr_term__reasm_proxy (.from_controller(reasm_proxy_mem_wr_if));

    // --- axi3_from_mem_adapter for HBM channel 0 ---
    // SAR writes; proxy reads
    axi3_from_mem_adapter #(
        .SIZE ( axi3_pkg::SIZE_32BYTES )
    ) i_axi3_from_mem_adapter__reasm (
        .clk,
        .srst,
        .init_done       (),
        .mem_wr_if       ( reasm_mem_wr_if       ),
        .mem_rd_if       ( reasm_proxy_mem_rd_if  ),
        .axi3_if         ( app__axi_if__hbm[0]   ),
        .wr_data_oflow   (),
        .wr_data_pending (),
        .wr_burst_oflow  (),
        .wr_burst_pending(),
        .rd_burst_oflow  (),
        .rd_burst_pending()
    );

    // ================================================================
    //  SEGMENTATION PATH (HBM channel 1)
    //  mem_proxy -> HBM[1] (write frame data)
    //  sar_packet_segmentation -> HBM[1] -> packet_capture
    // ================================================================

    // --- mem_proxy for segmentation frame write ---
    axi4l_intf axil_to_segmentation_mem_proxy__clk ();

    axi4l_intf_cdc i_axil_cdc__seg_proxy (
        .axi4l_if_from_controller ( axil_to_segmentation_mem_proxy      ),
        .clk_to_peripheral        ( clk                                  ),
        .axi4l_if_to_peripheral   ( axil_to_segmentation_mem_proxy__clk  )
    );

    mem_intf #(.ADDR_WID(SAR_MEM_ADDR_WID), .DATA_WID(PACKET_DATA_WID)) seg_proxy_mem_if (.clk);
    mem_wr_intf #(.ADDR_WID(SAR_MEM_ADDR_WID), .DATA_WID(PACKET_DATA_WID)) seg_proxy_mem_wr_if (.clk);
    mem_rd_intf #(.ADDR_WID(SAR_MEM_ADDR_WID), .DATA_WID(PACKET_DATA_WID)) seg_proxy_mem_rd_if (.clk);

    mem_proxy #(
        .ACCESS_TYPE   ( mem_pkg::ACCESS_READ_WRITE ),
        .MEM_TYPE      ( mem_pkg::MEM_TYPE_HBM      ),
        .BIGENDIAN     ( 1                           )
    ) i_mem_proxy__segmentation (
        .clk,
        .srst,
        .init_done (),
        .axil_if   ( axil_to_segmentation_mem_proxy__clk ),
        .mem_if    ( seg_proxy_mem_if                     )
    );

    // Split mem_intf into mem_wr_intf + mem_rd_intf
    mem_sp_to_sdp_adapter i_mem_sp_to_sdp__seg_proxy (
        .mem_if    ( seg_proxy_mem_if    ),
        .mem_wr_if ( seg_proxy_mem_wr_if ),
        .mem_rd_if ( seg_proxy_mem_rd_if )
    );

    // Tie off the read side (software writes frames, not reads)
    mem_rd_intf_peripheral_term i_mem_rd_term__seg_proxy (.from_controller(seg_proxy_mem_rd_if));

    // --- Segmentation frame control registers ---
    axi4l_intf axil_to_segmentation_ctrl__clk ();

    axi4l_intf_cdc i_axil_cdc__seg_ctrl (
        .axi4l_if_from_controller ( axil_to_segmentation_ctrl      ),
        .clk_to_peripheral        ( clk                            ),
        .axi4l_if_to_peripheral   ( axil_to_segmentation_ctrl__clk )
    );

    sar_test_seg_ctrl_reg_intf seg_ctrl_regs ();

    sar_test_seg_ctrl_reg_blk i_seg_ctrl_reg_blk (
        .axil_if    ( axil_to_segmentation_ctrl__clk ),
        .reg_blk_if ( seg_ctrl_regs                  )
    );

    // FSM to drive sar_packet_segmentation frame handshake
    logic seg_frame_valid;
    logic seg_frame_ready;
    logic [SAR_BUF_ID_WID-1:0]    seg_frame_buf_id;
    logic [SAR_FRAME_SIZE_WID-1:0] seg_frame_len;

    typedef enum logic [1:0] {
        SEG_CTRL_IDLE,
        SEG_CTRL_ACTIVE,
        SEG_CTRL_DONE
    } seg_ctrl_state_t;

    seg_ctrl_state_t seg_ctrl_state;

    sar_test_seg_ctrl_reg_pkg::reg_status_t seg_status;

    always_ff @(posedge clk) begin
        if (srst) begin
            seg_ctrl_state  <= SEG_CTRL_IDLE;
            seg_frame_valid <= 1'b0;
            seg_frame_buf_id <= '0;
            seg_frame_len   <= '0;
            seg_status      <= '0;
        end else begin
            case (seg_ctrl_state)
                SEG_CTRL_IDLE: begin
                    if (seg_ctrl_regs.trigger_wr_evt) begin
                        seg_frame_valid  <= 1'b1;
                        seg_frame_buf_id <= SAR_BUF_ID_WID'(seg_ctrl_regs.frame_buf_id);
                        seg_frame_len    <= SAR_FRAME_SIZE_WID'(seg_ctrl_regs.frame_len);
                        seg_status.busy  <= 1'b1;
                        seg_status.done  <= 1'b0;
                        seg_ctrl_state   <= SEG_CTRL_ACTIVE;
                    end
                end
                SEG_CTRL_ACTIVE: begin
                    if (seg_frame_valid && seg_frame_ready) begin
                        seg_frame_valid <= 1'b0;
                        seg_ctrl_state  <= SEG_CTRL_DONE;
                    end
                end
                SEG_CTRL_DONE: begin
                    seg_status.busy <= 1'b0;
                    seg_status.done <= 1'b1;
                    seg_ctrl_state  <= SEG_CTRL_IDLE;
                end
                default: seg_ctrl_state <= SEG_CTRL_IDLE;
            endcase
        end
    end

    assign seg_ctrl_regs.status_nxt_v = 1'b1;
    assign seg_ctrl_regs.status_nxt   = seg_status;

    // --- sar_packet_segmentation ---
    mem_rd_intf #(.ADDR_WID(SAR_MEM_ADDR_WID), .DATA_WID(PACKET_DATA_WID)) seg_mem_rd_if (.clk);

    axi4l_intf axil_to_segmentation__clk ();

    axi4l_intf_cdc i_axil_cdc__seg (
        .axi4l_if_from_controller ( axil_to_segmentation      ),
        .clk_to_peripheral        ( clk                       ),
        .axi4l_if_to_peripheral   ( axil_to_segmentation__clk )
    );

    packet_intf #(.DATA_BYTE_WID(PACKET_DATA_BYTE_WID), .META_WID(1)) packet_if__capture (.clk);

    sar_packet_segmentation #(
        .NUM_FRAME_BUFFERS ( SAR_NUM_FRAME_BUFFERS ),
        .MAX_FRAME_SIZE    ( SAR_MAX_FRAME_SIZE    ),
        .MAX_PKT_SIZE      ( SAR_MAX_PKT_SIZE      ),
        .MAX_RD_LATENCY    ( SAR_MAX_RD_LATENCY    )
    ) i_sar_packet_segmentation (
        .clk,
        .srst,
        .init_done    (),
        .packet_buf_id(),
        .packet_offset(),
        .packet_size  (),
        .packet_last  (),
        .packet_if    ( packet_if__capture  ),
        .axil_if      ( axil_to_segmentation__clk ),
        .frame_valid  ( seg_frame_valid     ),
        .frame_ready  ( seg_frame_ready     ),
        .frame_buf_id ( seg_frame_buf_id    ),
        .frame_len    ( seg_frame_len       ),
        .mem_rd_if    ( seg_mem_rd_if       ),
        .mem_init_done( hbm_init_done       )
    );

    // --- axi3_from_mem_adapter for HBM channel 1 ---
    // proxy writes; SAR reads
    axi3_from_mem_adapter #(
        .SIZE ( axi3_pkg::SIZE_32BYTES )
    ) i_axi3_from_mem_adapter__seg (
        .clk,
        .srst,
        .init_done       (),
        .mem_wr_if       ( seg_proxy_mem_wr_if  ),
        .mem_rd_if       ( seg_mem_rd_if         ),
        .axi3_if         ( app__axi_if__hbm[1]  ),
        .wr_data_oflow   (),
        .wr_data_pending (),
        .wr_burst_oflow  (),
        .wr_burst_pending(),
        .rd_burst_oflow  (),
        .rd_burst_pending()
    );

    // --- packet_capture ---
    axi4l_intf axil_to_segmentation_capture__clk ();

    axi4l_intf_cdc i_axil_cdc__seg_capture (
        .axi4l_if_from_controller ( axil_to_segmentation_capture      ),
        .clk_to_peripheral        ( clk                               ),
        .axi4l_if_to_peripheral   ( axil_to_segmentation_capture__clk )
    );

    packet_capture #(
        .PACKET_MEM_SIZE ( SAR_MAX_FRAME_SIZE )
    ) i_packet_capture (
        .clk,
        .srst,
        .en      (),
        .axil_if ( axil_to_segmentation_capture__clk ),
        .packet_if ( packet_if__capture )
    );

    // ================================================================
    //  AXI-S pass-through (unused datapath)
    // ================================================================
    generate
        for (genvar g_port = 0; g_port < NUM_PORTS; g_port++) begin : g__port
            axi4s_full_pipe axi4s_full_pipe_0 (.srst, .from_tx(axi4s_in[g_port]), .to_rx(axi4s_out[g_port]));
            axi4s_intf_tx_term axi4s_intf_tx_term_0 (.to_rx(axi4s_c2h[g_port]));
        end
    endgenerate

endmodule : sar_test
