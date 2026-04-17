module tb;
    import tb_pkg::*;
    import smartnic_pkg::*;

    //===================================
    // Device Under Test
    //===================================
    `include "../include/DUT.svh"

    //===================================
    // Local signals
    //===================================
    // Clocks
    initial clk = 1'b0;
    always #1455ps clk = ~clk; // 343.75 MHz

    initial axil_if.aclk = 1'b0;
    always #4ns axil_if.aclk = ~axil_if.aclk; // 125 MHz

    // Resets
    std_reset_intf reset_if (.clk(clk));
    assign srst = reset_if.reset;
    initial begin
       reset_if.ready = 1'b0;
       reset_if._wait(10); reset_if.ready = 1'b1;
    end

    assign axil_if.aresetn = !srst;

    // App AXI-L interface shares common AXI-L clock/reset
    assign app_axil_if.aclk    = axil_if.aclk;
    assign app_axil_if.aresetn = axil_if.aresetn;

    // Timestamp interface
    timestamp_intf #() timestamp_if (.clk, .srst);
    assign timestamp = timestamp_if.timestamp;

    // Port loopback mux logic.
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID), .DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  _axis_in_if    [NUM_PROC_PORTS] (.aclk(clk));
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID), .DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  _axis_out_if   [NUM_PROC_PORTS] (.aclk(clk));
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID), .DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_port_lpbk [NUM_PROC_PORTS] (.aclk(clk));

    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID), .DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_port_lpbk_demux [NUM_PROC_PORTS][2] (.aclk(clk));
    axi4s_intf #(.TUSER_WID(TUSER_SMARTNIC_META_WID), .DATA_BYTE_WID(AXIS_DATA_BYTE_WID),
                 .TID_WID(PORT_WID), .TDEST_WID(PORT_WID))  axis_port_lpbk_mux   [NUM_PROC_PORTS][2] (.aclk(clk));

    logic port_lpbk_en = 0;

    generate for (genvar i = 0; i < NUM_PROC_PORTS; i += 1) begin : g__lpbk
        axi4s_intf_demux axi4s_port_lpbk_demux (.srst(srst), .from_tx(axis_out_if[i]), .to_rx(axis_port_lpbk_demux[i]), .sel(port_lpbk_en));

        axi4s_intf_connector axi4s_demux_connector_0 (.from_tx(axis_port_lpbk_demux[i][0]), .to_rx(_axis_out_if[i]));
        axi4s_intf_connector axi4s_demux_connector_1 (.from_tx(axis_port_lpbk_demux[i][1]), .to_rx(axis_port_lpbk[i]));

        axi4s_intf_connector axi4s_mux_connector_0 (.from_tx(_axis_in_if[i]),    .to_rx(axis_port_lpbk_mux[i][0]));
        axi4s_intf_connector axi4s_mux_connector_1 (.from_tx(axis_port_lpbk[i]), .to_rx(axis_port_lpbk_mux[i][1]));

        axi4s_intf_mux axi4s_port_lpbk_mux (.from_tx(axis_port_lpbk_mux[i]), .to_rx(axis_in_if[i]), .sel(port_lpbk_en));

    end : g__lpbk
    endgenerate


    //===================================
    // Build
    //===================================
    function automatic tb_env build();
        tb_env env;
        // Instantiate environment
        env = new("tb_env");

        // Connect environment
        env.reset_vif            = reset_if;
        env.timestamp_vif        = timestamp_if;
        env.app_axil_vif         = app_axil_if;
        env.axil_vif             = axil_if;
        env.axis_in_vif[0]       = _axis_in_if[0];
        env.axis_in_vif[1]       = _axis_in_if[1];
        env.axis_h2c_vif[0][0]   = axis_h2c_if[0][0];
        env.axis_h2c_vif[1][0]   = axis_h2c_if[1][0];
        env.axis_h2c_vif[2][0]   = axis_h2c_if[2][0];
        env.axis_h2c_vif[0][1]   = axis_h2c_if[0][1];
        env.axis_h2c_vif[1][1]   = axis_h2c_if[1][1];
        env.axis_h2c_vif[2][1]   = axis_h2c_if[2][1];
        env.axis_out_vif[0]      = _axis_out_if[0];
        env.axis_out_vif[1]      = _axis_out_if[1];
        env.axis_c2h_vif[0][0]   = axis_c2h_if[0][0];
        env.axis_c2h_vif[1][0]   = axis_c2h_if[1][0];
        env.axis_c2h_vif[2][0]   = axis_c2h_if[2][0];
        env.axis_c2h_vif[0][1]   = axis_c2h_if[0][1];
        env.axis_c2h_vif[1][1]   = axis_c2h_if[1][1];
        env.axis_c2h_vif[2][1]   = axis_c2h_if[2][1];

        env.build();
        env.set_debug_level(0);
        return env;
    endfunction

endmodule : tb
