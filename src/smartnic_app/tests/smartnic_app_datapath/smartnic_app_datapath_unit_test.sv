`include "svunit_defines.svh"

import tb_pkg::*;

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module smartnic_app_datapath_unit_test;

    // Testcase name
    string name = "smartnic_app_datapath_ut";

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
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.

    smartnic_app_igr_demux_reg_verif_pkg::smartnic_app_igr_reg_blk_agent #() smartnic_app_igr_reg_blk_agent;

    port_t in_if=0, out_if=0;

    //===================================
    // Import common testcase tasks
    //=================================== 
    `include "../common/tasks.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);

        // Build testbench
        tb.build();
       
        // Retrieve reference to testbench environment class
        env = tb.env;

        // Create P4 table agent
        vitisnetp4_agent = new;
        vitisnetp4_agent.create("tb"); // DPI-C P4 table agent requires hierarchial
                                       // path to AXI-L write/read tasks

        smartnic_app_igr_reg_blk_agent = new("smartnic_app_igr_reg_blk_agent", 'h20000);
        smartnic_app_igr_reg_blk_agent.reg_agent = env.app_reg_agent;
    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // Flush packets from pipeline
        for (integer i = 0; i < 2; i += 1) begin
            env.axis_out_monitor[i].flush();
            for (integer j = 0; j < 3; j += 1) begin
                env.axis_c2h_monitor[j][i].flush();
            end
        end

        // Issue reset (both datapath and management domains)
        reset();

        // Put AXI-S interfaces into quiescent state
        for (integer i = 0; i < 2; i += 1) begin
            env.axis_in_driver[i].idle();
            env.axis_out_monitor[i].idle();
            for (integer j = 0; j < 3; j += 1) begin
                env.axis_h2c_driver[j][i].idle();
                env.axis_c2h_monitor[j][i].idle();
            end
        end

         in_if.encoded.num = P0;  in_if.encoded.typ = PHY;
        out_if.encoded.num = P0; out_if.encoded.typ = PHY;
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

        // Flush remaining packets
        for (integer i = 0; i < 2; i += 1) begin
            env.axis_out_monitor[i].flush();
            for (integer j = 0; j < 3; j += 1) begin
                env.axis_c2h_monitor[j][i].flush();
            end
        end
        #10us;

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

    `SVTEST(init)
        // Initialize VitisNetP4 tables
        vitisnetp4_agent.init();
    `SVTEST_END

    `include "../../../vitisnetp4/p4/sim/run_pkt_test_incl.svh"

    `SVTEST(test_cmac_ifs)
        for (int i=0; i<2; i++) begin
            debug_msg($sformatf("Testing CMAC%0b igr and egr interfaces...", i), 1);
            run_pkt_test(.testdir("test-fwd-p0"), .in_if(in_if+i), .out_if(out_if+i), .write_p4_tables(1));
            check_cleared_probes;
        end
    `SVTEST_END


    `SVTEST(test_pf_ifs)
        in_if.encoded.typ = PF;
        for (int i=0; i<2; i++) begin
            debug_msg($sformatf("Testing PF%0b igr interface...", i), 1);
            run_pkt_test(.testdir("test-fwd-p0"), .in_if(in_if+i), .out_if(out_if+i), .write_p4_tables(0));
            check_cleared_probes;
        end

        // enable override mux. select PF egr path.
        env.smartnic_app_reg_agent.write_smartnic_app_igr_p4_out_sel(2'b11);

        in_if.encoded.typ  = PHY;
        out_if.encoded.typ = PF;
        for (int i=0; i<2; i++) begin
            debug_msg($sformatf("Testing PF%0b egr interface (override mux control)...", i), 1);
            run_pkt_test(.testdir("test-fwd-p0"), .in_if(in_if+i), .out_if(out_if+i), .write_p4_tables(0));
            check_cleared_probes;
        end
    `SVTEST_END


    `SVTEST(test_vf0_ifs)
        in_if.encoded.typ = VF0;
        for (int i=0; i<2; i++) begin
            debug_msg($sformatf("Testing PF%0b VF0 igr interface...", i), 1);
            run_pkt_test(.testdir("test-fwd-p0"), .in_if(in_if+i), .out_if(out_if+i), .write_p4_tables(0));
            check_cleared_probes;
        end

        // enable demux to select VF0 egr path.
        smartnic_app_igr_reg_blk_agent.write_app_igr_config(1'b1);

        in_if.encoded.typ  = PHY;
        out_if.encoded.typ = VF0;
        for (int i=0; i<2; i++) begin
            debug_msg($sformatf("Testing PF%0b VF0 egr interface...", i), 1);
            run_pkt_test(.testdir("test-fwd-p0"), .in_if(in_if+i), .out_if(out_if+i), .write_p4_tables(0));
            check_cleared_probes;
        end
    `SVTEST_END


    `SVTEST(test_vf1_ifs)
        in_if.encoded.typ  = VF1;
        out_if.encoded.typ = VF1;
        for (int i=0; i<2; i++) begin
            debug_msg($sformatf("Testing PF%0b VF1 igr and egr interfaces...", i), 1);
            run_pkt_test(.testdir("test-fwd-p0"), .in_if(in_if+i), .out_if(out_if+i), .write_p4_tables(0));
            check_cleared_probes;
        end
    `SVTEST_END


    `SVTEST(test_to_pf_ifs_from_p4)
        out_if.encoded.typ = PF;
        for (int i=0; i<2; i++) begin
            debug_msg($sformatf("Testing PF%0b egr interface (p4 control)...", i), 1);
            run_pkt_test(.testdir("test-fwd-p2"), .in_if(in_if+i), .out_if(out_if+i), .dest_port(2), .write_p4_tables(1));
            check_cleared_probes;
        end
    `SVTEST_END


    `SVTEST(test_to_vf0_ifs_from_p4)
        out_if.encoded.typ = VF0;
        for (int i=0; i<2; i++) begin
            debug_msg($sformatf("Testing PF%0b VF0 egr interface (p4 control)...", i), 1);
            run_pkt_test(.testdir("test-fwd-p4"), .in_if(in_if+i), .out_if(out_if+i), .dest_port(4), .write_p4_tables(1));
            check_cleared_probes;
        end
    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
