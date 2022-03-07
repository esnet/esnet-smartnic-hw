`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_322mhz_ctrl_unit_test;

    string name = "smartnic_322mhz_ctrl_ut";
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic_322mhz
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
    `include "../../tests/common/tasks.svh"

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

    // Test read access to smartnic_322mhz.status register
    // (currently a read-only register containing 32'hC0BEBEEF)
    `SVTEST(read_smartnic_322mhz_status)
        logic [31:0] exp_data = 32'hc0bebeef;
        logic [31:0] got_data;

        // Read smartnic_322mhz status register
        env.smartnic_322mhz_reg_blk_agent.read_status(got_data);
        `FAIL_UNLESS(got_data == exp_data);
    `SVTEST_END

    // Test read/write access to smartnic_322mhz.port_config register
    `SVTEST(set_port_config)
        smartnic_322mhz_reg_pkg::reg_port_config_t set_config;
        smartnic_322mhz_reg_pkg::reg_port_config_t get_config;

        set_config.input_enable = smartnic_322mhz_reg_pkg::PORT_CONFIG_INPUT_ENABLE_PORT0;
        set_config.output_enable = smartnic_322mhz_reg_pkg::PORT_CONFIG_OUTPUT_ENABLE_USE_META;

        // Read port_config register and confirm init value
        env.smartnic_322mhz_reg_blk_agent.read_port_config(get_config);

        `FAIL_UNLESS(get_config == smartnic_322mhz_reg_pkg::INIT_PORT_CONFIG);

        // Write new config to port_config register
        env.smartnic_322mhz_reg_blk_agent.write_port_config(set_config);

        // Read back...
        env.smartnic_322mhz_reg_blk_agent.read_port_config(get_config);

        `FAIL_UNLESS(get_config == set_config);
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

    `SVUNIT_TESTS_END

endmodule
