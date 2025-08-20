`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module p4_proc_datapath_unit_test
#(
    parameter int HDR_LENGTH = 0
 );
    // Testcase name
    string name = $sformatf("p4_proc_datapath_hdrlen_%0d_ut", HDR_LENGTH);

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

    // VitisNetP4 table agent
    vitisnetp4_verif_pkg::vitisnetp4_agent vitisnetp4_agent;

    p4_proc_reg_pkg::reg_p4_proc_config_t    p4_proc_config;
    p4_proc_reg_pkg::reg_p4_bypass_config_t  p4_bypass_config;
    p4_proc_reg_pkg::reg_trunc_config_t      trunc_config;


    //===================================
    // Import common testcase tasks
    //=================================== 
    `include "../common/tasks.svh"

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

    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // start environment
        env.run();
        // Write hdr_length register (set hdr_length to 0B to disable split-join logic).
        p4_proc_config.hdr_length = HDR_LENGTH;
        env.p4_proc_reg_agent.write_p4_proc_config(p4_proc_config);

        // initialize p4_bypass_config.
        p4_bypass_config.p4_bypass_enable          = 1'b0;
        p4_bypass_config.p4_bypass_egr_port_num_0  = 1'b0;
        p4_bypass_config.p4_bypass_egr_port_type_0 =   '0;
        p4_bypass_config.p4_bypass_egr_port_num_1  = 1'b1;
        p4_bypass_config.p4_bypass_egr_port_type_1 =   '0;

        // initialize expected 'tuser' signal.
        tuser='{rss_enable: 1'b1, rss_entropy: '0};

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

    `SVUNIT_TESTS_BEGIN

    `SVTEST(init)
        // Initialize VitisNetP4 tables
        vitisnetp4_agent.init();
    `SVTEST_END

    `include "../../../vitisnetp4/p4/sim/run_pkt_test_incl.svh"

    `SVTEST(test_fwd_p3)
        run_pkt_test ( .testdir("test-fwd-p3"), .tuser(tuser), .tdest(3) );
    `SVTEST_END


    `SVTEST(test_traffic_mux)
        string testdir_0 = "test-default";
        string testdir_1 = "test-fwd-p1";
        string filename;

        // reset rss_enable (when bypassing p4 processor).
        tuser.rss_enable = 1'b0;

        // force output tuser for ALL pkts (for consistency in p4-mode and p4-bypass-mode).
        force tb.axis_out_if[0].tuser = tuser;
        force tb.axis_out_if[1].tuser = tuser;

        write_p4_tables ( .testdir(testdir_1) );

        repeat (3) begin
            // post expected pkts to scoreboards.
            filename = {p4_sim_dir, testdir_1, "/packets_out.pcap"};
            env.pcap_to_scoreboard (.filename(filename), .tuser(tuser), .tdest(1),
                                    .scoreboard(env.scoreboard[1]) );

            filename = {p4_sim_dir, testdir_0, "/packets_out.pcap"};
            env.pcap_to_scoreboard (.filename(filename), .tuser(tuser),
                                    .scoreboard(env.scoreboard[0]) );

            // inject input pkts to drivers.
            filename = {p4_sim_dir, testdir_1, "/packets_in.pcap"};
            env.pcap_to_driver     (.filename(filename), .driver(env.driver[1]));

            filename = {p4_sim_dir, testdir_0, "/packets_in.pcap"};
            env.pcap_to_driver     (.filename(filename), .driver(env.driver[0]));

            #3us;  // time to allow packets to flow through DUT.

            // toggle p4_bypass register.
            p4_bypass_config.p4_bypass_enable = ~p4_bypass_config.p4_bypass_enable;
            env.p4_proc_reg_agent.write_p4_bypass_config(p4_bypass_config);

            #3us;  // time to allow 'p4_bypass' timer to expire.
        end

        for (int i=0; i < env.NUM_PROC_PORTS; i++) `FAIL_IF_LOG(env.scoreboard[i].report(msg) > 0, msg);

        release tb.axis_out_if[0].tuser;
        release tb.axis_out_if[1].tuser;

    `SVTEST_END


    `SVTEST(test_egr_pkt_trunc)
        string testdir_0 = "test-default";
        string testdir_1 = "test-fwd-p1";
        string filename;

        logic [15:0] len;

        write_p4_tables ( .testdir(testdir_1) );

        repeat (3) begin
            len =  $urandom_range(65,300);  // generate random max pkt length.

            // write trunc_config register.
            trunc_config.enable = 1'b1;
            trunc_config.trunc_enable = 1'b1;
            trunc_config.trunc_length = len;
            env.p4_proc_reg_agent.write_trunc_config(trunc_config);

            // set expected tuser fields
            tuser='{rss_enable: 1'b1, rss_entropy: '0};

            // post expected pkts to scoreboards.
            filename = {p4_sim_dir, testdir_1, "/packets_out.pcap"};
            env.pcap_to_scoreboard (.filename(filename), .tuser(tuser), .tdest(1),
                                    .scoreboard(env.scoreboard[1]), .len(len) );

            filename = {p4_sim_dir, testdir_0, "/packets_out.pcap"};
            env.pcap_to_scoreboard (.filename(filename), .tuser(tuser),
                                    .scoreboard(env.scoreboard[0]), .len(len) );

            // inject input pkts to drivers.
            filename = {p4_sim_dir, testdir_1, "/packets_in.pcap"};
            env.pcap_to_driver     (.filename(filename), .driver(env.driver[1]));        

            filename = {p4_sim_dir, testdir_0, "/packets_in.pcap"};
            env.pcap_to_driver     (.filename(filename), .driver(env.driver[0]));        

            #3us;  // time to allow packets to flow through DUT.
        end

        for (int i=0; i < env.NUM_PROC_PORTS; i++) `FAIL_IF_LOG(env.scoreboard[i].report(msg) > 0, msg);

    `SVTEST_END


    `SVTEST(test_unset_err_drops)
        int pkts=4, bytes=2048; // pkt and byte counts for 'test-unset'.

        fork
           begin
              // run packets from port 1 to port 1 (includes programming the p4 tables).
              run_pkt_test ( .testdir("test-unset"), .in_port(1), .out_port(1),
                             .check_scoreboards(0) );
              check_probe (DROPS_UNSET_ERR_PORT_1, pkts, bytes);
             `FAIL_UNLESS_EQUAL(env.scoreboard[1].got_processed(), 0);

              // run packets from port 0 to port 0 (skips reprogramming the p4 tables).
              run_pkt_test ( .testdir("test-unset"), .in_port(0), .out_port(0),
                             .check_scoreboards(0), .write_tables(0) );
              check_probe (DROPS_UNSET_ERR_PORT_0, pkts, bytes);
             `FAIL_UNLESS_EQUAL(env.scoreboard[0].got_processed(), 0);
           end
           begin
              // monitor output interfaces for any valid axi4s transactions.
              forever @(negedge tb.axis_out_if[0].aclk) begin
                 `FAIL_IF_LOG( tb.axis_out_if[0].tready && tb.axis_out_if[0].tvalid,
                               $sformatf("FAIL!!! Valid axi4s transaction received on output interface 0") )
                 `FAIL_IF_LOG( tb.axis_out_if[1].tready && tb.axis_out_if[1].tvalid,
                               $sformatf("FAIL!!! Valid axi4s transaction received on output interface 1") )
              end
           end
        join_any
    `SVTEST_END


    `SVTEST(test_p4_bypass)
        // reset rss_enable (when bypassing p4 processor).
        tuser.rss_enable = 1'b0;

        // Write p4_bypass register.
        p4_bypass_config.p4_bypass_enable = 1'b1;
        env.p4_proc_reg_agent.write_p4_bypass_config(p4_bypass_config);

        write_p4_tables ( .testdir("test-default-w-drops") );
        run_pkt_test ( .testdir("test-default"), .tuser(tuser), .write_tables(0) );
    `SVTEST_END


    `SVTEST(test_p4_bypass_w_traffic)
        // reset rss_enable (when bypassing p4 processor).
        tuser.rss_enable = 1'b0;

        // force output tuser for ALL pkts (for consistency in p4-mode and p4-bypass-mode).
        force tb.axis_out_if[0].tuser = tuser;

        fork
           run_pkt_test ( .testdir("test-default"), .tuser(tuser) );

           @(posedge tb.axis_out_if[0].tvalid) begin
               // Write p4_bypass register.
               p4_bypass_config.p4_bypass_enable = 1'b1;
               env.p4_proc_reg_agent.write_p4_bypass_config(p4_bypass_config);
           end
        join

        release tb.axis_out_if[0].tuser;

    `SVTEST_END

    `SVTEST(terminate)
        // Clean up VitisNetP4 driver
        vitisnetp4_agent.terminate();
    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule


// 'Boilerplate' unit test wrapper code
// Builds unit test for a specific axi4s_split_join configuration in a way
// that maintains SVUnit compatibility

`define P4_PROC_DATAPATH_UNIT_TEST(HDR_LENGTH)\
  import svunit_pkg::svunit_testcase;\
  svunit_testcase svunit_ut;\
  p4_proc_datapath_unit_test #(HDR_LENGTH) test();\
  function void build();\
    test.build();\
    svunit_ut = test.svunit_ut;\
  endfunction\
  function void __register_tests();\
    test.__register_tests();\
  endfunction\
  task run();\
    test.run();\
  endtask

module p4_proc_datapath_hdrlen_0_unit_test;
`P4_PROC_DATAPATH_UNIT_TEST(0)
endmodule

module p4_proc_datapath_hdrlen_64_unit_test;
`P4_PROC_DATAPATH_UNIT_TEST(64)
endmodule

module p4_proc_datapath_hdrlen_256_unit_test;
`P4_PROC_DATAPATH_UNIT_TEST(256)
endmodule
