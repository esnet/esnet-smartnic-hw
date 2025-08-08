`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_packet_playback_unit_test;
    import packet_verif_pkg::*;
    import smartnic_pkg::*;

    // Testcase name
    string name = "smartnic_packet_playback_ut";

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
        env.set_debug_level(1);

        smartnic_app_igr_reg_blk_agent = new("smartnic_app_igr_reg_blk_agent", 'h100000 + 'h20000);
        smartnic_app_igr_reg_blk_agent.reg_agent = env.reg_agent;
    endfunction

    //===================================
    // Local test variables
    //===================================
    localparam type PKT_PLAYBACK_META_T = struct packed {port_t tid; port_t tdest; bit tuser;};

    PKT_PLAYBACK_META_T meta = '0;

    int len=100;
    int got_int;

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // start environment
        env.run();

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

    task automatic pkt_playback_test(input int pkts=1, len=0, port_t tid=PF0, tdest=PHY0);
        int port;

        if (len==0) len = $urandom_range(64, 512);
        for (int i = 0; i < pkts; i++)
            env.pkt_to_playback(.len(len), .id(i), .tid(tid), .tdest(tdest));

        case(tdest)
            PF0_VF1: port = PF0;            
            PF1_VF1: port = PF1;            
            default: port = tdest;
        endcase

        fork
            #1ms; // timeout.

            while (env.scoreboard[port].got_processed() < pkts) #10us;
        join_any

        #10us;
        `FAIL_IF_LOG(env.scoreboard[port].report(msg) > 0, msg );
        `FAIL_UNLESS_EQUAL(env.scoreboard[port].got_matched(), pkts);
    endtask


    `SVUNIT_TESTS_BEGIN

        `SVTEST(reset)
        `SVTEST_END

        `SVTEST(info)
            // Check packet memory size
            env.pkt_playback_driver.agent.read_mem_size(got_int);
            `FAIL_UNLESS_EQUAL(got_int, 16384);

            // Check metadata width
            env.pkt_playback_driver.agent.read_meta_width(got_int);
            `FAIL_UNLESS_EQUAL(got_int, $bits(PKT_PLAYBACK_META_T));
        `SVTEST_END

         // ---------------------------
         // Traffic tests
         // ---------------------------

        `SVTEST(basic_sanity)
            pkt_playback_test(.pkts(5), .tid(PF0), .tdest(PHY0));
        `SVTEST_END

        `SVTEST(pkt_playback_to_PF0)
            pkt_playback_test(.len(len), .tid(PF0), .tdest(PHY0));
            check_probe(PROBE_FROM_APP_PF0, 1, len);
        `SVTEST_END

        `SVTEST(pkt_playback_to_PF1)
            pkt_playback_test(.len(len), .tid(PF1), .tdest(PHY1));
            check_probe(PROBE_FROM_APP_PF1, 1, len);
        `SVTEST_END

        `SVTEST(pkt_playback_to_PF0_VF0)
            pkt_playback_test(.len(len), .tid(PF0_VF0), .tdest(PHY0));
            check_probe(PROBE_FROM_APP_PF0_VF0, 1, len);
        `SVTEST_END

        `SVTEST(pkt_playback_to_PF1_VF0)
            pkt_playback_test(.len(len), .tid(PF1_VF0), .tdest(PHY1));
            check_probe(PROBE_FROM_APP_PF1_VF0, 1, len);
        `SVTEST_END

        `SVTEST(pkt_playback_to_PF0_VF1)
            pkt_playback_test(.len(len), .tid(PF0_VF1), .tdest(PF0_VF1));
            check_probe(PROBE_FROM_APP_PF0_VF1, 1, len);
        `SVTEST_END

        `SVTEST(pkt_playback_to_PF1_VF1)
            pkt_playback_test(.len(len), .tid(PF1_VF1), .tdest(PF1_VF1));
            check_probe(PROBE_FROM_APP_PF1_VF1, 1, len);
        `SVTEST_END

        `SVTEST(pkt_playback_to_PF0_VF2)
            pkt_playback_test(.len(len), .tid(PF0_VF2), .tdest(PHY0));
            check_probe(PROBE_FROM_PF0_VF2, 1, len);
        `SVTEST_END

        `SVTEST(pkt_playback_to_PF1_VF2)
            pkt_playback_test(.len(len), .tid(PF1_VF2), .tdest(PHY1));
            check_probe(PROBE_FROM_PF1_VF2, 1, len);
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
