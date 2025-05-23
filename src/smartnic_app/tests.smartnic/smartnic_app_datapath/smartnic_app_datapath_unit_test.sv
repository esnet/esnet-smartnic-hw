`include "svunit_defines.svh"

import tb_pkg::*;
import p4_proc_verif_pkg::*;
import smartnic_app_verif_pkg::*;
//import smartnic_app_reg_pkg::*;

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module smartnic_app_datapath_unit_test
#(
    parameter int HDR_LENGTH = 0
 );
    // Testcase name
    string name = $sformatf("smartnic_app_datapath_hdrlen_%0d_ut", HDR_LENGTH);

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
    // via the testbench environment class (tb_env).
    // A reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::tb_env env;

    // VitisNetP4 table agent
    vitisnetp4_igr_verif_pkg::vitisnetp4_igr_agent vitisnetp4_agent;

    // p4_proc register agent and variables
    p4_proc_reg_agent  p4_proc_reg_agent;

    p4_proc_reg_pkg::reg_p4_proc_config_t  p4_proc_config;
    p4_proc_reg_pkg::reg_trunc_config_t    trunc_config;

    wire [11:0] rss_entropy [2];
    assign rss_entropy[0] = tb.m_axis_adpt_rx_322mhz_tuser_rss_entropy[11:0];
    assign rss_entropy[1] = tb.m_axis_adpt_rx_322mhz_tuser_rss_entropy[23:12];

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

        // Create P4 reg agents
        p4_proc_reg_agent = new("p4_proc_reg_agent", env.reg_agent, 'h80000 + 'h60000);
    endfunction

    //===================================
    // Local test variables
    //===================================

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

       `SVTEST(rss_metadata_test) // tests propagation of rss_metadata and qid selection through datapath to smartnic ports.
           port_t  src_vf[2];

           env.smartnic_reg_blk_agent.write_smartnic_demux_out_sel('1);  // demux egr traffic to host ports.

           env.smartnic_hash2qid_0_reg_blk_agent.write_q_config (3, 1);  // write PF0_VF2 base address = 1.
           env.smartnic_hash2qid_1_reg_blk_agent.write_q_config (3, 16); // write PF1_VF2 base address = 16.

           fork
              // --- run traffic from/to both HOST ports ---
              begin
                 // source traffic from/to PF0_VF2.
                 // direct traffic to qid 'PF0_VF2' (echoes 'src_vf' in dst qid).
                 // p4 program sets rss_entropy to 'src_vf' (ingress_port).
                 src_vf[0].encoded.num = P0; src_vf[0].encoded.typ = VF2;
                 env.smartnic_hash2qid_0_reg_blk_agent.write_vf2_table ({'0, src_vf[0]}, {'0, src_vf[0]});
                 run_pkt_test (.testdir( "test-default" ), .init_timestamp(1), .in_port(2), .out_port(2));

                 // source traffic from/to PF1_VF2.
                 // direct traffic to qid 'PF1_VF2' (echoes 'src_vf' in dst qid).
                 // p4 program sets rss_entropy to 'src_vf' (ingress_port).
                 src_vf[1].encoded.num = P1; src_vf[1].encoded.typ = VF2;
                 env.smartnic_hash2qid_1_reg_blk_agent.write_vf2_table ({'0, src_vf[1]}, {'0, src_vf[1]});
                 run_pkt_test (.testdir( "test-default" ), .init_timestamp(1), .in_port(3), .out_port(3));
              end

              // --- compare rss metadata to expected on HOST_0 port ---
              while (1) @(posedge tb.axis_c2h[0].aclk) if (tb.axis_c2h[0].tvalid) begin
                 `FAIL_UNLESS( tb.m_axis_adpt_rx_322mhz_tuser_rss_enable[src_vf[0].encoded.num] == 1'b1 );
                 `FAIL_UNLESS( rss_entropy[src_vf[0].encoded.num] == src_vf[0]+1 );
              end

              // --- compare rss metadata to expected on HOST_1 port ---
              while (1) @(posedge tb.axis_c2h[1].aclk) if (tb.axis_c2h[1].tvalid) begin
                 `FAIL_UNLESS( tb.m_axis_adpt_rx_322mhz_tuser_rss_enable[src_vf[1].encoded.num] == 1'b1 );
                 `FAIL_UNLESS( rss_entropy[src_vf[1].encoded.num] == src_vf[1]+16 );
              end
           join_any

       `SVTEST_END

       `SVTEST(cmac0_to_cmac0_test)
           run_pkt_test ( .testdir("test-fwd-p0"), .init_timestamp(1), .in_port(0), .out_port(0) );
       `SVTEST_END

       `SVTEST(cmac0_to_cmac1_test)
           run_pkt_test ( .testdir("test-fwd-p1"), .init_timestamp(1), .in_port(0), .out_port(1) );
       `SVTEST_END

       `SVTEST(cmac1_to_cmac0_test)
           run_pkt_test ( .testdir("test-fwd-p0"), .init_timestamp(1), .in_port(1), .out_port(0) );
       `SVTEST_END

       `SVTEST(cmac1_to_cmac1_test)
           run_pkt_test ( .testdir("test-fwd-p1"), .init_timestamp(1), .in_port(1), .out_port(1) );
       `SVTEST_END

       `include "../../../vitisnetp4/p4/sim/run_pkt_test_incl.svh"

    `SVUNIT_TESTS_END

endmodule



// 'Boilerplate' unit test wrapper code
//  Builds unit test for a specific axi4s_split_join configuration in a way
//  that maintains SVUnit compatibility

`define P4_ONLY_DATAPATH_UNIT_TEST(HDR_LENGTH)\
  import svunit_pkg::svunit_testcase;\
  svunit_testcase svunit_ut;\
  smartnic_app_datapath_unit_test #(HDR_LENGTH) test();\
  function void build();\
    test.build();\
    svunit_ut = test.svunit_ut;\
  endfunction\
  function void __register_tests();\
    test.__register_tests();\
  endfunction \
  task run();\
    test.run();\
  endtask


module smartnic_app_datapath_hdrlen_0_unit_test;
`P4_ONLY_DATAPATH_UNIT_TEST(0)
endmodule

module smartnic_app_datapath_hdrlen_128_unit_test;
`P4_ONLY_DATAPATH_UNIT_TEST(128)
endmodule
