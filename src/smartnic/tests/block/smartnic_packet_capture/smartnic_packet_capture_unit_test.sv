`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_packet_capture_unit_test;
    import packet_verif_pkg::*;
    import smartnic_pkg::*;

    // Testcase name
    string name = "smartnic_packet_capture_ut";

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

        env.smartnic_reg_blk_agent.write_switch_config({1'b1, 1'b0, 1'b0, 1'b0});  // set 'pkt_capture_enable'.
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

    task automatic pkt_capture_test(input int pkts=2, mode=$urandom_range(64, 512), port_num_t port=P0);
        app_mode(port);
        env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b11 );

        // run packets from PHY to pkt_capture block. Use 'UNSET' codepoint to direct traffic to pkt_capture scoreboard.
        packet_stream(.pkts(pkts), .mode(mode), .bytes(bytes[0]), .tid({PHY,port}), .tdest({UNSET,port}));

        fork
            #1ms; // timeout.

            while (env.scoreboard[4].got_processed() < pkts) #10us;  // pkt_capture scoreboard.
        join_any

        #10us;
        check_scoreboard (.port(4), .pkts(pkts));  // pkt_capture scoreboard.
        check_pf0(.pkts()) ; check_phy0(); check_phy1(); check_pf1();
    endtask

    `SVUNIT_TESTS_BEGIN

        `SVTEST(reset)
        `SVTEST_END

        `SVTEST(PHY0_to_pkt_capture_test)
             pkt_capture_test(.port(P0));
        `SVTEST_END

        `SVTEST(PHY1_to_pkt_capture_test)
             pkt_capture_test(.port(P1));
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
