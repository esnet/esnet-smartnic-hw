import smartnic_pkg::*;

tb_pkg::tb_env env;

vitisnetp4_igr_verif_pkg::vitisnetp4_igr_agent vitisnetp4_agent;

//=======================================================================
// Probe tasks
//=======================================================================
typedef enum logic [31:0] {
    PROBE_FROM_PF0      = 'h64000,
    PROBE_FROM_PF1      = 'h64100,
    PROBE_FROM_PF0_VF0  = 'h64200,
    PROBE_FROM_PF1_VF0  = 'h64300,
    PROBE_FROM_PF0_VF1  = 'h64400,
    PROBE_FROM_PF1_VF1  = 'h64500,

    PROBE_TO_PF0        = 'h64600,
    PROBE_TO_PF1        = 'h64700,
    PROBE_TO_PF0_VF0    = 'h64800,
    PROBE_TO_PF1_VF0    = 'h64900,
    PROBE_TO_PF0_VF1    = 'h64a00,
    PROBE_TO_PF1_VF1    = 'h64b00,

    PROBE_TO_APP_IGR_IN0  = 'h64c00,
    PROBE_TO_APP_IGR_IN1  = 'h64d00,
    PROBE_TO_APP_EGR_IN0  = 'h64e00,
    PROBE_TO_APP_EGR_IN1  = 'h64f00,
    PROBE_TO_APP_EGR_OUT0 = 'h65000,
    PROBE_TO_APP_EGR_OUT1 = 'h65100

    } cntr_addr_encoding_t;

typedef union packed {
    cntr_addr_encoding_t  encoded;
    logic [31:0]          raw;
} cntr_addr_t;

