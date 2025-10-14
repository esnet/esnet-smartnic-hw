module smartnic_mux
#(
    parameter int  NUM_CMAC = 2
) (
    input logic        core_clk,
    input logic        core_rstn,

    axi4s_intf.rx   axis_cmac_to_core   [NUM_CMAC],
    axi4s_intf.rx   axis_host_to_core   [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_app    [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_bypass [NUM_CMAC],

    input smartnic_reg_pkg::reg_smartnic_mux_out_sel_t  mux_out_sel [4],
    input logic     tpause
);
    import smartnic_pkg::*;

    // ----------------------------------------------------------------
    //  axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))        axis_cmac_to_core_p [NUM_CMAC]    (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))        axis_host_to_core_p [NUM_CMAC]    (.aclk(core_clk));

    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))  _axis_cmac_to_core_p [NUM_CMAC]    (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))  _axis_host_to_core_p [NUM_CMAC]    (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))  igr_mux_in           [NUM_CMAC][2] (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))  igr_mux_out          [NUM_CMAC]    (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))  igr_demux_out        [NUM_CMAC][2] (.aclk(core_clk));

    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))  _axis_core_to_app    [NUM_CMAC]    (.aclk(core_clk));
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(IGR_TDEST_WID))  _axis_core_to_bypass [NUM_CMAC]    (.aclk(core_clk));

    logic  srst;

    igr_tdest_t smartnic_mux_out_sel [2*NUM_CMAC];

    logic  igr_demux_sel  [NUM_CMAC];

    assign srst = !core_rstn;

    // ingress mux/demux logic.
    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__mux_demux
        axi4s_intf_pipe cmac_to_core_pipe (.srst, .from_tx(axis_cmac_to_core[i]), .to_rx(axis_cmac_to_core_p[i]));
        axi4s_intf_pipe host_to_core_pipe (.srst, .from_tx(axis_host_to_core[i]), .to_rx(axis_host_to_core_p[i]));

        logic axis_cmac_to_core_sop;
        logic axis_host_to_core_sop;

        igr_tdest_t igr_mux_out_tdest;

        packet_sop packet_sop_cmac_to_core (
            .clk (core_clk),
            .srst,
            .vld (axis_cmac_to_core[i].tvalid),
            .rdy (axis_cmac_to_core[i].tready),
            .eop (axis_cmac_to_core[i].tlast),
            .sop (axis_cmac_to_core_sop)
        );

        packet_sop packet_sop_host_to_core (
            .clk (core_clk),
            .srst,
            .vld (axis_host_to_core[i].tvalid),
            .rdy (axis_host_to_core[i].tready),
            .eop (axis_host_to_core[i].tlast),
            .sop (axis_host_to_core_sop)
        );

        // ingress tdest configuration logic.
        always @(posedge core_clk) begin
            if (srst) begin
                smartnic_mux_out_sel[i]   <= DROP;
                smartnic_mux_out_sel[2+i] <= DROP;
            end else begin
                if (axis_cmac_to_core_sop)
                    smartnic_mux_out_sel[i] <= mux_out_sel[i].value;

                if (axis_host_to_core_sop)
                    smartnic_mux_out_sel[2+i] <= mux_out_sel[2+i].value;
            end
        end

        assign axis_cmac_to_core_p[i].tready   = _axis_cmac_to_core_p[i].tready;

        assign _axis_cmac_to_core_p[i].tvalid  = axis_cmac_to_core_p[i].tvalid;
        assign _axis_cmac_to_core_p[i].tdata   = axis_cmac_to_core_p[i].tdata;
        assign _axis_cmac_to_core_p[i].tkeep   = axis_cmac_to_core_p[i].tkeep;
        assign _axis_cmac_to_core_p[i].tlast   = axis_cmac_to_core_p[i].tlast;
        assign _axis_cmac_to_core_p[i].tid     = axis_cmac_to_core_p[i].tid;
        assign _axis_cmac_to_core_p[i].tuser   = axis_cmac_to_core_p[i].tuser;
        assign _axis_cmac_to_core_p[i].tdest   = smartnic_mux_out_sel[i];

        assign axis_host_to_core_p[i].tready   = _axis_host_to_core_p[i].tready;

        assign _axis_host_to_core_p[i].tvalid  = axis_host_to_core_p[i].tvalid;
        assign _axis_host_to_core_p[i].tdata   = axis_host_to_core_p[i].tdata;
        assign _axis_host_to_core_p[i].tkeep   = axis_host_to_core_p[i].tkeep;
        assign _axis_host_to_core_p[i].tlast   = axis_host_to_core_p[i].tlast;
        assign _axis_host_to_core_p[i].tid     = axis_host_to_core_p[i].tid;
        assign _axis_host_to_core_p[i].tuser   = axis_host_to_core_p[i].tuser;
        assign _axis_host_to_core_p[i].tdest   = smartnic_mux_out_sel[2+i];

        axi4s_intf_connector axi4s_igr_mux_in_pipe_0 (.from_tx(_axis_cmac_to_core_p[i]), .to_rx(igr_mux_in[i][0]));
        axi4s_intf_connector axi4s_igr_mux_in_pipe_1 (.from_tx(_axis_host_to_core_p[i]), .to_rx(igr_mux_in[i][1]));

        axi4s_mux #(.N(2)) axi4s_igr_mux (
            .srst,
            .axi4s_in  (igr_mux_in[i]),
            .axi4s_out (igr_mux_out[i])
        ); 

        // BYPASS and DROP pkts go to igr_demux_out[1].
        assign igr_mux_out_tdest = igr_mux_out[i].tdest;
        assign igr_demux_sel[i] = (igr_mux_out_tdest.encoded == BYPASS) || (igr_mux_out_tdest.encoded == DROP);

        axi4s_intf_demux #(.N(2)) axi4s_igr_demux (
            .srst,
            .from_tx (igr_mux_out[i]),
            .to_rx   (igr_demux_out[i]),
            .sel     (igr_demux_sel[i])
        ); 

        axi4s_intf_connector axis_core_to_app_pipe (.from_tx(igr_demux_out[i][0]), .to_rx(_axis_core_to_app[i]));

        assign _axis_core_to_app[i].tready = axis_core_to_app[i].tready;

        assign axis_core_to_app[i].tvalid  = _axis_core_to_app[i].tvalid;
        assign axis_core_to_app[i].tdata   = _axis_core_to_app[i].tdata;
        assign axis_core_to_app[i].tkeep   = _axis_core_to_app[i].tkeep;
        assign axis_core_to_app[i].tlast   = _axis_core_to_app[i].tlast;
        assign axis_core_to_app[i].tid     = _axis_core_to_app[i].tid;
        assign axis_core_to_app[i].tuser   = '0;
        assign axis_core_to_app[i].tdest   = {'0, _axis_core_to_app[i].tid[0]};  // assign tdest to CMAC0/CMAC1 by default.

        axi4s_intf_connector axis_core_to_bypass_pipe (.from_tx(igr_demux_out[i][1]), .to_rx(_axis_core_to_bypass[i]));

        // tpause logic for bypass ingress traffic (for test purposes).
        assign _axis_core_to_bypass[i].tready = axis_core_to_bypass[i].tready && !tpause;

        assign axis_core_to_bypass[i].tvalid  = _axis_core_to_bypass[i].tvalid && !tpause;
        assign axis_core_to_bypass[i].tdata   = _axis_core_to_bypass[i].tdata;
        assign axis_core_to_bypass[i].tkeep   = _axis_core_to_bypass[i].tkeep;
        assign axis_core_to_bypass[i].tlast   = _axis_core_to_bypass[i].tlast;
        assign axis_core_to_bypass[i].tid     = _axis_core_to_bypass[i].tid;
        assign axis_core_to_bypass[i].tuser   = '0;
        assign axis_core_to_bypass[i].tdest   = _axis_core_to_bypass[i].tdest;

    end : g__mux_demux
    endgenerate

endmodule // smartnic_mux
