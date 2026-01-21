`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_egress_qs_unit_test;
    import smartnic_pkg::*;

    // Testcase name
    string name = "smartnic_egress_qs_ut";

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

    smartnic_app_igr_demux_reg_verif_pkg::smartnic_app_igr_reg_blk_agent  #() smartnic_app_igr_reg_blk_agent;

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
        env = tb.build();
        env.pkt_capture_monitor.disable_autostart();

        smartnic_app_igr_reg_blk_agent = new("smartnic_app_igr_reg_blk_agent", 'h100000 + 'h20000);
        smartnic_app_igr_reg_blk_agent.reg_agent = env.reg_agent;
    endfunction

    //===================================
    // Local test variables
    //===================================
    real FIFO_DEPTH = 1306.0; // 1024 - 4 (fifo_async) + 2 x 143 (axi4s_pkt_discard_ovfl)

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // start environment
        env.run();

        env.enable_egress_qs();

        // configure all ingress ports for BYPASS mode.
        bypass_mode(0); bypass_mode(1); bypass_mode(2); bypass_mode(3);

        // set igr queue configuration for all igr ports. 512 queues per if x 8 ifs.
        env.smartnic_reg_blk_agent.write_igr_q_config_0(0, {12'd512, 12'd0});
        env.smartnic_reg_blk_agent.write_igr_q_config_0(1, {12'd512, 12'd512});
        env.smartnic_reg_blk_agent.write_igr_q_config_0(2, {12'd512, 12'd1024});
        env.smartnic_reg_blk_agent.write_igr_q_config_0(3, {12'd511, 12'd1536}); // queue 1536+512 out-of-range

        env.smartnic_reg_blk_agent.write_igr_q_config_1(0, {12'd512, 12'd2048});
        env.smartnic_reg_blk_agent.write_igr_q_config_1(1, {12'd512, 12'd2560});
        env.smartnic_reg_blk_agent.write_igr_q_config_1(2, {12'd512, 12'd3072});
        env.smartnic_reg_blk_agent.write_igr_q_config_1(3, {12'd511, 12'd3584}); // queue 3584+512 out-of-range

        // set egr queue configuration for all egr ports. base qid per if x 8 ifs.
        env.smartnic_hash2qid_0_reg_blk_agent.write_q_config (0, 12'd2048);
        env.smartnic_hash2qid_0_reg_blk_agent.write_q_config (1, 12'd2560);
        env.smartnic_hash2qid_0_reg_blk_agent.write_q_config (2, 12'd3072);
        env.smartnic_hash2qid_0_reg_blk_agent.write_q_config (3, 12'd3584);

        env.smartnic_hash2qid_1_reg_blk_agent.write_q_config (0, 12'd0);
        env.smartnic_hash2qid_1_reg_blk_agent.write_q_config (1, 12'd512);
        env.smartnic_hash2qid_1_reg_blk_agent.write_q_config (2, 12'd1024);
        env.smartnic_hash2qid_1_reg_blk_agent.write_q_config (3, 12'd1536);
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

    task automatic passthru_test(input int pkts=10, mode=0, usec=5);
        // configure to pass traffic through app (PHY-to-HOST & HOST-to-PHY)
        app_mode(0); app_mode(1); app_mode(2); app_mode(3);
        env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b11 );

        // setup 4 concurrent traffic streams.
        packet_stream(.pkts(pkts), .mode(mode), .bytes(bytes[0]), .tid(PHY0), .tdest(PF0));
        packet_stream(.pkts(pkts), .mode(mode), .bytes(bytes[1]), .tid(PHY1), .tdest(PF1));
        packet_stream(.pkts(pkts), .mode(mode), .bytes(bytes[2]), .tid(PF0),  .tdest(PHY0));
        packet_stream(.pkts(pkts), .mode(mode), .bytes(bytes[3]), .tid(PF1),  .tdest(PHY1));

        #(usec*1us);  // 1us > (3ns/cycle * 10 pkts * 1518/64 cycles/pkt)

        // check counters and scoreboards.
        latch_probe_counters;

        check_probe(PROBE_FROM_CMAC0,   pkts, bytes[0]);
        check_probe(PROBE_CORE_TO_APP0, pkts, bytes[0]);
        check_probe(PROBE_TO_PF0,       pkts, bytes[0]);

        check_probe(PROBE_FROM_CMAC1,   pkts, bytes[1]);
        check_probe(PROBE_CORE_TO_APP1, pkts, bytes[1]);
        check_probe(PROBE_TO_PF1,       pkts, bytes[1]);

        check_probe(PROBE_FROM_PF0,     pkts, bytes[2]);
        check_probe(PROBE_APP0_TO_CORE, pkts, bytes[2]);
        check_probe(PROBE_TO_CMAC0,     pkts, bytes[2]);

        check_probe(PROBE_FROM_PF1,     pkts, bytes[3]);
        check_probe(PROBE_APP1_TO_CORE, pkts, bytes[3]);
        check_probe(PROBE_TO_CMAC1,     pkts, bytes[3]);

        check_phy0(.pkts(pkts)); check_phy1(.pkts(pkts));
        check_pf0 (.pkts(pkts)); check_pf1 (.pkts(pkts));
    endtask



    `SVUNIT_TESTS_BEGIN

        `SVTEST(reset)
        `SVTEST_END

         // ---------------------------
         // Traffic tests
         // ---------------------------
        `SVTEST(basic_sanity)
            passthru_test();
            check_cleared_probe_counters;
        `SVTEST_END

        `SVTEST(min_size_test)
            env.driver[PHY0].set_min_gap(8); // set gap to 50 cycles
            env.driver[PHY1].set_min_gap(8);
            env.driver[PF0].set_min_gap(8);
            env.driver[PF1].set_min_gap(8);

            passthru_test(.mode(64));
        `SVTEST_END

        `SVTEST(max_size_test)
            passthru_test(.pkts(4), .mode(9100), .usec(20));
        `SVTEST_END

        `SVTEST(tkeep_stress_test)
            env.driver[PHY0].set_min_gap(8); // set gap to 50 cycles
            env.driver[PHY1].set_min_gap(8);
            env.driver[PF0].set_min_gap(8);
            env.driver[PF1].set_min_gap(8);

            passthru_test(.mode(1), .pkts(192), .usec(20));
        `SVTEST_END

        `SVTEST(single_pkts_test)
            env.driver[PHY0].set_min_gap(50); // set gap to 50 cycles
            env.driver[PHY1].set_min_gap(50);
            env.driver[PF0].set_min_gap(50);
            env.driver[PF1].set_min_gap(50);

            passthru_test(.usec(20));
        `SVTEST_END

        `SVTEST(backpressure_test)
            env.monitor[PHY0].set_tpause(2);
            env.monitor[PHY1].set_tpause(2);
            passthru_test(.pkts(128), .usec(20));
        `SVTEST_END

        `SVTEST(stress_test)
            passthru_test(.pkts(2048), .usec(200));
        `SVTEST_END




    `SVUNIT_TESTS_END

endmodule
