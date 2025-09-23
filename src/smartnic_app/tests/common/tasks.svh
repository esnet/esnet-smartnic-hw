import smartnic_pkg::*;
import axi4s_verif_pkg::*;

//=======================================================================
// Global variables
//=======================================================================
typedef enum logic [31:0] {
    PROBE_FROM_PF0      = 'h65000,
    PROBE_FROM_PF1      = 'h65100,
    PROBE_FROM_PF0_VF0  = 'h65200,
    PROBE_FROM_PF1_VF0  = 'h65300,
    PROBE_FROM_PF0_VF1  = 'h65400,
    PROBE_FROM_PF1_VF1  = 'h65500,

    PROBE_TO_PF0        = 'h65600,
    PROBE_TO_PF1        = 'h65700,
    PROBE_TO_PF0_VF0    = 'h65800,
    PROBE_TO_PF1_VF0    = 'h65900,
    PROBE_TO_PF0_VF1    = 'h65a00,
    PROBE_TO_PF1_VF1    = 'h65b00,

    PROBE_TO_APP_IGR_IN0  = 'h65c00,
    PROBE_TO_APP_IGR_IN1  = 'h65d00,
    PROBE_TO_APP_EGR_IN0  = 'h65e00,
    PROBE_TO_APP_EGR_IN1  = 'h65f00,
    PROBE_TO_APP_EGR_OUT0 = 'h66000,
    PROBE_TO_APP_EGR_OUT1 = 'h66100,

    PROBE_TO_APP_IGR_P4_OUT0 = 'h66200,
    PROBE_TO_APP_IGR_P4_OUT1 = 'h66300,
    PROBE_TO_APP_EGR_P4_IN0  = 'h66400,
    PROBE_TO_APP_EGR_P4_IN1  = 'h66500
    } cntr_addr_encoding_t;

typedef union packed {
    cntr_addr_encoding_t  encoded;
    logic [31:0]          raw;
} cntr_addr_t;


localparam PHY0    = 4'h0;
localparam PHY1    = 4'h1;
localparam PF0     = 4'h2;
localparam PF1     = 4'h3;
localparam PF0_VF0 = 4'h4;
localparam PF1_VF0 = 4'h5;
localparam PF0_VF1 = 4'h6;
localparam PF1_VF1 = 4'h7;
localparam PF0_VF2 = 4'h8;
localparam PF1_VF2 = 4'h9;

string  msg;
string  p4_sim_dir = "../../../../vitisnetp4/p4/sim/";

tuser_smartnic_meta_t   tuser;

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
                             tuser_smartnic_meta_t tuser='{rss_enable: 1'b0, rss_entropy: '0},
                             bit write_tables=1);
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

    #100ns;
    for (int i=0; i < env.N; i++) `FAIL_IF_LOG(env.scoreboard[i].report(msg) > 0, msg);

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


task check_cleared_probes;
    check_probe ( .base_addr(PROBE_FROM_PF0),     .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_PF1),     .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_PF0_VF0), .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_PF1_VF0), .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_PF0_VF1), .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_PF1_VF1), .exp_pkts(0), .exp_bytes(0) );

    check_probe ( .base_addr(PROBE_TO_PF0),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_PF1),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_PF0_VF0),   .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_PF1_VF0),   .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_PF0_VF1),   .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_PF1_VF1),   .exp_pkts(0), .exp_bytes(0) );

    check_probe ( .base_addr(PROBE_TO_APP_IGR_IN0),      .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_APP_IGR_IN1),      .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_APP_EGR_IN0),      .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_APP_EGR_IN1),      .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_APP_EGR_OUT0),     .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_APP_EGR_OUT1),     .exp_pkts(0), .exp_bytes(0) );

    check_probe ( .base_addr(PROBE_TO_APP_IGR_P4_OUT0),  .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_APP_IGR_P4_OUT1),  .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_APP_EGR_P4_IN0),   .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_APP_EGR_P4_IN1),   .exp_pkts(0), .exp_bytes(0) );
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

// Disable VitisNetP4 IP assertions
// - works around a time-zero underflow assertion that causes an immediate exit from the sim
// TODO: make this fine-grained... Vivado sim doesn't support hierarchical scoping, but could
//       turn off assertions during reset and then re-enable possibly
initial $assertoff(0);
