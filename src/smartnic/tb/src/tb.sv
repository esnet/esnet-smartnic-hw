module tb;
    import tb_pkg::*;
    import smartnic_pkg::*;

    //===================================
    // (Common) test environment
    //===================================
    smartnic_env env;

    //===================================
    // DUT
    //===================================
    `include "../include/DUT.svh"

    axi4s_intf #(.DATA_BYTE_WID(64), .TID_T(adpt_tx_tid_t), .TDEST_T(port_t), .TUSER_T(bit))  axis_in_if  [4] ();
    axi4s_intf #(.DATA_BYTE_WID(64),
                 .TID_T(port_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t))           axis_out_if [4] ();

    generate for (genvar i = 0; i < 2; i += 1) begin
        port_t axis_in_if_tdest_cmac_igr;
        port_t axis_in_if_tdest_h2c;

        assign axis_cmac_igr[i].aclk = axis_in_if[i].aclk;
        assign axis_cmac_igr[i].aresetn = axis_in_if[i].aresetn;
        assign axis_cmac_igr[i].tvalid = axis_in_if[i].tvalid;
        assign axis_cmac_igr[i].tlast = axis_in_if[i].tlast;
        assign axis_cmac_igr[i].tdata = axis_in_if[i].tdata;
        assign axis_cmac_igr[i].tkeep = axis_in_if[i].tkeep;
        assign axis_cmac_igr[i].tid = axis_in_if[i].tid;
        assign axis_in_if_tdest_cmac_igr = axis_in_if[i].tdest;
        assign axis_cmac_igr[i].tdest = axis_in_if_tdest_cmac_igr[1:0];
        assign axis_cmac_igr[i].tuser = axis_in_if[i].tuser;
        assign axis_in_if[i].tready = axis_cmac_igr[i].tready;

        axi4s_intf_connector cmac_egr_connector (.axi4s_from_tx(axis_cmac_egr[i]), .axi4s_to_rx(axis_out_if[i]));

        assign axis_h2c[i].aclk = axis_in_if[i+2].aclk;
        assign axis_h2c[i].aresetn = axis_in_if[i+2].aresetn;
        assign axis_h2c[i].tvalid = axis_in_if[i+2].tvalid;
        assign axis_h2c[i].tlast = axis_in_if[i+2].tlast;
        assign axis_h2c[i].tdata = axis_in_if[i+2].tdata;
        assign axis_h2c[i].tkeep = axis_in_if[i+2].tkeep;
        assign axis_h2c[i].tid = axis_in_if[i+2].tid;
        assign axis_in_if_tdest_h2c = axis_in_if[i+2].tdest;
        assign axis_h2c[i].tdest = axis_in_if_tdest_h2c[1:0];
        assign axis_h2c[i].tuser = axis_in_if[i+2].tuser;
        assign axis_in_if[i+2].tready = axis_h2c[i].tready;

        axi4s_intf_connector      c2h_connector (.axi4s_from_tx(axis_c2h[i]),      .axi4s_to_rx(axis_out_if[i+2]));
    end endgenerate

    //===================================
    // Local signals
    //===================================

    // Clocks
    assign axil_if.aclk = axil_aclk;

    logic axis_clk;
    generate for (genvar i = 0; i < 4; i += 1) assign axis_in_if[i].aclk    = axis_clk; endgenerate
    generate for (genvar i = 0; i < 2; i += 1) assign cmac_clk[i]           = axis_clk; endgenerate
    generate for (genvar i = 0; i < 2; i += 1) assign axis_cmac_egr[i].aclk = axis_clk; endgenerate
    generate for (genvar i = 0; i < 2; i += 1) assign axis_c2h[i].aclk      = axis_clk; endgenerate

    // Resets
    std_reset_intf reset_if (.clk(axis_clk));
    assign mod_rstn = ~reset_if.reset;
    assign reset_if.ready = mod_rst_done;

    generate for (genvar i = 0; i < 4; i += 1) assign axis_in_if[i].aresetn  = ~reset_if.reset; endgenerate
    generate for (genvar i = 0; i < 4; i += 1) assign axis_out_if[i].aresetn = ~reset_if.reset; endgenerate

    assign axil_if.aresetn = ~reset_if.reset;


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
    function void build();
        // Instantiate environment
        env = new("env", 0); // bigendian=0 to match CMACs.

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
    endfunction

    // Export AXI-L accessors to VitisNetP4 shared library
    export "DPI-C" task axi_lite_wr;
    task axi_lite_wr(input int address, input int data);
        env.vitisnetp4_write(address, data);
    endtask

    export "DPI-C" task axi_lite_rd;
    task axi_lite_rd(input int address, inout int data);
        env.vitisnetp4_read(address, data);
    endtask

endmodule : tb
