`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module udplb_fec_datapath_unit_test;
    import fec_pkg::*;

    // Testcase name
    string name = "udplb_fec_datapath_ut";

    // SVUnit base testcase
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic_app
    // testbench top level. The 'tb' module is
    // loaded into the global scope.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::tb_env env;

    // VitisNetP4 table agent
    `define NO_P4_AGENT
    //vitisnetp4_igr_verif_pkg::vitisnetp4_igr_agent vitisnetp4_agent;

    // smartnic_app_igr reg blk agent.
    smartnic_app_igr_reg_verif_pkg::smartnic_app_igr_reg_blk_agent #() smartnic_app_igr_reg_blk_agent;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../../../../src/smartnic_app/tests/common/tasks.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build testbench
        env = tb.build();

        // Create P4 table agent
        //vitisnetp4_agent = new(.hier_path(p4_dpic_hier_path)); // DPI-C P4 table agent requires hierarchical path to AXI-L write/read tasks

        // Create smartnic_app_igr reg block agent
        smartnic_app_igr_reg_blk_agent = new("smartnic_app_igr_reg_blk_agent", 'h20000);
        smartnic_app_igr_reg_blk_agent.reg_agent = env.app_reg_agent;

    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // start environment
        env.run();

        tuser='0;  //'{rss_enable: 1'b1, rss_entropy: 16'd0};

        p4_sim_dir = "../../../p4/sim_igr/";

        #100ns;
    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        // Stop environment
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

    int iter=8;  // number of pcap iterations.
    int pkts=4*iter, bytes=2048*iter; // pkt and byte counts for 'test-fwd-p0'.
    int offset;

    `SVUNIT_TESTS_BEGIN

/* NO_P4_AGENT
        `SVTEST(init)
            // Initialize VitisNetP4 tables
            vitisnetp4_agent.init();
        `SVTEST_END
*/

/* NO passthru to/from VF0
        `SVTEST(VF0_if_test)
            for (int i=0; i<2; i++) begin
                debug_msg($sformatf("Testing PF%0b VF0 igr interface...", i), 1);
                run_pkt_test(.testdir("test-fwd-p0"), .in_port(PF0_VF0+i), .out_port(PHY0+i), .write_tables(0));
                offset = 'h100 * i;
                check_probe (offset + PROBE_FROM_PF0_VF0,        pkts, bytes);
                check_probe (offset + PROBE_TO_APP_EGR_OUT0,     pkts, bytes);
                check_probe (offset + PROBE_TO_APP_EGR_P4_IN0,   pkts, bytes);
            end

            // enable demux to select VF0 egr path.
            smartnic_app_igr_reg_blk_agent.write_app_igr_config(1'b1);

            for (int i=0; i<2; i++) begin
                debug_msg($sformatf("Testing PF%0b VF0 egr interface...", i), 1);
                run_pkt_test(.testdir("test-fwd-p0"), .in_port(PHY0+i), .out_port(PF0_VF0+i), .write_tables(0),
                             .tuser(tuser));
                offset = 'h100 * i;
                check_probe (offset + PROBE_TO_APP_IGR_P4_OUT0,  pkts, bytes);
                check_probe (offset + PROBE_TO_APP_IGR_IN0,      pkts, bytes);
                check_probe (offset + PROBE_TO_PF0_VF0,          pkts, bytes);
            end
            check_cleared_probes;
        `SVTEST_END
*/

        `SVTEST(port_lpbk_test) // smartnic_egr (rs encode) -> port_lpbk -> smartnic_igr (fec_decode).
            tb.port_lpbk_en = 1;

            for (int i=0; i<1; i++) begin
                debug_msg($sformatf("Testing PF%0b VF0 igr -> loopback -> PF%0b VF0...", i, i), 1);
                run_pkt_test(.testdir("test-fwd-p0"), .in_port(PF0_VF0+i), .out_port(PF0_VF0+i), .write_tables(0),
                             .tuser(tuser), .iter(8));
                offset = 'h100 * i;

                check_probe (offset + PROBE_FROM_PF0_VF0,        pkts, bytes);
                check_probe (offset + PROBE_TO_APP_EGR_OUT0,     pkts*RS_N/RS_K, bytes*RS_N/RS_K);
                check_probe (offset + PROBE_TO_APP_EGR_P4_IN0,   pkts*RS_N/RS_K, bytes*RS_N/RS_K);
                check_probe (offset + PROBE_TO_APP_IGR_P4_OUT0,  pkts*RS_N/RS_K, bytes*RS_N/RS_K);
                check_probe (offset + PROBE_TO_APP_IGR_IN0,      pkts*RS_N/RS_K, bytes*RS_N/RS_K);
                check_probe (offset + PROBE_TO_PF0_VF0,          pkts, bytes);
            end

            check_cleared_probes;
        `SVTEST_END

/* NO_P4_AGENT
        `SVTEST(terminate)
            // Clean up vitisnetp4 tables
            vitisnetp4_agent.terminate();
        `SVTEST_END
*/
    `SVUNIT_TESTS_END

endmodule
