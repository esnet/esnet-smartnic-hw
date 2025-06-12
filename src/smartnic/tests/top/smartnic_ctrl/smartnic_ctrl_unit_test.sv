`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_ctrl_unit_test;
    // Testcase name
    string name = "smartnic_ctrl_ut";

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
    tb_pkg::smartnic_env env;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../../common/tasks.svh"

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

        // start environment
        env.run();

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

    // Test read access to smartnic.status register
    // (currently a read-only register containing 32'hC0BEBEEF)
    `SVTEST(read_smartnic_status)
        logic [31:0] exp_data = 32'hc0bebeef;
        logic [31:0] got_data;

        // Read smartnic status register
        env.smartnic_reg_blk_agent.read_status(got_data);
        `FAIL_UNLESS(got_data == exp_data);
    `SVTEST_END

    // Test flow_control access.
    `SVTEST(flow_control)
        logic [3:0][7:0] exp_data;
        logic [3:0][7:0] got_data;

        // check default values.
        exp_data = smartnic_reg_pkg::INIT_EGR_FC_THRESH;
        env.smartnic_reg_blk_agent.read_egr_fc_thresh(0, got_data); `FAIL_UNLESS(got_data == exp_data);

        exp_data = smartnic_reg_pkg::INIT_EGR_FC_THRESH;
        env.smartnic_reg_blk_agent.read_egr_fc_thresh(1, got_data); `FAIL_UNLESS(got_data == exp_data);

        exp_data = smartnic_reg_pkg::INIT_EGR_FC_THRESH;
        env.smartnic_reg_blk_agent.read_egr_fc_thresh(2, got_data); `FAIL_UNLESS(got_data == exp_data);

        exp_data = smartnic_reg_pkg::INIT_EGR_FC_THRESH;
        env.smartnic_reg_blk_agent.read_egr_fc_thresh(3, got_data); `FAIL_UNLESS(got_data == exp_data);

        // check r/w access.
        exp_data = 32'h1111_1111; env.smartnic_reg_blk_agent.write_egr_fc_thresh(0, exp_data);
        env.smartnic_reg_blk_agent.read_egr_fc_thresh(0, got_data); `FAIL_UNLESS(got_data == exp_data);

        exp_data = 32'h2222_2222; env.smartnic_reg_blk_agent.write_egr_fc_thresh(1, exp_data);
        env.smartnic_reg_blk_agent.read_egr_fc_thresh(1, got_data); `FAIL_UNLESS(got_data == exp_data);

        exp_data = 32'h3333_3333; env.smartnic_reg_blk_agent.write_egr_fc_thresh(2, exp_data);
        env.smartnic_reg_blk_agent.read_egr_fc_thresh(2, got_data); `FAIL_UNLESS(got_data == exp_data);

        exp_data = 32'h4444_4444; env.smartnic_reg_blk_agent.write_egr_fc_thresh(3, exp_data);
        env.smartnic_reg_blk_agent.read_egr_fc_thresh(3, got_data); `FAIL_UNLESS(got_data == exp_data);

    `SVTEST_END

    // Test endian check component
    // Write packed value and compare against values unpacked to byte monitors
    `SVTEST(endian_check_packed_to_unpacked)
        logic [3:0][7:0] exp_data;
        logic [3:0][7:0] got_data;

        exp_data = 32'h88776655;

        env.reg_endian_check_reg_blk_agent.write_scratchpad_packed(exp_data);
        env.reg_endian_check_reg_blk_agent.read_scratchpad_packed_monitor_byte_0(got_data[0]);
        env.reg_endian_check_reg_blk_agent.read_scratchpad_packed_monitor_byte_1(got_data[1]);
        env.reg_endian_check_reg_blk_agent.read_scratchpad_packed_monitor_byte_2(got_data[2]);
        env.reg_endian_check_reg_blk_agent.read_scratchpad_packed_monitor_byte_3(got_data[3]);

        `FAIL_UNLESS(got_data == exp_data);
    `SVTEST_END

    // Test endian check component
    // Write unpacked byte values and compare against values packed to reg monitor
    `SVTEST(endian_check_unpacked_to_packed)
        logic [3:0][7:0] exp_data;
        logic [3:0][7:0] got_data;

        exp_data = 32'h88776655;

        env.reg_endian_check_reg_blk_agent.write_scratchpad_unpacked_byte_0(exp_data[0]);
        env.reg_endian_check_reg_blk_agent.write_scratchpad_unpacked_byte_1(exp_data[1]);
        env.reg_endian_check_reg_blk_agent.write_scratchpad_unpacked_byte_2(exp_data[2]);
        env.reg_endian_check_reg_blk_agent.write_scratchpad_unpacked_byte_3(exp_data[3]);
        env.reg_endian_check_reg_blk_agent.read_scratchpad_unpacked_monitor(got_data);

        `FAIL_UNLESS(got_data == exp_data);
    `SVTEST_END

    // Test hash2qid access
    `SVTEST(hash2qid)
        logic [47:0] exp_data;
        logic [47:0] got_data;

        exp_data = 48'h123_456_789_abc;

        env.smartnic_hash2qid_0_reg_blk_agent.write_q_config  (0, exp_data[11:0]);
        env.smartnic_hash2qid_0_reg_blk_agent.write_q_config  (1, exp_data[23:12]);
        env.smartnic_hash2qid_0_reg_blk_agent.write_q_config  (2, exp_data[35:24]);
        env.smartnic_hash2qid_0_reg_blk_agent.write_q_config  (3, exp_data[47:36]);

        env.smartnic_hash2qid_0_reg_blk_agent.read_q_config   (0, got_data[11:0]);
        env.smartnic_hash2qid_0_reg_blk_agent.read_q_config   (1, got_data[23:12]);
        env.smartnic_hash2qid_0_reg_blk_agent.read_q_config   (2, got_data[35:24]);
        env.smartnic_hash2qid_0_reg_blk_agent.read_q_config   (3, got_data[47:36]);

        `FAIL_UNLESS(got_data == exp_data);

        exp_data = 48'hcba_987_654_321;

        env.smartnic_hash2qid_0_reg_blk_agent.write_pf_table  (0, exp_data[11:0]);
        env.smartnic_hash2qid_0_reg_blk_agent.write_vf0_table (0, exp_data[23:12]);
	env.smartnic_hash2qid_0_reg_blk_agent.write_vf1_table (0, exp_data[35:24]);
        env.smartnic_hash2qid_0_reg_blk_agent.write_vf2_table (0, exp_data[47:36]);

        env.smartnic_hash2qid_0_reg_blk_agent.read_pf_table   (0, got_data[11:0]);
        env.smartnic_hash2qid_0_reg_blk_agent.read_vf0_table  (0, got_data[23:12]);
        env.smartnic_hash2qid_0_reg_blk_agent.read_vf1_table  (0, got_data[35:24]);
        env.smartnic_hash2qid_0_reg_blk_agent.read_vf2_table  (0, got_data[47:36]);

        `FAIL_UNLESS(got_data == exp_data);

    `SVTEST_END

    // Test igr_q_config_0 access
    `SVTEST(igr_q_config_0)
        logic [47:0] exp_data;
        logic [47:0] got_data;

        exp_data = 48'h123_456_789_abc;

        env.smartnic_reg_blk_agent.write_igr_q_config_0 (0, exp_data[23:0]);
        env.smartnic_reg_blk_agent.write_igr_q_config_0 (1, exp_data[47:24]);

        env.smartnic_reg_blk_agent.read_igr_q_config_0  (0, got_data[23:0]);
        env.smartnic_reg_blk_agent.read_igr_q_config_0  (1, got_data[47:24]);

        `FAIL_UNLESS(got_data == exp_data);

        exp_data = 48'hcba_987_654_321;

        env.smartnic_reg_blk_agent.write_igr_q_config_0 (2, exp_data[23:0]);
        env.smartnic_reg_blk_agent.write_igr_q_config_0 (3, exp_data[47:24]);

        env.smartnic_reg_blk_agent.read_igr_q_config_0  (2, got_data[23:0]);
        env.smartnic_reg_blk_agent.read_igr_q_config_0  (3, got_data[47:24]);

        `FAIL_UNLESS(got_data == exp_data);

    `SVTEST_END

    // Test igr_q_config_1 access
    `SVTEST(igr_q_config_1)
        logic [47:0] exp_data;
        logic [47:0] got_data;

        exp_data = 48'h123_456_789_abc;

        env.smartnic_reg_blk_agent.write_igr_q_config_1 (0, exp_data[23:0]);
        env.smartnic_reg_blk_agent.write_igr_q_config_1 (1, exp_data[47:24]);

        env.smartnic_reg_blk_agent.read_igr_q_config_1  (0, got_data[23:0]);
        env.smartnic_reg_blk_agent.read_igr_q_config_1  (1, got_data[47:24]);

        `FAIL_UNLESS(got_data == exp_data);

        exp_data = 48'hcba_987_654_321;

        env.smartnic_reg_blk_agent.write_igr_q_config_1 (2, exp_data[23:0]);
        env.smartnic_reg_blk_agent.write_igr_q_config_1 (3, exp_data[47:24]);

        env.smartnic_reg_blk_agent.read_igr_q_config_1  (2, got_data[23:0]);
        env.smartnic_reg_blk_agent.read_igr_q_config_1  (3, got_data[47:24]);

        `FAIL_UNLESS(got_data == exp_data);

    `SVTEST_END


    `SVUNIT_TESTS_END

endmodule
