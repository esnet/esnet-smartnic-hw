module p4_proc
    import smartnic_pkg::*;
    import p4_proc_pkg::*;
#(
    parameter int   NUM_PORTS = 2  // Number of processor ports.
) (
    input logic        core_clk,
    input logic        core_rstn,
    input timestamp_t  timestamp,

    axi4l_intf.peripheral axil_if,

    axi4s_intf.rx axis_in  [NUM_PORTS],
    axi4s_intf.tx axis_out [NUM_PORTS],

    axi4s_intf.tx axis_to_vitisnetp4,
    axi4s_intf.rx axis_from_vitisnetp4,

    output user_metadata_t user_metadata_to_vitisnetp4,
    output logic           user_metadata_to_vitisnetp4_valid,

    input  user_metadata_t user_metadata_from_vitisnetp4,
    input  logic           user_metadata_from_vitisnetp4_valid
);

    // -------------------------------------------------
    // Parameter checking
    // -------------------------------------------------
    initial std_pkg::param_check_gt(NUM_PORTS, 1, "NUM_PORTS");
    initial std_pkg::param_check_lt(NUM_PORTS, 2, "NUM_PORTS");

    // -------------------------------------------------
    // Typedefs
    // -------------------------------------------------

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
        .axi4s_split_join_0_axil_if     (axil_to_split_join[0]),
        .axi4s_split_join_1_axil_if     (axil_to_split_join[1])
    );

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
    logic zero_length [NUM_PORTS];
    logic loop_detect [NUM_PORTS];
    logic drop_pkt    [NUM_PORTS];

    logic proc_port;

    logic [15:0] trunc_length [NUM_PORTS];

    user_metadata_t   user_metadata_from_vitisnetp4_latch;
    port_t            axis_from_vitisnetp4_tdest;
    port_t            axis_from_vitisnetp4_tdest_latch;

    tuser_t  _axis_in_tuser [NUM_PORTS];
    tuser_t  _axis_from_split_join_tuser [NUM_PORTS];
    tuser_t  axis_to_vitisnetp4_tuser;
    tuser_t  _axis_from_vitisnetp4_tuser;
    tuser_t  axis_from_bypass_mux_tuser;

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   _axis_in [NUM_PORTS] ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   axis_from_split_join [NUM_PORTS] ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   _axis_from_split_join [NUM_PORTS] ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   axis_to_bypass_mux ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   _axis_to_bypass_mux ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   axis_from_bypass_mux ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   _axis_from_bypass_mux ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   _axis_from_vitisnetp4 ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   axis_to_split_join [NUM_PORTS] ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   axis_to_drop [NUM_PORTS] ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   axis_to_drop_p [NUM_PORTS] ();

    axi4s_intf  #( .TUSER_T(tuser_t),
                   .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   axis_to_trunc [NUM_PORTS] ();


    // --------------------------------------------------------------------
    //  per port functionality.  pkt split-join, drop and truncation logic.
    // --------------------------------------------------------------------
    generate for (genvar i = 0; i < NUM_PORTS; i += 1) begin : g__proc_port
        // add timestamp to tuser signal (for consistent pipelining with pkt data destined to axis_to_bypass_mux).
        assign _axis_in[i].aclk         = axis_in[i].aclk;
        assign _axis_in[i].aresetn      = axis_in[i].aresetn;
        assign _axis_in[i].tvalid       = axis_in[i].tvalid;
        assign _axis_in[i].tlast        = axis_in[i].tlast;
        assign _axis_in[i].tkeep        = axis_in[i].tkeep;
        assign _axis_in[i].tdata        = axis_in[i].tdata;
        assign _axis_in[i].tid          = axis_in[i].tid;
        assign _axis_in[i].tdest        = axis_in[i].tdest;

        always_comb begin
             _axis_in_tuser[i]           = axis_in[i].tuser;
             _axis_in_tuser[i].timestamp = timestamp;
             _axis_in[i].tuser           = _axis_in_tuser[i];
        end

        assign axis_in[i].tready = _axis_in[i].tready;

        // xilinx_axi4s_ila xilinx_axi4s_ila_0 (.axis_in(_axis_in[0]));

        // axi4s_split_join instantiation (separates and recombines packet headers).
        axi4s_split_join #(
            .BIGENDIAN  (0),
            .FIFO_DEPTH (512)
        ) axi4s_split_join_inst (
            .axi4s_in      (_axis_in[i]),
            .axi4s_out     (axis_to_drop_p[i]),
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
 
        // xilinx_axi4s_ila xilinx_axi4s_ila_1 (.axis_in(_axis_from_split_join[0]));

        axi4s_tready_pipe axis_to_drop_pipe (.axi4s_if_from_tx(axis_to_drop_p[i]), .axi4s_if_to_rx(axis_to_drop[i]));

        // packet drop logic.  deletes zero-length packets, and packets with tdest == tid i.e. switching loops.
        assign zero_length[i] = axis_to_drop[i].tvalid && axis_to_drop[i].sop && axis_to_drop[i].tlast &&
                                axis_to_drop[i].tkeep == '0;

        assign loop_detect[i] = p4_proc_regs[1].p4_proc_config.drop_pkt_loop && axis_to_drop[i].tvalid && axis_to_drop[i].sop &&
                                axis_to_drop[i].tdest == axis_to_drop[i].tid;

        assign drop_pkt[i] = zero_length[i] || loop_detect[i];

        // axi4s pkt drop instantiation.
        axi4s_drop axi4s_drop_inst (
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
            .axi4s_out(axis_out[i]),
            .length(trunc_length[i])
        );

    end : g__proc_port
    endgenerate


    // ----------------------------------------------------------------
    // axi4s mux and demux logic for NUM_PORTS > 1, or connection logic for NUM_PORTS = 1.
    // ----------------------------------------------------------------
    generate
        if (NUM_PORTS > 1) begin
            axi4s_mux #(.N(NUM_PORTS)) axi4s_mux_0 (
                .axi4s_in (_axis_from_split_join),
                .axi4s_out(_axis_to_bypass_mux) );

        end else begin // NUM_PORTS <= 1
            axi4s_intf_connector axis_from_split_join_connector (
                .axi4s_from_tx(_axis_from_split_join[0]),
                .axi4s_to_rx(_axis_to_bypass_mux) );
        end

        // axis_to_bypass_mux assignments. gate tready and tvalid with tpause register (used for test purposes).
        assign axis_to_bypass_mux.aclk    = _axis_to_bypass_mux.aclk;
        assign axis_to_bypass_mux.aresetn = _axis_to_bypass_mux.aresetn;
        assign axis_to_bypass_mux.tvalid  = _axis_to_bypass_mux.tvalid && !p4_proc_regs[1].tpause;
        assign axis_to_bypass_mux.tlast   = _axis_to_bypass_mux.tlast;
        assign axis_to_bypass_mux.tkeep   = _axis_to_bypass_mux.tkeep;
        assign axis_to_bypass_mux.tdata   = _axis_to_bypass_mux.tdata;
        assign axis_to_bypass_mux.tid     = _axis_to_bypass_mux.tid;
        assign axis_to_bypass_mux.tdest   = _axis_to_bypass_mux.tdest;
        assign axis_to_bypass_mux.tuser   = _axis_to_bypass_mux.tuser;
        assign _axis_to_bypass_mux.tready = axis_to_bypass_mux.tready  && !p4_proc_regs[1].tpause;


        // axis_from_bypass_mux assignments. extract proc_port and wire in override registers.
        assign axis_from_bypass_mux.aclk    = _axis_from_bypass_mux.aclk;
        assign axis_from_bypass_mux.aresetn = _axis_from_bypass_mux.aresetn;
        assign axis_from_bypass_mux.tvalid  = _axis_from_bypass_mux.tvalid;
        assign axis_from_bypass_mux.tlast   = _axis_from_bypass_mux.tlast;
        assign axis_from_bypass_mux.tkeep   = _axis_from_bypass_mux.tkeep;
        assign axis_from_bypass_mux.tdata   = _axis_from_bypass_mux.tdata;
        assign axis_from_bypass_mux.tid     = _axis_from_bypass_mux.tid;
        assign axis_from_bypass_mux.tdest   = _axis_from_bypass_mux.tdest;
        assign _axis_from_bypass_mux.tready = axis_from_bypass_mux.tready;

        always_comb begin
             axis_from_bypass_mux_tuser = _axis_from_bypass_mux.tuser;

	     proc_port                               = axis_from_bypass_mux_tuser.pid[9];
             axis_from_bypass_mux_tuser.pid          = {'0, axis_from_bypass_mux_tuser.pid[8:0]};

             axis_from_bypass_mux_tuser.trunc_enable = p4_proc_regs[1].trunc_config.enable ?
                                                       p4_proc_regs[1].trunc_config.trunc_enable :
                                                       axis_from_bypass_mux_tuser.trunc_enable;

             axis_from_bypass_mux_tuser.trunc_length = p4_proc_regs[1].trunc_config.enable ?
                                                       p4_proc_regs[1].trunc_config.trunc_length :
                                                       axis_from_bypass_mux_tuser.trunc_length;

             axis_from_bypass_mux_tuser.rss_enable   = p4_proc_regs[1].rss_config.enable ?
                                                       p4_proc_regs[1].rss_config.rss_enable :
                                                       axis_from_bypass_mux_tuser.rss_enable;

             axis_from_bypass_mux_tuser.rss_entropy  = p4_proc_regs[1].rss_config.enable ?
                                                       p4_proc_regs[1].rss_config.rss_entropy :
                                                       axis_from_bypass_mux_tuser.rss_entropy;

             axis_from_bypass_mux.tuser = axis_from_bypass_mux_tuser;
        end


        if (NUM_PORTS > 1) begin
            axi4s_intf_1to2_demux axi4s_intf_1to2_demux_0 (
                .axi4s_in   (axis_from_bypass_mux),
                .axi4s_out0 (axis_to_split_join[0]),
                .axi4s_out1 (axis_to_split_join[1]),
                .output_sel (proc_port)
            );

        end else begin // NUM_PORTS <= 1
            axi4s_intf_connector axis_to_split_join_connector (
                .axi4s_from_tx(axis_from_bypass_mux),
                .axi4s_to_rx(axis_to_split_join[0]) );

            axi4l_intf_peripheral_term axi4l_to_split_join_1_peripheral_term ( .axi4l_if(axil_to_split_join[1]) );
            axi4l_intf_peripheral_term axi4l_to_drops_1_peripheral_term ( .axi4l_if(axil_to_drops[1]) );
        end
    endgenerate


    // bypass mux instantation (used to bypass p4 processor, when enabled).
    axi4s_intf_bypass_mux #(
        .PIPE_STAGES(1), .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_t)
    ) bypass_mux (
        .axi4s_in         (axis_to_bypass_mux),
        .axi4s_to_block   (axis_to_vitisnetp4),
        .axi4s_from_block (_axis_from_vitisnetp4),
        .axi4s_out        (_axis_from_bypass_mux),
        .bypass           (p4_proc_regs[1].p4_proc_config.p4_bypass)
    );


    // ----------------------------------------------------------------
    // SDnet block supporting logic.
    // ----------------------------------------------------------------
    // metadata type definitions (from ip/<app_name>/vitisnetp4_0/src/verilog/vitisnetp4_0_pkg.sv).
    // --- metadata_to_vitisnetp4 ---
    assign axis_to_vitisnetp4_tuser = axis_to_vitisnetp4.tuser;

    always_comb begin
        user_metadata_to_vitisnetp4.timestamp_ns      =      axis_to_vitisnetp4_tuser.timestamp;
        user_metadata_to_vitisnetp4.pid               = {'0, axis_to_vitisnetp4_tuser.pid[9:0]};
        user_metadata_to_vitisnetp4.ingress_port      =      axis_to_vitisnetp4.tid;
        user_metadata_to_vitisnetp4.egress_port       =      axis_to_vitisnetp4.tdest[1:0];  // egress_port is 2 bits.
        user_metadata_to_vitisnetp4.truncate_enable   =      axis_to_vitisnetp4_tuser.trunc_enable;
        user_metadata_to_vitisnetp4.truncate_length   =      axis_to_vitisnetp4_tuser.trunc_length;
        user_metadata_to_vitisnetp4.rss_enable        =      axis_to_vitisnetp4_tuser.rss_enable;
        user_metadata_to_vitisnetp4.rss_entropy       =      axis_to_vitisnetp4_tuser.rss_entropy;
        user_metadata_to_vitisnetp4.drop_reason       = 0;
        user_metadata_to_vitisnetp4.scratch           = 0;

        user_metadata_to_vitisnetp4_valid = axis_to_vitisnetp4.tvalid && axis_to_vitisnetp4.sop;
    end

    // --- metadata_from_vitisnetp4 ---
    always @(posedge core_clk) if (user_metadata_from_vitisnetp4_valid) user_metadata_from_vitisnetp4_latch <= user_metadata_from_vitisnetp4;

    always_comb begin
        case (user_metadata_from_vitisnetp4.egress_port)
            2'h0: axis_from_vitisnetp4_tdest = CMAC0;
            2'h1: axis_from_vitisnetp4_tdest = CMAC1;
            2'h2: axis_from_vitisnetp4_tdest = PF0;
            2'h3: axis_from_vitisnetp4_tdest = LOOPBACK;
        endcase
    end

    always @(posedge core_clk) if (user_metadata_from_vitisnetp4_valid) axis_from_vitisnetp4_tdest_latch <= axis_from_vitisnetp4_tdest;

    assign _axis_from_vitisnetp4.tdest              = user_metadata_from_vitisnetp4_valid ?
                                                      axis_from_vitisnetp4_tdest :
                                                      axis_from_vitisnetp4_tdest_latch;

    assign _axis_from_vitisnetp4.tid                = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.ingress_port :
                                                      user_metadata_from_vitisnetp4_latch.ingress_port;

    assign _axis_from_vitisnetp4_tuser.pid          = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.pid :
                                                      user_metadata_from_vitisnetp4_latch.pid;

    assign _axis_from_vitisnetp4_tuser.trunc_enable = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.truncate_enable :
                                                      user_metadata_from_vitisnetp4_latch.truncate_enable;

    assign _axis_from_vitisnetp4_tuser.trunc_length = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.truncate_length :
                                                      user_metadata_from_vitisnetp4_latch.truncate_length;

    assign _axis_from_vitisnetp4_tuser.rss_enable   = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.rss_enable :
                                                      user_metadata_from_vitisnetp4_latch.rss_enable;

    assign _axis_from_vitisnetp4_tuser.rss_entropy  = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.rss_entropy :
                                                      user_metadata_from_vitisnetp4_latch.rss_entropy;

    assign _axis_from_vitisnetp4.tuser = _axis_from_vitisnetp4_tuser;

    assign _axis_from_vitisnetp4.aclk    = axis_from_vitisnetp4.aclk;
    assign _axis_from_vitisnetp4.aresetn = axis_from_vitisnetp4.aresetn;
    assign _axis_from_vitisnetp4.tvalid  = axis_from_vitisnetp4.tvalid;
    assign _axis_from_vitisnetp4.tlast   = axis_from_vitisnetp4.tlast;
    assign _axis_from_vitisnetp4.tkeep   = axis_from_vitisnetp4.tkeep;
    assign _axis_from_vitisnetp4.tdata   = axis_from_vitisnetp4.tdata;

    assign axis_from_vitisnetp4.tready   = _axis_from_vitisnetp4.tready;


endmodule: p4_proc
