module proxy_test
    import smartnic_pkg::*;
(
    input logic        clk,
    input logic        srst,
    input timestamp_t  timestamp,

    axi4l_intf.peripheral axil_if,
    axi4l_intf.peripheral axil_to_vitisnetp4,

    axi4s_intf.tx axis_to_switch_0,
    axi4s_intf.rx axis_from_switch_0,
    axi4s_intf.tx axis_to_switch_1,
    axi4s_intf.rx axis_from_switch_1
);

    // ----------------------------------------------------------------
    //  Imports
    // ----------------------------------------------------------------
    import proxy_test_pkg::*;

    // ----------------------------------------------------------------
    //  Register map block and decoder instantiations
    // ----------------------------------------------------------------

    axi4l_intf axil_to_proxy_test ();
    axi4l_intf axil_to_reg_proxy ();
    axi4l_intf axil_to_mem_proxy_4b ();
    axi4l_intf axil_to_mem_proxy_64b ();

    proxy_test_reg_intf  proxy_test_regs();

    // proxy_test register decoder
    proxy_test_decoder proxy_test_decoder (
        .axil_if               ( axil_if ),					
        .proxy_test_axil_if    ( axil_to_proxy_test ),
        .reg_proxy_axil_if     ( axil_to_reg_proxy ),
        .mem_proxy_4b_axil_if  ( axil_to_mem_proxy_4b ),
        .mem_proxy_64b_axil_if ( axil_to_mem_proxy_64b )
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
    //  Datpath pass-through connections (hard-wired bypass)
    // ----------------------------------------------------------------
    assign axis_to_switch_1.aclk    = axis_from_switch_1.aclk;
    assign axis_to_switch_1.aresetn = axis_from_switch_1.aresetn;
    assign axis_to_switch_1.tvalid  = axis_from_switch_1.tvalid;
    assign axis_to_switch_1.tdata   = axis_from_switch_1.tdata;
    assign axis_to_switch_1.tkeep   = axis_from_switch_1.tkeep;
    assign axis_to_switch_1.tlast   = axis_from_switch_1.tlast;
    assign axis_to_switch_1.tid     = axis_from_switch_1.tid;
    assign axis_to_switch_1.tdest   = {'0, axis_from_switch_1.tdest};
    assign axis_to_switch_1.tuser   = axis_from_switch_1.tuser;

    assign axis_from_switch_1.tready = axis_to_switch_1.tready;

    // ----------------------------------------------------------------
    // VitisNetP4
    // ----------------------------------------------------------------
    tuser_smartnic_meta_t  axis_from_switch_0_tuser;
    assign axis_from_switch_0_tuser = axis_from_switch_0.tuser;

    tuser_smartnic_meta_t  axis_to_switch_0_tuser;
    assign axis_to_switch_0.tuser = axis_to_switch_0_tuser;

    // --- metadata_in ---
    user_metadata_t user_metadata_in;
    logic           user_metadata_in_valid;

    always_comb begin
        user_metadata_in.timestamp_ns      = timestamp;
        user_metadata_in.pid               = axis_from_switch_0_tuser.pid;
        user_metadata_in.ingress_port      = {'0, axis_from_switch_0.tid};
        user_metadata_in.egress_port       = {'0, axis_from_switch_0.tid};
        user_metadata_in.truncate_enable   = 0;
        user_metadata_in.truncate_length   = 0;
        user_metadata_in.rss_enable        = 0;
        user_metadata_in.rss_entropy       = 0;
        user_metadata_in.drop_reason       = 0;
        user_metadata_in.scratch           = 0;

        user_metadata_in_valid = axis_from_switch_0.tvalid && axis_from_switch_0.sop;
    end

    // --- metadata_out ---
    user_metadata_t user_metadata_out, user_metadata_out_latch;
    logic           user_metadata_out_valid;

    always @(posedge clk) if (user_metadata_out_valid) user_metadata_out_latch <= user_metadata_out;

    assign axis_to_switch_0.tdest = user_metadata_out_valid ?
                                    user_metadata_out.egress_port : user_metadata_out_latch.egress_port;

    assign axis_to_switch_0_tuser.pid         = user_metadata_out_valid ?
                                                user_metadata_out.pid[15:0] : user_metadata_out_latch.pid[15:0];

    assign axis_to_switch_0_tuser.trunc_enable = user_metadata_out_valid ?
                                                 user_metadata_out.truncate_enable : user_metadata_out_latch.truncate_enable;

    assign axis_to_switch_0_tuser.trunc_length = user_metadata_out_valid ?
                                                 user_metadata_out.truncate_length : user_metadata_out_latch.truncate_length;

    assign axis_to_switch_0_tuser.rss_enable  = user_metadata_out_valid ?
                                                user_metadata_out.rss_enable  : user_metadata_out_latch.rss_enable;

    assign axis_to_switch_0_tuser.rss_entropy = user_metadata_out_valid ?
                                                user_metadata_out.rss_entropy : user_metadata_out_latch.rss_entropy;


    // --- vitisnetp4_igr instance (proxy_test) ---
    vitisnetp4_igr vitisnetp4_igr_proxy_test
    (
        // Clocks & Resets
        .s_axis_aclk             (clk),
        .s_axis_aresetn          (!srst),
        .s_axi_aclk              (axil_to_vitisnetp4.aclk),
        .s_axi_aresetn           (axil_to_vitisnetp4.aresetn),
        .cam_mem_aclk            (clk),
        .cam_mem_aresetn         (!srst),

        // Metadata
        .user_metadata_in        (user_metadata_in),
        .user_metadata_in_valid  (user_metadata_in_valid),
        .user_metadata_out       (user_metadata_out),
        .user_metadata_out_valid (user_metadata_out_valid),

        // Slave AXI-lite interface
        .s_axi_awaddr  (axil_to_vitisnetp4.awaddr),
        .s_axi_awvalid (axil_to_vitisnetp4.awvalid),
        .s_axi_awready (axil_to_vitisnetp4.awready),
        .s_axi_wdata   (axil_to_vitisnetp4.wdata),
        .s_axi_wstrb   (axil_to_vitisnetp4.wstrb),
        .s_axi_wvalid  (axil_to_vitisnetp4.wvalid),
        .s_axi_wready  (axil_to_vitisnetp4.wready),
        .s_axi_bresp   (axil_to_vitisnetp4.bresp),
        .s_axi_bvalid  (axil_to_vitisnetp4.bvalid),
        .s_axi_bready  (axil_to_vitisnetp4.bready),
        .s_axi_araddr  (axil_to_vitisnetp4.araddr),
        .s_axi_arvalid (axil_to_vitisnetp4.arvalid),
        .s_axi_arready (axil_to_vitisnetp4.arready),
        .s_axi_rdata   (axil_to_vitisnetp4.rdata),
        .s_axi_rvalid  (axil_to_vitisnetp4.rvalid),
        .s_axi_rready  (axil_to_vitisnetp4.rready),
        .s_axi_rresp   (axil_to_vitisnetp4.rresp),

        // AXI Master port
        .m_axis_tdata  (axis_to_switch_0.tdata),
        .m_axis_tkeep  (axis_to_switch_0.tkeep),
        .m_axis_tvalid (axis_to_switch_0.tvalid),
        .m_axis_tlast  (axis_to_switch_0.tlast),
        .m_axis_tready (axis_to_switch_0.tready),

        // AXI Slave port
        .s_axis_tdata  (axis_from_switch_0.tdata),
        .s_axis_tkeep  (axis_from_switch_0.tkeep),
        .s_axis_tvalid (axis_from_switch_0.tvalid),
        .s_axis_tlast  (axis_from_switch_0.tlast),
        .s_axis_tready (axis_from_switch_0.tready)
    );

    assign axis_to_switch_0.aclk = clk;
    assign axis_to_switch_0.aresetn = !srst;

endmodule: proxy_test
