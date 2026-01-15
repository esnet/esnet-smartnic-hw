`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module fec_test_datapath_unit_test;
    // Testcase name
    string name = "fec_test_datapath_ut";

    // SVUnit base testcase
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

    // smartnic_app_igr reg blk agent.
//    smartnic_app_igr_reg_verif_pkg::smartnic_app_igr_reg_blk_agent #() smartnic_app_igr_reg_blk_agent;

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
        env.set_debug_level(1);

        // Create P4 table agent
        vitisnetp4_agent = new(.hier_path(p4_dpic_hier_path)); // DPI-C P4 table agent requires hierarchical path to AXI-L write/read tasks

//        smartnic_app_igr_reg_blk_agent = new("smartnic_app_igr_reg_blk_agent", 'h20000);
//        smartnic_app_igr_reg_blk_agent.reg_agent = env.app_reg_agent;
    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // start environment
        env.run();

        p4_sim_dir = "../../../p4/sim/";

        tuser='{rss_enable: 1'b1, rss_entropy: 16'd0};

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

    int pkts=4, bytes=2048; // pkt and byte counts for 'test-fwd-p0', 'test-fwd-p2', and 'test-fwd-p4'.
    int offset;

    `SVUNIT_TESTS_BEGIN

        `SVTEST(init)
            // Initialize VitisNetP4 tables
            vitisnetp4_agent.init();
        `SVTEST_END

        `SVTEST(PHY_if_test)
            for (int i=0; i<2; i++) begin
                debug_msg($sformatf("Testing PHY%0b igr and egr interfaces...", i), 1);
                run_pkt_test(.testdir("test-fwd-p0"), .in_port(PHY0+i), .out_port(PHY0+i),
                             .tuser(tuser));
                offset = 'h100 * i;
                check_probe (offset + PROBE_TO_APP_IGR_P4_OUT0,  pkts, bytes);
                check_probe (offset + PROBE_TO_APP_IGR_IN0,      pkts, bytes);
                check_probe (offset + PROBE_TO_APP_EGR_IN0,      pkts, bytes);
                check_probe (offset + PROBE_TO_APP_EGR_OUT0,     pkts, bytes);
                check_probe (offset + PROBE_TO_APP_EGR_P4_IN0,   pkts, bytes);
            end
            check_cleared_probes;
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
