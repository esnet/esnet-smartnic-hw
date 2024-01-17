`include "svunit_defines.svh"

import tb_pkg::*;

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module p4_proc_datapath_unit_test;

    // Testcase name
    string name = "p4_proc_datapath_ut";

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

    `include "../../p4/sim/run_pkt_test_incl.svh"

// Commented out due outstanding (init?) issue. Test passes on its own, but not within test suite.
//    `SVTEST(test_default_w_force)
//        force tb.axis_in_if[0].tid = 2'h2;
//        run_pkt_test ( .testdir("test-default"), .init_timestamp('0), .dest_port(2) );
//    `SVTEST_END

    `SVTEST(test_pkt_loopback_w_force)
        force tb.axis_in_if[0].tdest = 2'h2;
        run_pkt_test ( .testdir("test-pkt-loopback"), .init_timestamp('0), .dest_port(7) );
    `SVTEST_END

    `SVTEST(test_fwd_p0_w_force)
        force tb.axis_in_if[0].tdest = 2'h2;
        run_pkt_test ( .testdir("test-fwd-p0"), .init_timestamp('0), .dest_port(0) );
    `SVTEST_END

    `SVTEST(test_fwd_p1_w_force)
        force tb.axis_in_if[0].tdest = 2'h2;
        run_pkt_test ( .testdir("test-fwd-p1"), .init_timestamp('0), .dest_port(1) );
    `SVTEST_END

    `SVTEST(test_fwd_p3_w_force)
        force tb.axis_in_if[0].tdest = 2'h2;
        run_pkt_test ( .testdir("test-fwd-p3"), .init_timestamp('0), .dest_port(3) );
    `SVTEST_END

    `SVTEST(test_traffic_mux)
        fork
           // run packet stream from CMAC1 to CMAC1 (includes programming the p4 tables accordingly).
           run_pkt_test ( .testdir("test-fwd-p1"), .init_timestamp(1), .in_if(1), .out_if(1), .dest_port(1) );

           // simultaneously run packet stream from CMAC0 to CMAC0, starting once CMAC1 traffic is started.
           // (without re-programming the p4 tables).
           @(posedge tb.axis_in_if[1].tvalid)
               run_pkt_test ( .testdir("test-default"), .init_timestamp(1), .in_if(0), .out_if(0), .write_p4_tables(0) );

           // manually pause traffic through ingress mux, and restart.
           @(posedge tb.axis_in_if[1].tvalid) begin
               env.p4_proc_reg_agent.write_tpause(1);
               env.p4_proc_reg_agent.write_tpause(0);
           end
        join
    `SVTEST_END

    `SVUNIT_TESTS_END


     task automatic run_pkt_test (
        input string testdir, input logic[63:0] init_timestamp=0, input in_if=0, out_if=0, input egr_tdest_t dest_port=0,
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
           filename = {"../../../p4/sim/", testdir, "/cli_commands.txt"};
           vitisnetp4_agent.table_init_from_file(filename);
           debug_msg("Done writing VitisNetP4 tables...", VERBOSE);
        end

        debug_msg("Reading expected pcap file...", VERBOSE);
        filename = {"../../../p4/sim/", testdir, "/expected/packets_out.pcap"};
        pcap_pkg::read_pcap(filename, exp_pcap_hdr, exp_pcap_record_hdr, exp_data);

        debug_msg("Starting simulation...", VERBOSE);
         filename = {"../../../p4/sim/", testdir, "/packets_in.pcap"};
         rx_pkt_cnt = 0;
         fork
             begin
                 // Send packets
                 send_pcap(filename, num_pkts, start_idx, twait, in_if, in_if, dest_port);
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