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
    // loaded into the tb_glbl scope, so is available
    // at tb_glbl.tb.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::tb_env env;

    p2p_reg_verif_pkg::p2p_reg_blk_agent #() p2p_reg_blk_agent;
    p2p_reg_verif_pkg::p2p_reg_blk_agent #() vitisnetp4_reg_blk_agent;

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
        tb.build();

        // Retrieve reference to testbench environment class
        env = tb.env;

        p2p_reg_blk_agent = new("p2p_reg_blk", env.AXIL_APP_OFFSET);
        p2p_reg_blk_agent.reg_agent = env.reg_agent;

        vitisnetp4_reg_blk_agent = new("vitisnetp4_reg_blk", env.AXIL_VITISNET_OFFSET);
        vitisnetp4_reg_blk_agent.reg_agent = env.reg_agent;
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

    // Test read access to p2p status register
    `SVTEST(read_p2p_status)
        logic [31:0] rd_data;

        // Read p2p status registers
        p2p_reg_blk_agent.read_status_upper(rd_data);
        `FAIL_UNLESS(rd_data == p2p_reg_pkg::INIT_STATUS_UPPER);

        p2p_reg_blk_agent.read_status_lower(rd_data);
        `FAIL_UNLESS(rd_data == p2p_reg_pkg::INIT_STATUS_LOWER);

        // Read vitisnetp4 status registers
        vitisnetp4_reg_blk_agent.read_status_upper(rd_data);
        `FAIL_UNLESS(rd_data == p2p_reg_pkg::INIT_STATUS_UPPER);

        vitisnetp4_reg_blk_agent.read_status_lower(rd_data);
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

        // latch timestamp value received by p2p block
        vitisnetp4_reg_blk_agent.write_timestamp_rd_latch( 0 );

        // Read vitisnetp4 status registers
        vitisnetp4_reg_blk_agent.read_status_upper(rd_data);
        `FAIL_UNLESS(rd_data == wr_data_upper);

        vitisnetp4_reg_blk_agent.read_status_lower(rd_data);
        // validate upper bits only, since timestamp counter is free-running.
        `FAIL_UNLESS(rd_data[31:14] == wr_data_lower[31:14]);

    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
