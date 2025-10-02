module p4_proc
    import smartnic_pkg::*;
    import p4_proc_pkg::*;
#(
    parameter int   NUM_PORTS = 2,  // Number of processor ports.
    parameter int   FIFO_DEPTH = 512
) (
    input logic        core_clk,
    input logic        core_rstn,

    input logic [TIMESTAMP_WID-1:0] timestamp,

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

    localparam int PTR_LEN = $clog2(FIFO_DEPTH);
    typedef struct packed {
        logic [PTR_LEN-1:0] pid;
        logic               hdr_tlast;
    } split_join_meta_t;

    localparam int PROC_PORT_WID = NUM_PORTS > 1 ? $clog2(NUM_PORTS) : 1;

    typedef struct packed {
        logic [PROC_PORT_WID-1:0] proc_port;
        logic [PTR_LEN-1:0] payload_ptr;
    } pid_t;

    typedef struct packed {
        tuser_smartnic_meta_t        smartnic_meta;
        logic [TIMESTAMP_WID-1:0]    timestamp;
        logic [PROC_PORT_WID-1:0]    proc_port;
        trunc_meta_t                 trunc;
    } tuser_pkt_t;
    localparam int TUSER_PKT_WID = $bits(tuser_pkt_t);

    typedef struct packed {
        tuser_smartnic_meta_t        smartnic_meta;
        logic [TIMESTAMP_WID-1:0]    timestamp;
        logic [PROC_PORT_WID-1:0]    proc_port;
        trunc_meta_t                 trunc;
        split_join_meta_t            split_join;
    } tuser_hdr_t;
    localparam int TUSER_HDR_WID = $bits(tuser_hdr_t);

    // -------------------------------------------------
    // Parameter checking
    // -------------------------------------------------
    initial begin
        std_pkg::param_check(axis_in[0].DATA_BYTE_WID,  64,                      "axis_in[0].DATA_BYTE_WID");
        std_pkg::param_check(axis_in[0].TID_WID,        PORT_WID,                "axis_in[0].TID_WID");
        std_pkg::param_check(axis_in[0].TDEST_WID,      PORT_WID,                "axis_in[0].TDEST_WID");
        std_pkg::param_check(axis_in[0].TUSER_WID,      TUSER_SMARTNIC_META_WID, "axis_in[0].TUSER_WID");
        std_pkg::param_check(axis_out[0].DATA_BYTE_WID, 64,                      "axis_out[0].DATA_BYTE_WID");
        std_pkg::param_check(axis_out[0].TID_WID,       PORT_WID,                "axis_out[0].TID_WID");
        std_pkg::param_check(axis_out[0].TDEST_WID,     PORT_WID,                "axis_out[0].TDEST_WID");
        std_pkg::param_check(axis_out[0].TUSER_WID,     TUSER_SMARTNIC_META_WID, "axis_out[0].TUSER_WID");
        std_pkg::param_check(axis_to_vitisnetp4.DATA_BYTE_WID, axis_from_vitisnetp4.DATA_BYTE_WID, "axis_to_vitisnetp4.DATA_BYTE_WID");
        std_pkg::param_check(axis_to_vitisnetp4.TID_WID,       axis_from_vitisnetp4.TID_WID,       "axis_to_vitisnetp4.TID_WID");
        std_pkg::param_check(axis_to_vitisnetp4.TDEST_WID,     axis_from_vitisnetp4.TDEST_WID,     "axis_to_vitisnetp4.TDEST_WID");
        std_pkg::param_check(axis_to_vitisnetp4.TUSER_WID,     axis_from_vitisnetp4.TUSER_WID,     "axis_to_vitisnetp4.TUSER_WID");
        std_pkg::param_check_gt(NUM_PORTS, 1, "NUM_PORTS");
        std_pkg::param_check_lt(NUM_PORTS, 2, "NUM_PORTS");
        std_pkg::param_check_gt(PID_WID, $bits(pid_t), "PID_WID");
    end

    // ----------------------------------------------------------------------
    //  axil register map. axil intf, regio block and decoder instantiations.
    // ----------------------------------------------------------------------
    axi4l_intf  axil_to_p4_proc ();
    axi4l_intf  axil_to_p4_proc__core_clk ();

    axi4l_intf  axil_stub[2] ();
    axi4l_intf  axil_to_p4_drops ();
    axi4l_intf  axil_to_unset_drops[2] ();
    axi4l_intf  axil_to_split_join[2] ();

    p4_proc_reg_intf  p4_proc_regs[2] ();

    // p4_proc register decoder
    p4_proc_decoder p4_proc_decoder (
        .axil_if          (axil_if),
        .p4_proc_axil_if  (axil_to_p4_proc),
        .drops_from_p4_axil_if          (axil_to_p4_drops),
        .drops_unset_err_port_0_axil_if (axil_to_unset_drops[0]),
        .drops_unset_err_port_1_axil_if (axil_to_unset_drops[1]),
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
        p4_proc_regs[1].p4_proc_config   <= p4_proc_regs[0].p4_proc_config;
        p4_proc_regs[1].p4_bypass_config <= p4_proc_regs[0].p4_bypass_config;
        p4_proc_regs[1].trunc_config     <= p4_proc_regs[0].trunc_config;
        p4_proc_regs[1].rss_config       <= p4_proc_regs[0].rss_config;
        p4_proc_regs[1].tpause           <= p4_proc_regs[0].tpause;
    end


    // ----------------------------------------------------------------
    //  local signals and axi4s intf instantiations.
    // ----------------------------------------------------------------
    logic p4_drop    [NUM_PORTS];
    logic unset_drop [NUM_PORTS];

    logic proc_port;

    logic [15:0] trunc_length [NUM_PORTS];

    logic        p4_bypass_enable;
    logic        p4_bypass_timer_enable;
    logic [10:0] p4_bypass_timer;

    user_metadata_t   user_metadata_from_vitisnetp4_latch;
    port_t            axis_from_vitisnetp4_tdest;
    port_t            axis_from_vitisnetp4_tdest_latch;

    tuser_hdr_t  _axis_to_vitisnetp4_tuser;
    tuser_hdr_t  _axis_from_vitisnetp4_tuser;
    tuser_hdr_t  _axis_from_bypass_mux_tuser;
    tuser_hdr_t  axis_from_bypass_mux_tuser;

    pid_t user_metadata_to_vitisnetp4_pid;
    pid_t user_metadata_from_vitisnetp4_pid;

    axi4s_intf  #( .TUSER_WID(TUSER_PKT_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   _axis_in [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_from_split_join [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_to_bypass_mux (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   _axis_to_bypass_mux (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_from_bypass_mux (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   _axis_from_bypass_mux (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   _axis_to_vitisnetp4 (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   _axis_from_vitisnetp4 (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_to_split_join [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_HDR_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   _axis_to_split_join [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_PKT_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_to_p4_drop_cnt (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_PKT_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_to_p4_drop [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_PKT_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_to_p4_drop_p [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_PKT_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_to_unset_drop [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_PKT_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_to_trunc [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #( .TUSER_WID(TUSER_PKT_WID),
                   .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   _axis_out [NUM_PORTS] (.aclk(core_clk), .aresetn(core_rstn));


    // --------------------------------------------------------------------
    //  per port functionality.  pkt split-join, drop and truncation logic.
    // --------------------------------------------------------------------
    generate for (genvar i = 0; i < NUM_PORTS; i++) begin : g__proc_port
        tuser_pkt_t _axis_in_tuser;
        port_t      axis_to_unset_drop_tdest;
        tuser_pkt_t axis_to_trunc_tuser;

        // add proc_port to tuser signal (to pipeline with pkt data destined to axis_to_bypass_mux).
        assign _axis_in[i].tvalid       = axis_in[i].tvalid;
        assign _axis_in[i].tlast        = axis_in[i].tlast;
        assign _axis_in[i].tkeep        = axis_in[i].tkeep;
        assign _axis_in[i].tdata        = axis_in[i].tdata;
        assign _axis_in[i].tid          = axis_in[i].tid;
        assign _axis_in[i].tdest        = axis_in[i].tdest;

        always_comb begin
             _axis_in_tuser.smartnic_meta = axis_in[i].tuser;
             _axis_in_tuser.timestamp     = timestamp;
             _axis_in_tuser.proc_port     = i;
             _axis_in_tuser.trunc         = '0;
             _axis_in[i].tuser            = _axis_in_tuser;
        end

        assign axis_in[i].tready = _axis_in[i].tready;

        // xilinx_axi4s_ila xilinx_axi4s_ila_0 (.axis_in(_axis_in[0]));

        // axi4s_split_join instantiation (separates and recombines packet headers).
        axi4s_split_join #(
            .FIFO_DEPTH (FIFO_DEPTH)
        ) axi4s_split_join_inst (
            .clk           (core_clk),
            .srst          (!core_rstn),
            .axi4s_in      (_axis_in[i]),
            .axi4s_out     (axis_to_p4_drop_p[i]),
            .axi4s_hdr_out (axis_from_split_join[i]),
            .axi4s_hdr_in  (axis_to_split_join[i]),
            .axil_if       (axil_to_split_join[i]),
            .hdr_length    (p4_proc_regs[1].p4_proc_config.hdr_length)
        );
 
        // xilinx_axi4s_ila xilinx_axi4s_ila_1 (.axis_in(axis_from_split_join[0]));

        axi4s_tready_pipe axis_to_p4_drop_pipe ( .from_tx(axis_to_p4_drop_p[i]),
                                                 .to_rx(axis_to_p4_drop[i]) );

        // p4 drop logic (zero-length packets).
        assign p4_drop[i] = axis_to_p4_drop[i].tvalid && axis_to_p4_drop[i].sop &&
                            axis_to_p4_drop[i].tlast  && axis_to_p4_drop[i].tkeep == '0;


        // p4 drop instantiation.
        axi4l_intf_controller_term axi4l_stub_term (.axi4l_if (axil_stub[i]));

        axi4s_drop axi4s_p4_drop_inst (
            .clk         (core_clk),
            .srst        (!core_rstn),
            .axi4s_in    (axis_to_p4_drop[i]),
            .axi4s_out   (axis_to_unset_drop[i]),
            .axil_if     (axil_stub[i]),
            .drop_pkt    (p4_drop[i])
        );

        // unset drop logic (packets with UNSET codepoint).
        assign axis_to_unset_drop_tdest = axis_to_unset_drop[i].tdest;
        assign unset_drop[i] = axis_to_unset_drop[i].tvalid && axis_to_unset_drop[i].sop &&
                               axis_to_unset_drop_tdest.encoded.typ == UNSET;

        // unset drop instantiation.
        axi4s_drop axi4s_unset_drop_inst (
            .clk         (core_clk),
            .srst        (!core_rstn),
            .axi4s_in    (axis_to_unset_drop[i]),
            .axi4s_out   (axis_to_trunc[i]),
            .axil_if     (axil_to_unset_drops[i]),
            .drop_pkt    (unset_drop[i])
        );

        // pkt trunc logic.  truncates pkt length based on (p4-driven) tuser meta data.
        assign axis_to_trunc_tuser = axis_to_trunc[i].tuser;
        assign trunc_length[i] = axis_to_trunc_tuser.trunc.enable ?
                                 axis_to_trunc_tuser.trunc.length : '1;

        // axi4s pkt truncate instantiation.
        axi4s_trunc #(
            .IN_PIPE(1), .OUT_PIPE(1)
        ) axi4s_trunc_inst (
            .clk         (core_clk),
            .srst        (!core_rstn),
            .axi4s_in(axis_to_trunc[i]),
            .axi4s_out(_axis_out[i]),
            .length(trunc_length[i])
        );

        // Shed unnecessary metadata
        tuser_pkt_t _axis_out_tuser;
        assign _axis_out_tuser = _axis_out[i].tuser;
        axi4s_intf_set_meta #(
            .TID_WID (PORT_WID),
            .TDEST_WID (PORT_WID),
            .TUSER_WID (TUSER_SMARTNIC_META_WID)
        ) axi4s_intf_set_meta_out (
            .from_tx (_axis_out[i]),
            .to_rx   (axis_out[i]),
            .tid     (_axis_out[i].tid),
            .tdest   (_axis_out[i].tdest),
            .tuser   (_axis_out_tuser.smartnic_meta)
        );

    end : g__proc_port
    endgenerate


    // ----------------------------------------------------------------
    // axi4s mux and demux logic for NUM_PORTS > 1, or connection logic for NUM_PORTS = 1.
    // ----------------------------------------------------------------
    generate
        if (NUM_PORTS > 1) begin : g__multi_port_to_bypass
            axi4s_mux #(.N(NUM_PORTS)) axi4s_mux_0 (
                .axi4s_in (axis_from_split_join),
                .axi4s_out(_axis_to_bypass_mux) );

        end : g__multi_port_to_bypass
        else begin : g__single_port_to_bypass // NUM_PORTS <= 1
            axi4s_intf_connector axis_from_split_join_connector (
                .from_tx(axis_from_split_join[0]),
                .to_rx(_axis_to_bypass_mux) );
        end : g__single_port_to_bypass
    endgenerate

    // axis_to_bypass_mux assignments. gate tready and tvalid with tpause register (used for test purposes).
    assign axis_to_bypass_mux.tvalid  = _axis_to_bypass_mux.tvalid &&
                                        !p4_proc_regs[1].tpause && !p4_bypass_timer_enable;
    assign axis_to_bypass_mux.tlast   = _axis_to_bypass_mux.tlast;
    assign axis_to_bypass_mux.tkeep   = _axis_to_bypass_mux.tkeep;
    assign axis_to_bypass_mux.tdata   = _axis_to_bypass_mux.tdata;
    assign axis_to_bypass_mux.tid     = _axis_to_bypass_mux.tid;
    assign axis_to_bypass_mux.tdest   = _axis_to_bypass_mux.tdest;
    assign axis_to_bypass_mux.tuser   = _axis_to_bypass_mux.tuser;
    assign _axis_to_bypass_mux.tready = axis_to_bypass_mux.tready  &&
                                        !p4_proc_regs[1].tpause && !p4_bypass_timer_enable;


    // axis_from_bypass_mux assignments. extract proc_port and wire in override registers.
    assign _axis_from_bypass_mux.tready = axis_from_bypass_mux.tready;

    assign axis_from_bypass_mux.tvalid  = _axis_from_bypass_mux.tvalid;
    assign axis_from_bypass_mux.tlast   = _axis_from_bypass_mux.tlast;
    assign axis_from_bypass_mux.tkeep   = _axis_from_bypass_mux.tkeep;
    assign axis_from_bypass_mux.tdata   = _axis_from_bypass_mux.tdata;
    assign axis_from_bypass_mux.tid     = _axis_from_bypass_mux.tid;
    assign axis_from_bypass_mux.tdest   = _axis_from_bypass_mux.tdest;

    always_comb begin
         _axis_from_bypass_mux_tuser = _axis_from_bypass_mux.tuser;

         proc_port                               = _axis_from_bypass_mux_tuser.proc_port;
         axis_from_bypass_mux_tuser.timestamp    = _axis_from_bypass_mux_tuser.timestamp;
         axis_from_bypass_mux_tuser.split_join   = {'0, _axis_from_bypass_mux_tuser.split_join};

         axis_from_bypass_mux_tuser.trunc.enable = p4_proc_regs[1].trunc_config.enable ?
                                                   p4_proc_regs[1].trunc_config.trunc_enable :
                                                   _axis_from_bypass_mux_tuser.trunc.enable;

         axis_from_bypass_mux_tuser.trunc.length = p4_proc_regs[1].trunc_config.enable ?
                                                   p4_proc_regs[1].trunc_config.trunc_length :
                                                   _axis_from_bypass_mux_tuser.trunc.length;

         axis_from_bypass_mux_tuser.smartnic_meta.rss_enable  = p4_proc_regs[1].rss_config.enable ?
                                                   p4_proc_regs[1].rss_config.rss_enable :
                                                   _axis_from_bypass_mux_tuser.smartnic_meta.rss_enable;

         axis_from_bypass_mux_tuser.smartnic_meta.rss_entropy = p4_proc_regs[1].rss_config.enable ?
                                                   p4_proc_regs[1].rss_config.rss_entropy :
                                                   _axis_from_bypass_mux_tuser.smartnic_meta.rss_entropy;

         axis_from_bypass_mux.tuser = axis_from_bypass_mux_tuser;
    end

    // p4 drop counter instantiation and signalling.
    assign axis_to_p4_drop_cnt.tready  = axis_from_bypass_mux.tready;
    assign axis_to_p4_drop_cnt.tvalid  = axis_from_bypass_mux.tvalid && axis_from_bypass_mux.sop &&
                                         axis_from_bypass_mux.tlast  && axis_from_bypass_mux.tkeep == '0;
    assign axis_to_p4_drop_cnt.tdata   = axis_from_bypass_mux.tdata;
    assign axis_to_p4_drop_cnt.tkeep   = axis_from_bypass_mux.tkeep;
    assign axis_to_p4_drop_cnt.tlast   = axis_from_bypass_mux.tlast;
    assign axis_to_p4_drop_cnt.tid     = axis_from_bypass_mux.tid;
    assign axis_to_p4_drop_cnt.tdest   = axis_from_bypass_mux.tdest;
    assign axis_to_p4_drop_cnt.tuser   = axis_from_bypass_mux.tuser;

    axi4s_probe axis_p4_drop_count (
        .axi4l_if  (axil_to_p4_drops),
        .axi4s_if  (axis_to_p4_drop_cnt)
    );

    generate
        if (NUM_PORTS > 1) begin : g__multi_port_from_bypass
            axi4s_intf_1to2_demux axi4s_intf_1to2_demux_0 (
                .from_tx (axis_from_bypass_mux),
                .to_rx_0 (_axis_to_split_join[0]),
                .to_rx_1 (_axis_to_split_join[1]),
                .output_sel (proc_port)
            );

            for (genvar i = 0; i < NUM_PORTS; i++) begin : g__port
                assign _axis_to_split_join[i].tready = axis_to_split_join[i].tready;

                assign axis_to_split_join[i].tvalid  = _axis_to_split_join[i].tvalid;
                assign axis_to_split_join[i].tlast   = _axis_to_split_join[i].tlast;
                assign axis_to_split_join[i].tkeep   = _axis_to_split_join[i].tkeep;
                assign axis_to_split_join[i].tdata   = _axis_to_split_join[i].tdata;
                assign axis_to_split_join[i].tid     = _axis_to_split_join[i].tid;
                assign axis_to_split_join[i].tuser   = _axis_to_split_join[i].tuser;
            end : g__port

            assign axis_to_split_join[0].tdest   = !p4_bypass_enable ? _axis_to_split_join[0].tdest :
                                                   {p4_proc_regs[1].p4_bypass_config.p4_bypass_egr_port_type_0,
                                                    p4_proc_regs[1].p4_bypass_config.p4_bypass_egr_port_num_0} ;

            assign axis_to_split_join[1].tdest   = !p4_bypass_enable ? _axis_to_split_join[1].tdest :
                                                   {p4_proc_regs[1].p4_bypass_config.p4_bypass_egr_port_type_1,
                                                    p4_proc_regs[1].p4_bypass_config.p4_bypass_egr_port_num_1} ;

        end : g__multi_port_from_bypass
        else begin : g__single_port_from_bypass // NUM_PORTS <= 1
            axi4s_intf_connector axis_to_split_join_connector (
                .axi4s_from_tx(axis_from_bypass_mux),
                .axi4s_to_rx(_axis_to_split_join[0]) );

            assign _axis_to_split_join[0].tready = axis_to_split_join[0].tready;

            assign axis_to_split_join[0].tvalid  = _axis_to_split_join[0].tvalid;
            assign axis_to_split_join[0].tlast   = _axis_to_split_join[0].tlast;
            assign axis_to_split_join[0].tkeep   = _axis_to_split_join[0].tkeep;
            assign axis_to_split_join[0].tdata   = _axis_to_split_join[0].tdata;
            assign axis_to_split_join[0].tid     = _axis_to_split_join[0].tid;
            assign axis_to_split_join[0].tuser   = _axis_to_split_join[0].tuser;

            assign axis_to_split_join[0].tdest   = !p4_bypass_enable ? _axis_to_split_join[0].tdest :
                                                   {p4_proc_regs[1].p4_bypass_config.p4_bypass_egr_port_type_0,
                                                    p4_proc_regs[1].p4_bypass_config.p4_bypass_egr_port_num_0} ;

            axi4l_intf_peripheral_term axi4l_to_split_join_1_peripheral_term ( .axi4l_if(axil_to_split_join[1])  );
            axi4l_intf_peripheral_term axi4l_to_p4_drops_1_peripheral_term   ( .axi4l_if(axil_to_unset_drops[1]) );
        end : g__single_port_from_bypass
    endgenerate


    assign p4_bypass_timer_enable = (p4_proc_regs[1].p4_bypass_config.p4_bypass_enable ^ p4_bypass_enable) &&
                                     axis_to_bypass_mux.sop;

    always @(posedge core_clk) begin
        if (!p4_bypass_timer_enable)
            p4_bypass_timer <= 0;
        else if (axis_to_p4_drop_p[0].tready && axis_to_p4_drop_p[1].tready) // stall timer when split_join stalls.
            p4_bypass_timer <= p4_bypass_timer+1;

        if (!core_rstn)
            p4_bypass_enable <= 0;
        else if (p4_bypass_timer == 2*FIFO_DEPTH) // Double timer threshold for margin (due to pipelining).
            p4_bypass_enable <= p4_proc_regs[1].p4_bypass_config.p4_bypass_enable;
    end

    // bypass mux instantation (used to bypass p4 processor, when enabled).
    axi4s_intf_bypass_mux #(
        .PIPE_STAGES(1)
    ) bypass_mux (
        .from_tx    (axis_to_bypass_mux),
        .to_block   (_axis_to_vitisnetp4),
        .from_block (_axis_from_vitisnetp4),
        .to_rx      (_axis_from_bypass_mux),
        .bypass     (p4_bypass_enable)
    );


    // ----------------------------------------------------------------
    // SDnet block supporting logic.
    // ----------------------------------------------------------------
    // metadata type definitions (from ip/<app_name>/vitisnetp4_0/src/verilog/vitisnetp4_0_pkg.sv).
    // --- metadata_to_vitisnetp4 ---
    assign _axis_to_vitisnetp4_tuser = _axis_to_vitisnetp4.tuser;

    always_comb begin
        user_metadata_to_vitisnetp4.timestamp_ns      =      _axis_to_vitisnetp4_tuser.timestamp;
        user_metadata_to_vitisnetp4_pid.proc_port     = _axis_to_vitisnetp4_tuser.proc_port;
        user_metadata_to_vitisnetp4_pid.payload_ptr   = _axis_to_vitisnetp4_tuser.split_join.pid;
        user_metadata_to_vitisnetp4.pid               = {'0, user_metadata_to_vitisnetp4_pid};
        user_metadata_to_vitisnetp4.ingress_port      =      _axis_to_vitisnetp4.tid;
        user_metadata_to_vitisnetp4.egress_port       = {UNSET, _axis_to_vitisnetp4.tid[0]}; // axis_to_vitisnetp4.tdest;
        user_metadata_to_vitisnetp4.truncate_enable   =      _axis_to_vitisnetp4_tuser.trunc.enable;
        user_metadata_to_vitisnetp4.truncate_length   =      _axis_to_vitisnetp4_tuser.trunc.length;
        user_metadata_to_vitisnetp4.rss_enable        =      _axis_to_vitisnetp4_tuser.smartnic_meta.rss_enable;
        user_metadata_to_vitisnetp4.rss_entropy       =      _axis_to_vitisnetp4_tuser.smartnic_meta.rss_entropy;
        user_metadata_to_vitisnetp4.drop_reason       = 0;
        user_metadata_to_vitisnetp4.scratch           = 0;

        user_metadata_to_vitisnetp4_valid = axis_to_vitisnetp4.tvalid && axis_to_vitisnetp4.sop;
    end

    // TID/TDEST/TUSER not needed towards VitisNetP4 IP
    axi4s_intf_set_meta axi4s_intf_set_meta_to_vitisnet (
        .from_tx (_axis_to_vitisnetp4),
        .to_rx   (axis_to_vitisnetp4)
    );

    // --- metadata_from_vitisnetp4 ---
    always @(posedge core_clk)
        if (user_metadata_from_vitisnetp4_valid)
            user_metadata_from_vitisnetp4_latch <= user_metadata_from_vitisnetp4;

    always_comb begin
        case (user_metadata_from_vitisnetp4.egress_port[0])
            1'b0: axis_from_vitisnetp4_tdest.encoded.num = P0;
            1'b1: axis_from_vitisnetp4_tdest.encoded.num = P1;
        endcase

        case (user_metadata_from_vitisnetp4.egress_port[3:1])
            3'h0: axis_from_vitisnetp4_tdest.encoded.typ = PHY;
            3'h1: axis_from_vitisnetp4_tdest.encoded.typ = PF;
            3'h2: axis_from_vitisnetp4_tdest.encoded.typ = VF0;
            3'h3: axis_from_vitisnetp4_tdest.encoded.typ = APP_IGR;
            3'h4: axis_from_vitisnetp4_tdest.encoded.typ = VF2; // reserved for testing.
            3'h5: axis_from_vitisnetp4_tdest.encoded.typ = UNSET;
            3'h6: axis_from_vitisnetp4_tdest.encoded.typ = UNSET;
            3'h7: axis_from_vitisnetp4_tdest.encoded.typ = UNSET;
        endcase
    end

    always @(posedge core_clk)
        if (user_metadata_from_vitisnetp4_valid)
            axis_from_vitisnetp4_tdest_latch <= axis_from_vitisnetp4_tdest;

    assign _axis_from_vitisnetp4.tdest              = user_metadata_from_vitisnetp4_valid ?
                                                      axis_from_vitisnetp4_tdest :
                                                      axis_from_vitisnetp4_tdest_latch;

    assign _axis_from_vitisnetp4.tid                = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.ingress_port :
                                                      user_metadata_from_vitisnetp4_latch.ingress_port;

    assign user_metadata_from_vitisnetp4_pid = user_metadata_from_vitisnetp4.pid;
    assign _axis_from_vitisnetp4_tuser.split_join.pid = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4_pid.payload_ptr :
                                                      user_metadata_from_vitisnetp4_latch.pid;
    assign _axis_from_vitisnetp4_tuser.split_join.hdr_tlast = 1'b0;
    assign _axis_from_vitisnetp4_tuser.proc_port = user_metadata_from_vitisnetp4_pid.proc_port;

    assign _axis_from_vitisnetp4_tuser.trunc.enable = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.truncate_enable :
                                                      user_metadata_from_vitisnetp4_latch.truncate_enable;

    assign _axis_from_vitisnetp4_tuser.trunc.length = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.truncate_length :
                                                      user_metadata_from_vitisnetp4_latch.truncate_length;

    assign _axis_from_vitisnetp4_tuser.smartnic_meta.rss_enable  = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.rss_enable :
                                                      user_metadata_from_vitisnetp4_latch.rss_enable;

    assign _axis_from_vitisnetp4_tuser.smartnic_meta.rss_entropy = user_metadata_from_vitisnetp4_valid ?
                                                      user_metadata_from_vitisnetp4.rss_entropy :
                                                      user_metadata_from_vitisnetp4_latch.rss_entropy;
    assign _axis_from_vitisnetp4_tuser.timestamp = 'x;

    assign _axis_from_vitisnetp4.tuser = _axis_from_vitisnetp4_tuser;

    assign _axis_from_vitisnetp4.tvalid  = axis_from_vitisnetp4.tvalid;
    assign _axis_from_vitisnetp4.tlast   = axis_from_vitisnetp4.tlast;
    assign _axis_from_vitisnetp4.tkeep   = axis_from_vitisnetp4.tkeep;
    assign _axis_from_vitisnetp4.tdata   = axis_from_vitisnetp4.tdata;

    assign axis_from_vitisnetp4.tready   = _axis_from_vitisnetp4.tready;


endmodule: p4_proc
