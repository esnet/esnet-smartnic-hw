module smartnic_host
#(
    parameter int  NUM_CMAC = 2,
    parameter int  HOST_NUM_IFS = 3
) (
    input logic        core_clk,
    input logic        core_rstn,

    axi4s_intf.rx   axis_host_to_core [NUM_CMAC],
    axi4s_intf.tx   axis_core_to_host [NUM_CMAC],

    axi4s_intf.rx   axis_core_to_host_mux   [NUM_CMAC][2],
    axi4s_intf.tx   axis_host_to_core_demux [NUM_CMAC][2],

    axi4l_intf.peripheral  axil_q_range_fail [NUM_CMAC],
    axi4l_intf.peripheral  axil_to_hash2qid  [NUM_CMAC],

    smartnic_reg_intf.peripheral   smartnic_regs
);

    import smartnic_pkg::*;

    // ----------------------------------------------------------------
    //  axi4s interface instantiations
    // ----------------------------------------------------------------
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(adpt_tx_tid_t), .TDEST_T(igr_tdest_t))  axis_host_to_core_p [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(igr_tdest_t))         axis_host_tid       [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(igr_tdest_t))         axis_host_tid_p     [NUM_CMAC] ();
    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(igr_tdest_t))         axis_q_range_fail   [NUM_CMAC] ();

    axi4s_intf  #(.DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t))
                                                                                     axis_hash2qid       [NUM_CMAC] ();

    //------------------------ tid assignment logic --------------
    logic host_if_sel [NUM_CMAC][HOST_NUM_IFS+1];
    generate
        for (genvar j = 0; j < HOST_NUM_IFS+1; j += 1) begin : g__host_if_sel
            always @(posedge core_clk) begin
                host_if_sel[0][j] <= (        axis_host_to_core[0].tid[11:0]  >=  smartnic_regs.igr_q_config_0[j].base ) &&
                                     ( {1'b0, axis_host_to_core[0].tid[11:0]} <  (smartnic_regs.igr_q_config_0[j].base +
                                                                                  smartnic_regs.igr_q_config_0[j].num_q) );
                host_if_sel[1][j] <= (        axis_host_to_core[1].tid[11:0]  >=  smartnic_regs.igr_q_config_1[j].base ) &&
                                     ( {1'b0, axis_host_to_core[1].tid[11:0]} <  (smartnic_regs.igr_q_config_1[j].base +
                                                                                  smartnic_regs.igr_q_config_1[j].num_q) );
            end
        end : g__host_if_sel
    endgenerate


    logic  host_q_in_range [NUM_CMAC];
    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__host_tid
        axi4s_intf_pipe axi4s_host_to_core_pipe (.axi4s_if_from_tx(axis_host_to_core[i]), .axi4s_if_to_rx(axis_host_to_core_p[i]));

        assign axis_host_tid[i].tid.raw[0] = i;
        assign axis_host_tid[i].tid.encoded.typ = (host_if_sel[i][0] ? PF  :
                                                  (host_if_sel[i][1] ? VF0 :
                                                  (host_if_sel[i][2] ? VF1 : VF2)));

        assign host_q_in_range[i] = host_if_sel[i][0] || host_if_sel[i][1] || host_if_sel[i][2] || host_if_sel[i][3];

        // axis_q_range_fail assignments
        assign axis_q_range_fail[i].aclk    = axis_host_to_core_p[i].aclk;
        assign axis_q_range_fail[i].aresetn = axis_host_to_core_p[i].aresetn;
        assign axis_q_range_fail[i].tready  = axis_host_to_core_p[i].tready;
        assign axis_q_range_fail[i].tvalid  = axis_host_to_core_p[i].tvalid && !host_q_in_range[i];
        assign axis_q_range_fail[i].tdata   = axis_host_to_core_p[i].tdata;
        assign axis_q_range_fail[i].tkeep   = axis_host_to_core_p[i].tkeep;
        assign axis_q_range_fail[i].tlast   = axis_host_to_core_p[i].tlast;
        assign axis_q_range_fail[i].tdest   = axis_host_to_core_p[i].tdest;
        assign axis_q_range_fail[i].tuser   = axis_host_to_core_p[i].tuser;
        assign axis_q_range_fail[i].tid     = axis_host_to_core_p[i].tid;

        axi4s_probe q_range_fail_probe (.axi4l_if(axil_q_range_fail[i]), .axi4s_if(axis_q_range_fail[i]));

        // host port tid assignments
        assign axis_host_to_core_p[i].tready = axis_host_tid[i].tready;

        assign axis_host_tid[i].aclk    = axis_host_to_core_p[i].aclk;
        assign axis_host_tid[i].aresetn = axis_host_to_core_p[i].aresetn;
        assign axis_host_tid[i].tvalid  = axis_host_to_core_p[i].tvalid && host_q_in_range[i];
        assign axis_host_tid[i].tdata   = axis_host_to_core_p[i].tdata;
        assign axis_host_tid[i].tkeep   = axis_host_to_core_p[i].tkeep;
        assign axis_host_tid[i].tlast   = axis_host_to_core_p[i].tlast;
        assign axis_host_tid[i].tdest   = axis_host_to_core_p[i].tdest;
        assign axis_host_tid[i].tuser   = axis_host_to_core_p[i].tuser;
        //     axis_host_tid[i].tid assigned above.

        axi4s_intf_pipe axi4s_host_tid_pipe (.axi4s_if_from_tx(axis_host_tid[i]), .axi4s_if_to_rx(axis_host_tid_p[i]));

        //ila_axi4s ila_host_tid (
        //   .clk    (axis_host_tid_p[i].aclk),
        //   .probe0 (axis_host_tid_p[i].tdata),
        //   .probe1 (axis_host_tid_p[i].tvalid),
        //   .probe2 (axis_host_tid_p[i].tlast),
        //   .probe3 (axis_host_tid_p[i].tkeep),
        //   .probe4 (axis_host_tid_p[i].tready),
        //   .probe5 ({30'd0, axis_host_tid_p[i].tid})
        //);
    end : g__host_tid
    endgenerate


    //------------------------ host mux/demux logic --------------
    logic host_to_core_demux_sel [NUM_CMAC];
    generate for (genvar i = 0; i < NUM_CMAC; i += 1) begin : g__host_mux_core  // core-side host mux logic
        // host_to_core demux logic.
        always @(posedge core_clk)
            if (!core_rstn)
                host_to_core_demux_sel[i] <= 0;
            else if (axis_host_tid[i].tready && axis_host_tid[i].tvalid && axis_host_tid[i].sop)
                host_to_core_demux_sel[i] <= host_if_sel[i][0] || host_if_sel[i][1] || host_if_sel[i][2];

        axi4s_intf_demux #(.N(2)) host_to_core_demux_inst (
           .axi4s_in   ( axis_host_tid_p[i] ),
           .axi4s_out  ( axis_host_to_core_demux[i] ),
           .sel        ( host_to_core_demux_sel[i] )
        );


        // core_to_host mux logic.
        axi4s_mux #(.N(2)) core_to_host_mux_inst (
            .axi4s_in   ( axis_core_to_host_mux[i] ),
            .axi4s_out  ( axis_hash2qid[i] )
        );

        smartnic_hash2qid #(
            .DATA_BYTE_WID(64), .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)
        ) smartnic_hash2qid (
            .core_clk       (core_clk),
            .core_rstn      (core_rstn),
            .axi4s_in       (axis_hash2qid[i]),
            .axi4s_out      (axis_core_to_host[i]),
            .axil_if        (axil_to_hash2qid[i])
        );

    end : g__host_mux_core
    endgenerate

endmodule // smartnic_host
