//=======================================================================
// Global variables
//=======================================================================
localparam NUM_PORTS = 4;

import smartnic_pkg::*;
port_t out_port_map [NUM_PORTS-1:0];  // vector specifies output port for each input stream.
logic  host_ports;                // set (1) to exercise 'host' ports during stream test. default is 'cmac' ports.

string in_pcap  [NUM_PORTS-1:0];  // vector specifies the in_pcap file for each input stream.
string out_pcap [NUM_PORTS-1:0];  // vector specifies the out_pcap file for each input stream.

// variables for probe checks.
int tx_pkt_cnt  [NUM_PORTS-1:0];  // captures the tx pkt & byte counts from the pcap file for a given test.
int tx_byte_cnt [NUM_PORTS-1:0];
int rx_pkt_cnt  [NUM_PORTS-1:0];  // captures the rx pkt & byte counts from the pcap file for a given test.
int rx_byte_cnt [NUM_PORTS-1:0];
int rx_pkt_tot  = 0;
int rx_byte_tot = 0;
int exp_pkts    [NUM_PORTS-1:0];  // vector specifies the expected number of pkts received for each stream.

typedef enum logic [31:0] {
    PROBE_FROM_CMAC0      = 'h2000,
    DROPS_OVFL_FROM_CMAC0 = 'h2100,
    DROPS_ERR_FROM_CMAC0  = 'h2200,
    PROBE_FROM_CMAC1      = 'h2300,
    DROPS_OVFL_FROM_CMAC1 = 'h2400,
    DROPS_ERR_FROM_CMAC1  = 'h2500,
    PROBE_TO_CMAC0        = 'h2600,
    DROPS_OVFL_TO_CMAC0   = 'h2700,
    PROBE_TO_CMAC1        = 'h2800,
    DROPS_OVFL_TO_CMAC1   = 'h2900,

    PROBE_FROM_PF0        = 'h3000,
    PROBE_FROM_PF1        = 'h3100,
    PROBE_TO_PF0          = 'h3200,
    DROPS_OVFL_TO_PF0     = 'h3300,
    PROBE_TO_PF1          = 'h3400,
    DROPS_OVFL_TO_PF1     = 'h3500,

    PROBE_TO_BYPASS0      = 'h4000,
    DROPS_TO_BYPASS0      = 'h4100,
    DROPS_FROM_BYPASS0    = 'h4200,
    PROBE_TO_BYPASS1      = 'h4300,
    DROPS_TO_BYPASS1      = 'h4400,
    DROPS_FROM_BYPASS1    = 'h4500,

    PROBE_CORE_TO_APP0    = 'h0c00,
    PROBE_CORE_TO_APP1    = 'h0d00,
    PROBE_APP0_TO_CORE    = 'h0e00,
    PROBE_APP1_TO_CORE    = 'h0f00,

    DROPS_FROM_IGR_PROC_PORT0 = 'h20400

    } cntr_addr_encoding_t;

typedef union packed {
    cntr_addr_encoding_t  encoded;
    logic [31:0]          raw;
} cntr_addr_t;

smartnic_reg_pkg::reg_switch_config_t switch_config;


//=======================================================================
// Tasks
//=======================================================================

    // ----- setup for unit tests -----
    task setup();
        svunit_ut.setup();

        for (int i=0; i<NUM_PORTS/2; i++) env.axis_cmac_igr_driver[i].set_min_gap(0);
        for (int i=0; i<NUM_PORTS/2; i++) env.axis_h2c_driver[i].set_min_gap(0);

        // start environment
