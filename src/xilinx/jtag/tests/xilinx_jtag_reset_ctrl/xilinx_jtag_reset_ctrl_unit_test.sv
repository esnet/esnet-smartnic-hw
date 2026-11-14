`include "svunit_defines.svh"

module xilinx_jtag_reset_ctrl_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "xilinx_jtag_reset_ctrl_ut";
    svunit_testcase svunit_ut;

    logic debug_clk = 1'b0;
    logic debug_clk_enable = 1'b1;
    logic ready;
    logic rstn_in;
    wire rstn_out;

    xilinx_jtag_reset_ctrl DUT (.*);

    always #5ns begin
        if (debug_clk_enable) debug_clk = ~debug_clk;
        else                  debug_clk = 1'b0;
    end

    function void build();
        svunit_ut = new(name);
    endfunction

    task setup();
        svunit_ut.setup();
        debug_clk_enable = 1'b1;
        ready = 1'b0;
        rstn_in = 1'b0;
        force DUT.jtag_reset = 1'b0;
        settle();
    endtask

    task teardown();
        debug_clk_enable = 1'b1;
        release DUT.jtag_reset;
        svunit_ut.teardown();
    endtask

    `SVUNIT_TESTS_BEGIN

        `SVTEST(status_waits_for_debug_clock)
            stop_debug_clock();
            rstn_in = 1'b1;
            ready = 1'b1;
            #1ns;
            `FAIL_UNLESS(rstn_out === 1'b1)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in0 === 1'b0)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b0)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in2 === 1'b0)
            #20ns;
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in0 === 1'b0)
            debug_clk_enable = 1'b1;
            settle();
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in0 === 1'b1)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b1)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in2 === 1'b1)
        `SVTEST_END

        `SVTEST(raw_reset_asserts_without_debug_clock)
            rstn_in = 1'b1;
            settle();
            stop_debug_clock();
            rstn_in = 1'b0;
            #1ns;
            `FAIL_UNLESS(rstn_out === 1'b0)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in0 === 1'b1)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b1)
            debug_clk_enable = 1'b1;
            settle();
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in0 === 1'b0)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b0)
        `SVTEST_END

        `SVTEST(jtag_override_preserves_raw_reset_status)
            rstn_in = 1'b1;
            settle();
            @(negedge debug_clk);
            force DUT.jtag_reset = 1'b1;
            #1ns;
            `FAIL_UNLESS(rstn_out === 1'b0)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b1)
            settle();
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in0 === 1'b1)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b0)
            @(negedge debug_clk);
            force DUT.jtag_reset = 1'b0;
            #1ns;
            `FAIL_UNLESS(rstn_out === 1'b1)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b0)
            settle();
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b1)
            rstn_in = 1'b0;
            force DUT.jtag_reset = 1'b1;
            #1ns;
            force DUT.jtag_reset = 1'b0;
            #1ns;
            `FAIL_UNLESS(rstn_out === 1'b0)
        `SVTEST_END

        `SVTEST(ready_is_monitored_during_reset)
            ready = 1'b1;
            settle();
            `FAIL_UNLESS(rstn_out === 1'b0)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in0 === 1'b0)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in1 === 1'b0)
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in2 === 1'b1)
            ready = 1'b0;
            settle();
            `FAIL_UNLESS(DUT.i_xilinx_jtag_reset_vio.probe_in2 === 1'b0)
        `SVTEST_END

    `SVUNIT_TESTS_END

    task settle();
        repeat (8) @(posedge debug_clk);
        #1ps;
    endtask

    task stop_debug_clock();
        @(negedge debug_clk);
        debug_clk_enable = 1'b0;
    endtask
endmodule
