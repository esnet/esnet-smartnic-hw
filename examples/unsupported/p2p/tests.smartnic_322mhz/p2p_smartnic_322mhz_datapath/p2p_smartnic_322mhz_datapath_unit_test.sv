`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module p2p_smartnic_322mhz_datapath_unit_test;

    // Testcase name
    string name = "p2p_smartnic_322mhz_datapath_ut";

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

    //===================================
    // Import common testcase tasks
    //=================================== 
    `include "../../../../../../src/smartnic_322mhz/tests/common/tasks.svh"       

    //===================================
    // Connect AXI-S sample interface
    //===================================

    /*
    assign tb.axis_sample_clk = tb.clk;
    assign tb.axis_sample_aresetn = !tb.rst;
    assign tb.axis_sample_if.tvalid = tb.DUT.bypass_mux_to_switch.axi4s_in.tvalid;
    assign tb.axis_sample_if.tlast  = tb.DUT.bypass_mux_to_switch.axi4s_in.tlast;
    assign tb.axis_sample_if.tdata  = tb.DUT.bypass_mux_to_switch.axi4s_in.tdata;
    assign tb.axis_sample_if.tkeep  = tb.DUT.bypass_mux_to_switch.axi4s_in.tkeep;
    assign tb.axis_sample_if.tuser  = tb.DUT.bypass_mux_to_switch.axi4s_in.tuser;
    assign tb.axis_sample_if.tready = tb.DUT.bypass_mux_to_switch.axi4s_in.tready;
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
    // Global test variables
    //===================================
    localparam NUM_PORTS = 4;
    localparam FIFO_DEPTH = 410.0; // 124 (fifo_async) + 2 x 143 (axi4s_pkt_discard)

    smartnic_322mhz_reg_pkg::reg_port_config_t set_config;

    // variables for switch tests.
    import smartnic_322mhz_pkg::*;
    port_t out_port_map [NUM_PORTS-1:0];  // vector specifies output port for each input stream.

    string in_pcap  [NUM_PORTS-1:0];  // vector specifies the in_pcap file for each input stream.
    string out_pcap [NUM_PORTS-1:0];  // vector specifies the out_pcap file for each input stream.

    // variables for probe checks.
    int tx_pkt_cnt  [NUM_PORTS-1:0];  // captures the tx pkt & byte counts from the pcap file for a given test.
    int tx_byte_cnt [NUM_PORTS-1:0];

    int rx_pkt_cnt  [NUM_PORTS-1:0];  // captures the rx pkt & byte counts from the pcap file for a given test.
    int rx_byte_cnt [NUM_PORTS-1:0];

    int rx_pkt_tot  = 0;
    int rx_byte_tot = 0;

    // variables for discard tests.
    int	pkt_len     [NUM_PORTS-1:0];
    int exp_pkt_cnt [NUM_PORTS-1:0];  // vector specifies the expected number of pkts received for each stream.

   
    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        // default variable configuration
         in_pcap[0] = "../../../smartnic/src/smartnic_322mhz/tests/common/pcap/20xrandom_pkts.pcap";
        out_pcap[0] = "../../../smartnic/src/smartnic_322mhz/tests/common/pcap/20xrandom_pkts.pcap";
         in_pcap[1] = "../../../smartnic/src/smartnic_322mhz/tests/common/pcap/30xrandom_pkts.pcap";
        out_pcap[1] = "../../../smartnic/src/smartnic_322mhz/tests/common/pcap/30xrandom_pkts.pcap";
         in_pcap[2] = "../../../smartnic/src/smartnic_322mhz/tests/common/pcap/40xrandom_pkts.pcap";
        out_pcap[2] = "../../../smartnic/src/smartnic_322mhz/tests/common/pcap/40xrandom_pkts.pcap";
         in_pcap[3] = "../../../smartnic/src/smartnic_322mhz/tests/common/pcap/50xrandom_pkts.pcap";
        out_pcap[3] = "../../../smartnic/src/smartnic_322mhz/tests/common/pcap/50xrandom_pkts.pcap";

        out_port_map = {2'h0, 2'h2, 2'h3, 2'h1};
        pkt_len      = {0, 0, 0, 0};  
        exp_pkt_cnt  = {0, 0, 0, 0};  // if exp_pkt_cnt field is set 0, value is determined from pcap file.

        for (int i=0; i<NUM_PORTS; i++) env.axis_driver[i].set_min_gap(0);

        svunit_ut.setup();

        // Issue reset (both datapath and management domains)
        reset();

        `INFO("Waiting to initialize axis fifos...");
        for (integer i = 0; i < 100 ; i=i+1 ) begin
          @(posedge tb.clk);
        end

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

      `SVTEST(basic_sanity)
         out_port_map = {2'h3, 2'h2, 2'h1, 2'h0}; 
         run_stream_test(); check_stream_test_probes;
      `SVTEST_END

    `SVUNIT_TESTS_END

   
    task run_stream_test (input int tpause = 0, twait = 0);
        fork
           run_pkt_stream ( .in_port(0), .out_port(out_port_map[0]), .in_pcap(in_pcap[0]), .out_pcap(out_pcap[0]),
                            .tx_pkt_cnt(tx_pkt_cnt[0]), .tx_byte_cnt(tx_byte_cnt[0]), 
                            .rx_pkt_cnt(rx_pkt_cnt[0]), .rx_byte_cnt(rx_byte_cnt[0]),
                            .exp_pkt_cnt(exp_pkt_cnt[0]),
                            .tpause(tpause), .twait(twait) );

           run_pkt_stream ( .in_port(1), .out_port(out_port_map[1]), .in_pcap(in_pcap[1]), .out_pcap(out_pcap[1]),
                            .tx_pkt_cnt(tx_pkt_cnt[1]), .tx_byte_cnt(tx_byte_cnt[1]), 
                            .rx_pkt_cnt(rx_pkt_cnt[1]), .rx_byte_cnt(rx_byte_cnt[1]),
                            .exp_pkt_cnt(exp_pkt_cnt[1]),
                            .tpause(tpause), .twait(twait) );

           run_pkt_stream ( .in_port(2), .out_port(out_port_map[2]), .in_pcap(in_pcap[2]), .out_pcap(out_pcap[2]),
                            .tx_pkt_cnt(tx_pkt_cnt[2]), .tx_byte_cnt(tx_byte_cnt[2]), 
                            .rx_pkt_cnt(rx_pkt_cnt[2]), .rx_byte_cnt(rx_byte_cnt[2]),
                            .exp_pkt_cnt(exp_pkt_cnt[2]),
                            .tpause(tpause), .twait(twait) );

           run_pkt_stream ( .in_port(3), .out_port(out_port_map[3]), .in_pcap(in_pcap[3]), .out_pcap(out_pcap[3]),
                            .tx_pkt_cnt(tx_pkt_cnt[3]), .tx_byte_cnt(tx_byte_cnt[3]), 
                            .rx_pkt_cnt(rx_pkt_cnt[3]), .rx_byte_cnt(rx_byte_cnt[3]),
                            .exp_pkt_cnt(exp_pkt_cnt[3]),
                            .tpause(tpause), .twait(twait) );

        join
    endtask
   

    task check_stream_test_probes (input logic ingress_drops = 0);
        for (int i=0; i<NUM_PORTS; i++) begin
           check_stream_probes (
              .in_port         (i), 
              .out_port        (out_port_map[i]),
              .exp_good_pkts   (rx_pkt_cnt[i]), 
              .exp_good_bytes  (rx_byte_cnt[i]), 
              .exp_drop_pkts   (tx_pkt_cnt[i]  - rx_pkt_cnt[i]), 
              .exp_drop_bytes  (tx_byte_cnt[i] - rx_byte_cnt[i]),
              .ingress_drops   (ingress_drops)
           );
	end
    endtask;


    typedef enum logic [31:0] {
        PROBE_FROM_CMAC_PORT0 = 'h8000,
        DROPS_FROM_CMAC_PORT0 = 'h8400,
        PROBE_FROM_CMAC_PORT1 = 'h8800,
        DROPS_FROM_CMAC_PORT1 = 'h8c00,
        PROBE_FROM_HOST_PORT0 = 'h9000,
        DROPS_FROM_HOST_PORT0 = 'h9400,
        PROBE_FROM_HOST_PORT1 = 'h9800,
        DROPS_FROM_HOST_PORT1 = 'h9c00,

        PROBE_TO_CMAC_PORT0 = 'hb000,
        DROPS_TO_CMAC_PORT0 = 'hb400,
        PROBE_TO_CMAC_PORT1 = 'hb800,
        DROPS_TO_CMAC_PORT1 = 'hbc00,
        PROBE_TO_HOST_PORT0 = 'hc000,
        DROPS_TO_HOST_PORT0 = 'hc400,
        PROBE_TO_HOST_PORT1 = 'hc800,
        DROPS_TO_HOST_PORT1 = 'hcc00
    } cntr_addr_encoding_t;

    typedef union packed {
        cntr_addr_encoding_t  encoded;
        logic [31:0]          raw;
    } cntr_addr_t;

   
    task check_stream_probes ( input port_t       in_port, out_port,
                               input logic [63:0] exp_good_pkts, exp_good_bytes, exp_drop_pkts=0, exp_drop_bytes=0,
                               input logic        ingress_drops = 0 );

        cntr_addr_t in_port_base_addr, out_port_base_addr;
        logic [63:0] exp_tot_pkts, exp_tot_bytes;

        // establish base addr for ingress probe
        case (in_port)
               CMAC_PORT0 : in_port_base_addr = 'h8000;
               CMAC_PORT1 : in_port_base_addr = 'h8800;
               HOST_PORT0 : in_port_base_addr = 'h9000;
               HOST_PORT1 : in_port_base_addr = 'h9800;
	    default : in_port_base_addr = 'hxxxx;
        endcase

        // establish base addr for egress probe
        case (out_port)
               CMAC_PORT0 : out_port_base_addr = 'hb000;
               CMAC_PORT1 : out_port_base_addr = 'hb800;
               HOST_PORT0 : out_port_base_addr = 'hc000;
               HOST_PORT1 : out_port_base_addr = 'hc800;
	    default : out_port_base_addr = 'hxxxx;
        endcase

        // establish pkt and byte totals       
        exp_tot_pkts  = exp_good_pkts  + exp_drop_pkts;
        exp_tot_bytes = exp_good_bytes + exp_drop_bytes;


        // check ingress and egress probe counts
        if (ingress_drops) 
           check_probe (.base_addr(in_port_base_addr), .exp_pkt_cnt(exp_good_pkts), .exp_byte_cnt(exp_good_bytes));
        else
           check_probe (.base_addr(in_port_base_addr), .exp_pkt_cnt(exp_tot_pkts),  .exp_byte_cnt(exp_tot_bytes));

        check_probe (.base_addr(out_port_base_addr), .exp_pkt_cnt(exp_good_pkts), .exp_byte_cnt(exp_good_bytes));


        // check ingress and egress drop counts
        if ( (in_port != HOST_PORT0) && (in_port != HOST_PORT1) ) begin  // no drop counters for these ingress ports.
           in_port_base_addr = in_port_base_addr + 'h400;
           if (ingress_drops) 
              check_probe (.base_addr(in_port_base_addr), .exp_pkt_cnt(exp_drop_pkts), .exp_byte_cnt(exp_drop_bytes));
           else	   
              check_probe (.base_addr(in_port_base_addr), .exp_pkt_cnt(0), .exp_byte_cnt(0));
        end

        if ( (out_port != HOST_PORT0) ) begin  // no drop counters for these egress ports.
           out_port_base_addr = out_port_base_addr + 'h400;
           if (ingress_drops)
              check_probe (.base_addr(out_port_base_addr), .exp_pkt_cnt(0), .exp_byte_cnt(0));
           else
              check_probe (.base_addr(out_port_base_addr), .exp_pkt_cnt(exp_drop_pkts), .exp_byte_cnt(exp_drop_bytes));
        end
       
    endtask;


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

endmodule
