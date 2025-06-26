`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 100us

module p4_and_verilog_ctrl_unit_test;

    string name = "p4_and_verilog_ctrl_ut";
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic_app
    // testbench top level. The 'tb' module is
    // loaded into the global scope.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::tb_env env;

    // VitisNetP4 table agent
    vitisnetp4_igr_verif_pkg::vitisnetp4_igr_agent vitisnetp4_agent;

    p4_and_verilog_verif_pkg::p4_and_verilog_reg_agent p4_and_verilog_reg_agent;

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
        env = tb.build();

        // Create P4 table agent
        vitisnetp4_agent = new(.hier_path(p4_dpic_hier_path)); // DPI-C P4 table agent requires hierarchical path to AXI-L write/read tasks

        p4_and_verilog_reg_agent = new("p4_and_verilog_reg_agent", env.app_reg_agent, 'h20000);

    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // start environment
        env.run();

        #100ns;
    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        // Stop environment
        env.stop();

        svunit_ut.teardown();
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

    // Verify expected p4_and_verilog status register value
    `SVTEST(check_status)
        bit error;
        string msg;

        // Check p4_and_verilog status register
        p4_and_verilog_reg_agent.check_status(error, msg);
        `FAIL_IF_LOG(
            error == 1,
            msg
        );
    `SVTEST_END

    // Test read access to p4_and_verilog.status register
    `SVTEST(read_p4_and_verilog_status)
        logic [31:0] got_data;

        // Read p4_and_verilog status register
        p4_and_verilog_reg_agent.read_status(got_data);
        `FAIL_UNLESS(got_data == p4_and_verilog_reg_pkg::INIT_STATUS);
    `SVTEST_END
      
    `SVUNIT_TESTS_END

endmodule
