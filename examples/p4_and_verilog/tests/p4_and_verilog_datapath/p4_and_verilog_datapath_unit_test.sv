`include "svunit_defines.svh"

import tb_pkg::*;

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module p4_and_verilog_datapath_unit_test;

    // Testcase name
    string name = "p4_and_verilog_datapath_ut";

    // SVUnit base testcase
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic
    // testbench top level. The 'tb' module is
    // loaded into the tb_glbl scope, so is available
    // at tb_glbl.tb.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.

    //===================================
    // Import common testcase tasks
    //=================================== 
    `include "../../../../src/smartnic_app/tests/common/tasks.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build testbench
        tb.build();
       
        // Retrieve reference to testbench environment class
        env = tb.env;

        // Create P4 table agent
        vitisnetp4_agent = new;
        vitisnetp4_agent.create("tb"); // DPI-C P4 table agent requires hierarchial
                                       // path to AXI-L write/read tasks
    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // Flush packets from pipeline
        for (integer i = 0; i < 2; i += 1) begin
            env.axis_out_monitor[i].flush();
            for (integer j = 0; j < 3; j += 1) begin
                env.axis_c2h_monitor[j][i].flush();
            end
        end

        // Issue reset (both datapath and management domains)
        reset();

        // Put AXI-S interfaces into quiescent state
        for (integer i = 0; i < 2; i += 1) begin
            env.axis_in_driver[i].idle();
            env.axis_out_monitor[i].idle();
            for (integer j = 0; j < 3; j += 1) begin
                env.axis_h2c_driver[j][i].idle();
                env.axis_c2h_monitor[j][i].idle();
            end
        end

    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        `INFO("Waiting to end testcase...");
        for (integer i = 0; i < 100 ; i=i+1 ) @(posedge tb.clk);
        `INFO("Ending testcase!");

        svunit_ut.teardown();

        // Flush remaining packets
        for (integer i = 0; i < 2; i += 1) begin
            env.axis_out_monitor[i].flush();
            for (integer j = 0; j < 3; j += 1) begin
                env.axis_c2h_monitor[j][i].flush();
            end
        end
        #10us;

    endtask

   
    //=======================================================================
    // TESTS
    //=======================================================================

    //===================================
    // All tests are defined between the
    // SVUNIT_TESTS_BEGIN/END macros
    //
    // Each individual test must be
    // defined between `SVTEST(_NAME_)
    // `SVTEST_END
    //
    // i.e.
    //   `SVTEST(mytest)
    //     <test code>
    //   `SVTEST_END
    //===================================

    `SVUNIT_TESTS_BEGIN

    `SVTEST(init)
        // Initialize VitisNetP4 tables
        vitisnetp4_agent.init();
    `SVTEST_END

    `include "../../p4/sim/run_pkt_test_incl.svh"

    `SVUNIT_TESTS_END

endmodule
