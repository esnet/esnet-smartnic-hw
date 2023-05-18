`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_250mhz_ctrl_unit_test;

    string name = "smartnic_250mhz_ctrl_ut";
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic_250mhz
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
    `include "../common/tasks.svh"

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

    `SVTEST(reset)
    `SVTEST_END

    // Test read access to smartnic_322mhz.status register
    // (currently a read-only register containing 32'hC0BEBEEF)
    `SVTEST(scratchpad)
        logic [31:0] exp_data;
        logic [31:0] got_data;

        // Write random word to scratchpad
        void'(std::randomize(exp_data));
        env.smartnic_250mhz_reg_blk_agent.write_scratchpad(exp_data);

        // Read smartnic_322mhz status register
        env.smartnic_250mhz_reg_blk_agent.read_scratchpad(got_data);
        `FAIL_UNLESS_EQUAL(got_data, exp_data);
    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
