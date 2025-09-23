`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module p2p_smartnic_ctrl_unit_test;

    // Testcase name
    string name = "p2p_smartnic_ctrl_ut";

    // SVUnit base testcase
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic
    // testbench top level. The 'tb' module is
    // loaded into the global scope.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (smartnic_env).
    // A reference to the testbench environment is provided
    // here for convenience.
    smartnic_verif_pkg::smartnic_env env;

    p2p_reg_verif_pkg::p2p_reg_blk_agent #() p2p_reg_blk_agent;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../../../../../src/smartnic/tests/common/tasks.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build testbench
        env = tb.build();

        p2p_reg_blk_agent = new("p2p_reg_blk", 'h100000 + 'h20000);
        p2p_reg_blk_agent.reg_agent = env.reg_agent;
    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // start environment
        env.run();

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

    // Test read access to p2p status register
    `SVTEST(read_p2p_status)
        logic [31:0] rd_data;

        // Read p2p status registers
        p2p_reg_blk_agent.read_status_upper(rd_data);
        `FAIL_UNLESS(rd_data == p2p_reg_pkg::INIT_STATUS_UPPER);

        p2p_reg_blk_agent.read_status_lower(rd_data);
        `FAIL_UNLESS(rd_data == p2p_reg_pkg::INIT_STATUS_LOWER);
    `SVTEST_END

    // Test timestamp access
    `SVTEST(timestamp_test)
        logic [31:0] wr_data_upper, wr_data_lower;
        logic [63:0] rd_data;

        // write and verify random value to smartnic timestamp counter
        wr_data_upper = $urandom(); wr_data_lower = $urandom();

        env.smartnic_reg_blk_agent.write_timestamp_wr_upper( wr_data_upper );
        env.smartnic_reg_blk_agent.write_timestamp_wr_lower( wr_data_lower );

        env.smartnic_reg_blk_agent.read_timestamp_wr_upper ( rd_data[63:32] );
        env.smartnic_reg_blk_agent.read_timestamp_wr_lower ( rd_data[31:0] );

        `FAIL_UNLESS( rd_data == {wr_data_upper, wr_data_lower} );

    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
