`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_datapath_unit_test;
    import packet_verif_pkg::*;
    import smartnic_pkg::*;

    // Testcase name
    string name = "smartnic_ut";

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

    task automatic passthru_test(input int pkts=10, mode=0, usec=1);
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
            passthru_test(.mode(64));
        `SVTEST_END

        `SVTEST(max_size_test)
            passthru_test(.pkts(4), .mode(9100), .usec(3));
        `SVTEST_END

        `SVTEST(tkeep_stress_test)
            passthru_test(.mode(1), .pkts(192), .usec(2));
        `SVTEST_END

        `SVTEST(single_pkts_test)
            env.driver[PHY0].set_min_gap(50); // set gap to 50 cycles
            env.driver[PHY1].set_min_gap(50);
            env.driver[PF0].set_min_gap(50);
            env.driver[PF1].set_min_gap(50);

            passthru_test(.usec(3));
        `SVTEST_END

        `SVTEST(phy_bypass_test)
            check_probe_control_defaults;

            // configure to pass traffic through bypass path.
            bypass_mode(0); bypass_mode(1); bypass_mode(2); bypass_mode(3);

            // setup 2 concurrent traffic streams.
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));

            #1us;  // 1us > (3ns/cycle * 10 pkts * 1518/64 cycles/pkt)

            // check counters and scoreboards.
            latch_probe_counters;

            check_probe(PROBE_FROM_CMAC0, 10, bytes[0]);
            check_probe(PROBE_TO_BYPASS0, 10, bytes[0]);
            check_probe(PROBE_TO_CMAC0,   10, bytes[0]);

            check_probe(PROBE_FROM_CMAC1, 10, bytes[1]);
            check_probe(PROBE_TO_BYPASS1, 10, bytes[1]);
            check_probe(PROBE_TO_CMAC1,   10, bytes[1]);

            check_phy0(.pkts(10));  check_phy1(.pkts(10)); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(host_bypass_test)
            host_mode(0); host_mode(1);  // direct egress traffic to PF VF2.
            bypass_mode(0); bypass_mode(1); bypass_mode(2); bypass_mode(3);

            packet_stream(.pkts(10), .mode(0), .bytes(bytes[2]), .tid(PF0_VF2), .tdest(PF0_VF2));
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[3]), .tid(PF1_VF2), .tdest(PF1_VF2));

            #1us;  // 1us > (3ns/cycle * 10 pkts * 1518/64 cycles/pkt)
            latch_probe_counters;

            check_probe(PROBE_FROM_PF0,     10, bytes[2]);
            check_probe(PROBE_FROM_PF0_VF2, 10, bytes[2]);
            check_probe(PROBE_TO_BYPASS0,   10, bytes[2]);
            check_probe(PROBE_TO_PF0_VF2,   10, bytes[2]);
            check_probe(PROBE_TO_PF0,       10, bytes[2]);

            check_probe(PROBE_FROM_PF1,     10, bytes[3]);
            check_probe(PROBE_FROM_PF1_VF2, 10, bytes[3]);
            check_probe(PROBE_TO_BYPASS1,   10, bytes[3]);
            check_probe(PROBE_TO_PF1_VF2,   10, bytes[3]);
            check_probe(PROBE_TO_PF1,       10, bytes[3]);

            check_pf0(.pkts(10));  check_pf1(.pkts(10)); check_phy0(); check_phy1();

            check_cleared_probe_counters;
        `SVTEST_END


         // ---------------------------
         // Path tests
         // ---------------------------
        `SVTEST(PHY0_to_PHY0_test)
            packet_stream(.bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            #1us;  // 1us > (3ns/cycle * 10 pkts * 1518/64 cycles/pkt)
            check_phy0(.pkts(10)) ; check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PHY1_to_PHY1_test)
            packet_stream(.bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));
            #1us;
            check_phy1(.pkts(10)) ; check_phy0(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PHY0_to_PHY1_test)
            env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths

            packet_stream(.bytes(bytes[1]), .tid(PHY0), .tdest(PHY1));
            #1us;
            check_phy1(.pkts(10)) ; check_phy0(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PHY1_to_PHY0_test)
            env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths

            packet_stream(.bytes(bytes[0]), .tid(PHY1), .tdest(PHY0));
            #1us;
            check_phy0(.pkts(10)) ; check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PHY0_to_PF0_VF2_test)
            env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);

            packet_stream(.bytes(bytes[2]), .tid(PHY0), .tdest(PF0_VF2));
            #1us;
            check_pf0(.pkts(10)) ; check_phy0(); check_phy1(); check_pf1();
        `SVTEST_END

        `SVTEST(PHY1_to_PF1_VF2_test)
            env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);

            packet_stream(.bytes(bytes[3]), .tid(PHY1), .tdest(PF1_VF2));
            #1us;
            check_pf1(.pkts(10)) ; check_phy0(); check_phy1(); check_pf0();
        `SVTEST_END

        `SVTEST(PHY0_to_PF0_test)
            app_mode(0);
            env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b11 );

            packet_stream(.bytes(bytes[2]), .tid(PHY0), .tdest(PF0));
            #1us;
            check_pf0(.pkts(10)) ; check_phy0(); check_phy1(); check_pf1();
        `SVTEST_END

        `SVTEST(PHY1_to_PF1_test)
            app_mode(1);
            env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b11 );

            packet_stream(.bytes(bytes[3]), .tid(PHY1), .tdest(PF1));
            #1us;
            check_pf1(.pkts(10)) ; check_phy0(); check_phy1(); check_pf0();
        `SVTEST_END

        `SVTEST(PHY0_to_PF0_VF0_test)
            app_mode(0);
            env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b10 );
            smartnic_app_igr_reg_blk_agent.write_app_igr_config(1'b1);

            packet_stream(.bytes(bytes[2]), .tid(PHY0), .tdest(PF0_VF0));
            #1us;
            check_pf0(.pkts(10)) ; check_phy0(); check_phy1(); check_pf1();
        `SVTEST_END

        `SVTEST(PHY1_to_PF1_VF0_test)
            app_mode(1);
            env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b10 );
            smartnic_app_igr_reg_blk_agent.write_app_igr_config(1'b1);

            packet_stream(.bytes(bytes[3]), .tid(PHY1), .tdest(PF1_VF0));
            #1us;
            check_pf1(.pkts(10)) ; check_phy0(); check_phy1(); check_pf0();
        `SVTEST_END

        `SVTEST(PF0_VF2_to_PHY0_test)
            packet_stream(.bytes(bytes[0]), .tid(PF0_VF2), .tdest(PHY0));
            #1us;
            check_phy0(.pkts(10)) ; check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PF1_VF2_to_PHY1_test)
            packet_stream(.bytes(bytes[1]), .tid(PF1_VF2), .tdest(PHY1));
            #1us;
            check_phy1(.pkts(10)) ; check_phy0(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PF0_VF2_to_PF0_VF2_test)
            env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);

            packet_stream(.bytes(bytes[2]), .tid(PF0_VF2), .tdest(PF0_VF2));
            #1us
            check_pf0(.pkts(10)) ; check_phy0(); check_phy1(); check_pf1();
        `SVTEST_END

        `SVTEST(PF1_VF2_to_PF0_VF2_test)
            env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);

            packet_stream(.bytes(bytes[3]), .tid(PF1_VF2), .tdest(PF1_VF2));
            #1us
            check_pf1(.pkts(10)) ; check_phy0(); check_phy1(); check_pf0();
        `SVTEST_END

        `SVTEST(PF0_VF1_to_PF0_VF1_test)
            packet_stream(.bytes(bytes[2]), .tid(PF0_VF1), .tdest(PF0_VF1));
            #1us;
            check_pf0(.pkts(10)) ; check_phy0(); check_phy1(); check_pf1();
        `SVTEST_END

        `SVTEST(PF1_VF1_to_PF1_VF1_test)
            packet_stream(.bytes(bytes[3]), .tid(PF1_VF1), .tdest(PF1_VF1));
            #1us;
            check_pf1(.pkts(10)) ; check_phy0(); check_phy1(); check_pf0();
        `SVTEST_END

        `SVTEST(PF0_VF0_to_PHY0_test)
            packet_stream(.bytes(bytes[0]), .tid(PF0_VF0), .tdest(PHY0));
            #1us;
            check_phy0(.pkts(10)) ; check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PF1_VF0_to_PHY1_test)
            packet_stream(.bytes(bytes[1]), .tid(PF1_VF0), .tdest(PHY1));
            #1us;
            check_phy1(.pkts(10)) ; check_phy0(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PF0_to_PHY0_test)
            packet_stream(.bytes(bytes[0]), .tid(PF0), .tdest(PHY0));
            #1us;
            check_phy0(.pkts(10)) ; check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PF1_to_PHY1_test)
            packet_stream(.bytes(bytes[1]), .tid(PF1), .tdest(PHY1));
            #1us;
            check_phy1(.pkts(10)) ; check_phy0(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(random_tid_test)
            port_t  tid, tdest;
            int     pkts;

            for (int i = 0; i < NUM_PORTS; i++) exp_pkts[i] = 0;

            for (int i = 0; i < 10; i++) begin  // send 10 consecutive pkt streams
                // randomly select tid from P0/P1 and PHY/PF/VF0/VF1/VF2.
                tid.raw = $urandom_range(0,9);

                tdest.encoded.num = tid.encoded.num;

                case (tid.encoded.typ)
                    PHY: tdest.encoded.typ = PHY;
                    PF:  tdest.encoded.typ = PHY;
                    VF0: tdest.encoded.typ = PHY;
                    VF1: tdest.encoded.typ = VF1;
                    VF2: tdest.encoded.typ = PHY;
                endcase

                // randomly select the number of packets and start traffic.
                pkts = $urandom_range(1,5);
                packet_stream(.bytes(bytes[0]), .pkts(pkts), .tid(tid), .tdest(tdest));

                case (tdest.encoded.typ)
                    PHY: if (tdest.encoded.num == P0) exp_pkts[PHY0] = exp_pkts[PHY0] + pkts;
                         else                         exp_pkts[PHY1] = exp_pkts[PHY1] + pkts;
                    VF1: if (tdest.encoded.num == P0) exp_pkts[PF0]  = exp_pkts[PF0]  + pkts;
                         else                         exp_pkts[PF1]  = exp_pkts[PF1]  + pkts;
                endcase

                #500ns;  // 500ns > (3ns/cycle * 5 pkts * 1518/64 cycles/pkt)
            end

            // check scoreboards.
            check_phy0(.pkts(exp_pkts[PHY0])); check_phy1(.pkts(exp_pkts[PHY1]));
            check_pf0 (.pkts(exp_pkts[PF0]));  check_pf1 (.pkts(exp_pkts[PF1]));
        `SVTEST_END


         // ---------------------------
         // Reconfiguration tests
         // ---------------------------
        `SVTEST(reconfig_demux_out_sel0)
            bypass_mode(0);
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[0]), .tid(PHY0), .tdest(PF0_VF2));
            fork
                #3us;

                @(posedge tb.DUT.axis_cmac_to_core[0].tlast)
                          env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b01);
            join
            check_phy0(.pkts(2));  check_phy1(); check_pf0(.pkts(2)); check_pf1();

        `SVTEST_END

        `SVTEST(reconfig_demux_out_sel1)
            bypass_mode(1);
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[1]), .tid(PHY1), .tdest(PF1_VF2));
            fork
                #3us;

                @(posedge tb.DUT.axis_cmac_to_core[1].tlast)
                          env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b10);
            join
            check_phy0(); check_phy1(.pkts(2));  check_pf0(); check_pf1(.pkts(2));

        `SVTEST_END

        `SVTEST(reconfig_bypass_swap)
            bypass_mode(0); bypass_mode(1);

            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY1));

            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY0));

            fork
                #3us;

                @(posedge tb.DUT.axis_cmac_to_core[0].tlast)
                          env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths
            join

            check_phy0(.pkts(4)) ; check_phy1(.pkts(4)); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(reconfig_mux_out_sel0)
            // initial configuration - PHY-to-PHY thru app, bypass paths swapped.
            app_mode(0);
            env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b10 );
            env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths

            // start traffic.  2 pkts PHY-to-PHY thru app, then two pkts thru BYPASS swap.
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY1));

            fork
                #3us;

                // reconfigure mux_out_sel for bypass mode after 1st packet.
                @(posedge tb.DUT.axis_cmac_to_core[0].tlast) bypass_mode(0);
            join

            check_phy0(.pkts(2)) ; check_phy1(.pkts(2)); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(reconfig_mux_out_sel1)
            // initial configuration - PHY-to-PHY thru app, bypass paths swapped.
            app_mode(1);
            env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b10 );
            env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths

            // start traffic.  2 pkts PHY-to-PHY thru app, then two pkts thru BYPASS swap.
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY0));

            fork
                #3us;

                // reconfigure mux_out_sel for bypass mode after 1st packet.
                @(posedge tb.DUT.axis_cmac_to_core[1].tlast) bypass_mode(1);
            join

            check_phy0(.pkts(2)) ; check_phy1(.pkts(2)); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(reconfig_mux_out_sel2)
            // initial configuration - PF_VF2-to-PHY thru app, bypass paths swapped.
            app_mode(2);
            env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b10 );
            env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths

            // start traffic.  2 pkts PF_VF2-to-PHY thru app, then two pkts thru BYPASS swap.
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[2]), .tid(PF0_VF2), .tdest(PHY0));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[2]), .tid(PF0_VF2), .tdest(PHY1));

            fork
                #3us;

                // reconfigure mux_out_sel for bypass mode after 1st packet.
                @(posedge tb.DUT.axis_host_to_core[0].tlast) bypass_mode(2);
            join

            check_phy0(.pkts(2)) ; check_phy1(.pkts(2)); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(reconfig_mux_out_sel3)
            // initial configuration - PF_VF2-to-PHY thru app, bypass paths swapped.
            app_mode(3);
            env.smartnic_app_reg_blk_agent.write_smartnic_app_igr_p4_out_sel( 2'b10 );
            env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths

            // start traffic.  2 pkts PF_VF2-to-PHY thru app, then two pkts thru BYPASS swap.
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[3]), .tid(PF1_VF2), .tdest(PHY1));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[3]), .tid(PF1_VF2), .tdest(PHY0));

            fork
                #3us;

                // reconfigure mux_out_sel for bypass mode after 1st packet.
                @(posedge tb.DUT.axis_host_to_core[1].tlast) bypass_mode(3);
            join

            check_phy0(.pkts(2)) ; check_phy1(.pkts(2)); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(traffic_after_drops0)
            // initial configuration. PHY-to-PHY thru app, bypass paths swapped.
            drop_mode(0);
            env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths

            // start traffic.  2 dropped pkts, then two pkts thru BYPASS swap.
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY1));

            fork
                #3us;

                @(posedge tb.DUT.axis_cmac_to_core[0].tlast) bypass_mode(0);
            join

            check_phy0() ; check_phy1(.pkts(2)); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(traffic_after_drops1)
            // initial configuration - PHY-to-PHY thru app, bypass paths swapped.
            drop_mode(1);
            env.smartnic_reg_blk_agent.write_bypass_config(1);  // swap paths

            // start traffic.  2 dropped pkts, then two pkts thru BYPASS swap.
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));
            packet_stream(.pkts(2), .mode(9000), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY0));

            fork
                #3us;

                @(posedge tb.DUT.axis_cmac_to_core[1].tlast) bypass_mode(1);
            join

            check_phy0(.pkts(2)) ; check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END


         // ---------------------------
         // Drop tests
         // ---------------------------
        `SVTEST(phy_drops_to_BYPASS0)
            drop_mode(0);
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            #1us;
            check_probe(PROBE_FROM_CMAC0, 10, bytes[0]);
            check_probe(DROPS_TO_BYPASS0, 10, bytes[0]);
            check_probe(PROBE_TO_BYPASS0, 0, 0);
            check_phy0();  check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

         `SVTEST(phy_drops_to_BYPASS1)
            drop_mode(1);
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));
            #1us;
            check_probe(PROBE_FROM_CMAC1, 10, bytes[1]);
            check_probe(DROPS_TO_BYPASS1, 10, bytes[1]);
            check_probe(PROBE_TO_BYPASS1, 0, 0);
            check_phy0();  check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(host_drops_to_BYPASS0)
            drop_mode(2);
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[2]), .tid(PF0_VF2), .tdest(PHY0));
            #1us;
            check_probe(PROBE_FROM_PF0_VF2, 10, bytes[2]);
            check_probe(DROPS_TO_BYPASS0, 10, bytes[2]);
            check_probe(PROBE_TO_BYPASS0, 0, 0);
            check_phy0();  check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(host_drops_to_BYPASS1)
            drop_mode(3);
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[3]), .tid(PF1_VF2), .tdest(PHY1));
            #1us;
            check_probe(PROBE_FROM_PF1_VF2, 10, bytes[3]);
            check_probe(DROPS_TO_BYPASS1, 10, bytes[3]);
            check_probe(PROBE_TO_BYPASS1, 0, 0);
            check_phy0();  check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(err_drops_from_PHY0)
            env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);

            packet_stream(.pkts(5), .mode(0), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0), .tuser(1));
            packet_stream(.pkts(5), .mode(0), .bytes(bytes[2]), .tid(PHY0), .tdest(PF0_VF2));
            #1us;
            check_probe(DROPS_ERR_FROM_CMAC0, 5, bytes[0]);
            check_phy0();  check_phy1(); check_pf0(.pkts(5)); check_pf1();
        `SVTEST_END

        `SVTEST(err_drops_from_PHY1)
            env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);

            packet_stream(.pkts(5), .mode(0), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1), .tuser(1));
            packet_stream(.pkts(5), .mode(0), .bytes(bytes[3]), .tid(PHY1), .tdest(PF1_VF2));
            #1us;
            check_probe(DROPS_ERR_FROM_CMAC1, 5, bytes[1]);
            check_phy0();  check_phy1(); check_pf0(); check_pf1(.pkts(5));
        `SVTEST_END

        `SVTEST(ovfl_drops_from_PHY0)
            drop_mode(0);
            exp_pkts[PHY0] = FIFO_DEPTH/$ceil(9100/64.0)+1;

            // force backpressure (deasserts tready from app core to ingress switch).
            switch_config.igr_sw_tpause = 1; env.smartnic_reg_blk_agent.write_switch_config(switch_config);

            // start traffic and check probes.
            packet_stream(.pkts(32), .mode(9100), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            #15us;
            check_probe(PROBE_FROM_CMAC0, exp_pkts[PHY0], exp_pkts[PHY0]*9100);
            check_probe(DROPS_OVFL_FROM_CMAC0, 32-exp_pkts[PHY0], (32-exp_pkts[PHY0])*9100);

            // release backpressure. start traffic and check probes.
            switch_config.igr_sw_tpause = 0; env.smartnic_reg_blk_agent.write_switch_config(switch_config);
            #5us;
            check_probe(DROPS_TO_BYPASS0, exp_pkts[PHY0], exp_pkts[PHY0]*9100);

            // send packets to PF0_VF2 and check scoreboards.
            app_mode(0); env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[0]), .tid(PHY0), .tdest(PF0_VF2));
            #1us;
            check_phy0();  check_phy1(); check_pf0(.pkts(10)); check_pf1();
        `SVTEST_END

        `SVTEST(ovfl_drops_from_PHY1)
            drop_mode(1);
            exp_pkts[PHY1] = FIFO_DEPTH/$ceil(9100/64.0)+1;

            switch_config.igr_sw_tpause = 1; env.smartnic_reg_blk_agent.write_switch_config(switch_config);

            packet_stream(.pkts(32), .mode(9100), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));
            #15us;
            check_probe(PROBE_FROM_CMAC1, exp_pkts[PHY1], exp_pkts[PHY1]*9100);
            check_probe(DROPS_OVFL_FROM_CMAC1, 32-exp_pkts[PHY1], (32-exp_pkts[PHY1])*9100);

            switch_config.igr_sw_tpause = 0; env.smartnic_reg_blk_agent.write_switch_config(switch_config);
            #5us;
            check_probe(DROPS_TO_BYPASS1, exp_pkts[PHY1], exp_pkts[PHY1]*9100);

            app_mode(1); env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);
            packet_stream(.pkts(10), .mode(0), .bytes(bytes[1]), .tid(PHY1), .tdest(PF1_VF2));
            #1us;
            check_phy0();  check_phy1(); check_pf0(); check_pf1(.pkts(10));
        `SVTEST_END

        `SVTEST(ovfl_drops_to_PHY0)
            exp_pkts[PHY0] = FIFO_DEPTH/$ceil(1518/64.0)+1;

            // set flow control threshold and check egr_flow_ctl.
            env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_EGR_FC_THRESH[0], 32'd1020);
            `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[0] == 1'b0 );

            // assert backpressure, start traffic, and check probes.
            tb.start_rx=0;
            packet_stream(.pkts(128), .mode(1518), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
            #10us;
            check_probe(PROBE_FROM_CMAC0, 128, 128*1518);
            check_probe(DROPS_OVFL_TO_CMAC0, 128-exp_pkts[PHY0], (128-exp_pkts[PHY0])*1518);
            `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[0] == 1'b1 );

            // relase backpressure and check egr_flow_ctl.
            tb.start_rx=1;
            @(posedge tb.axis_out_if[0].tlast) `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[0] == 1'b0 );

            // start traffic and check probes.
            #4us;
            check_probe(PROBE_TO_CMAC0, exp_pkts[PHY0], exp_pkts[PHY0]*1518);
            check_phy1(); check_pf0(); check_pf1();

            `FAIL_UNLESS_EQUAL(env.scoreboard[PHY0].got_processed(),   exp_pkts[PHY0]);
            `FAIL_UNLESS_EQUAL(env.scoreboard[PHY0].got_matched(),     exp_pkts[PHY0]);
            `FAIL_UNLESS_EQUAL(env.scoreboard[PHY0].exp_pending(), 128-exp_pkts[PHY0]);
        `SVTEST_END

        `SVTEST(ovfl_drops_to_PHY1)
            exp_pkts[PHY1] = FIFO_DEPTH/$ceil(1518/64.0)+1;

            env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_EGR_FC_THRESH[1], 32'd1020);
            `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[1] == 1'b0 );

            tb.start_rx=0;
            packet_stream(.pkts(128), .mode(1518), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));
            #10us;
            check_probe(PROBE_FROM_CMAC1, 128, 128*1518);
            check_probe(DROPS_OVFL_TO_CMAC1, 128-exp_pkts[PHY1], (128-exp_pkts[PHY1])*1518);
            `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[1] == 1'b1 );

            tb.start_rx=1;
            @(posedge tb.axis_out_if[1].tlast) `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[1] == 1'b0 );

            #4us;
            check_probe(PROBE_TO_CMAC1, exp_pkts[PHY1], exp_pkts[PHY1]*1518);
            check_phy0(); check_pf0(); check_pf1();

            `FAIL_UNLESS_EQUAL(env.scoreboard[PHY1].got_processed(),   exp_pkts[PHY1]);
            `FAIL_UNLESS_EQUAL(env.scoreboard[PHY1].got_matched(),     exp_pkts[PHY1]);
            `FAIL_UNLESS_EQUAL(env.scoreboard[PHY1].exp_pending(), 128-exp_pkts[PHY1]);
        `SVTEST_END

        `SVTEST(ovfl_drops_to_PF0)
            exp_pkts[PF0] = FIFO_DEPTH/$ceil(1518/64.0)+1;
            host_mode(0);

            env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_EGR_FC_THRESH[2], 32'd1020);
            `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[2] == 1'b0 );

            tb.start_rx=0;
            packet_stream(.pkts(128), .mode(1518), .bytes(bytes[2]), .tid(PHY0), .tdest(PF0_VF2));
            #10us;
            check_probe(PROBE_FROM_CMAC0, 128, 128*1518);
            check_probe(DROPS_OVFL_TO_PF0, 128-exp_pkts[PF0], (128-exp_pkts[PF0])*1518);
            `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[2] == 1'b1 );

            tb.start_rx=1;
            @(posedge tb.axis_out_if[2].tlast) `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[2] == 1'b0 );

            #4us;
            check_probe(PROBE_TO_PF0, exp_pkts[PF0], exp_pkts[PF0]*1518);
            check_phy0(); check_phy1(); check_pf1();

            `FAIL_UNLESS_EQUAL(env.scoreboard[PF0].got_processed(),   exp_pkts[PF0]);
            `FAIL_UNLESS_EQUAL(env.scoreboard[PF0].got_matched(),     exp_pkts[PF0]);
            `FAIL_UNLESS_EQUAL(env.scoreboard[PF0].exp_pending(), 128-exp_pkts[PF0]);
        `SVTEST_END

        `SVTEST(ovfl_drops_to_PF1)
            exp_pkts[PF1] = FIFO_DEPTH/$ceil(1518/64.0)+1;
            host_mode(1);

            env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_EGR_FC_THRESH[3], 32'd1020);
            `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[3] == 1'b0 );

            tb.start_rx=0;
            packet_stream(.pkts(128), .mode(1518), .bytes(bytes[3]), .tid(PHY1), .tdest(PF1_VF2));
            #10us;
            check_probe(PROBE_FROM_CMAC1, 128, 128*1518);
            check_probe(DROPS_OVFL_TO_PF1, 128-exp_pkts[PF1], (128-exp_pkts[PF1])*1518);
            `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[3] == 1'b1 );

            tb.start_rx=1;
            @(posedge tb.axis_out_if[3].tlast) `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[3] == 1'b0 );

            #4us;
            check_probe(PROBE_TO_PF1, exp_pkts[PF1], exp_pkts[PF1]*1518);
            check_phy0(); check_phy1(); check_pf0();

            `FAIL_UNLESS_EQUAL(env.scoreboard[PF1].got_processed(),   exp_pkts[PF1]);
            `FAIL_UNLESS_EQUAL(env.scoreboard[PF1].got_matched(),     exp_pkts[PF1]);
            `FAIL_UNLESS_EQUAL(env.scoreboard[PF1].exp_pending(), 128-exp_pkts[PF1]);
        `SVTEST_END

        `SVTEST(PF0_out_of_range_test)
            env.smartnic_reg_blk_agent.write_igr_q_config_0(0, {12'd0, 12'd0});

            packet_stream(.bytes(bytes[0]), .tid(PF0), .tdest(PHY0));
            #1us;
            check_probe(PROBE_FROM_PF0,      10, bytes[0]);
            check_probe(DROPS_Q_RANGE_FAIL0, 10, bytes[0]);
            check_phy0() ; check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

        `SVTEST(PF1_out_of_range_test)
            env.smartnic_reg_blk_agent.write_igr_q_config_1(0, {12'd0, 12'd0});

            packet_stream(.bytes(bytes[1]), .tid(PF1), .tdest(PHY1));
            #1us;
            check_probe(PROBE_FROM_PF1,      10, bytes[1]);
            check_probe(DROPS_Q_RANGE_FAIL1, 10, bytes[1]);
            check_phy0() ; check_phy1(); check_pf0(); check_pf1();
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
