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
task send_pcap(input string pcap_filename, input int num_pkts=0, start_idx=0, twait=0, input in_if=0, input port_t id=0, dest=0);
    env.axis_driver[in_if].send_from_pcap(pcap_filename, num_pkts, start_idx, twait, id, dest);
endtask


// Compare packets
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
       if (pkt1[byte_idx] != pkt2[byte_idx]) begin
          $display("pkt1:"); pcap_pkg::print_pkt_data(pkt1);
          $display("pkt2:"); pcap_pkg::print_pkt_data(pkt2);
	  
          `FAIL_IF_LOG( pkt1[byte_idx] != pkt2[byte_idx],
                        $sformatf("FAIL!!! Packet bytes mismatch at byte_idx: 0x%0h (d:%0d)", byte_idx, byte_idx) )
       end
       byte_idx++;
    end
endtask


// Drop counter typedefs
typedef enum logic [31:0] {
    DROPS_FROM_PROC_PORT_0 = 'h0400,
    DROPS_FROM_PROC_PORT_1 = 'h0800
    } cntr_addr_encoding_t;

typedef union packed {
    cntr_addr_encoding_t  encoded;
    logic [31:0]          raw;
} cntr_addr_t;


// Check probe counts (pkt and byte).
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