task check_probe (input cntr_addr_t base_addr, input logic [63:0] exp_pkt_cnt, exp_byte_cnt);
    logic [63:0] rd_data;

    env.reg_agent.read_reg( base_addr + 'h0, rd_data[63:32] );  // pkt_count_upper
    env.reg_agent.read_reg( base_addr + 'h4, rd_data[31:0]  );  // pkt_count_lower
   `INFO($sformatf("%s pkt count: %0d", base_addr.encoded.name(), rd_data));
   `FAIL_UNLESS( rd_data == exp_pkt_cnt );

    env.reg_agent.read_reg( base_addr + 'h8, rd_data[63:32] );  // byte_count_upper
    env.reg_agent.read_reg( base_addr + 'hc, rd_data[31:0]  );  // byte_count_lower
   `INFO($sformatf("%s byte count: %0d", base_addr.encoded.name(), rd_data));
   `FAIL_UNLESS( rd_data == exp_byte_cnt );
endtask;

task clear_igr_probe (input port_t in_if=0);
    case (in_if)
        PF0:          env.probe_from_pf0_reg_blk_agent.write_probe_control ( 'h2 );
        PF1:          env.probe_from_pf1_reg_blk_agent.write_probe_control ( 'h2 );
        PF0_VF0:  env.probe_from_pf0_vf0_reg_blk_agent.write_probe_control ( 'h2 );
        PF1_VF0:  env.probe_from_pf1_vf0_reg_blk_agent.write_probe_control ( 'h2 );
        PF0_VF1:  env.probe_from_pf0_vf1_reg_blk_agent.write_probe_control ( 'h2 );
        PF1_VF1:  env.probe_from_pf1_vf1_reg_blk_agent.write_probe_control ( 'h2 );
    endcase
endtask;

task clear_egr_probe (input port_t out_if=0);
    case (out_if)
        CMAC0: begin
              env.probe_to_app_igr_in0_reg_blk_agent.write_probe_control ( 'h2 );
              env.probe_to_app_egr_in0_reg_blk_agent.write_probe_control ( 'h2 );
              env.probe_to_app_egr_out0_reg_blk_agent.write_probe_control( 'h2 );
        end
        CMAC1: begin
              env.probe_to_app_igr_in1_reg_blk_agent.write_probe_control ( 'h2 );
              env.probe_to_app_egr_in1_reg_blk_agent.write_probe_control ( 'h2 );
              env.probe_to_app_egr_out1_reg_blk_agent.write_probe_control( 'h2 );
        end
        PF0:          env.probe_to_pf0_reg_blk_agent.write_probe_control ( 'h2 );
        PF1:          env.probe_to_pf1_reg_blk_agent.write_probe_control ( 'h2 );
        PF0_VF0:  env.probe_to_pf0_vf0_reg_blk_agent.write_probe_control ( 'h2 );
        PF1_VF0:  env.probe_to_pf1_vf0_reg_blk_agent.write_probe_control ( 'h2 );
        PF0_VF1:  env.probe_to_pf0_vf1_reg_blk_agent.write_probe_control ( 'h2 );
        PF1_VF1:  env.probe_to_pf1_vf1_reg_blk_agent.write_probe_control ( 'h2 );
    endcase
endtask;

task clear_all_probes;
    env.probe_from_pf0_reg_blk_agent.write_probe_control     ( 'h2 );
    env.probe_from_pf1_reg_blk_agent.write_probe_control     ( 'h2 );
    env.probe_from_pf0_vf0_reg_blk_agent.write_probe_control ( 'h2 );
    env.probe_from_pf1_vf0_reg_blk_agent.write_probe_control ( 'h2 );
    env.probe_from_pf0_vf1_reg_blk_agent.write_probe_control ( 'h2 );
    env.probe_from_pf1_vf1_reg_blk_agent.write_probe_control ( 'h2 );

    env.probe_to_pf0_reg_blk_agent.write_probe_control       ( 'h2 );
    env.probe_to_pf1_reg_blk_agent.write_probe_control       ( 'h2 );
    env.probe_to_pf0_vf0_reg_blk_agent.write_probe_control   ( 'h2 );
    env.probe_to_pf1_vf0_reg_blk_agent.write_probe_control   ( 'h2 );
    env.probe_to_pf0_vf1_reg_blk_agent.write_probe_control   ( 'h2 );
    env.probe_to_pf1_vf1_reg_blk_agent.write_probe_control   ( 'h2 );
endtask;

task check_cleared_probes;
    check_probe ( .base_addr(PROBE_FROM_PF0),     .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_FROM_PF1),     .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_FROM_PF0_VF0), .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_FROM_PF1_VF0), .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_FROM_PF0_VF1), .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_FROM_PF1_VF1), .exp_pkt_cnt(0), .exp_byte_cnt(0) );

    check_probe ( .base_addr(PROBE_TO_PF0),       .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_TO_PF1),       .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_TO_PF0_VF0),   .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_TO_PF1_VF0),   .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_TO_PF0_VF1),   .exp_pkt_cnt(0), .exp_byte_cnt(0) );
    check_probe ( .base_addr(PROBE_TO_PF1_VF1),   .exp_pkt_cnt(0), .exp_byte_cnt(0) );
endtask;



//=======================================================================
// Traffic tasks
//=======================================================================
string P4_SIM_PATH = "../../../p4/sim/";

task debug_msg(input string msg, input bit VERBOSE=0);
    if (VERBOSE) `INFO(msg);
endtask

// Execute block reset (dataplane + control plane)
task reset();
    automatic bit reset_done;
    automatic string msg;
    env.reset();
    env.wait_reset_done(reset_done, msg);
    `FAIL_IF_LOG((reset_done == 0), msg);
endtask


// Send packets described in PCAP file on AXI-S input interface
task send_pcap(input string pcap_filename, input int num_pkts=0, start_idx=0, twait=0, input port_t in_if=0, id=0, dest=0);
    case (in_if)
        CMAC0:          env.axis_in_driver[0].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
        CMAC1:          env.axis_in_driver[1].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
        PF0:       env.axis_h2c_driver[PF][0].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
        PF1:       env.axis_h2c_driver[PF][1].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
        PF0_VF0:  env.axis_h2c_driver[VF0][0].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
        PF1_VF0:  env.axis_h2c_driver[VF0][1].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
        PF0_VF1:  env.axis_h2c_driver[VF1][0].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
        PF1_VF1:  env.axis_h2c_driver[VF1][1].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
        default:  $display ("Input interface 'in_if' undefined:", in_if);
    endcase
endtask


// Compare packets
task compare_pkts(input byte pkt1[$], pkt2[$]);
    automatic int byte_idx = 0;

    if (pkt1.size != pkt2.size()) begin
        $display("pkt1:"); pcap_pkg::print_pkt_data(pkt1);
        $display("pkt2:"); pcap_pkg::print_pkt_data(pkt2);
        `FAIL_IF_LOG(
            pkt1.size() != pkt2.size(),
            $sformatf("FAIL!!! Packet size mismatch. size1=%0d size2=%0d", pkt1.size(), pkt2.size())
        );
    end

    byte_idx = 0;
    while ( byte_idx < pkt1.size() ) begin
       if (pkt1[byte_idx] != pkt2[byte_idx]) begin
          $display("pkt1:"); pcap_pkg::print_pkt_data(pkt1);
          $display("pkt2:"); pcap_pkg::print_pkt_data(pkt2);
	  
          `FAIL_IF_LOG( pkt1[byte_idx] != pkt2[byte_idx],
                        $sformatf("FAIL!!! Packet bytes mismatch at byte_idx: 0x%0h (d:%0d)", byte_idx, byte_idx) )
       end
       byte_idx++;
    end
endtask


// Run packet test
task automatic run_pkt_test (
    input string testdir, expfile="/expected/packets_out.pcap",
    input logic[63:0] init_timestamp=0,
    input port_t in_if=0, out_if=0, dest_port=0,
    input write_p4_tables=1, check_tdest=1, VERBOSE=1 );

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
    automatic int rx_byte_cnt = 0;
    automatic bit rx_done = 0;
    byte          rx_data[$];
    port_t        id;
    port_t        dest;
    bit           user;

    debug_msg($sformatf("Write initial timestamp value: %0x", timestamp), VERBOSE);
    env.ts_agent.set_static(timestamp);

    if (write_p4_tables==1) begin
        debug_msg("Start writing VitisNetP4 tables...", VERBOSE);
        filename = {P4_SIM_PATH, testdir, "/cli_commands.txt"};
        vitisnetp4_agent.table_init_from_file(filename);
        debug_msg("Done writing VitisNetP4 tables...", VERBOSE);
    end

    debug_msg("Reading expected pcap file...", VERBOSE);
    filename = {P4_SIM_PATH, testdir, expfile};
    exp_pcap = pcap_pkg::read_pcap(filename);

    debug_msg("Starting simulation...", VERBOSE);
    filename = {P4_SIM_PATH, testdir, "/packets_in.pcap"};
    rx_pkt_cnt = 0;
    rx_byte_cnt = 0;
    clear_all_probes;
    fork
        begin
            // Send packets
            send_pcap(.pcap_filename(filename), .num_pkts(num_pkts), .start_idx(start_idx),
                      .twait(twait), .in_if(in_if), .id(in_if), .dest(dest_port));
        end

        begin
            // If init_timestamp=1, increment timestamp after each tx packet (puts packet # in timestamp field)
            while ( (init_timestamp == 1) && (in_if==0) && !rx_done ) begin
                @(posedge tb.axis_in_if[0].tlast or posedge rx_done) begin
                    if (tb.axis_in_if[0].tlast) begin tb.axis_in_if[0]._wait(50); timestamp++; env.ts_agent.set_static(timestamp); end
                end
            end
        end

        begin
            // Monitor output packets
            while (rx_pkt_cnt < exp_pcap.records.size()) begin
                case (out_if)
                    CMAC0:        env.axis_out_monitor[0].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(5));
                    CMAC1:        env.axis_out_monitor[1].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(5));
                    PF0:      env.axis_c2h_monitor[PF][0].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(5));
                    PF1:      env.axis_c2h_monitor[PF][1].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(5));
                    PF0_VF0: env.axis_c2h_monitor[VF0][0].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(5));
                    PF1_VF0: env.axis_c2h_monitor[VF0][1].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(5));
                    PF0_VF1: env.axis_c2h_monitor[VF1][0].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(5));
                    PF1_VF1: env.axis_c2h_monitor[VF1][1].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(5));
                    default: $display ("Output interface 'out_if' undefined:", out_if);
                endcase

                rx_pkt_cnt++;
                rx_byte_cnt = rx_byte_cnt + rx_data.size();
                debug_msg( $sformatf( "      Receiving packet # %0d (of %0d)...",
                                      rx_pkt_cnt, exp_pcap.records.size()), VERBOSE );

                debug_msg("      Comparing rx_pkt to exp_pkt...", VERBOSE);
                compare_pkts(rx_data, exp_pcap.records[start_idx+rx_pkt_cnt-1].pkt_data);
                if (check_tdest) `FAIL_IF_LOG( dest != dest_port,
                                               $sformatf("FAIL!!! Output tdest mismatch. tdest=%0h (exp:%0h)", dest, dest_port) )
            end

            case (in_if)
                PF0:       begin check_probe (PROBE_FROM_PF0,     rx_pkt_cnt, rx_byte_cnt); clear_igr_probe(in_if); end
                PF1:       begin check_probe (PROBE_FROM_PF1,     rx_pkt_cnt, rx_byte_cnt); clear_igr_probe(in_if); end
                PF0_VF0:   begin check_probe (PROBE_FROM_PF0_VF0, rx_pkt_cnt, rx_byte_cnt); clear_igr_probe(in_if); end
                PF1_VF0:   begin check_probe (PROBE_FROM_PF1_VF0, rx_pkt_cnt, rx_byte_cnt); clear_igr_probe(in_if); end
                PF0_VF1:   begin check_probe (PROBE_FROM_PF0_VF1, rx_pkt_cnt, rx_byte_cnt); clear_igr_probe(in_if); end
                PF1_VF1:   begin check_probe (PROBE_FROM_PF1_VF1, rx_pkt_cnt, rx_byte_cnt); clear_igr_probe(in_if); end
            endcase

            case (out_if)
                CMAC0:     if (in_if == CMAC0) begin
                                 check_probe (PROBE_TO_APP_IGR_IN0,  rx_pkt_cnt, rx_byte_cnt);
                                 check_probe (PROBE_TO_APP_EGR_IN0,  rx_pkt_cnt, rx_byte_cnt);
                                 check_probe (PROBE_TO_APP_EGR_OUT0, rx_pkt_cnt, rx_byte_cnt); clear_egr_probe(out_if);
                           end
                CMAC1:     if (in_if == CMAC1) begin
                                 check_probe (PROBE_TO_APP_IGR_IN1,  rx_pkt_cnt, rx_byte_cnt);
                                 check_probe (PROBE_TO_APP_EGR_IN1,  rx_pkt_cnt, rx_byte_cnt);
                                 check_probe (PROBE_TO_APP_EGR_OUT1, rx_pkt_cnt, rx_byte_cnt); clear_egr_probe(out_if);
                           end
                PF0:       begin check_probe (PROBE_TO_PF0,     rx_pkt_cnt, rx_byte_cnt); clear_egr_probe(out_if); end
                PF1:       begin check_probe (PROBE_TO_PF1,     rx_pkt_cnt, rx_byte_cnt); clear_egr_probe(out_if); end
                PF0_VF0:   begin check_probe (PROBE_TO_PF0_VF0, rx_pkt_cnt, rx_byte_cnt); clear_egr_probe(out_if); end
                PF1_VF0:   begin check_probe (PROBE_TO_PF1_VF0, rx_pkt_cnt, rx_byte_cnt); clear_egr_probe(out_if); end
                PF0_VF1:   begin check_probe (PROBE_TO_PF0_VF1, rx_pkt_cnt, rx_byte_cnt); clear_egr_probe(out_if); end
                PF1_VF1:   begin check_probe (PROBE_TO_PF1_VF1, rx_pkt_cnt, rx_byte_cnt); clear_egr_probe(out_if); end
            endcase

            rx_done = 1;
        end
    join
endtask
