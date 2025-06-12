//=======================================================================
// Global variables
//=======================================================================
localparam NUM_PORTS = 4;

import smartnic_pkg::*;
import axi4s_verif_pkg::*;

typedef enum logic [31:0] {
    PROBE_CORE_TO_APP0    = 'h0c00,
    PROBE_CORE_TO_APP1    = 'h0d00,
    PROBE_APP0_TO_CORE    = 'h0e00,
    PROBE_APP1_TO_CORE    = 'h0f00,

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
    PROBE_FROM_PF0_VF2    = 'h3600,
    PROBE_FROM_PF1_VF2    = 'h3700,
    PROBE_TO_PF0_VF2      = 'h3800,
    PROBE_TO_PF1_VF2      = 'h3900,
    DROPS_Q_RANGE_FAIL0   = 'h3a00,
    DROPS_Q_RANGE_FAIL1   = 'h3b00,

    PROBE_TO_BYPASS0      = 'h4000,
    DROPS_TO_BYPASS0      = 'h4100,
    PROBE_TO_BYPASS1      = 'h4300,
    DROPS_TO_BYPASS1      = 'h4400
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
localparam UNSET   = 4'hf;

string  msg;

smartnic_reg_pkg::reg_switch_config_t switch_config;

int exp_pkts [NUM_PORTS-1:0];

`SVUNIT_CLK_GEN(tb.axil_aclk, 4ns);   // 125 Mhz
`SVUNIT_CLK_GEN(tb.axis_clk, 1553ps); // 322 Mhz


//=======================================================================
// Tasks
//=======================================================================
task automatic app_mode(input int port);
    env.smartnic_reg_blk_agent.write_smartnic_mux_out_sel(port, 0);
endtask


task automatic bypass_mode(input int port);
    env.smartnic_reg_blk_agent.write_smartnic_mux_out_sel(port, 2);
endtask


task automatic drop_mode(input int port);
    env.smartnic_reg_blk_agent.write_smartnic_mux_out_sel(port, 3);
endtask


task automatic host_mode(input int port);
    logic [1:0] rd_data;

    env.smartnic_reg_blk_agent.read_smartnic_demux_out_sel(rd_data);
    rd_data[port] = 1;
    env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel(rd_data);
endtask


task automatic stream_test(input bit mode);
endtask


// Create and send input transaction
task automatic one_packet(input int idx=0, len=64, input port_t tid=0, tdest=tid, input bit tuser=0);
    axi4s_transaction#(adpt_tx_tid_t, port_t, bit)  transaction_in;

    transaction_in = new(.name($sformatf("trans_%0d_in", idx)), .len(len));
    transaction_in.randomize();
    transaction_in.set_tdest(tdest);
    transaction_in.set_tuser(tuser);
    case (tid.encoded.typ)
        PHY: if (tid.encoded.num == P0) begin transaction_in.set_tid(0); env.inbox[PHY0].put(transaction_in); end
             else                       begin transaction_in.set_tid(0); env.inbox[PHY1].put(transaction_in); end

        PF:  if (tid.encoded.num == P0) begin
                 transaction_in.set_tid($urandom_range(0,511) + 16'd0);     env.inbox[PF0].put(transaction_in);
             end else begin
                 transaction_in.set_tid($urandom_range(0,511) + 16'd2048);  env.inbox[PF1].put(transaction_in);
             end
        VF0: if (tid.encoded.num == P0) begin
                 transaction_in.set_tid($urandom_range(0,511) + 16'd512);   env.inbox[PF0].put(transaction_in);
             end else begin
                 transaction_in.set_tid($urandom_range(0,511) + 16'd2560);  env.inbox[PF1].put(transaction_in);
             end
        VF1: if (tid.encoded.num == P0) begin
                 transaction_in.set_tid($urandom_range(0,511) + 16'd1024);  env.inbox[PF0].put(transaction_in);
             end else begin
                 transaction_in.set_tid($urandom_range(0,511) + 16'd3072);  env.inbox[PF1].put(transaction_in);
             end
        VF2: if (tid.encoded.num == P0) begin
                 transaction_in.set_tid($urandom_range(0,510) + 16'd1536);  env.inbox[PF0].put(transaction_in);
             end else begin
                 transaction_in.set_tid($urandom_range(0,510) + 16'd3584);  env.inbox[PF1].put(transaction_in);
             end
        UNSET: if (tid.encoded.num == P0) begin  // used for out-of-range test
                 transaction_in.set_tid(                  511 + 16'd1536);  env.inbox[PF0].put(transaction_in);
             end else begin
                 transaction_in.set_tid(                  511 + 16'd3584);  env.inbox[PF1].put(transaction_in);
             end
    endcase
endtask


task automatic packet_stream(input int pkts=10, mode=0, output int bytes, input port_t tid=0, tdest=tid, input bit tuser=0);
    int len = 63;
    bytes=0;

    for (int i = 0; i < pkts; i++) begin
        if      (mode==0) len = $urandom_range(64, 1518);
        else if (mode==1) len = len+1;
        else              len = mode;

        one_packet(.idx(i), .len(len), .tid(tid), .tdest(tdest), .tuser(tuser));
        bytes = bytes + len;
    end
endtask


task automatic check_scoreboard(input int port=0, pkts=0);
    if (pkts==0) begin
       `FAIL_UNLESS_EQUAL(env.scoreboard[port].got_processed(), 0);
    end else begin
       `FAIL_UNLESS_EQUAL(env.scoreboard[port].got_matched(), pkts);
       `FAIL_IF_LOG(env.scoreboard[port].report(msg) > 0, msg);
    end
endtask

task automatic check_phy0(input int pkts=0);
    check_scoreboard (.port(PHY0), .pkts(pkts) );
endtask

task automatic check_phy1(input int pkts=0);
    check_scoreboard (.port(PHY1), .pkts(pkts) );
endtask

task automatic check_pf0(input int pkts=0);
    check_scoreboard (.port(PF0), .pkts(pkts) );
endtask

task automatic check_pf1(input int pkts=0);
    check_scoreboard (.port(PF1), .pkts(pkts) );
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


task latch_probe_counters;
    env.reg_agent.write_reg( PROBE_CORE_TO_APP0    + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_CORE_TO_APP1    + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_APP0_TO_CORE    + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_APP1_TO_CORE    + 'h10, 'h1 );

    env.reg_agent.write_reg( PROBE_FROM_CMAC0      + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_OVFL_FROM_CMAC0 + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_ERR_FROM_CMAC0  + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_FROM_CMAC1      + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_OVFL_FROM_CMAC1 + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_ERR_FROM_CMAC1  + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_TO_CMAC0        + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_OVFL_TO_CMAC0   + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_TO_CMAC1        + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_OVFL_TO_CMAC1   + 'h10, 'h1 );

    env.reg_agent.write_reg( PROBE_FROM_PF0        + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_FROM_PF1        + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_TO_PF0          + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_OVFL_TO_PF0     + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_TO_PF1          + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_OVFL_TO_PF1     + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_FROM_PF0_VF2    + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_FROM_PF1_VF2    + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_TO_PF0_VF2      + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_TO_PF1_VF2      + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_Q_RANGE_FAIL0   + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_Q_RANGE_FAIL1   + 'h10, 'h1 );

    env.reg_agent.write_reg( PROBE_TO_BYPASS0      + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_TO_BYPASS0      + 'h10, 'h1 );
    env.reg_agent.write_reg( PROBE_TO_BYPASS1      + 'h10, 'h1 );
    env.reg_agent.write_reg( DROPS_TO_BYPASS1      + 'h10, 'h1 );
endtask;


task check_cleared_probe_counters;
    check_probe ( .base_addr(PROBE_CORE_TO_APP0),     .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_CORE_TO_APP1),     .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_APP0_TO_CORE),     .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_APP1_TO_CORE),     .exp_pkts(0), .exp_bytes(0) );

    check_probe ( .base_addr(PROBE_FROM_CMAC0),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_OVFL_FROM_CMAC0),  .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_ERR_FROM_CMAC0),   .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_CMAC1),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_OVFL_FROM_CMAC1),  .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_ERR_FROM_CMAC1),   .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_CMAC0),         .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_OVFL_TO_CMAC0),    .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_CMAC1),         .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_OVFL_TO_CMAC1),    .exp_pkts(0), .exp_bytes(0) );

    check_probe ( .base_addr(PROBE_FROM_PF0),         .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_PF1),         .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_PF0),           .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_OVFL_TO_PF0),      .exp_pkts(0), .exp_bytes(0) ); 
    check_probe ( .base_addr(PROBE_TO_PF1),           .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_OVFL_TO_PF1),      .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_PF0_VF2),     .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_FROM_PF1_VF2),     .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_PF0_VF2),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_PF1_VF2),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_Q_RANGE_FAIL0),    .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_Q_RANGE_FAIL1),    .exp_pkts(0), .exp_bytes(0) );

    check_probe ( .base_addr(PROBE_TO_BYPASS0),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_TO_BYPASS0),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(PROBE_TO_BYPASS1),       .exp_pkts(0), .exp_bytes(0) );
    check_probe ( .base_addr(DROPS_TO_BYPASS1),       .exp_pkts(0), .exp_bytes(0) );
endtask;


task check_probe_control_defaults;
    logic [31:0]  rd_data;
    automatic bit rd_fail = 0;

    env.reg_agent.read_reg( PROBE_CORE_TO_APP0    + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_CORE_TO_APP1    + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_APP0_TO_CORE    + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_APP1_TO_CORE    + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);

    env.reg_agent.read_reg( PROBE_FROM_CMAC0      + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_OVFL_FROM_CMAC0 + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_ERR_FROM_CMAC0  + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_FROM_CMAC1      + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_OVFL_FROM_CMAC1 + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_ERR_FROM_CMAC1  + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_TO_CMAC0        + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_OVFL_TO_CMAC0   + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_TO_CMAC1        + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_OVFL_TO_CMAC1   + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);

    env.reg_agent.read_reg( PROBE_FROM_PF0        + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_FROM_PF1        + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_TO_PF0          + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_OVFL_TO_PF0     + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_TO_PF1          + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_OVFL_TO_PF1     + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_FROM_PF0_VF2    + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_FROM_PF1_VF2    + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_TO_PF0_VF2      + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_TO_PF1_VF2      + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_Q_RANGE_FAIL0   + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_Q_RANGE_FAIL1   + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);

    env.reg_agent.read_reg( PROBE_TO_BYPASS0      + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_TO_BYPASS0      + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( PROBE_TO_BYPASS1      + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);
    env.reg_agent.read_reg( DROPS_TO_BYPASS1      + 'h10, rd_data ); rd_fail = rd_fail || (rd_data != 0);

    `FAIL_UNLESS( rd_fail == 0 );
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
