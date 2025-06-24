import smartnic_pkg::*;
import axi4s_verif_pkg::*;
import p4_proc_pkg::*;

//=======================================================================
// Global variables
//=======================================================================
typedef enum logic [31:0] {
    DROPS_FROM_P4          = 'h0400,
    DROPS_UNSET_ERR_PORT_0 = 'h0800,
    DROPS_UNSET_ERR_PORT_1 = 'h0C00
    } cntr_addr_encoding_t;

typedef union packed {
    cntr_addr_encoding_t  encoded;
    logic [31:0]          raw;
} cntr_addr_t;

string  msg;
string  p4_sim_dir = "../../../../vitisnetp4/p4/sim/";

tuser_t tuser;

//=======================================================================
// Tasks
//=======================================================================
task debug_msg(input string msg, input bit VERBOSE=0);
    if (VERBOSE) `INFO(msg);
endtask


task automatic write_p4_tables (input string testdir);
    string filename;

   `INFO("Writing VitisNetP4 tables...");
    filename = {p4_sim_dir, testdir, "/cli_commands.txt"};
    vitisnetp4_agent.table_init_from_file(filename);
endtask


task automatic run_pkt_test (input string testdir, port_t in_port=0, out_port=0, tid=0, tdest=0,
                             tuser_t tuser={64'hxxxxxxxxxxxxxxxx,16'd0,1'bx,16'hxxxx,1'b0,12'd0,1'bx},
                             bit write_tables=1, check_scoreboards=1);
    string filename;
    bit    rx_done=0;

    if (write_tables) write_p4_tables (.testdir(testdir));

   `INFO("Writing expected pcap data to scoreboard...");
    filename = {p4_sim_dir, testdir, "/packets_out.pcap"};

    env.pcap_to_scoreboard (.filename(filename), .tid(tid), .tdest(tdest), .tuser(tuser),
                            .scoreboard(env.scoreboard[out_port]) );

   `INFO("Starting simulation...");
    filename = {p4_sim_dir, testdir, "/packets_in.pcap"};
    env.pcap_to_driver     (.filename(filename), .driver(env.driver[in_port]));

    #1us;
    fork
        #10us if (!rx_done) `INFO("run_pkt_test task TIMEOUT!");

        while (!rx_done) #100ns if (env.scoreboard[out_port].exp_pending()==0)  rx_done=1;
    join_any
 
    if (check_scoreboards)
       for (int i=0; i < env.NUM_PROC_PORTS; i++) `FAIL_IF_LOG(env.scoreboard[i].report(msg) > 0, msg);

endtask


task check_probe (input cntr_addr_t base_addr, input logic [63:0] exp_pkts, exp_bytes);
    logic [63:0] rd_data;

    env.reg_agent.read_reg( base_addr + 'h0, rd_data[63:32] );  // pkt_count_upper
    env.reg_agent.read_reg( base_addr + 'h4, rd_data[31:0]  );  // pkt_count_lower
   `INFO($sformatf("%s pkt count: %0d", base_addr.encoded.name(), rd_data));
   `FAIL_UNLESS( rd_data == exp_pkts );

    env.reg_agent.read_reg( base_addr + 'h8, rd_data[63:32] );  // byte_count_upper
    env.reg_agent.read_reg( base_addr + 'hc, rd_data[31:0]  );  // byte_count_lower
   `INFO($sformatf("%s byte count: %0d", base_addr.encoded.name(), rd_data));
   `FAIL_UNLESS( rd_data == exp_bytes );

    env.reg_agent.write_reg( base_addr + 'h10, 'h2 ); // CLR_ON_WR_EVT
endtask;


// Export AXI-L accessors to VitisNetP4 shared library
export "DPI-C" task axi_lite_wr;
task axi_lite_wr(input int address, input int data);
    env.vitisnetp4_write(address, data);
endtask

export "DPI-C" task axi_lite_rd;
task axi_lite_rd(input int address, inout int data);
    env.vitisnetp4_read(address, data);
endtask

string p4_dpic_hier_path = $sformatf("%m");
