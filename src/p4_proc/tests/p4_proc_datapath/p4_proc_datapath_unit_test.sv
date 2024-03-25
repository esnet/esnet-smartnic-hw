`include "svunit_defines.svh"

import tb_pkg::*;

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

    p4_proc_reg_pkg::reg_p4_proc_config_t  p4_proc_config;
    p4_proc_reg_pkg::reg_trunc_config_t    trunc_config;

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

        // Write hdr_length register (hdr_length = 0B to disable split-join logic).
        p4_proc_config.hdr_length = HDR_LENGTH;
        p4_proc_config.drop_pkt_loop = 1'b0;
        env.p4_proc_reg_agent.write_p4_proc_config(p4_proc_config);

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
//        run_pkt_test ( .testdir("test-default"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp('0), .dest_port(2) );
//    `SVTEST_END

    `SVTEST(test_pkt_loopback_w_force)
        force tb.axis_in_if[0].tdest = 2'h2;
        run_pkt_test ( .testdir("test-pkt-loopback"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp('0), .dest_port(7) );
    `SVTEST_END

    `SVTEST(test_fwd_p0_w_force)
        force tb.axis_in_if[0].tdest = 2'h2;
        run_pkt_test ( .testdir("test-fwd-p0"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp('0), .dest_port(0) );
    `SVTEST_END

    `SVTEST(test_fwd_p1_w_force)
        force tb.axis_in_if[0].tdest = 2'h2;
        run_pkt_test ( .testdir("test-fwd-p1"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp('0), .dest_port(1) );
    `SVTEST_END

    `SVTEST(test_fwd_p3_w_force)
        force tb.axis_in_if[0].tdest = 2'h2;
        run_pkt_test ( .testdir("test-fwd-p3"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp('0), .dest_port(3) );
    `SVTEST_END

    `SVTEST(test_traffic_mux)
        fork
           // run packet stream from CMAC1 to CMAC1 (includes programming the p4 tables accordingly).
           run_pkt_test ( .testdir("test-fwd-p1"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt),
                          .init_timestamp(1), .in_if(1), .out_if(1), .dest_port(1) );

           // simultaneously run packet stream from CMAC0 to CMAC0, starting once CMAC1 traffic is started.
           // (without re-programming the p4 tables).
           @(posedge tb.axis_in_if[1].tvalid)
               run_pkt_test ( .testdir("test-default"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt),
                              .init_timestamp(1), .in_if(0), .out_if(0), .write_p4_tables(0) );

           // manually pause traffic through ingress mux, and restart.
           @(posedge tb.axis_in_if[1].tvalid) begin
               env.p4_proc_reg_agent.write_tpause(1);
               env.p4_proc_reg_agent.write_tpause(0);
            end
        join
    `SVTEST_END

    `SVTEST(test_pkt_loop_drops)
        // Write drop_pkt_loop register.
        p4_proc_config.drop_pkt_loop = 1'b1;
        p4_proc_config.hdr_length = HDR_LENGTH;
        env.p4_proc_reg_agent.write_p4_proc_config(p4_proc_config);

        fork
           begin
              // run packet stream from CMAC1-to-CMAC1 (includes programming the p4 tables accordingly).
              run_pkt_test ( .testdir("test-fwd-p1"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt),
                             .init_timestamp(1), .in_if(1), .out_if(1), .dest_port(1), .enable_monitor(0) );
              check_probe (DROPS_FROM_PROC_PORT_1, exp_pkt_cnt, exp_byte_cnt);

              // run packet streams from CMAC0-to-CMAC0 (skips reprogramming the p4 tables).
              run_pkt_test ( .testdir("test-default"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt),
                             .init_timestamp(1), .in_if(0), .out_if(0), .dest_port(0), .enable_monitor(0), .write_p4_tables(0) );
              check_probe (DROPS_FROM_PROC_PORT_0, exp_pkt_cnt, exp_byte_cnt);
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

    `SVTEST(test_egr_pkt_trunc)
        repeat (1) begin
           // Write trunc_config register and run pkt test.
           trunc_config.enable = 1'b1;
           trunc_config.trunc_enable = 1'b1;
           trunc_config.trunc_length = $urandom_range(65,500);
           env.p4_proc_reg_agent.write_trunc_config(trunc_config);

           run_pkt_test ( .testdir("test-pkt-loopback"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt),
                          .init_timestamp('0), .dest_port(7), .max_pkt_size(trunc_config.trunc_length) );
        end
    `SVTEST_END

    `SVUNIT_TESTS_END


     task automatic run_pkt_test (
        input string testdir, output int exp_pkt_cnt, exp_byte_cnt,
        input logic[63:0] init_timestamp=0, input in_if=0, out_if=0, input egr_tdest_t dest_port=0,
        input int max_pkt_size = 0, input bit write_p4_tables=1, enable_monitor=1, VERBOSE=1 );
	
        string filename;

        // expected pcap data
        pcap_pkg::pcap_t exp_pcap;

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
        filename = {"../../../p4/sim/", testdir, "/packets_out.pcap"};
        exp_pcap = pcap_pkg::read_pcap(filename);

        exp_pkt_cnt = exp_pcap.records.size();
        exp_byte_cnt = 0; for (integer i = 0; i < exp_pkt_cnt; i=i+1) exp_byte_cnt = exp_byte_cnt + exp_pcap.records[i].pkt_data.size();

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
                 if (enable_monitor == 1) begin
                      // Monitor output packets
                      while (rx_pkt_cnt < exp_pcap.records.size()) begin
                          env.axis_monitor[out_if].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(10));
                          rx_pkt_cnt++;
                          debug_msg( $sformatf( "      Receiving packet # %0d (of %0d)...",
                                                rx_pkt_cnt, exp_pcap.records.size()), VERBOSE );

                          debug_msg("      Comparing rx_pkt to exp_pkt...", VERBOSE);
                          compare_pkts(rx_data, exp_pcap.records[start_idx+rx_pkt_cnt-1].pkt_data, max_pkt_size);
                          `FAIL_IF_LOG( dest != dest_port,
                                        $sformatf("FAIL!!! Output tdest mismatch. tdest=%0h (exp:%0h)", dest, dest_port) )
                      end
                 end
                 rx_done = 1;
             end
         join
     endtask

     task debug_msg(input string msg, input bit VERBOSE=0);
         if (VERBOSE) `INFO(msg);
     endtask
      
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
