`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 100us

module p4_proc_ctrl_unit_test;

    string name = "p4_proc_ctrl_ut";
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common p4_proc
    // testbench top level. The 'tb' module is
    // loaded into the global scope.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::tb_env env;

    // VitisNetP4 table agent
    vitisnetp4_verif_pkg::vitisnetp4_agent vitisnetp4_agent;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../common/tasks.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build testbench
        env = tb.build();

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

    // Verify expected p4_proc status register value
    `SVTEST(check_status)
        bit error;
        string msg;

        // Check p4_proc status register
        env.p4_proc_reg_agent.check_status(error, msg);
        `FAIL_IF_LOG(
            error == 1,
            msg
        );
    `SVTEST_END

    // Test read access to p4_proc.status register
    `SVTEST(read_p4_proc_status)
        logic [31:0] got_data;

        // Read p4_proc status register
        env.p4_proc_reg_agent.read_status(got_data);
        `FAIL_UNLESS(got_data == p4_proc_reg_pkg::INIT_STATUS);
    `SVTEST_END
      
    // Test write access to p4_proc.rss_config register
    `SVTEST(write_p4_proc_rss_config)
        p4_proc_reg_pkg::reg_rss_config_t   rss_config, got_data;

        // Write rss_config register
        rss_config.enable = 1'b1;
        rss_config.rss_enable = 1'b1;
        rss_config.rss_entropy = 12'habc;
        env.p4_proc_reg_agent.write_rss_config(rss_config);

        // Read rss_config register
        env.p4_proc_reg_agent.read_rss_config(got_data);
        `FAIL_UNLESS(got_data == rss_config);

        // Change rss_config settings
        rss_config.rss_entropy = 12'h123;
        env.p4_proc_reg_agent.write_rss_config(rss_config);

        rss_config.rss_enable = 1'b0;
        env.p4_proc_reg_agent.write_rss_config(rss_config);

        rss_config.enable = 1'b0;
        env.p4_proc_reg_agent.write_rss_config(rss_config);

    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
