module p4_proc
    import p4_proc_pkg::*;
#(
    parameter int   N = 2,                // Number of processor ports.
    parameter bit   EXTERN_PORTS = 0,     // 1: Connects extern ports to wrapper, 0: Ties off extern ports
    parameter type  USER_EXTERN_OUT_T   = bit,
    parameter type  USER_EXTERN_IN_T    = bit,
    parameter type  USER_EXTERN_VALID_T = bit
) (
    input logic        core_clk,
    input logic        core_rstn,
    input timestamp_t  timestamp,

    output USER_EXTERN_OUT_T    user_extern_out,
    output USER_EXTERN_VALID_T  user_extern_out_valid,
    input  USER_EXTERN_IN_T     user_extern_in,
    input  USER_EXTERN_VALID_T  user_extern_in_valid,

    axi4l_intf.peripheral axil_if,
    axi4l_intf.peripheral axil_to_sdnet,

    axi4s_intf.tx axis_to_switch[N],
    axi4s_intf.rx axis_from_switch[N],

    axi3_intf.controller  axi_to_hbm[16]
);
    import axi4s_pkg::*;
    import arb_pkg::*;

    // -------------------------------------------------
    // Parameter checking
    // -------------------------------------------------
    initial std_pkg::param_check_gt(N, 1, "N");
    initial std_pkg::param_check_lt(N, 2, "N");

    // ----------------------------------------------------------------------
    //  axil register map. axil intf, regio block and decoder instantiations.
    // ----------------------------------------------------------------------
    axi4l_intf  axil_to_p4_proc ();
    axi4l_intf  axil_to_p4_proc__core_clk ();

    axi4l_intf  axil_to_drops[2] ();
    axi4l_intf  axil_to_split_join[2] ();

    p4_proc_reg_intf  p4_proc_regs[2] ();

    // p4_proc register decoder
    p4_proc_decoder p4_proc_decoder (
        .axil_if          (axil_if),
        .p4_proc_axil_if  (axil_to_p4_proc),
        .drops_from_proc_port_0_axil_if (axil_to_drops[0]),
        .drops_from_proc_port_1_axil_if (axil_to_drops[1]),
        .axi4s_split_join_0_axil_if     (axil_to_split_join[0])
    );

    axi4l_intf_controller_term axi4l_to_split_join_1_term (.axi4l_if(axil_to_split_join[1]));
   
    // Pass AXI-L interface from aclk (AXI-L clock) to core clk domain
    axi4l_intf_cdc i_axil_intf_cdc (
        .axi4l_if_from_controller   (axil_to_p4_proc),
        .clk_to_peripheral          (core_clk),
        .axi4l_if_to_peripheral     (axil_to_p4_proc__core_clk)
    );

    // p4_proc register block
    p4_proc_reg_blk p4_proc_reg_blk (
        .axil_if    (axil_to_p4_proc__core_clk),
        .reg_blk_if (p4_proc_regs[0])
    );

    // p4_proc register pipeline stages
    always @(posedge core_clk) begin
        p4_proc_regs[1].p4_proc_config <= p4_proc_regs[0].p4_proc_config;
        p4_proc_regs[1].trunc_config   <= p4_proc_regs[0].trunc_config;
        p4_proc_regs[1].rss_config     <= p4_proc_regs[0].rss_config;
    end


    // ----------------------------------------------------------------
    //  local signals and axi4s intf instantiations.
    // ----------------------------------------------------------------
    logic zero_length[N];
    logic loop_detect[N];
    logic drop_pkt[N];

    logic axis_from_sdnet_proc_port;

    logic [15:0] trunc_length[N];

    tuser_smartnic_meta_t  _axis_from_switch_tuser[N];
    tuser_smartnic_meta_t  _axis_from_split_join_tuser[N];
    tuser_smartnic_meta_t  axis_to_sdnet_tuser;
    tuser_smartnic_meta_t  axis_from_sdnet_tuser;

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))   _axis_from_switch[N] ();

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))   _axis_from_split_join[N] ();

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))   axis_from_split_join[N] ();

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))        _axis_to_sdnet ();

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))        axis_to_sdnet ();

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))   axis_from_sdnet ();

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))   axis_to_split_join[N] ();

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))   axis_to_drop[N] ();

    axi4s_intf  #( .TUSER_T(tuser_smartnic_meta_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(egr_tdest_t))   axis_to_trunc[N] ();


    // --------------------------------------------------------------------
    //  per port functionality.  pkt split-join, drop and truncation logic.
    // --------------------------------------------------------------------
    generate for (genvar i = 0; i < N; i += 1) begin : g__proc_port
        // add timestamp to tuser signal.
        assign _axis_from_switch[i].aclk         = axis_from_switch[i].aclk;
        assign _axis_from_switch[i].aresetn      = axis_from_switch[i].aresetn;
        assign _axis_from_switch[i].tvalid       = axis_from_switch[i].tvalid;
        assign _axis_from_switch[i].tlast        = axis_from_switch[i].tlast;
        assign _axis_from_switch[i].tkeep        = axis_from_switch[i].tkeep;
        assign _axis_from_switch[i].tdata        = axis_from_switch[i].tdata;
        assign _axis_from_switch[i].tid          = axis_from_switch[i].tid;
        assign _axis_from_switch[i].tdest        = axis_from_switch[i].tdest;

        always_comb begin
             _axis_from_switch_tuser[i] = axis_from_switch[i].tuser;
             _axis_from_switch_tuser[i].timestamp = timestamp;
             _axis_from_switch[i].tuser           = _axis_from_switch_tuser[i];
        end
