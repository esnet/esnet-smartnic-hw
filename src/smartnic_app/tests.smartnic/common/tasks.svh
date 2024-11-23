    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        for (int i=0; i<NUM_PORTS; i++) env.axis_driver[i].set_min_gap(0);

        reset(); // Issue reset (both datapath and management domains)

        // Write hdr_length register (hdr_length = 0B to disable split-join logic).
        p4_proc_config.hdr_length = HDR_LENGTH;
        p4_proc_config.drop_pkt_loop = 1'b0;
        p4_proc_reg_agent.write_p4_proc_config(p4_proc_config);

        // Initialize VitisNetP4 tables
        vitisnetp4_agent.init();

        // Configure ingress queue assignment (all ingress host traffic is for VF2. base=0, num_q=1).
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_Q_CONFIG_0[3], {12'h1, 12'h0});
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_Q_CONFIG_1[3], {12'h1, 12'h0});

        // Configure tdest for CMAC_0 to APP_0 i.e. ingress switch port 0 is connected to vitisnetp4 block.
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[0], 2'h0 );
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[2], 2'h0 );

        // Configure tdest for CMAC_1 to APP_1 i.e. ingress switch port 1 is connected to vitisnetp4 block.
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[1], 2'h1 );
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[3], 2'h1 );

        // Configure igr_demux_sel to steer traffic to datapath (app_igr).
        //p4_only_reg_agent.write_igr_demux_sel({1'b1, IGR_DEMUX_SEL_VALUE_APP_IGR});

        `INFO("Waiting to initialize axis fifos...");
        for (integer i = 0; i < 100 ; i=i+1 ) begin
          @(posedge tb.clk);
        end

    endtask


    //=======================================
    // Teardown from running the Unit Tests
    //=======================================
    task teardown();
        `INFO("Waiting to end testcase...");
        for (integer i = 0; i < 100 ; i=i+1 ) @(posedge tb.clk);
        `INFO("Ending testcase!");

        svunit_ut.teardown();

        // Clean up VitisNetP4 tables
        vitisnetp4_agent.terminate();

    endtask


    //=======================================================================
    // Packet test sequence
    //=======================================================================
     task automatic run_pkt_test (
        input string testdir, input logic[63:0] init_timestamp=0,
        input port_t in_port=0, out_port=0,
        input int max_pkt_size = 0, input logic write_p4_tables=1, VERBOSE=1 );
	
        string filename;

        // expected pcap data
        pcap_pkg::pcap_t exp_pcap;

        // variables for sending packet data
        automatic logic [63:0] timestamp = init_timestamp;
        automatic int          num_pkts  = 0;
        automatic int          start_idx = 0;
        automatic int          twait = 0;
        automatic int          tuser = 0;

        // variables for receiving (monitoring) packet data
        automatic int rx_pkt_cnt = 0;
        automatic bit rx_done = 0;
        byte          rx_data[$];
        port_t        id;
        port_t        dest;
        bit           user;

        debug_msg($sformatf("Write initial timestamp value: %0x", timestamp), VERBOSE);
        env.ts_agent.set_static(timestamp);

        if (write_p4_tables==1) begin
          debug_msg("Start writing VitisNetP4 tables...", VERBOSE);
          filename = {"../../../../vitisnetp4/p4/sim/", testdir, "/cli_commands.txt"};
          vitisnetp4_agent.table_init_from_file(filename);
          debug_msg("Done writing VitisNetP4 tables...", VERBOSE);
        end

        debug_msg("Reading expected pcap file...", VERBOSE);
        filename = {"../../../../vitisnetp4/p4/sim/", testdir, "/packets_out.pcap"};
        exp_pcap = pcap_pkg::read_pcap(filename);

        debug_msg("Starting simulation...", VERBOSE);
        filename = {"../../../../vitisnetp4/p4/sim/", testdir, "/packets_in.pcap"};
        rx_pkt_cnt = 0;
        fork
            begin
                // Send packets
                send_pcap(filename, num_pkts, start_idx, twait, in_port, out_port, tuser);
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
                            // Monitor received packets on port 0 (CMAC_0).
                            env.axis_monitor[out_port].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(0));
                            rx_pkt_cnt++;
                            debug_msg( $sformatf( "      Port %0d. Receiving packet # %0d (of %0d)...",
                                                 out_port, rx_pkt_cnt, exp_pcap.records.size()), VERBOSE );
                            debug_msg("      Comparing rx_pkt to exp_pkt...", VERBOSE);
                            compare_pkts(rx_data, exp_pcap.records[start_idx+rx_pkt_cnt-1].pkt_data, max_pkt_size);
                           `FAIL_IF_LOG( dest[0] != out_port[0],
                                        $sformatf("FAIL!!! Output tdest mismatch. tdest=%0h (exp:%0h)", dest, out_port) )
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
