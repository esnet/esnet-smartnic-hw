`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_datapath_unit_test;

    // Testcase name
    string name = "smartnic_datapath_ut";

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

    //===================================
    // Import common testcase tasks
    //=================================== 
    `include "../common/tasks.svh"
       
    //===================================
    // Connect AXI-S sample interface
    //===================================

    /*
    assign tb.axis_sample_clk = tb.clk;
    assign tb.axis_sample_aresetn = !tb.rst;
    assign tb.axis_sample_if.tvalid = tb.DUT.axi4s_split_join_0.axi4s_in.tvalid;
    assign tb.axis_sample_if.tlast  = tb.DUT.axi4s_split_join_0.axi4s_in.tlast;
    assign tb.axis_sample_if.tdata  = tb.DUT.axi4s_split_join_0.axi4s_in.tdata;
    assign tb.axis_sample_if.tkeep  = tb.DUT.axi4s_split_join_0.axi4s_in.tkeep;
    assign tb.axis_sample_if.tuser  = tb.DUT.axi4s_split_join_0.axi4s_in.tuser;
    assign tb.axis_sample_if.tready = tb.DUT.axi4s_split_join_0.axi4s_in.tready;
    */

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build testbench
        tb.build();

        // Retrieve reference to testbench environment class
        env = tb.env;

    endfunction

    //===================================
    // Local test variables
    //===================================
    real FIFO_DEPTH = 1306.0; // 1024 - 4 (fifo_async) + 2 x 143 (axi4s_pkt_discard_ovfl)

    int	pkt_len     [NUM_PORTS-1:0];

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        for (int i=0; i<NUM_PORTS/2; i++) env.axis_cmac_igr_driver[i].set_min_gap(0);
        for (int i=0; i<NUM_PORTS/2; i++) env.axis_h2c_driver[i].set_min_gap(0);

        reset(); // Issue reset (both datapath and management domains)

        // initialize switch configuration registers.
        init_sw_config_regs;

        switch_config = 0; env.smartnic_reg_blk_agent.write_switch_config(switch_config);

        // default variable configuration
         in_pcap[0] = "../../common/pcap/10xrandom_pkts.pcap";
        out_pcap[0] = "../../common/pcap/10xrandom_pkts.pcap";
         in_pcap[1] = "../../common/pcap/20xrandom_pkts.pcap";
        out_pcap[1] = "../../common/pcap/20xrandom_pkts.pcap";
         in_pcap[2] = "../../common/pcap/30xrandom_pkts.pcap";
        out_pcap[2] = "../../common/pcap/30xrandom_pkts.pcap";
         in_pcap[3] = "../../common/pcap/40xrandom_pkts.pcap";
        out_pcap[3] = "../../common/pcap/40xrandom_pkts.pcap";

        out_port_map = {4'h3, 4'h2, 4'h1, 4'h0};
        pkt_len      = {0, 0, 0, 0};  
        exp_pkts     = {0, 0, 0, 0};  // if exp_pkts field is set 0, value is determined from pcap file.

        `INFO("Waiting to initialize axis fifos...");
        for (integer i = 0; i < 100 ; i=i+1 ) begin
          @(posedge tb.clk);
        end

        host_ports = $urandom % 2; // determines ports used for stream tests (0:CMAC0/CMAC1, 1:PF0_VF2/PF1_VF2).
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

    `SVTEST(single_pkt_stream)
        run_pkt_stream ( .in_port(0), .out_port(out_port_map[0]), .in_pcap(in_pcap[0]), .out_pcap(out_pcap[0]),
                        .tx_pkt_cnt(tx_pkt_cnt[0]), .tx_byte_cnt(tx_byte_cnt[0]),
                        .rx_pkt_cnt(rx_pkt_cnt[0]), .rx_byte_cnt(rx_byte_cnt[0]),
                        .exp_pkt_cnt(exp_pkts[0]),
                        .tpause(0), .twait(0) );
    `SVTEST_END


    `SVTEST(switch_basic_sanity)
        check_probe_control_defaults;
        latch_probe_counters;

        if (host_ports == 1) env.smartnic_reg_blk_agent.write_egr_demux_sel('1);
        run_stream_test(.host_ports(host_ports), .tpause(0));

        latch_probe_counters;
        check_stream_test_probes(.host_ports(host_ports));

        clear_and_check_probe_counters;
    `SVTEST_END


    `SVTEST(switch_and_clear_probe_counts)
        latch_probe_counters;

        if (host_ports == 1) env.smartnic_reg_blk_agent.write_egr_demux_sel('1);
        run_stream_test(.host_ports(host_ports));

        latch_and_clear_probe_counters;
        latch_probe_counters;
        check_cleared_probe_counters;

    `SVTEST_END


    `SVTEST(igr_switch_reconfig)
        int count = 0;
        int igr_sw_tdest;
        int enable_monitor;

        out_port_map = {4'h1, 4'h0, 4'h1, 4'h0};

        //int igr_port = $urandom % NUM_PORTS;
        for (int igr_port = 0; igr_port < NUM_PORTS; igr_port++) begin
          igr_sw_tdest   = 2; // select BYPASS interface to start.
          enable_monitor = 1; // enable output monitor when BYPASS is selected.  disable for APP0 interface (which sinks traffic).

          env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[igr_port], igr_sw_tdest );

          for (int i = 0; i < 3; i++) begin  // reconfigure igr_sw_tdest iteratively.
             fork
               // Stream 2x9100B packets from igr_port (through bypass path).  Monitoring output if enabled.
               run_pkt_stream ( .in_port(igr_port), .out_port(out_port_map[igr_port]),
                                .in_pcap  ("../../common/pcap/32x9100B_pkts.pcap"),
                                .out_pcap ("../../common/pcap/32x9100B_pkts.pcap"),
                                .tx_pkt_cnt(tx_pkt_cnt[igr_port]), .tx_byte_cnt(tx_byte_cnt[igr_port]),
                                .rx_pkt_cnt(rx_pkt_cnt[igr_port]), .rx_byte_cnt(rx_byte_cnt[igr_port]),
                                .num_pkts(2), .exp_pkt_cnt(2),
                                .tpause(0), .twait(0), .enable_monitor(enable_monitor) );

               // Reconfigure IGR_SW_TDEST (during 2nd packet).
               begin
                 count = 0;
                 while (count < 2) @(negedge tb.DUT.axis_core_to_bypass[0].tlast or negedge tb.DUT.axis_core_to_bypass[1].tlast) count++;
                 igr_sw_tdest =   (igr_sw_tdest == 2) ? 3 : 2;  // alternate directing traffic to bypass interface and igr_sw_drop.
                 enable_monitor = (igr_sw_tdest == 2) ? 1 : 0;  // disable output monitor when traffic flows to DROP interface.
                 env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[igr_port], igr_sw_tdest );
               end
             join
          end
        end
    `SVTEST_END


    `SVTEST(egr_switch_reconfig)
        int count = 0;

        // assign egr_port to random value for regression.  uncomment 'for' loop below to test all egress ports.
        port_t egr_port = $urandom % 2;
        //for (int egr_port = 0; egr_port < NUM_PORTS; egr_port++) begin

           // Configure igr_sw tdest register (CMAC_0 -> BYPASS).
           env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[0], 2'h2 );

           for (int i = 0; i < 4; i++) begin  // reconfigure egr_port iteratively.
             fork
                // Stream 2x9100B packets through BYPASS interface.  Monitoring output.
                run_pkt_stream ( .in_port(egr_port[0]), .out_port(egr_port),
                                 .in_pcap  ("../../../../../src/smartnic/tests/common/pcap/32x9100B_pkts.pcap"),
                                 .out_pcap ("../../../../../src/smartnic/tests/common/pcap/32x9100B_pkts.pcap"),
                                 .tx_pkt_cnt(tx_pkt_cnt[egr_port[0]]), .tx_byte_cnt(tx_byte_cnt[egr_port[0]]),
                                 .rx_pkt_cnt(rx_pkt_cnt[egr_port[0]]), .rx_byte_cnt(rx_byte_cnt[egr_port[0]]),
                                 .num_pkts(2), .exp_pkt_cnt(2),
                                 .tpause(0), .twait(0) );

                // Reconfigure BYPASS_TDEST (during 2nd packet).
                begin
                  count = 0;
                  while (count < 2) @(negedge tb.DUT.axis_core_to_bypass[0].tlast or negedge tb.DUT.axis_core_to_bypass[1].tlast) count++;
                    env.smartnic_reg_blk_agent.write_egr_demux_sel({egr_port<2, egr_port<2});  // alternates between emitting to CMAC and HOST.
                end
             join

             egr_port = (egr_port+2) % NUM_PORTS;  // change egress port for next iteration (tracks reconfiguration in above iteration).
           end
        //end
    `SVTEST_END


    `SVTEST(single_stream_with_egress_discards)
        //port_t port = $urandom % 2;
        for (int port = 0; port < 2; port++) begin

            in_pcap[port] = "../../common/pcap/128x1518B_pkts.pcap";
           out_pcap[port] = "../../common/pcap/128x1518B_pkts.pcap";
            pkt_len[port] = 1518;

           // FIFO holds FIFO_DEPTH x 64B good packets (all others dropped).
           exp_pkts[port] = (pkt_len[port]==0) ? 0 : FIFO_DEPTH/$ceil(pkt_len[port]/64.0)+1;

           // set flow control threshold.
           env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_EGR_FC_THRESH[0] + 4*port, 32'd1020);
          `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[port] == 1'b0 );

           fork
              run_pkt_stream ( .in_port(port), .out_port(out_port_map[port]), .in_pcap(in_pcap[port]), .out_pcap(out_pcap[port]),
                               .tx_pkt_cnt(tx_pkt_cnt[port]), .tx_byte_cnt(tx_byte_cnt[port]),
                               .rx_pkt_cnt(rx_pkt_cnt[port]), .rx_byte_cnt(rx_byte_cnt[port]),
                               .exp_pkt_cnt(exp_pkts[port]),
                               .init_pause(50000) );

              #(50000) `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[port] == 1'b1 );
           join

          `FAIL_UNLESS( tb.DUT.smartnic_app.egr_flow_ctl[port] == 1'b0 );

           check_stream_probes (
              .in_port         (port),
              .out_port        (out_port_map[port]),
              .exp_good_pkts   (rx_pkt_cnt[port]),
              .exp_good_bytes  (rx_byte_cnt[port]),
              .exp_ovfl_pkts   (tx_pkt_cnt[port]  - rx_pkt_cnt[port]),
              .exp_ovfl_bytes  (tx_byte_cnt[port] - rx_byte_cnt[port])
           );

           if (port[0] == 1'b0) check_probe (.base_addr(PROBE_TO_BYPASS0), .exp_pkt_cnt(tx_pkt_cnt[port]), .exp_byte_cnt(tx_byte_cnt[port]));
           else                 check_probe (.base_addr(PROBE_TO_BYPASS1), .exp_pkt_cnt(tx_pkt_cnt[port]), .exp_byte_cnt(tx_byte_cnt[port]));
        end
    `SVTEST_END


    `SVTEST(discards_from_cmac)
         in_pcap[0] = "../../common/pcap/32x9100B_pkts.pcap";
        out_pcap[0] = "../../common/pcap/32x9100B_pkts.pcap";
         pkt_len[0] = 9100;
         in_pcap[1] = "../../common/pcap/128x1518B_pkts.pcap";
        out_pcap[1] = "../../common/pcap/128x1518B_pkts.pcap";
         pkt_len[1] = 1518;

        // FIFO holds FIFO_DEPTH x 64B good packets (all others dropped).
        for (int i=0; i<NUM_PORTS; i++)
           exp_pkts[i] = (pkt_len[i]==0) ? 0 : FIFO_DEPTH/$ceil(pkt_len[i]/64.0)+1;

        // force backpressure on ingress ports (deasserts tready from app core to ingress switch).
        switch_config.igr_sw_tpause = 1; env.smartnic_reg_blk_agent.write_switch_config(switch_config);
   
        fork
           run_stream_test();

           begin
              #(50us);
              // release backpressure on ingress ports
              switch_config.igr_sw_tpause = 0; env.smartnic_reg_blk_agent.write_switch_config(switch_config);
           end
	join

        check_stream_test_probes (.ovfl_mode(1));
    `SVTEST_END


    `SVTEST(errored_packets)
         for (int i=0; i<2; i++) begin // 2 iterations

            for (int cmac_port=0; cmac_port<2; cmac_port++) begin // foreach cmac port

               env.axis_cmac_igr_driver[cmac_port].set_min_gap(i); // set gap to i cycles.

               // send 10 errored packets i.e. with tuser=1
               send_pcap(.pcap_filename ("../../common/pcap/64B_multiples_10pkts.pcap"),
                         .id(cmac_port), .dest(cmac_port), .user(1));
               // check error counts
               check_and_clear_err_probes (.in_port(cmac_port), .exp_err_pkts(10), .exp_err_bytes(3520));

               // send and check unerrored packet stream i.e. with tuser=0 (default)
               run_pkt_stream (.in_port(cmac_port), .out_port(cmac_port),
                               .in_pcap  ("../../common/pcap/10xrandom_pkts.pcap"),
                               .out_pcap ("../../common/pcap/10xrandom_pkts.pcap"),
                               .tx_pkt_cnt(tx_pkt_cnt[cmac_port]), .tx_byte_cnt(tx_byte_cnt[cmac_port]),
                               .rx_pkt_cnt(rx_pkt_cnt[cmac_port]), .rx_byte_cnt(rx_byte_cnt[cmac_port]) );

               // check stream probe counts
               check_stream_probes (.in_port(cmac_port), .out_port(cmac_port),
                                    .exp_good_pkts(rx_pkt_cnt[cmac_port]), .exp_good_bytes(rx_byte_cnt[cmac_port]),
                                    .exp_ovfl_pkts(0), .exp_ovfl_bytes(0) );

               clear_and_check_probe_counters;
             end

          end
    `SVTEST_END


    `SVTEST(bypass_drops)
        switch_config.drop_pkt_loop = 1; env.smartnic_reg_blk_agent.write_switch_config(switch_config);

        fork
           run_pkt_stream ( .in_port(0), .out_port(out_port_map[0]), .in_pcap(in_pcap[0]), .out_pcap(out_pcap[0]),
                         .tx_pkt_cnt(tx_pkt_cnt[0]), .tx_byte_cnt(tx_byte_cnt[0]),
                         .rx_pkt_cnt(rx_pkt_cnt[0]), .rx_byte_cnt(rx_byte_cnt[0]),
                         .exp_pkt_cnt(exp_pkts[0]),
                         .tpause(0), .twait(0) );

           begin 
              #10us
              check_probe (.base_addr(PROBE_TO_BYPASS0), .exp_pkt_cnt(tx_pkt_cnt[0]), .exp_byte_cnt(tx_byte_cnt[0]));
              check_probe (.base_addr(DROPS_FROM_BYPASS0), .exp_pkt_cnt(tx_pkt_cnt[0]), .exp_byte_cnt(tx_byte_cnt[0]));
              check_stream_probes (.in_port(0), .out_port(out_port_map[0]),
                                   .exp_good_pkts(0), .exp_good_bytes(0), .exp_ovfl_pkts(tx_pkt_cnt[0]), .exp_ovfl_bytes(tx_byte_cnt[0]),
                                   .ovfl_mode(2) );
           end
        join_any

    `SVTEST_END


    `SVTEST(igr_sw_drops)
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[0], 3 );

        run_pkt_stream ( .in_port(0), .out_port(out_port_map[0]), .in_pcap(in_pcap[0]), .out_pcap(out_pcap[0]),
                         .tx_pkt_cnt(tx_pkt_cnt[0]), .tx_byte_cnt(tx_byte_cnt[0]),
                         .rx_pkt_cnt(rx_pkt_cnt[0]), .rx_byte_cnt(rx_byte_cnt[0]),
                         .exp_pkt_cnt(exp_pkts[0]),
                         .tpause(0), .twait(0),
                         .enable_monitor(0) );

        check_probe (.base_addr(DROPS_TO_BYPASS0), .exp_pkt_cnt(tx_pkt_cnt[0]), .exp_byte_cnt(tx_byte_cnt[0]));
        check_probe (.base_addr(PROBE_TO_BYPASS0), .exp_pkt_cnt(0), .exp_byte_cnt(0));
        check_stream_probes (.in_port(0), .out_port(out_port_map[0]),
                             .exp_good_pkts(0), .exp_good_bytes(0), .exp_ovfl_pkts(tx_pkt_cnt[0]), .exp_ovfl_bytes(tx_byte_cnt[0]),
                             .ovfl_mode(2) );
    `SVTEST_END


    `SVTEST(single_packets)
         env.axis_cmac_igr_driver[1].set_min_gap(1000); // set gap to 1000 cycles.

         run_pkt_stream ( .in_port(1), .out_port(1), 
                         .in_pcap  ("../../common/pcap/64B_multiples_10pkts.pcap"),
                         .out_pcap ("../../common/pcap/64B_multiples_10pkts.pcap"),
                         .tx_pkt_cnt(tx_pkt_cnt[1]), .tx_byte_cnt(tx_byte_cnt[1]),
                         .rx_pkt_cnt(rx_pkt_cnt[1]), .rx_byte_cnt(rx_byte_cnt[1]) );
    `SVTEST_END


    `SVTEST(min_size_stress)
        for (int i=0; i<NUM_PORTS; i++) begin
            in_pcap[i] = "../../common/pcap/512x64B_pkts.pcap";
           out_pcap[i] = "../../common/pcap/512x64B_pkts.pcap";
        end

        if (host_ports == 1) env.smartnic_reg_blk_agent.write_egr_demux_sel('1);
        run_stream_test(.host_ports(host_ports)); check_stream_test_probes(.host_ports(host_ports));

    `SVTEST_END


    `SVTEST(max_size_stress)
        for (int i=0; i<NUM_PORTS; i++) begin
            in_pcap[i] = "../../common/pcap/128x1518B_pkts.pcap";
           out_pcap[i] = "../../common/pcap/128x1518B_pkts.pcap";
        end

        for (int i=0; i<NUM_PORTS/2; i++) env.axis_cmac_igr_driver[i].set_min_gap(2*24);  // set gap to 2 pkts.
        for (int i=0; i<NUM_PORTS/2; i++) env.axis_h2c_driver[i].set_min_gap(2*24);

        if (host_ports == 1) env.smartnic_reg_blk_agent.write_egr_demux_sel('1);
        run_stream_test(.host_ports(host_ports)); check_stream_test_probes(.host_ports(host_ports));

    `SVTEST_END


    `SVTEST(long_pkt)
        for (int i=0; i<NUM_PORTS; i++) begin
            in_pcap[i] = "../../common/pcap/32x9100B_pkts.pcap";
           out_pcap[i] = "../../common/pcap/32x9100B_pkts.pcap";
        end

        for (int i=0; i<NUM_PORTS/2; i++) env.axis_cmac_igr_driver[i].set_min_gap(2*143);  // set gap to 2 pkts.
        for (int i=0; i<NUM_PORTS/2; i++) env.axis_h2c_driver[i].set_min_gap(2*143);

        if (host_ports == 1) env.smartnic_reg_blk_agent.write_egr_demux_sel('1);
        run_stream_test(.host_ports(host_ports)); check_stream_test_probes(.host_ports(host_ports));
    `SVTEST_END


    `SVTEST(axi4s_tkeep_stress)
        for (int i=0; i<NUM_PORTS; i++) begin
            in_pcap[i] = "../../common/pcap/64B_to_319B_pkts.pcap";
           out_pcap[i] = "../../common/pcap/64B_to_319B_pkts.pcap";
        end

        for (int i=0; i<NUM_PORTS/2; i++) env.axis_cmac_igr_driver[i].set_min_gap(5);  // set gap to 5 cycles.
        for (int i=0; i<NUM_PORTS/2; i++) env.axis_h2c_driver[i].set_min_gap(5);

        if (host_ports == 1) env.smartnic_reg_blk_agent.write_egr_demux_sel('1);
        run_stream_test(.host_ports(host_ports)); check_stream_test_probes(.host_ports(host_ports));
    `SVTEST_END

      
    `SVTEST(random_pkt_size)
        for (int i=0; i<NUM_PORTS; i++) begin
            in_pcap[i] = "../../common/pcap/100xrandom_pkts.pcap";
           out_pcap[i] = "../../common/pcap/100xrandom_pkts.pcap";
        end

        for (int i=0; i<NUM_PORTS/2; i++) env.axis_cmac_igr_driver[i].set_min_gap(1*143);  // set gap to 1 jumbo pkts.
        for (int i=0; i<NUM_PORTS/2; i++) env.axis_h2c_driver[i].set_min_gap(1*143);

        if (host_ports == 1) env.smartnic_reg_blk_agent.write_egr_demux_sel('1);
        run_stream_test(.host_ports(host_ports)); check_stream_test_probes(.host_ports(host_ports));
    `SVTEST_END


