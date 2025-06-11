`include "svunit_defines.svh"

import tb_pkg::*;
import p4_proc_verif_pkg::*;
import smartnic_app_verif_pkg::*;

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module smartnic_app_datapath_unit_test
#(
    parameter int HDR_LENGTH = 0
 );
    // Testcase name
    string name = $sformatf("smartnic_app_datapath_hdrlen_%0d_ut", HDR_LENGTH);

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
    // via the testbench environment class (smartnic_env).
    // A reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::smartnic_env env;

    // VitisNetP4 table agent
    vitisnetp4_igr_verif_pkg::vitisnetp4_igr_agent vitisnetp4_agent;

    // p4_proc register agent and variables
    p4_proc_reg_agent  p4_proc_reg_agent;
    p4_proc_reg_pkg::reg_p4_proc_config_t  p4_proc_config;

    tuser_smartnic_meta_t tuser=0;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../../../../src/smartnic/tests/common/tasks.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build testbench
        tb.build();

        // Retrieve reference to testbench environment class
        env = tb.env;

        // Create P4 table agent
        vitisnetp4_agent = new;
        vitisnetp4_agent.create("tb"); // DPI-C P4 table agent requires hierarchial
                                       // path to AXI-L write/read tasks
        // Create P4 reg agent
        p4_proc_reg_agent = new("p4_proc_reg_agent", env.reg_agent, env.AXIL_VITISNET_OFFSET + 'h60000);

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

        // write hdr_length register (hdr_length = 0B to disable split-join logic).
        p4_proc_config.hdr_length = HDR_LENGTH;
        p4_proc_reg_agent.write_p4_proc_config(p4_proc_config);

        // configure all ingress interfaces to direct pkts to app core.
        app_mode(0); app_mode(1); app_mode(2); app_mode(3);

        // initialize VitisNetP4 tables
        vitisnetp4_agent.init();

        tuser=0;
    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        // stop environment
        env.stop();

        svunit_ut.teardown();

        // clean up VitisNetP4 tables
        vitisnetp4_agent.terminate();

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

    task automatic run_pkt_test (input string testdir, port_t in_port=0, out_port=0,
                                 tuser_smartnic_meta_t tuser=0);
        string filename;

       `INFO("Writing VitisNetP4 tables...");
        filename = {"../../../../vitisnetp4/p4/sim/", testdir, "/cli_commands.txt"};
        vitisnetp4_agent.table_init_from_file(filename);

       `INFO("Writing expected pcap data to scoreboard...");
        filename = {"../../../../vitisnetp4/p4/sim/", testdir, "/packets_out.pcap"};
        env.pcap_to_scoreboard (.filename(filename), .tid('x), .tdest('x), .tuser(tuser), .out_port(out_port));

       `INFO("Starting simulation...");
        filename = {"../../../../vitisnetp4/p4/sim/", testdir, "/packets_in.pcap"};
        env.pcap_to_driver     (.filename(filename), .driver(env.driver[in_port]));

        #3us;
       `FAIL_IF_LOG(env.scoreboard0.report(msg), msg);
       `FAIL_IF_LOG(env.scoreboard1.report(msg), msg);
       `FAIL_IF_LOG(env.scoreboard2.report(msg), msg);
       `FAIL_IF_LOG(env.scoreboard3.report(msg), msg);
    endtask


    `SVUNIT_TESTS_BEGIN
       `SVTEST(rss_metadata_test)
           // tests propagation of rss_metadata/qid to smartnic egress ports.
           string testdir  = "../../../../vitisnetp4/p4/sim/test-default/";
           string filename = {testdir, "cli_commands.txt"};

           tuser='x;

           // ingress queue assignments. qid 0 maps to PF0_VF2 and PF1_VF2.
           env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_Q_CONFIG_0[3], {12'h1, 12'h0});
           env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_Q_CONFIG_1[3], {12'h1, 12'h0});

           // egr traffic is directed to PF0_VF2 and PF1_VF2.
           env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(2'b11);

           env.smartnic_hash2qid_0_reg_blk_agent.write_q_config (3, 1);  // PF0_VF2 base address = 1.
           env.smartnic_hash2qid_1_reg_blk_agent.write_q_config (3, 16); // PF1_VF2 base address = 16.

           // configure qid to match entropy values for indexes PF0_VF2 and PF0_VF1.
           env.smartnic_hash2qid_0_reg_blk_agent.write_vf2_table (PF0_VF2, PF0_VF2);
           env.smartnic_hash2qid_1_reg_blk_agent.write_vf2_table (PF1_VF2, PF1_VF2);

           vitisnetp4_agent.table_init_from_file(filename);  // configure p4 tables.

           // program scoreboards with expected data for PF0 and PF1.
           filename = {testdir, "packets_out.pcap"};
           tuser.rss_enable  = 1'b1;
           tuser.rss_entropy = PF0_VF2 + 1;
           env.pcap_to_scoreboard (.filename(filename), .tid('x), .tdest('x), .tuser(tuser), .out_port(PF0));
           tuser.rss_entropy = PF1_VF2 + 16;
           env.pcap_to_scoreboard (.filename(filename), .tid('x), .tdest('x), .tuser(tuser), .out_port(PF1));

           // program drivers with traffic data for PF0 and PF1.  start simulation.
           env.pcap_to_driver     (.filename(filename), .driver(env.driver[PF0]));
           env.pcap_to_driver     (.filename(filename), .driver(env.driver[PF1]));

           #4us;
          `FAIL_IF_LOG(env.scoreboard0.report(msg), msg);
          `FAIL_IF_LOG(env.scoreboard1.report(msg), msg);
          `FAIL_IF_LOG(env.scoreboard2.report(msg), msg);
          `FAIL_IF_LOG(env.scoreboard3.report(msg), msg);

       `SVTEST_END

       `SVTEST(PHY0_to_PHY0_test)
           run_pkt_test ( .testdir("test-fwd-p0"), .in_port(PHY0), .out_port(PHY0) );
       `SVTEST_END

       `SVTEST(PHY0_to_PHY1_test)
           run_pkt_test ( .testdir("test-fwd-p1"), .in_port(PHY0), .out_port(PHY1) );
       `SVTEST_END

       `SVTEST(PHY1_to_PHY0_test)
           run_pkt_test ( .testdir("test-fwd-p0"), .in_port(PHY1), .out_port(PHY0) );
       `SVTEST_END

       `SVTEST(PHY1_to_PHY1_test)
           run_pkt_test ( .testdir("test-fwd-p1"), .in_port(PHY1), .out_port(PHY1) );
       `SVTEST_END

       `include "../../../vitisnetp4/p4/sim/run_pkt_test_incl.svh"

    `SVUNIT_TESTS_END

endmodule



// 'Boilerplate' unit test wrapper code
//  Builds unit test for a specific axi4s_split_join configuration in a way
//  that maintains SVUnit compatibility

`define P4_ONLY_DATAPATH_UNIT_TEST(HDR_LENGTH)\
  import svunit_pkg::svunit_testcase;\
  svunit_testcase svunit_ut;\
  smartnic_app_datapath_unit_test #(HDR_LENGTH) test();\
  function void build();\
    test.build();\
    svunit_ut = test.svunit_ut;\
  endfunction\
  function void __register_tests();\
    test.__register_tests();\
  endfunction \
  task run();\
    test.run();\
  endtask


module smartnic_app_datapath_hdrlen_0_unit_test;
`P4_ONLY_DATAPATH_UNIT_TEST(0)
endmodule

module smartnic_app_datapath_hdrlen_128_unit_test;
`P4_ONLY_DATAPATH_UNIT_TEST(128)
endmodule
