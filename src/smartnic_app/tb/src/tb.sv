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
        env.axis_in_vif[0]       = axis_in_if[0];
        env.axis_in_vif[1]       = axis_in_if[1];
        env.axis_h2c_vif[0][0]   = axis_h2c_if[0][0];
        env.axis_h2c_vif[1][0]   = axis_h2c_if[1][0];
        env.axis_h2c_vif[2][0]   = axis_h2c_if[2][0];
        env.axis_h2c_vif[0][1]   = axis_h2c_if[0][1];
        env.axis_h2c_vif[1][1]   = axis_h2c_if[1][1];
        env.axis_h2c_vif[2][1]   = axis_h2c_if[2][1];
        env.axis_out_vif[0]      = axis_out_if[0];
        env.axis_out_vif[1]      = axis_out_if[1];
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
