`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module p2p_smartnic_datapath_unit_test;
    // Testcase name
    string name = "p2p_smartnic_datapath_ut";

    // SVUnit base testcase
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic
    // testbench top level. The 'tb' module is
    // loaded into the tb_glbl scope, so is available
    // at tb_glbl.tb.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (smartnic_env).
    // A reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::smartnic_env env;

    //===================================
    // Import common testcase tasks
    //=================================== 
    `include "../../../../../src/smartnic/tests/common/tasks.svh"       

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

    int bytes[2];

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // start environment
        env.run();

    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        // stop environment
        env.stop();

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
          app_mode(0); app_mode(1);

          packet_stream(.pkts(10), .mode(0), .bytes(bytes[0]), .tid(PHY0), .tdest(PHY0));
          packet_stream(.pkts(10), .mode(0), .bytes(bytes[1]), .tid(PHY1), .tdest(PHY1));

          #1us;  // 1us > (3ns/cycle * 10 pkts * 1518/64 cycles/pkt)
          latch_probe_counters;

          check_probe(PROBE_FROM_CMAC0,   10, bytes[0]);
          check_probe(PROBE_CORE_TO_APP0, 10, bytes[0]);
          check_probe(PROBE_TO_CMAC0,     10, bytes[0]);

          check_probe(PROBE_FROM_CMAC1,   10, bytes[1]);
          check_probe(PROBE_CORE_TO_APP1, 10, bytes[1]);
          check_probe(PROBE_TO_CMAC1,     10, bytes[1]);

          check_sb0(.pkts(10));  check_sb1(.pkts(10)); check_sb2(); check_sb3();

      `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