//        assign _axis_from_switch_tuser[i].timestamp = timestamp;
//        assign _axis_from_switch_tuser[i].pid[8:0]  = axis_from_switch_tuser[i].pid[8:0];
//        assign _axis_from_switch_tuser[i].pid[9]    = i;
//        assign _axis_from_switch[i].tuser           = _axis_from_switch_tuser[i];

        assign axis_from_switch[i].tready = _axis_from_switch[i].tready;


        // axi4s_split_join instantiation (separates and recombines packet headers).
        axi4s_split_join #(
            .BIGENDIAN  (0),
            .FIFO_DEPTH (512)
        ) axi4s_split_join_inst (
            .axi4s_in      (_axis_from_switch[i]),
            .axi4s_out     (axis_to_drop[i]),
            .axi4s_hdr_out (axis_from_split_join[i]),
            .axi4s_hdr_in  (axis_to_split_join[i]),
            .axil_if       (axil_to_split_join[i]),
            .hdr_length    (p4_proc_regs[1].p4_proc_config.hdr_length)
        );


        // add proc_port to tuser pid signal.
        assign _axis_from_split_join[i].aclk        = axis_from_split_join[i].aclk;
        assign _axis_from_split_join[i].aresetn     = axis_from_split_join[i].aresetn;
        assign _axis_from_split_join[i].tvalid      = axis_from_split_join[i].tvalid;
        assign _axis_from_split_join[i].tlast       = axis_from_split_join[i].tlast;
        assign _axis_from_split_join[i].tkeep       = axis_from_split_join[i].tkeep;
        assign _axis_from_split_join[i].tdata       = axis_from_split_join[i].tdata;
        assign _axis_from_split_join[i].tid         = axis_from_split_join[i].tid;
        assign _axis_from_split_join[i].tdest       = axis_from_split_join[i].tdest;

        always_comb begin
             _axis_from_split_join_tuser[i] = axis_from_split_join[i].tuser;
             _axis_from_split_join_tuser[i].pid[9] = i;
             _axis_from_split_join[i].tuser = _axis_from_split_join_tuser[i];
        end

        assign axis_from_split_join[i].tready = _axis_from_split_join[i].tready;
 

        // packet drop logic.  deletes zero-length packets, and packets with tdest == tid i.e. switching loops.
        assign zero_length[i] = axis_to_drop[i].tvalid && axis_to_drop[i].sop && axis_to_drop[i].tlast &&
                                axis_to_drop[i].tkeep == '0;

        assign loop_detect[i] = p4_proc_regs[1].p4_proc_config.drop_pkt_loop && axis_to_drop[i].tvalid && axis_to_drop[i].sop &&
                                axis_to_drop[i].tdest == axis_to_drop[i].tid;

        assign drop_pkt[i] = zero_length[i] || loop_detect[i];

        // axi4s pkt drop instantiation.
        axi4s_drop #(
            .OUT_PIPE(1)
        ) axi4s_drop_inst (
            .axi4s_in    (axis_to_drop[i]),
            .axi4s_out   (axis_to_trunc[i]),
            .axil_if     (axil_to_drops[i]),
            .drop_pkt    (drop_pkt[i])
        );


        // pkt trunc logic.  truncates pkt length based on (p4-driven) tuser meta data.
        assign trunc_length[i] = axis_to_trunc[i].tuser.trunc_enable ? axis_to_trunc[i].tuser.trunc_length : '1;

        // axi4s pkt truncate instantiation.
        axi4s_trunc #(
            .BIGENDIAN(0), .IN_PIPE(1), .OUT_PIPE(1)
        ) axi4s_trunc_inst (
            .axi4s_in(axis_to_trunc[i]),
            .axi4s_out(axis_to_switch[i]),
            .length(trunc_length[i])
        );

    end : g__proc_port
    endgenerate


    // ----------------------------------------------------------------
    // axi4s mux and demux logic for N > 1, or connection logic for N = 1.
    // ----------------------------------------------------------------
    generate
    if (N > 1) begin
        // --- hdr if muxing logic ---
        axi4s_mux #(.N(N)) axi4s_mux_0 (
            .axi4s_in (_axis_from_split_join),
            .axi4s_out(_axis_to_sdnet)
        );

        // gate tready and tvalid with tpause register (used for test purposes).
        assign axis_to_sdnet.aclk    = _axis_to_sdnet.aclk;
        assign axis_to_sdnet.aresetn = _axis_to_sdnet.aresetn;
        assign axis_to_sdnet.tvalid  = _axis_to_sdnet.tvalid && !p4_proc_regs[1].tpause;
        assign axis_to_sdnet.tlast   = _axis_to_sdnet.tlast;
        assign axis_to_sdnet.tkeep   = _axis_to_sdnet.tkeep;
        assign axis_to_sdnet.tdata   = _axis_to_sdnet.tdata;
        assign axis_to_sdnet.tid     = _axis_to_sdnet.tid;
        assign axis_to_sdnet.tdest   = _axis_to_sdnet.tdest;
        assign axis_to_sdnet.tuser   = _axis_to_sdnet.tuser;

        assign _axis_to_sdnet.tready = axis_to_sdnet.tready  && !p4_proc_regs[1].tpause;

        // --- demux to egress hdr interfaces ---
        axi4s_intf_1to2_demux axi4s_intf_1to2_demux_0 (
            .axi4s_in   (axis_from_sdnet),
            .axi4s_out0 (axis_to_split_join[0]),
            .axi4s_out1 (axis_to_split_join[1]),
            .output_sel (axis_from_sdnet_proc_port)
        );
    end else begin // N <= 1
        // gate tready and tvalid with tpause register (used for test purposes).
        assign axis_to_sdnet.aclk    = axis_from_split_join[0].aclk;
        assign axis_to_sdnet.aresetn = axis_from_split_join[0].aresetn;
        assign axis_to_sdnet.tvalid  = axis_from_split_join[0].tvalid && !p4_proc_regs[1].tpause;
        assign axis_to_sdnet.tlast   = axis_from_split_join[0].tlast;
        assign axis_to_sdnet.tkeep   = axis_from_split_join[0].tkeep;
        assign axis_to_sdnet.tdata   = axis_from_split_join[0].tdata;
        assign axis_to_sdnet.tid     = axis_from_split_join[0].tid;
        assign axis_to_sdnet.tdest   = axis_from_split_join[0].tdest;
        assign axis_to_sdnet.tuser   = axis_from_split_join[0].tuser;

        assign axis_from_split_join[0].tready = axis_to_sdnet.tready  && !p4_proc_regs[1].tpause;

        axi4s_intf_connector axi4s_intf_connector_0 (.axi4s_from_tx(axis_from_sdnet), .axi4s_to_rx(axis_to_split_join[0]));

        axi4l_intf_peripheral_term axi4l_to_split_join_1_peripheral_term (.axi4l_if(axil_to_split_join[1]));
        axi4l_intf_peripheral_term axi4l_to_drops_1_peripheral_term (.axi4l_if(axil_to_drops[1]));
    end
    endgenerate


    // ----------------------------------------------------------------
    // The SDnet block and supporting logic.
    // ----------------------------------------------------------------
    // metadata type definitions (from xilinx_ip/<app_name>/sdnet_0/src/verilog/sdnet_0_pkg.sv).
    // --- metadata_in ---
    user_metadata_t user_metadata_in;
    logic           user_metadata_in_valid;
   
    assign axis_to_sdnet_tuser = axis_to_sdnet.tuser;

    always_comb begin
        user_metadata_in.timestamp_ns      = axis_to_sdnet_tuser.timestamp;
        user_metadata_in.pid               = {'0, axis_to_sdnet_tuser.pid[9:0]};
        user_metadata_in.ingress_port      = {'0, axis_to_sdnet.tid};
        user_metadata_in.egress_port       = {'0, axis_to_sdnet.tid};
        user_metadata_in.truncate_enable   = 0;
        user_metadata_in.truncate_length   = 0;
        user_metadata_in.rss_enable        = 0;
        user_metadata_in.rss_entropy       = 0;
        user_metadata_in.drop_reason       = 0;
        user_metadata_in.scratch           = 0;

        user_metadata_in_valid = axis_to_sdnet.tvalid && axis_to_sdnet.sop;
    end

    // --- metadata_out ---
    user_metadata_t user_metadata_out, user_metadata_out_latch;
    logic           user_metadata_out_valid;

    always @(posedge core_clk) if (user_metadata_out_valid) user_metadata_out_latch <= user_metadata_out;
   
    assign axis_from_sdnet_proc_port = user_metadata_out_valid ? user_metadata_out.pid[9] : user_metadata_out_latch.pid[9];

    assign axis_from_sdnet.tid   = user_metadata_out_valid ?
                                   user_metadata_out.ingress_port : user_metadata_out_latch.ingress_port;

    assign axis_from_sdnet.tdest = user_metadata_out_valid ?
                                   user_metadata_out.egress_port : user_metadata_out_latch.egress_port;

    assign axis_from_sdnet_tuser.pid          = user_metadata_out_valid ? {'0, user_metadata_out.pid[8:0]} : {'0, user_metadata_out_latch.pid[8:0]};

    assign axis_from_sdnet_tuser.trunc_enable = p4_proc_regs[1].trunc_config.enable ? p4_proc_regs[1].trunc_config.trunc_enable :
                                                (user_metadata_out_valid ? user_metadata_out.truncate_enable : user_metadata_out_latch.truncate_enable);

    assign axis_from_sdnet_tuser.trunc_length = p4_proc_regs[1].trunc_config.enable ? p4_proc_regs[1].trunc_config.trunc_length :
                                                (user_metadata_out_valid ? user_metadata_out.truncate_length : user_metadata_out_latch.truncate_length);

    assign axis_from_sdnet_tuser.rss_enable   = p4_proc_regs[1].rss_config.enable ? p4_proc_regs[1].rss_config.rss_enable :
                                                (user_metadata_out_valid ? user_metadata_out.rss_enable  : user_metadata_out_latch.rss_enable);

    assign axis_from_sdnet_tuser.rss_entropy  = p4_proc_regs[1].rss_config.enable ? p4_proc_regs[1].rss_config.rss_entropy :
                                                (user_metadata_out_valid ? user_metadata_out.rss_entropy : user_metadata_out_latch.rss_entropy);

    assign axis_from_sdnet.tuser = axis_from_sdnet_tuser;


    // --- sdnet_0 instance (p4_proc) ---
    generate
        if (EXTERN_PORTS) begin
            sdnet_0_wrapper sdnet_0_p4_proc (
                .core_clk                (core_clk),
                .core_rstn               (core_rstn),
                .axil_if                 (axil_to_sdnet),
                .axis_rx                 (axis_to_sdnet),
                .axis_tx                 (axis_from_sdnet),
                .user_metadata_in_valid  (user_metadata_in_valid),
                .user_metadata_in        (user_metadata_in),
                .user_metadata_out_valid (user_metadata_out_valid),
                .user_metadata_out       (user_metadata_out),
                .user_extern_out         (user_extern_out),
                .user_extern_out_valid   (user_extern_out_valid),
                .user_extern_in          (user_extern_in),
                .user_extern_in_valid    (user_extern_in_valid),
                .axi_to_hbm              (axi_to_hbm)
            );
        end else begin
            sdnet_0_wrapper sdnet_0_p4_proc (
                .core_clk                (core_clk),
                .core_rstn               (core_rstn),
                .axil_if                 (axil_to_sdnet),
                .axis_rx                 (axis_to_sdnet),
                .axis_tx                 (axis_from_sdnet),
                .user_metadata_in_valid  (user_metadata_in_valid),
                .user_metadata_in        (user_metadata_in),
                .user_metadata_out_valid (user_metadata_out_valid),
                .user_metadata_out       (user_metadata_out),
                .axi_to_hbm              (axi_to_hbm)
            );

            assign user_extern_out_valid = 1'b0;
            assign user_extern_out       = 1'b0;
        end
    endgenerate

    assign axis_from_sdnet.aclk = core_clk;
    assign axis_from_sdnet.aresetn = core_rstn;

endmodule: p4_proc
