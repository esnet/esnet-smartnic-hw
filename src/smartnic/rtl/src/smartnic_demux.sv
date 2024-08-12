module smartnic_demux
#(
    parameter int  NUM_CMAC = 2
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

    // ----------------------------------------------------------------
    //  axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  bypass_demux_out [2] ();

    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))   axis_app_to_core_p [NUM_CMAC] ();
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  _axis_app_to_core_p [NUM_CMAC] ();

    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  port_demux_out  [NUM_CMAC][2]  ();
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  egr_mux_in    [NUM_CMAC][3] ();
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  egr_mux_out   [NUM_CMAC]    ();
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  egr_mux_out_p [NUM_CMAC]    ();
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  egr_demux_out [NUM_CMAC][2] ();

    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  _axis_core_to_cmac [NUM_CMAC] ();
    axi4s_intf  #(.TUSER_T(tuser_smartnic_meta_t),
                  .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t))  _axis_core_to_host [NUM_CMAC] ();


    logic egr_demux_sel [NUM_CMAC];


    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__mux_demux
        axi4s_intf_pipe axis_app_to_core_pipe (.axi4s_if_from_tx(axis_app_to_core[i]), .axi4s_if_to_rx(axis_app_to_core_p[i]));

        assign axis_app_to_core_p[i].tready   = _axis_app_to_core_p[i].tready;

        assign _axis_app_to_core_p[i].aclk    = axis_app_to_core_p[i].aclk;
        assign _axis_app_to_core_p[i].aresetn = axis_app_to_core_p[i].aresetn;
        assign _axis_app_to_core_p[i].tvalid  = axis_app_to_core_p[i].tvalid;
        assign _axis_app_to_core_p[i].tdata   = axis_app_to_core_p[i].tdata;
        assign _axis_app_to_core_p[i].tkeep   = axis_app_to_core_p[i].tkeep;
        assign _axis_app_to_core_p[i].tlast   = axis_app_to_core_p[i].tlast;
        assign _axis_app_to_core_p[i].tid     = axis_app_to_core_p[i].tid;
        assign _axis_app_to_core_p[i].tuser   = axis_app_to_core_p[i].tuser;
        assign _axis_app_to_core_p[i].tdest   = axis_app_to_core_p[i].tdest == LOOPBACK ?
                                                                               axis_app_to_core_p[i].tid :
                                                                               axis_app_to_core_p[i].tdest.raw;

        axi4s_intf_demux #(.N(2)) axi4s_port_demux (
            .axi4s_in  (_axis_app_to_core_p[i]),
            .axi4s_out (port_demux_out[i]),
            .sel       (_axis_app_to_core_p[i].tdest[0])  // LSB of tdest determines destination port (0:CMAC0/PF0, 1:CMAC1/PF1).
        );

        axi4s_intf_pipe axi4s_egr_mux_in_pipe_0 (.axi4s_if_from_tx(axis_bypass_to_core[i]), .axi4s_if_to_rx(egr_mux_in[i][0]));
        axi4s_intf_pipe axi4s_egr_mux_in_pipe_1 (.axi4s_if_from_tx(port_demux_out[0][i]),   .axi4s_if_to_rx(egr_mux_in[i][1]));
        axi4s_intf_pipe axi4s_egr_mux_in_pipe_2 (.axi4s_if_from_tx(port_demux_out[1][i]),   .axi4s_if_to_rx(egr_mux_in[i][2]));

        axi4s_mux #(.N(3), .OUT_PIPE(1)) axi4s_egr_mux (
            .axi4s_in  (egr_mux_in[i]),
            .axi4s_out (egr_mux_out[i])
        ); 

        axi4s_intf_pipe axi4s_egr_mux_out_pipe (.axi4s_if_from_tx(egr_mux_out[i]), .axi4s_if_to_rx(egr_mux_out_p[i]));

        always @(posedge core_clk)
	    if (egr_mux_out[i].tready && egr_mux_out[i].tvalid && egr_mux_out[i].sop)
               egr_demux_sel[i] <= smartnic_regs.egr_demux_sel[i];

        axi4s_intf_demux #(.N(2)) axi4s_egr_demux (
            .axi4s_in  (egr_mux_out_p[i]),
            .axi4s_out (egr_demux_out[i]),
            .sel       (egr_demux_sel[i])
        ); 

        axi4s_intf_pipe axi4s_egr_demux_out_pipe_0 (.axi4s_if_from_tx(egr_demux_out[i][0]), .axi4s_if_to_rx(_axis_core_to_cmac[i]));
        axi4s_intf_pipe axi4s_egr_demux_out_pipe_1 (.axi4s_if_from_tx(egr_demux_out[i][1]), .axi4s_if_to_rx(_axis_core_to_host[i]));

        assign _axis_core_to_cmac[i].tready = axis_core_to_cmac[i].tready;

        assign axis_core_to_cmac[i].aclk    = _axis_core_to_cmac[i].aclk;
        assign axis_core_to_cmac[i].aresetn = _axis_core_to_cmac[i].aresetn;
        assign axis_core_to_cmac[i].tvalid  = _axis_core_to_cmac[i].tvalid;
        assign axis_core_to_cmac[i].tdata   = _axis_core_to_cmac[i].tdata;
        assign axis_core_to_cmac[i].tkeep   = _axis_core_to_cmac[i].tkeep;
        assign axis_core_to_cmac[i].tlast   = _axis_core_to_cmac[i].tlast;
        assign axis_core_to_cmac[i].tid     = _axis_core_to_cmac[i].tid;
        assign axis_core_to_cmac[i].tuser   = '0;
        assign axis_core_to_cmac[i].tdest   = _axis_core_to_cmac[i].tdest;

        assign _axis_core_to_host[i].tready = axis_core_to_host[i].tready;

        assign axis_core_to_host[i].aclk    = _axis_core_to_host[i].aclk;
        assign axis_core_to_host[i].aresetn = _axis_core_to_host[i].aresetn;
        assign axis_core_to_host[i].tvalid  = _axis_core_to_host[i].tvalid;
        assign axis_core_to_host[i].tdata   = _axis_core_to_host[i].tdata;
        assign axis_core_to_host[i].tkeep   = _axis_core_to_host[i].tkeep;
        assign axis_core_to_host[i].tlast   = _axis_core_to_host[i].tlast;
        assign axis_core_to_host[i].tid     = _axis_core_to_host[i].tid;
        assign axis_core_to_host[i].tuser.pid         = '0;
        assign axis_core_to_host[i].tuser.rss_enable  = _axis_core_to_host[i].tuser.rss_enable;
        assign axis_core_to_host[i].tuser.rss_entropy = _axis_core_to_host[i].tuser.rss_entropy;
        assign axis_core_to_host[i].tuser.hdr_tlast   = '0;
        assign axis_core_to_host[i].tdest   = _axis_core_to_host[i].tdest;

    end : g__mux_demux
    endgenerate

endmodule // smartnic_demux
