`include "svunit_defines.svh"

import tb_pkg::*;

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module p4_app_datapath_unit_test;

    // Testcase name
    string name = "p4_app_datapath_ut";

    // SVUnit base testcase
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

    vitisnetp4_verif_pkg::vitisnetp4_agent vitisnetp4_agent;

    int exp_pkt_cnt, exp_byte_cnt;

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
        tb.build();
       
        // Retrieve reference to testbench environment class
        env = tb.env;

        // Create P4 table agent
        vitisnetp4_agent = new;
        vitisnetp4_agent.create("tb"); // DPI-C P4 table agent requires hierarchial
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

    `include "../../../../vitisnetp4/p4/sim/run_pkt_test_incl.svh"

    `SVUNIT_TESTS_END


     task automatic run_pkt_test (
        input string testdir, output int exp_pkt_cnt, exp_byte_cnt,
        input logic[63:0] init_timestamp=0, input in_if=0, out_if=0, input egr_tdest_t dest_port=0,
        input write_p4_tables=1, VERBOSE=1 );
	
        string filename;

        // variabes for reading expected pcap data
        byte                      exp_data[$][$];
        pcap_pkg::pcap_hdr_t      exp_pcap_hdr;
        pcap_pkg::pcaprec_hdr_t   exp_pcap_record_hdr[$];

        // variables for sending packet data
        automatic logic [63:0] timestamp = init_timestamp;
        automatic int          num_pkts  = 0;
        automatic int          start_idx = 0;
        automatic int          twait = 0;

        // variables for receiving (monitoring) packet data
        automatic int rx_pkt_cnt = 0;
        automatic bit rx_done = 0;
        byte          rx_data[$];
        port_t        id;
        egr_tdest_t   dest;
        bit           user;

        debug_msg($sformatf("Write initial timestamp value: %0x", timestamp), VERBOSE);
        env.ts_agent.set_static(timestamp);

        if (write_p4_tables==1) begin
           debug_msg("Start writing VitisNetP4 tables...", VERBOSE);
           filename = {"../../../../../vitisnetp4/p4/sim/", testdir, "/cli_commands.txt"};
           vitisnetp4_agent.table_init_from_file(filename);
           debug_msg("Done writing VitisNetP4 tables...", VERBOSE);
        end

        debug_msg("Reading expected pcap file...", VERBOSE);
        filename = {"../../../../../vitisnetp4/p4/sim/", testdir, "/expected/packets_out.pcap"};
        pcap_pkg::read_pcap(filename, exp_pcap_hdr, exp_pcap_record_hdr, exp_data);

        debug_msg("Starting simulation...", VERBOSE);
         filename = {"../../../../../vitisnetp4/p4/sim/", testdir, "/packets_in.pcap"};
         rx_pkt_cnt = 0;
         fork
             begin
                 // Send packets
                 send_pcap(.pcap_filename(filename), .num_pkts(num_pkts), .start_idx(start_idx),
                           .twait(twait), .in_if(in_if), .id(in_if), .dest(dest_port));
             end
             begin
                 // If init_timestamp=1, increment timestamp after each tx packet (puts packet # in timestamp field)
                 while ( (init_timestamp == 1) && !rx_done ) begin
                    @(posedge tb.axis_in_if[0][0].tlast or posedge rx_done) begin
                       if (tb.axis_in_if[0][0].tlast) begin timestamp++; env.ts_agent.set_static(timestamp); end
                    end
                 end
             end
             begin
                 // Monitor output packets
                 while (rx_pkt_cnt < exp_pcap_record_hdr.size()) begin
                     env.axis_monitor[out_if].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(10));
                     rx_pkt_cnt++;
                     debug_msg( $sformatf( "      Receiving packet # %0d (of %0d)...", 
                                           rx_pkt_cnt, exp_pcap_record_hdr.size()), VERBOSE );

                     debug_msg("      Comparing rx_pkt to exp_pkt...", VERBOSE);
                     compare_pkts(rx_data, exp_data[start_idx+rx_pkt_cnt-1]);
                    `FAIL_IF_LOG( dest != dest_port, 
                                  $sformatf("FAIL!!! Output tdest mismatch. tdest=%0h (exp:%0h)", dest, dest_port) )
                 end
                 rx_done = 1;
             end
         join
     endtask

     task debug_msg(input string msg, input bit VERBOSE=0);
         if (VERBOSE) `INFO(msg);
     endtask
      
endmodule
