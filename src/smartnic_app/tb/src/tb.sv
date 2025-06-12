module tb;
    import tb_pkg::*;
    import smartnic_pkg::*;

    //===================================
    // (Common) test environment
    //===================================
    tb_env env;

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
    assign rstn = ~reset_if.reset;
    initial begin
       reset_if.ready = 1'b0;
       reset_if._wait(10); reset_if.ready = 1'b1;
    end

    assign axil_if.aresetn = rstn;

    // App AXI-L interface shares common AXI-L clock/reset
    assign app_axil_if.aclk    = axil_if.aclk;
    assign app_axil_if.aresetn = axil_if.aresetn;

    // Assign AXI-S input clocks/resets
    generate
        for (genvar i = 0; i < NUM_PROC_PORTS; i += 1) begin
            for (genvar j = 0; j < NUM_HOST_IFS; j += 1) begin
                assign axis_h2c_if[j][i].aclk = clk;
                assign axis_h2c_if[j][i].aresetn = rstn;
            end
            assign axis_in_if[i].aclk = clk;
            assign axis_in_if[i].aresetn = rstn;
        end
    endgenerate

    // Timestamp interface
    timestamp_intf #() timestamp_if (.clk(clk), .srst(~rstn));
    assign timestamp = timestamp_if.timestamp;


    //===================================
    // Build
    //===================================
    function void build();
        // Instantiate environment
        env = new("tb_env", 0); // bigendian=0 to match CMACs.

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
