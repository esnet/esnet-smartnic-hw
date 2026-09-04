`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 100us

module sar_test_ctrl_unit_test;

    string name = "sar_test_ctrl_ut";
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    tb_pkg::tb_env env;

    // VitisNetP4 table agent
    vitisnetp4_igr_verif_pkg::vitisnetp4_igr_agent vitisnetp4_agent;

    sar_test_verif_pkg::sar_test_reg_agent sar_test_reg_agent;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../../../../src/smartnic_app/tests/common/tasks.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        env = tb.build();

        // Create P4 table agent
        vitisnetp4_agent = new(.hier_path(p4_dpic_hier_path)); // DPI-C P4 table agent requires hierarchical path to AXI-L write/read tasks

        // sar_test block is at 0x100000 (smartnic_app_igr base) + 0x00000 (sar_test offset)
        sar_test_reg_agent = new("sar_test_reg_agent", env.app_reg_agent, 'h100000);

    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        env.run();

        #100ns;
    endtask

    //===================================
    // Teardown
    //===================================
    task teardown();
        env.stop();

        svunit_ut.teardown();
    endtask

    //=======================================================================
    // TESTS
    //=======================================================================
    `SVUNIT_TESTS_BEGIN

    // Verify expected sar_test id register value (0x53415254 = "SART")
    `SVTEST(check_id)
        bit error;
        string msg;

        sar_test_reg_agent.check_id(error, msg);
        `FAIL_IF_LOG(
            error == 1,
            msg
        );
    `SVTEST_END

    // Direct read of id register
    `SVTEST(read_sar_test_id)
        logic [31:0] got_data;

        sar_test_reg_agent.read_id(got_data);
        `FAIL_UNLESS(got_data == sar_test_reg_pkg::INIT_ID);
    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
