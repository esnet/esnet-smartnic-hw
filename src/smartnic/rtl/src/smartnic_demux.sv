module smartnic_demux
#(
    parameter int  NUM_CMAC = 2,
    parameter int  MAX_PKT_LEN = 9100
) (
    input logic     core_clk,
    input logic     core_rstn,

    axi4s_intf.rx   axis_bypass_to_core [NUM_CMAC],
    axi4s_intf.rx   axis_app_to_core    [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_cmac   [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_host   [NUM_CMAC],

    smartnic_reg_intf.peripheral   smartnic_regs
);
    import smartnic_pkg::*;

    //  axi4l interface instantiations
    axi4l_intf  axil_probe_to_fifo [NUM_CMAC][2] ();
    axi4l_intf  axil_ovfl_to_fifo  [NUM_CMAC][2] ();
    axi4l_intf  axil_to_fifo       [NUM_CMAC][2] ();

    // ----------------------------------------------------------------
    //  axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  bypass_demux_out [2] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                  .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))   axis_app_to_core_p [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                  .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  port_demux_out  [NUM_CMAC][2] (.aclk(core_clk), .aresetn(core_rstn));
    axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                  .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  port_demux_out_fifo  [NUM_CMAC][2] (.aclk(core_clk), .aresetn(core_rstn));
    axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                  .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  egr_mux_in    [NUM_CMAC][3] (.aclk(core_clk), .aresetn(core_rstn));
    axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                  .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  egr_mux_out   [NUM_CMAC]    (.aclk(core_clk), .aresetn(core_rstn));
    axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                  .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  egr_mux_out_p [NUM_CMAC]    (.aclk(core_clk), .aresetn(core_rstn));
    axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                  .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  egr_demux_out [NUM_CMAC][2] (.aclk(core_clk), .aresetn(core_rstn));

    axi4s_intf  #(.TUSER_WID(TUSER_SMARTNIC_META_WID),
                  .DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  _axis_core_to_cmac [NUM_CMAC] (.aclk(core_clk), .aresetn(core_rstn));


    logic smartnic_demux_out_sel [NUM_CMAC];


    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__mux_demux
        axi4s_intf  #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID), .TUSER_WID(TUSER_SMARTNIC_META_WID))  __axis_bypass_to_core (.aclk(core_clk), .aresetn(core_rstn));
        tuser_smartnic_meta_t axis_core_to_host_tuser;

        axi4s_intf_connector axis_app_to_core_pipe (
            .from_tx(axis_app_to_core[i]), .to_rx(axis_app_to_core_p[i]));

        axi4s_intf_demux #(.N(2)) axi4s_port_demux (
            .from_tx (axis_app_to_core_p[i]),
            .to_rx   (port_demux_out[i]),
            .sel     (axis_app_to_core_p[i].tdest[0])  // tdest lsb determines dest port (0:CMAC0, 1:CMAC1).
        );

        axi4s_pkt_fifo_sync #(
           .FIFO_DEPTH     (512),
           .MAX_PKT_LEN    (MAX_PKT_LEN)
        ) port_demux_out_fifo_0 (
           .srst           (1'b0),
           .axi4s_in       (port_demux_out[i][0]),
           .axi4s_out      (port_demux_out_fifo[i][0]),
           .axil_to_probe  (axil_probe_to_fifo[i][0]),
           .axil_to_ovfl   (axil_ovfl_to_fifo[i][0]),
           .axil_if        (axil_to_fifo[i][0])
        );

        axi4l_intf_controller_term axi4l_probe_to_fifo_term_0 (.axi4l_if (axil_probe_to_fifo[i][0]));
        axi4l_intf_controller_term axi4l_ovfl_to_fifo_term_0  (.axi4l_if (axil_ovfl_to_fifo[i][0]));
        axi4l_intf_controller_term axi4l_to_fifo_term_0       (.axi4l_if (axil_to_fifo[i][0]));

        axi4s_pkt_fifo_sync #(
           .FIFO_DEPTH     (512),
           .MAX_PKT_LEN    (MAX_PKT_LEN)
        ) port_demux_out_fifo_1 (
           .srst           (1'b0),
           .axi4s_in       (port_demux_out[i][1]),
           .axi4s_out      (port_demux_out_fifo[i][1]),
           .axil_to_probe  (axil_probe_to_fifo[i][1]),
           .axil_to_ovfl   (axil_ovfl_to_fifo[i][1]),
           .axil_if        (axil_to_fifo[i][1])
        );

        axi4l_intf_controller_term axi4l_probe_to_fifo_term_1 (.axi4l_if (axil_probe_to_fifo[i][1]));
        axi4l_intf_controller_term axi4l_ovfl_to_fifo_term_1  (.axi4l_if (axil_ovfl_to_fifo[i][1]));
        axi4l_intf_controller_term axi4l_to_fifo_term_1       (.axi4l_if (axil_to_fifo[i][1]));


        axi4s_intf_set_meta #(
            .TID_WID (PORT_WID),
            .TDEST_WID (PORT_WID),
            .TUSER_WID (TUSER_SMARTNIC_META_WID)
        ) axi4s_intf_set_meta__bypass_to_core (
            .from_tx ( axis_bypass_to_core[i] ),
            .to_rx   ( __axis_bypass_to_core ),
            .tid     ( axis_bypass_to_core[i].tid ),
            .tdest   ( axis_bypass_to_core[i].tdest ),
            .tuser   ( '0 )
        );

        // axi4s_egr_mux connections. Note crossed connections from each demux_out_fifo instance.
        axi4s_full_pipe axi4s_egr_mux_in_pipe_0 (
            .from_tx(__axis_bypass_to_core),    .to_rx(egr_mux_in[i][0]));
        axi4s_full_pipe axi4s_egr_mux_in_pipe_1 (
            .from_tx(port_demux_out_fifo[0][i]), .to_rx(egr_mux_in[i][1]));
        axi4s_full_pipe axi4s_egr_mux_in_pipe_2 (
            .from_tx(port_demux_out_fifo[1][i]), .to_rx(egr_mux_in[i][2]));

        axi4s_mux #(.N(3)) axi4s_egr_mux (
            .axi4s_in  (egr_mux_in[i]),
            .axi4s_out (egr_mux_out[i])
        ); 

        axi4s_intf_pipe axi4s_egr_mux_out_pipe (
            .from_tx(egr_mux_out[i]), .to_rx(egr_mux_out_p[i]));

        always @(posedge core_clk)
            if (!core_rstn)
                smartnic_demux_out_sel[i] <= 0;
	    else if (egr_mux_out[i].tready && egr_mux_out[i].tvalid && egr_mux_out[i].sop)
                smartnic_demux_out_sel[i] <= smartnic_regs.smartnic_demux_out_sel[i];

        axi4s_intf_demux #(.N(2)) axi4s_egr_demux (
            .from_tx (egr_mux_out_p[i]),
            .to_rx   (egr_demux_out[i]),
            .sel     (smartnic_demux_out_sel[i])
        ); 

        axi4s_intf_connector axi4s_egr_demux_out_pipe_0 (
            .from_tx(egr_demux_out[i][0]), .to_rx(_axis_core_to_cmac[i]));
        axi4s_intf_connector axi4s_egr_demux_out_pipe_1 (
            .from_tx(egr_demux_out[i][1]), .to_rx(axis_core_to_host[i]));

        assign _axis_core_to_cmac[i].tready = axis_core_to_cmac[i].tready;

        assign axis_core_to_cmac[i].tvalid  = _axis_core_to_cmac[i].tvalid;
        assign axis_core_to_cmac[i].tdata   = _axis_core_to_cmac[i].tdata;
        assign axis_core_to_cmac[i].tkeep   = _axis_core_to_cmac[i].tkeep;
        assign axis_core_to_cmac[i].tlast   = _axis_core_to_cmac[i].tlast;
        assign axis_core_to_cmac[i].tid     = _axis_core_to_cmac[i].tid;
        assign axis_core_to_cmac[i].tuser   = '0;
        assign axis_core_to_cmac[i].tdest   = _axis_core_to_cmac[i].tdest;

    end : g__mux_demux
    endgenerate

endmodule // smartnic_demux
