`include "svunit_defines.svh"

import tb_pkg::*;

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module p4_multi_proc_datapath_unit_test;

    // Testcase name
    string name = "p4_multi_proc_datapath_ut";

    // SVUnit base testcase
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic_app
    // testbench top level. The 'tb' module is
    // loaded into the tb_glbl scope, so is available
    // at tb_glbl.tb.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::tb_env env;

    vitisnetp4_igr_verif_pkg::vitisnetp4_igr_agent vitisnetp4_agent;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../../../../src/smartnic_app/p4_only/tests/common/tasks.svh"

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
        vitisnetp4_agent.create("tb"); // DPI-C P4 table agent requires hierarchical
                                       // path to AXI-L write/read tasks
    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // Flush packets from pipeline
        env.axis_monitor[0].flush();
        env.axis_monitor[1].flush();

        // Issue reset (both datapath and management domains)
        reset();

        // Initialize vitisnetp4 tables
        vitisnetp4_agent.init();

        // Put AXI-S interfaces into quiescent state
        env.axis_driver[0].idle();
        env.axis_driver[1].idle();
        env.axis_monitor[0].idle();
        env.axis_monitor[1].idle();

    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        `INFO("Waiting to end testcase...");
        for (integer i = 0; i < 100 ; i=i+1 ) @(posedge tb.clk);
        `INFO("Ending testcase!");

        svunit_ut.teardown();

        // Flush remaining packets
        env.axis_monitor[0].flush();
        env.axis_monitor[1].flush();
        #10us;

        // Clean up vitisnetp4 tables
        vitisnetp4_agent.terminate();

    endtask


    //=======================================================================
    // TESTS
    //=======================================================================
    const string P4_SIM_PATH = "../../../p4/sim_igr";

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

    `SVTEST(test_fwd_p0)
        run_pkt_test(.testdir("test-fwd-p0"), .init_timestamp(1));
    `SVTEST_END

    `SVUNIT_TESTS_END

    //=======================================================================
    // TASKS
    //=======================================================================
     task run_pkt_test (
        input string testdir, input logic[63:0] init_timestamp=0, input port_t dest_port=0, input VERBOSE=1 );
	
        string filename;

        // variables for reading expected pcap data
        pcap_pkg::pcap_t exp_pcap;

        // variables for sending packet data
        automatic logic [63:0] timestamp = init_timestamp;
        automatic int          num_pkts  = 0;
        automatic int          start_idx = 0;

        // variables for receiving (monitoring) packet data
        automatic int rx_pkt_cnt = 0;
        automatic bit rx_done = 0;
        byte          rx_data[$];
        port_t        id;
        port_t        dest;
        bit           user;

        debug_msg($sformatf("Write initial timestamp value: %0x", timestamp), VERBOSE);
        env.ts_agent.set_static(timestamp);

        debug_msg("Start writing vitisnetp4 tables...", VERBOSE);
        filename = {P4_SIM_PATH,"/", testdir, "/cli_commands.txt"};
        vitisnetp4_agent.table_init_from_file(filename);
        debug_msg("Done writing vitisnetp4 tables...", VERBOSE);

        debug_msg("Reading expected pcap file...", VERBOSE);
        filename = {P4_SIM_PATH,"/", testdir, "/packets_out.pcap"};
        exp_pcap = pcap_pkg::read_pcap(filename);

        debug_msg("Starting simulation...", VERBOSE);
         filename = {P4_SIM_PATH,"/", testdir, "/packets_in.pcap"};
         rx_pkt_cnt = 0;
         fork
             begin
                 // Send packets
                 send_pcap(filename, num_pkts, start_idx, 0, 0, 0, dest_port); // twait=0, in_if=0, id=0.
             end
             begin
                 // If init_timestamp=1, increment timestamp after each tx packet (puts packet # in timestamp field)
                 while ( (init_timestamp == 1) && !rx_done ) begin
                    @(posedge tb.axis_in_if[0].tlast or posedge rx_done) begin
                       if (tb.axis_in_if[0].tlast) begin timestamp++; env.ts_agent.set_static(timestamp); end
                    end
                 end
             end
             begin
                 automatic time t = $time;
                 // Monitor output packets
                 while (rx_pkt_cnt < exp_pcap.records.size() || ($time < t + 5us)) begin
                     fork
                         begin
                             // Always monitor for some minumum period, even if no receive packets are expected
                             #5us;
                         end
                         begin
                             // Monitor received packets
                             env.axis_monitor[0].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(0));
                             rx_pkt_cnt++;
                             debug_msg( $sformatf( "      Receiving packet # %0d (of %0d)...",
                                                  rx_pkt_cnt, exp_pcap.records.size()), VERBOSE );
                             debug_msg("      Comparing rx_pkt to exp_pkt...", VERBOSE);
                             compare_pkts(rx_data, exp_pcap.records[start_idx+rx_pkt_cnt-1].pkt_data);
                            `FAIL_IF_LOG( dest != dest_port,
                                         $sformatf("FAIL!!! Output tdest mismatch. tdest=%0h (exp:%0h)", dest, dest_port) )
                         end
                     join_any
                     disable fork;
                 end
                 rx_done = 1;
             end
         join
     endtask

     task debug_msg(input string msg, input bit VERBOSE=0);
         if (VERBOSE) `INFO(msg);
     endtask

endmodule
