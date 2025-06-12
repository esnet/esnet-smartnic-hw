`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 100us

module proxy_test_ctrl_unit_test;

    string name = "proxy_test_ctrl_ut";
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common proxy_test
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

    proxy_test_verif_pkg::proxy_test_reg_agent proxy_test_reg_agent;

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

        proxy_test_reg_agent = new("proxy_test_reg_agent", env.app_reg_agent, 'h20000);

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

    // Verify expected proxy_test id register value
    `SVTEST(check_id)
        bit error;
        string msg;

        // Check proxy_test id register
        proxy_test_reg_agent.check_id(error, msg);
        `FAIL_IF_LOG(
            error == 1,
            msg
        );
    `SVTEST_END

    // Test read access to proxy_test.id register
    `SVTEST(read_proxy_test_id)
        logic [31:0] got_data;

        // Read proxy_test id register
        proxy_test_reg_agent.read_id(got_data);
        `FAIL_UNLESS(got_data == proxy_test_reg_pkg::INIT_ID);
    `SVTEST_END
      
    `SVUNIT_TESTS_END

endmodule
