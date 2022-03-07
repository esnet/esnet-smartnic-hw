//=======================================================================
// Tasks
//=======================================================================
import smartnic_322mhz_pkg::*;

// Execute block reset (dataplane + control plane)
task reset();
    automatic bit reset_done;
    automatic string msg;
    env.reset();
    env.wait_reset_done(reset_done, msg);
    `FAIL_IF_LOG((reset_done == 0), msg);
endtask


// Send packets described in PCAP file on AXI-S input interface
task send_pcap (
    input string  pcap_filename,
    input int     num_pkts=0, start_idx=0, twait=0,
    input port_t  id=0, dest=0 );

    env.axis_driver[id].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
endtask


// Compare packets
task compare_pkts(input byte pkt1[$], pkt2[$]);
    automatic int byte_idx = 0;

    if ( pkt1.size() != pkt2.size() ) begin
       $display("pkt1:"); pcap_pkg::print_pkt_data(pkt1);
       $display("pkt2:"); pcap_pkg::print_pkt_data(pkt2);

      `FAIL_IF_LOG( pkt1.size() != pkt2.size(),
                    $sformatf("FAIL!!! Packet size mismatch. size1=%0d size2=%0d", pkt1.size(), pkt2.size()))
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


task automatic run_pkt_stream (
       input port_t           in_port, out_port,
       input string           in_pcap, out_pcap,
       output logic [63:0]    tx_pkt_cnt, tx_byte_cnt,
       output logic [63:0]    rx_pkt_cnt, rx_byte_cnt,
       input int              exp_pkt_cnt = 0,
       input int              tpause = 0, twait = 0
    );
   
    // variabes for reading pcap data$
    byte                      pcap_data[$][$];
    pcap_pkg::pcap_hdr_t      pcap_hdr;
    pcap_pkg::pcaprec_hdr_t   pcap_record_hdr[$];

    // variables for sending packet data
    int num_pkts  = 0;
    int start_idx = 0;

    // variables for receiving (monitoring) packet data
    byte  rx_data[$];
    bit   id;
    bit   dest;
    bit   user;

   `INFO($sformatf("Stream in_port %0d: Reading input pcap file...", in_port));
    pcap_pkg::read_pcap(in_pcap, pcap_hdr, pcap_record_hdr, pcap_data);
    tx_pkt_cnt  = pcap_record_hdr.size();
    tx_byte_cnt = 0;  foreach (pcap_data[i,]) tx_byte_cnt += pcap_data[i].size();

   `INFO($sformatf("Stream in_port %0d: Reading output pcap file...", in_port));
    pcap_pkg::read_pcap(out_pcap, pcap_hdr, pcap_record_hdr, pcap_data);
   
   `INFO($sformatf("Stream in_port %0d: Starting packet stream...", in_port));
    fork
       begin
          // Send packets	    
          send_pcap(in_pcap, num_pkts, start_idx, twait, in_port, out_port);
       end
       begin
          // Monitor output packets
          rx_pkt_cnt = 0; rx_byte_cnt = 0;

          if (exp_pkt_cnt == 0) exp_pkt_cnt = pcap_record_hdr.size();

          while (rx_pkt_cnt < exp_pkt_cnt) begin
             env.axis_monitor[out_port].receive_raw(.data(rx_data), .id(id), .dest(dest), .user(user), .tpause(tpause));
             rx_pkt_cnt++;
             rx_byte_cnt = rx_byte_cnt + rx_data.size();
            `INFO($sformatf("       Stream in_port %0d (out_port %0d): Receiving packet # %0d (of %0d)...", 
                                    in_port, out_port, rx_pkt_cnt, exp_pkt_cnt) );
             // pcap_pkg::print_pkt_data(rx_data);
             compare_pkts(rx_data, pcap_data[start_idx+rx_pkt_cnt-1]);
          end
       end
    join
endtask;


// Force loopback
task force_loopback();
    `INFO("Forcing loopback from ingress switch to egress switch.");
    force tb.DUT.axis_switch_egress.s_axis_tvalid = tb.DUT.axis_switch_ingress.m_axis_tvalid;
    force tb.DUT.axis_switch_egress.s_axis_tdata  = tb.DUT.axis_switch_ingress.m_axis_tdata;
    force tb.DUT.axis_switch_egress.s_axis_tkeep  = tb.DUT.axis_switch_ingress.m_axis_tkeep;
    force tb.DUT.axis_switch_egress.s_axis_tlast  = tb.DUT.axis_switch_ingress.m_axis_tlast;
    force tb.DUT.axis_switch_egress.s_axis_tid    = tb.DUT.axis_switch_ingress.m_axis_tid;
    force tb.DUT.axis_switch_egress.s_axis_tdest  = tb.DUT.axis_switch_ingress.m_axis_tdest;

    force tb.DUT.axis_switch_ingress.m_axis_tready = tb.DUT.axis_switch_egress.s_axis_tready;
endtask // force_loopback


