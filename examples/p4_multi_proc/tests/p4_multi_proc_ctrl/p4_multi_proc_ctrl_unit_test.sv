`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 100us

module p4_multi_proc_unit_test;

    string name = "p4_multi_proc_ut";
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic_app
    // testbench top level. The 'tb' module is
    // loaded into the tb_glbl scope, so is available
    // at tb_glbl.tb.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::tb_env env;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../../../../src/smartnic_app/p4_only/tests/common/tasks.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build testbench
        tb.build();

        // Retrieve reference to testbench environment class
        env = tb.env;

    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // Issue reset (both datapath and management domains)
        reset();

    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
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

    // Verify expected p4_only status register value
    `SVTEST(check_status)
        bit error;
        string msg;

        // Check p4_only status register
        env.p4_only_reg_agent.check_status(error, msg);
        `FAIL_IF_LOG(
            error == 1,
            msg
        );
    `SVTEST_END

    // Test read access to p4_only.status register
    `SVTEST(read_p4_only_status)
        logic [31:0] got_data;

        // Read p4_only status register
        env.p4_only_reg_agent.read_status(got_data);
        `FAIL_UNLESS(got_data == p4_only_reg_pkg::INIT_STATUS);
    `SVTEST_END
      
    `SVUNIT_TESTS_END

endmodule