//        env.run();

        reset(); // Issue reset (both datapath and management domains)

        // Write hdr_length register (hdr_length = 0B to disable split-join logic).
        p4_proc_config.hdr_length = HDR_LENGTH;
        p4_proc_reg_agent.write_p4_proc_config(p4_proc_config);

        // Initialize VitisNetP4 tables
        vitisnetp4_agent.init();

        // Configure ingress queue assignment (all ingress host traffic is for VF2).
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_Q_CONFIG_0[3], {12'h1, 12'h2});
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_Q_CONFIG_1[3], {12'h1, 12'h3});

        // Configure tdest for CMAC_0 to APP_0 i.e. ingress switch port 0 is connected to vitisnetp4 block.
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_SMARTNIC_MUX_OUT_SEL[0], 2'h0 );
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_SMARTNIC_MUX_OUT_SEL[2], 2'h0 );

        // Configure tdest for CMAC_1 to APP_1 i.e. ingress switch port 1 is connected to vitisnetp4 block.
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_SMARTNIC_MUX_OUT_SEL[1], 2'h0 );
        env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_SMARTNIC_MUX_OUT_SEL[3], 2'h0 );

        // Configure smartnic_app_igr_p4_out_sel to steer traffic to datapath (app_igr).
        //p4_only_reg_agent.write_smartnic_app_igr_p4_out_sel({1'b1, SMARTNIC_APP_IGR_P4_OUT_SEL_VALUE_SMARTNIC_APP_IGR});

        `INFO("Waiting to initialize axis fifos...");
        for (integer i = 0; i < 100 ; i=i+1 ) begin
          @(posedge tb.clk);
        end

    endtask


    // ----- teardown for unit tests -----
    task teardown();
        `INFO("Waiting to end testcase...");
        for (integer i = 0; i < 100 ; i=i+1 ) @(posedge tb.clk);
        `INFO("Ending testcase!");

        svunit_ut.teardown();

        // Clean up VitisNetP4 tables
        vitisnetp4_agent.terminate();

    endtask


    // ----- execute block reset (dataplane + control plane) -----
    task reset();
        automatic bit reset_done;
        automatic string msg;
        env.reset();
        env.wait_reset_done(reset_done, msg);
        `FAIL_IF_LOG((reset_done == 0), msg);
    endtask


    // ----- send packets described in PCAP file on AXI-S input interface -----
    task send_pcap (
        input string  pcap_filename,
        input int     num_pkts=0, start_idx=0, twait=0,
        input adpt_tx_tid_t  id=0,
        input port_t  dest=0,
        input bit     user=0 );

        case (id)
            0: env.axis_cmac_igr_driver[0].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest, user);
            1: env.axis_cmac_igr_driver[1].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest, user);
            2:      env.axis_h2c_driver[0].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest, user);
            3:      env.axis_h2c_driver[1].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest, user);
        endcase
    endtask


    // ----- compare packets -----
    task compare_pkts(input byte pkt1[$], pkt2[$], input int size=0);
        automatic int byte_idx = 0;

        if ((size == 0) || (size > pkt2.size)) size = pkt2.size;

        if ( pkt1.size() != size ) begin
           $display("pkt1:"); pcap_pkg::print_pkt_data(pkt1);
           $display("pkt2:"); pcap_pkg::print_pkt_data(pkt2);

          `FAIL_IF_LOG( pkt1.size() != size,
                        $sformatf("FAIL!!! Packet size mismatch. size1=%0d size2=%0d", pkt1.size(), size) )
        end

        byte_idx = 0;
        while ( byte_idx < pkt1.size() ) begin
            //if (pkt1[byte_idx] == pkt2[byte_idx]) $display("Pass. Packet bytes match at byte_idx: %d", byte_idx);
            if (pkt1[byte_idx] != pkt2[byte_idx]) begin
                $display("pkt1:"); pcap_pkg::print_pkt_data(pkt1);
                $display("pkt2:"); pcap_pkg::print_pkt_data(pkt2);

                `FAIL_IF_LOG( pkt1[byte_idx] != pkt2[byte_idx],
                              $sformatf("FAIL!!! Packet bytes mismatch at byte_idx: 0x%0h (d:%0d)", byte_idx, byte_idx) )
            end
            byte_idx++;
        end
    endtask



    // ----- packet test sequence -----
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
                   @(posedge tb.axis_cmac_egr[0].tlast or posedge rx_done) begin
                      if (tb.axis_cmac_egr[0].tlast) begin timestamp++; env.ts_agent.set_static(timestamp); end
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
                            case (out_port)
                                0: env.axis_cmac_egr_monitor[0].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(0));
                                1: env.axis_cmac_egr_monitor[1].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(0));
                                2:      env.axis_c2h_monitor[0].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(0));
                                3:      env.axis_c2h_monitor[1].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(0));
                            endcase
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