// The following tests are commented out of the regression run for resource and runtime efficiency, but retained
// for the option of manual execution.

/*
    `SVTEST(jumbo_size_discards)
        for (int i=0; i<NUM_PORTS; i++) begin
            in_pcap[i] = "../../common/pcap/32x9100B_pkts.pcap";
           out_pcap[i] = "../../common/pcap/32x9100B_pkts.pcap";
        end

        // FIFO holds FIFO_DEPTH x 64B good packets (all others dropped).
        for (int i=0; i<NUM_PORTS; i++) begin
            pkt_len[i] = 9100;
            exp_pkts[i] = FIFO_DEPTH/$ceil(pkt_len[i]/64.0)+1;
        end

        force tb.axis_out_if[0].tready = 0;  // force backpressure on egress ports with discard points
        force tb.axis_out_if[1].tready = 0;
        force tb.axis_out_if[2].tready = 0;
        force tb.axis_out_if[3].tready = 0;

        for (int i=0; i<NUM_PORTS/2; i++) env.axis_cmac_igr_driver[i].set_min_gap(5*$ceil(pkt_len[i]/64.0)); // set gap to 5 pkts.
        for (int i=0; i<NUM_PORTS/2; i++) env.axis_h2c_driver[i].set_min_gap(5*$ceil(pkt_len[i]/64.0));

        fork
           run_stream_test();

           begin
              #(125us);
              force   tb.axis_out_if[0].tready = 1; release tb.axis_out_if[0].tready;
              force   tb.axis_out_if[1].tready = 1; release tb.axis_out_if[1].tready;
              force   tb.axis_out_if[2].tready = 1; release tb.axis_out_if[1].tready;
              force   tb.axis_out_if[3].tready = 1; release tb.axis_out_if[3].tready;
           end
	join

        check_stream_test_probes;
     `SVTEST_END


     `SVTEST(max_size_discards)
        for (int i=0; i<NUM_PORTS; i++) begin
            in_pcap[i] = "../../common/pcap/128x1518B_pkts.pcap";
           out_pcap[i] = "../../common/pcap/128x1518B_pkts.pcap";
        end

        // FIFO holds FIFO_DEPTH x 64B good packets (all others dropped).
        for (int i=0; i<NUM_PORTS; i++) begin
            pkt_len[i] = 1518;
            exp_pkts[i] = FIFO_DEPTH/$ceil(pkt_len[i]/64.0)+1;
        end
        exp_pkts[2] = 0;  // configures exp_pkts from pcap file.

        force tb.axis_out_if[0].tready = 0;  // force backpressure on egress ports with discard points
        force tb.axis_out_if[1].tready = 0;
        force tb.axis_out_if[2].tready = 0;
        force tb.axis_out_if[3].tready = 0;

        for (int i=0; i<NUM_PORTS/2; i++) env.axis_cmac_igr_driver[i].set_min_gap(2*$ceil(pkt_len[i]/64.0)); // set gap to 2 pkts.
        for (int i=0; i<NUM_PORTS/2; i++) env.axis_h2c_driver[i].set_min_gap(2*$ceil(pkt_len[i]/64.0));

        fork
           run_stream_test();

           begin
              #(50us);
              force   tb.axis_out_if[0].tready = 1; release tb.axis_out_if[0].tready;
              force   tb.axis_out_if[1].tready = 1; release tb.axis_out_if[1].tready;
              force   tb.axis_out_if[2].tready = 1; release tb.axis_out_if[1].tready;
              force   tb.axis_out_if[3].tready = 1; release tb.axis_out_if[3].tready;
           end
	join

        check_stream_test_probes;
    `SVTEST_END
*/
    `SVUNIT_TESTS_END

endmodule
