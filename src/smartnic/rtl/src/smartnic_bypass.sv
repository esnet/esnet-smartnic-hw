module smartnic_bypass #(
    parameter int  NUM_CMAC = 2,
    parameter int  MAX_PKT_LEN = 9100
) (
    input logic    core_clk,
    input logic    core_rstn,

    axi4s_intf.rx  axis_core_to_bypass [NUM_CMAC],
    axi4s_intf.tx  axis_bypass_to_core [NUM_CMAC],

    axi4l_intf.peripheral   axil_to_drops_to_bypass   [NUM_CMAC],
    axi4l_intf.peripheral   axil_to_probe_to_bypass   [NUM_CMAC],
    axi4l_intf.peripheral   axil_to_drops_from_bypass [NUM_CMAC],

    smartnic_reg_intf.peripheral   smartnic_regs
);
    import smartnic_pkg::*;

    // ----------------------------------------------------------------
    //  axi4l and axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4l_intf  axil_to_ovfl_to_bypass [NUM_CMAC] ();
    axi4l_intf  axil_to_fifo_to_bypass [NUM_CMAC] ();

    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_core_to_bypass_p   [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_igr_sw_drop        [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_to_bypass_fifo     [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_from_bypass_fifo   [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_from_bypass_fifo_p [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_to_bypass_drop     [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_bypass_demux_in    [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_bypass_demux_in_p  [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_bypass_demux_out   [NUM_CMAC][2] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  axis_bypass_mux_in      [NUM_CMAC][2] ();

    logic  igr_sw_drop_pkt  [NUM_CMAC];
    logic  bypass_drop_pkt  [NUM_CMAC];
    logic  bypass_demux_sel [NUM_CMAC];

    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__bypass
        axi4s_tready_pipe axis_core_to_bypass_pipe (.axi4s_if_from_tx(axis_core_to_bypass[i]), .axi4s_if_to_rx(axis_core_to_bypass_p[i]));

        // ingress switch drop pkt logic.  deletes packets that have tdest == DROP code point.
        assign igr_sw_drop_pkt[i] = axis_core_to_bypass_p[i].tvalid && axis_core_to_bypass_p[i].sop &&
                                    axis_core_to_bypass_p[i].tdest == DROP;

        // igr_sw_drop axi4s_drop instantiation.
        axi4s_drop igr_sw_drop_0 (
           .axi4s_in    (axis_core_to_bypass_p[i]),
           .axi4s_out   (axis_igr_sw_drop[i]),
           .axil_if     (axil_to_drops_to_bypass[i]),
           .drop_pkt    (igr_sw_drop_pkt[i])
        );

        axi4s_intf_pipe axis_to_bypass_pipe_0 (.axi4s_if_from_tx(axis_igr_sw_drop[i]), .axi4s_if_to_rx(axis_to_bypass_fifo[i]));

        axi4s_pkt_fifo_sync #(
           .FIFO_DEPTH     (512),
           .MAX_PKT_LEN    (MAX_PKT_LEN)
        ) bypass_fifo (
           .srst           (1'b0),
           .axi4s_in       (axis_to_bypass_fifo[i]),
           .axi4s_out      (axis_from_bypass_fifo[i]),
           .axil_to_probe  (axil_to_probe_to_bypass[i]),
           .axil_to_ovfl   (axil_to_ovfl_to_bypass[i]),
           .axil_if        (axil_to_fifo_to_bypass[i])
        );

        axi4l_intf_controller_term axi4l_to_ovfl_to_bypass_term  (.axi4l_if (axil_to_ovfl_to_bypass[i]));
        axi4l_intf_controller_term axi4l_to_fifo_to_bypass_term  (.axi4l_if (axil_to_fifo_to_bypass[i]));

        axi4s_full_pipe from_bypass_pipe_0 (.axi4s_if_from_tx(axis_from_bypass_fifo[i]), .axi4s_if_to_rx(axis_from_bypass_fifo_p[i]));

        // Bypass path assignments.  tdest = tid.
        assign axis_from_bypass_fifo_p[i].tready = axis_to_bypass_drop[i].tready;

        assign axis_to_bypass_drop[i].aclk    = axis_from_bypass_fifo_p[i].aclk;
        assign axis_to_bypass_drop[i].aresetn = axis_from_bypass_fifo_p[i].aresetn;
        assign axis_to_bypass_drop[i].tvalid  = axis_from_bypass_fifo_p[i].tvalid;
        assign axis_to_bypass_drop[i].tdata   = axis_from_bypass_fifo_p[i].tdata;
        assign axis_to_bypass_drop[i].tkeep   = axis_from_bypass_fifo_p[i].tkeep;
        assign axis_to_bypass_drop[i].tlast   = axis_from_bypass_fifo_p[i].tlast;
        assign axis_to_bypass_drop[i].tid     = axis_from_bypass_fifo_p[i].tid;
        assign axis_to_bypass_drop[i].tuser   = axis_from_bypass_fifo_p[i].tuser;
        assign axis_to_bypass_drop[i].tdest   = axis_from_bypass_fifo_p[i].tid;

        // bypass packet drop logic.  deletes packets that have tdest == tid (to prevent switching loops).
        assign bypass_drop_pkt[i] = smartnic_regs.switch_config.drop_pkt_loop &&
                                    axis_to_bypass_drop[i].tvalid && axis_to_bypass_drop[i].sop &&
                                    axis_to_bypass_drop[i].tdest == axis_to_bypass_drop[i].tid;

        // bypass packet drop instantiation.
        axi4s_drop bypass_drop_0 (
            .axi4s_in    (axis_to_bypass_drop[i]),
            .axi4s_out   (axis_bypass_demux_in[i]),
            .axil_if     (axil_to_drops_from_bypass[i]),
            .drop_pkt    (bypass_drop_pkt[i])
        );

        axi4s_intf_pipe axi4s_bypass_demux_in_pipe (.axi4s_if_from_tx(axis_bypass_demux_in[i]), .axi4s_if_to_rx(axis_bypass_demux_in_p[i]));

        always @(posedge core_clk)
            if (!core_rstn)
                bypass_demux_sel[i] <= 0;
            else if (axis_bypass_demux_in[i].tready && axis_bypass_demux_in[i].tvalid && axis_bypass_demux_in[i].sop) 
                bypass_demux_sel[i] <= smartnic_regs.bypass_config.switch_paths;

        axi4s_intf_demux #(.N(2)) axi4s_bypass_demux (
            .axi4s_in  (axis_bypass_demux_in_p[i]),
            .axi4s_out (axis_bypass_demux_out[i]),
            .sel       (bypass_demux_sel[i])
        );

        axi4s_mux #(.N(2)) axi4s_bypass_mux (
            .axi4s_in  (axis_bypass_mux_in[i]),  // see mux_in assignments below. supports 'pass-through' and 'switch-paths' modes.
            .axi4s_out (axis_bypass_to_core[i])
        );

    end : g__bypass
    endgenerate

    axi4s_intf_connector axi4s_bypass_mux_in_0_pipe_0 (.axi4s_from_tx(axis_bypass_demux_out[0][0]), .axi4s_to_rx(axis_bypass_mux_in[0][0]));
    axi4s_intf_connector axi4s_bypass_mux_in_1_pipe_1 (.axi4s_from_tx(axis_bypass_demux_out[0][1]), .axi4s_to_rx(axis_bypass_mux_in[1][1]));
    axi4s_intf_connector axi4s_bypass_mux_in_1_pipe_0 (.axi4s_from_tx(axis_bypass_demux_out[1][0]), .axi4s_to_rx(axis_bypass_mux_in[1][0]));
    axi4s_intf_connector axi4s_bypass_mux_in_0_pipe_1 (.axi4s_from_tx(axis_bypass_demux_out[1][1]), .axi4s_to_rx(axis_bypass_mux_in[0][1]));

endmodule // smartnic_bypass
