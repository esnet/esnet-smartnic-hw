module tb;
    import smartnic_pkg::*;
    import smartnic_verif_pkg::*;

    //===================================
    // DUT
    //===================================
    `include "../include/DUT.svh"

    axi4s_intf #(.DATA_BYTE_WID(64), .TID_WID(ADPT_TX_TID_WID), .TDEST_WID(PORT_WID), .TUSER_WID(1))  axis_in_if  [4] (.aclk(axis_clk), .aresetn(axis_aresetn));
    axi4s_intf #(.DATA_BYTE_WID(64), .TID_WID(PORT_WID), .TDEST_WID(PORT_WID),
                 .TUSER_WID(TUSER_SMARTNIC_META_WID))                                                 axis_out_if [4] (.aclk(axis_clk), .aresetn(axis_aresetn));

    generate for (genvar i = 0; i < 2; i += 1) begin : g__port
        port_t axis_in_if_tdest_cmac_igr;
        port_t axis_in_if_tdest_h2c;

        assign axis_cmac_igr[i].tvalid = axis_in_if[i].tvalid;
        assign axis_cmac_igr[i].tlast = axis_in_if[i].tlast;
        assign axis_cmac_igr[i].tdata = axis_in_if[i].tdata;
        assign axis_cmac_igr[i].tkeep = axis_in_if[i].tkeep;
        assign axis_cmac_igr[i].tid = axis_in_if[i].tid;
        assign axis_in_if_tdest_cmac_igr = axis_in_if[i].tdest;
        assign axis_cmac_igr[i].tdest = axis_in_if_tdest_cmac_igr[1:0];
        assign axis_cmac_igr[i].tuser = axis_in_if[i].tuser;
        assign axis_in_if[i].tready = axis_cmac_igr[i].tready;

        axi4s_intf_set_meta #(
            .TID_WID   (PORT_WID),
            .TDEST_WID (PORT_WID),
            .TUSER_WID (TUSER_SMARTNIC_META_WID)
        ) cmac_egr_connector (
            .from_tx(axis_cmac_egr[i]),
            .to_rx  (axis_out_if[i]),
            .tid ('0),
            .tdest ('0),
            .tuser  ('0)
        );

        assign cmac_clk[i] = axis_clk;

        assign axis_h2c[i].tvalid = axis_in_if[i+2].tvalid;
        assign axis_h2c[i].tlast = axis_in_if[i+2].tlast;
        assign axis_h2c[i].tdata = axis_in_if[i+2].tdata;
        assign axis_h2c[i].tkeep = axis_in_if[i+2].tkeep;
        assign axis_h2c[i].tid = axis_in_if[i+2].tid;
        assign axis_in_if_tdest_h2c = axis_in_if[i+2].tdest;
        assign axis_h2c[i].tdest = axis_in_if_tdest_h2c[1:0];
        assign axis_h2c[i].tuser = axis_in_if[i+2].tuser;
        assign axis_in_if[i+2].tready = axis_h2c[i].tready;

        axi4s_intf_set_meta #(
            .TID_WID   (PORT_WID),
            .TDEST_WID (PORT_WID),
            .TUSER_WID (TUSER_SMARTNIC_META_WID)
        ) c2h_connector (
            .from_tx(axis_c2h[i]),
            .to_rx(axis_out_if[i+2]),
            .tid ('0),
            .tdest ('0),
            .tuser (axis_c2h[i].tuser)
        );

    end : g__port
    endgenerate

    //===================================
    // Local signals
    //===================================

    // Clocks
    assign axil_if.aclk = axil_aclk;

    // Resets
    std_reset_intf reset_if (.clk(axis_clk));
    assign mod_rstn = ~reset_if.reset;
    assign reset_if.ready = mod_rst_done;

    assign axil_if.aresetn = ~reset_if.reset;
    assign axis_aresetn = ~reset_if.reset;


    // output monitors
    always @(negedge axis_cmac_egr[0].tvalid)
        if (axis_cmac_egr[0].tready && !axis_cmac_egr[0].tlast) $display ("Port0: tvalid gap.  May lead to ONS underflow!");
    always @(negedge axis_cmac_egr[1].tvalid)
        if (axis_cmac_egr[1].tready && !axis_cmac_egr[1].tlast) $display ("Port1: tvalid gap.  May lead to ONS underflow!");
    always @(negedge axis_c2h[0].tvalid)
        if (axis_c2h[0].tready && !axis_c2h[0].tlast)           $display ("Port2: tvalid gap.  May lead to ONS underflow!");
    always @(negedge axis_c2h[1].tvalid)
        if (axis_c2h[1].tready && !axis_c2h[1].tlast)           $display ("Port3: tvalid gap.  May lead to ONS underflow!");

    //always @(posedge axis_cmac_egr[0].aclk)
    //    if (axis_cmac_egr[0].tready && axis_cmac_egr[0].tvalid) $display ("Port0: Valid transaction!");
    //always @(posedge axis_cmac_egr[1].aclk)
    //    if (axis_cmac_egr[1].tready && axis_cmac_egr[1].tvalid) $display ("Port1: Valid transaction!");

    //===================================
    // Build
    //===================================
    function automatic smartnic_env build();
        smartnic_env env;
        // Instantiate environment
        env = new("env");

        // Connect environment
        env.reset_vif = reset_if;

        env.axis_in_vif[0] = axis_in_if[0];
        env.axis_in_vif[1] = axis_in_if[1];
        env.axis_in_vif[2] = axis_in_if[2];
        env.axis_in_vif[3] = axis_in_if[3];

        env.axis_out_vif[0] = axis_out_if[0];
        env.axis_out_vif[1] = axis_out_if[1];
        env.axis_out_vif[2] = axis_out_if[2];
        env.axis_out_vif[3] = axis_out_if[3];

        env.axil_vif = axil_if;

        env.build();
        env.set_debug_level(1);
        return env;
    endfunction

endmodule : tb
