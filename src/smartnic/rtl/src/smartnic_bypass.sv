module smartnic_bypass #(
    parameter int  NUM_CMAC = 2,
    parameter int  MAX_PKT_LEN = 9100
) (
    input logic    core_clk,
    input logic    core_rstn,

    axi4s_intf.rx  axis_core_to_bypass [NUM_CMAC],
    axi4s_intf.tx  axis_bypass_to_core [NUM_CMAC],

    axi4l_intf.peripheral   axil_to_drops_to_bypass [NUM_CMAC],
    axi4l_intf.peripheral   axil_to_probe_to_bypass [NUM_CMAC],

    input logic    bypass_swap_paths
);
    import smartnic_pkg::*;

    // ----------------------------------------------------------------
    //  axi4l and axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4l_intf  axil_to_ovfl_to_bypass [NUM_CMAC] ();
    axi4l_intf  axil_to_fifo_to_bypass [NUM_CMAC] ();

    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))  axis_core_to_bypass_p [NUM_CMAC] (.aclk(core_clk));

    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID)) _axis_core_to_bypass_p [NUM_CMAC] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_igr_sw_drop      [NUM_CMAC] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_to_bypass_fifo   [NUM_CMAC] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_from_bypass_fifo [NUM_CMAC] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_to_bypass_drop   [NUM_CMAC] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_bypass_demux_in  [NUM_CMAC] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_bypass_demux_out [NUM_CMAC][2] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_bypass_mux_in    [NUM_CMAC][2] (.aclk(core_clk));

    logic  srst;

    logic  igr_sw_drop_pkt  [NUM_CMAC];
    logic  bypass_demux_sel [NUM_CMAC];

    assign srst = !core_rstn;

    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__bypass
        igr_tdest_t axis_core_to_bypass_p_tdest;

        logic axis_core_to_bypass_p_sop;
        logic axis_from_bypass_fifo_sop;

        axi4s_tready_pipe axis_core_to_bypass_pipe (
            .from_tx(axis_core_to_bypass[i]), .to_rx(axis_core_to_bypass_p[i]));

        packet_sop packet_sop_core_to_bypass_p (
            .clk (core_clk),
            .srst,
            .vld (axis_core_to_bypass_p[i].tvalid),
            .rdy (axis_core_to_bypass_p[i].tready),
            .eop (axis_core_to_bypass_p[i].tlast),
            .sop (axis_core_to_bypass_p_sop)
        );

        // ingress switch drop pkt logic.  deletes packets that have tdest == DROP code point.
        assign axis_core_to_bypass_p_tdest = axis_core_to_bypass_p[i].tdest;
        assign igr_sw_drop_pkt[i] = axis_core_to_bypass_p[i].tvalid && axis_core_to_bypass_p_sop &&
                                    axis_core_to_bypass_p_tdest.encoded == DROP;

        assign  axis_core_to_bypass_p[i].tready  = _axis_core_to_bypass_p[i].tready;

        assign _axis_core_to_bypass_p[i].tvalid  =  axis_core_to_bypass_p[i].tvalid;
        assign _axis_core_to_bypass_p[i].tdata   =  axis_core_to_bypass_p[i].tdata;
        assign _axis_core_to_bypass_p[i].tkeep   =  axis_core_to_bypass_p[i].tkeep;
        assign _axis_core_to_bypass_p[i].tlast   =  axis_core_to_bypass_p[i].tlast;
        assign _axis_core_to_bypass_p[i].tid     =  axis_core_to_bypass_p[i].tid;
        assign _axis_core_to_bypass_p[i].tuser   =  '0;
        assign _axis_core_to_bypass_p[i].tdest   = {'0, axis_core_to_bypass_p[i].tid[0]};  // assign tdest to CMAC0/CMAC1 by default.

        // igr_sw_drop axi4s_drop instantiation.
        axi4s_drop igr_sw_drop_0 (
           .clk         (core_clk),
           .srst,
           .axi4s_in    (_axis_core_to_bypass_p[i]),
           .axi4s_out   (axis_igr_sw_drop[i]),
           .axil_if     (axil_to_drops_to_bypass[i]),
           .drop_pkt    (igr_sw_drop_pkt[i])
        );

        axi4s_intf_pipe axis_to_bypass_pipe_0 (
            .srst, .from_tx(axis_igr_sw_drop[i]), .to_rx(axis_to_bypass_fifo[i]));

        axi4s_pkt_fifo_sync #(
           .FIFO_DEPTH     (512),
           .MAX_PKT_LEN    (MAX_PKT_LEN)
        ) bypass_fifo (
           .srst,
           .axi4s_in       (axis_to_bypass_fifo[i]),
           .axi4s_out      (axis_from_bypass_fifo[i]),
           .axil_to_probe  (axil_to_probe_to_bypass[i]),
           .axil_to_ovfl   (axil_to_ovfl_to_bypass[i]),
           .axil_if        (axil_to_fifo_to_bypass[i])
        );

        axi4l_intf_controller_term axi4l_to_ovfl_to_bypass_term  (.axi4l_if (axil_to_ovfl_to_bypass[i]));
        axi4l_intf_controller_term axi4l_to_fifo_to_bypass_term  (.axi4l_if (axil_to_fifo_to_bypass[i]));

        axi4s_full_pipe from_bypass_pipe_0 (
            .srst,
            .from_tx(axis_from_bypass_fifo[i]),
            .to_rx(axis_bypass_demux_in[i]) );

        packet_sop packet_sop_from_bypass_fifo (
            .clk (core_clk),
            .srst,
            .vld (axis_from_bypass_fifo[i].tvalid),
            .rdy (axis_from_bypass_fifo[i].tready),
            .eop (axis_from_bypass_fifo[i].tlast),
            .sop (axis_from_bypass_fifo_sop)
        );

        always @(posedge core_clk)
            if (srst)
                bypass_demux_sel[i] <= 0;
            else if (axis_from_bypass_fifo[i].tready && axis_from_bypass_fifo[i].tvalid &&
                     axis_from_bypass_fifo_sop)
                bypass_demux_sel[i] <= bypass_swap_paths;

        axi4s_intf_demux #(.N(2)) axi4s_bypass_demux (
            .srst,
            .from_tx (axis_bypass_demux_in[i]),
            .to_rx   (axis_bypass_demux_out[i]),
            .sel     (bypass_demux_sel[i])
        );

        axi4s_mux #(.N(2)) axi4s_bypass_mux (
            .srst,
            .axi4s_in  (axis_bypass_mux_in[i]),  // mux_in assignments below
            .axi4s_out (axis_bypass_to_core[i])
        );

    end : g__bypass
    endgenerate

    // mux_in assignments.  support for 'pass-through' and 'swap-paths' modes.
    axi4s_intf_connector axi4s_bypass_mux_in_0_pipe_0 (
        .from_tx(axis_bypass_demux_out[0][0]), .to_rx(axis_bypass_mux_in[0][0]));
    axi4s_intf_connector axi4s_bypass_mux_in_1_pipe_1 (
        .from_tx(axis_bypass_demux_out[0][1]), .to_rx(axis_bypass_mux_in[1][1]));
    axi4s_intf_connector axi4s_bypass_mux_in_1_pipe_0 (
        .from_tx(axis_bypass_demux_out[1][0]), .to_rx(axis_bypass_mux_in[1][0]));
    axi4s_intf_connector axi4s_bypass_mux_in_0_pipe_1 (
        .from_tx(axis_bypass_demux_out[1][1]), .to_rx(axis_bypass_mux_in[0][1]));

endmodule // smartnic_bypass
