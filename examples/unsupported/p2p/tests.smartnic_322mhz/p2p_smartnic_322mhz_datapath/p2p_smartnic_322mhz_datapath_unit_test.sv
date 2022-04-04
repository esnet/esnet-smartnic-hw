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
    // Local test variables
    //===================================
    localparam FIFO_DEPTH = 410.0; // 124 (fifo_async) + 2 x 143 (axi4s_pkt_discard)

    smartnic_322mhz_reg_pkg::reg_port_config_t set_config;

    // variables for discard tests.
    int	pkt_len     [NUM_PORTS-1:0];

   
    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        // default variable configuration
         in_pcap[0] = "../../../../../../src/smartnic_322mhz/tests/common/pcap/20xrandom_pkts.pcap";
        out_pcap[0] = "../../../../../../src/smartnic_322mhz/tests/common/pcap/20xrandom_pkts.pcap";
         in_pcap[1] = "../../../../../../src/smartnic_322mhz/tests/common/pcap/30xrandom_pkts.pcap";
        out_pcap[1] = "../../../../../../src/smartnic_322mhz/tests/common/pcap/30xrandom_pkts.pcap";
         in_pcap[2] = "../../../../../../src/smartnic_322mhz/tests/common/pcap/40xrandom_pkts.pcap";
        out_pcap[2] = "../../../../../../src/smartnic_322mhz/tests/common/pcap/40xrandom_pkts.pcap";
         in_pcap[3] = "../../../../../../src/smartnic_322mhz/tests/common/pcap/50xrandom_pkts.pcap";
        out_pcap[3] = "../../../../../../src/smartnic_322mhz/tests/common/pcap/50xrandom_pkts.pcap";

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

endmodule
