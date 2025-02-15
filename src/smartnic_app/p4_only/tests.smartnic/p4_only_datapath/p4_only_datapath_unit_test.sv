`include "svunit_defines.svh"

import tb_pkg::*;
import p4_proc_verif_pkg::*;

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 200us

module p4_only_datapath_unit_test
#(
    parameter int HDR_LENGTH = 0
 );
    // Testcase name
    string name = $sformatf("p4_only_datapath_hdrlen_%0d_ut", HDR_LENGTH);

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
    tb_pkg::tb_env env;

    // VitisNetP4 table agent
    vitisnetp4_verif_pkg::vitisnetp4_agent vitisnetp4_agent;

    // p4_proc register agent and variables
    p4_proc_reg_agent  p4_proc_reg_agent;

    p4_proc_reg_pkg::reg_p4_proc_config_t  p4_proc_config;
    p4_proc_reg_pkg::reg_trunc_config_t    trunc_config;

    wire [11:0] rss_entropy [2];
    assign rss_entropy[0] = tb.m_axis_adpt_rx_322mhz_tuser_rss_entropy[11:0];
    assign rss_entropy[1] = tb.m_axis_adpt_rx_322mhz_tuser_rss_entropy[23:12];

    int exp_pkt_cnt, exp_byte_cnt;

    //===================================
    // Import common testcase tasks
    //===================================
    `include "../../../../../src/smartnic/tests/common/tasks.svh"
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

        // Create P4 reg agent
        p4_proc_reg_agent = new("p4_proc_reg_agent", env.reg_agent, 'h1e0000);
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

       `SVTEST(test_rss_metadata) // tests propagation of rss_metadata through datapath to smartnic ports.
           port_t  src_port, dst_port;

           fork
              // --- run traffic from/to both HOST ports ---
              begin
                 // source traffic from src_port=HOST_0. direct traffic to dst_port=HOST_0.
                 src_port = 2'h2; dst_port = 2'h2;
                 run_pkt_test ( .testdir( "test-default" ), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp(1), .in_port(src_port), .out_port(dst_port) );

                 // source traffic from src_port=HOST_1. direct traffic to dst_port=HOST_1.
                 src_port = 2'h3; dst_port = 2'h3;
                 run_pkt_test ( .testdir( "test-default" ), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp(1), .in_port(src_port), .out_port(dst_port) );
              end

              // --- compare rss metadata to expected on HOST_0 port ---
              while (1) @(posedge tb.axis_out_if[2].aclk) if (tb.axis_out_if[2].tvalid) begin
                 `FAIL_UNLESS( tb.m_axis_adpt_rx_322mhz_tuser_rss_enable[dst_port[0]] == 1'b1 );
                 `FAIL_UNLESS( rss_entropy[dst_port[0]] == src_port );
              end

              // --- compare rss metadata to expected on HOST_1 port ---
              while (1) @(posedge tb.axis_out_if[3].aclk) if (tb.axis_out_if[3].tvalid) begin
                 `FAIL_UNLESS( tb.m_axis_adpt_rx_322mhz_tuser_rss_enable[dst_port[0]] == 1'b1 );
                 `FAIL_UNLESS( rss_entropy[dst_port[0]] == src_port );
              end
           join_any

       `SVTEST_END

       `SVTEST(test_pkt_loopback)
           run_pkt_test ( .testdir("test-pkt-loopback"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp('0), .out_port(0) );
       `SVTEST_END

       `SVTEST(test_egr_pkt_trunc)
           repeat (1) begin
              // Write trunc_config register and run pkt test.
              trunc_config.enable = 1'b1;
              trunc_config.trunc_enable = 1'b1;
              trunc_config.trunc_length = $urandom_range(65,500);
              p4_proc_reg_agent.write_trunc_config(trunc_config);

              run_pkt_test ( .testdir("test-pkt-loopback"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp('0), .out_port(0), .max_pkt_size(trunc_config.trunc_length) );
           end
       `SVTEST_END

       `SVTEST(test_traffic_mux)
           env.reg_agent.write_reg( smartnic_reg_pkg::OFFSET_APP_1_TDEST_REMAP[1], 1 );
           //write_p4_tables ( .testdir("test-fwd-p1") );
           fork
              // run packet stream from CMAC1 to CMAC1 (includes programming the p4 tables accordingly).
              run_pkt_test ( .testdir("test-fwd-p1"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp(1), .in_port(1), .out_port(1) );

              // simultaneously run packet stream from CMAC0 to CMAC0, starting once CMAC1 traffic is started.
              // (without re-programming the p4 tables).
              @(posedge tb.axis_in_if[1].tvalid)
                run_pkt_test ( .testdir("test-default"), .exp_pkt_cnt(exp_pkt_cnt), .exp_byte_cnt(exp_byte_cnt), .init_timestamp(1), .in_port(0), .out_port(0), .write_p4_tables(0) );
           join
       `SVTEST_END

       `include "../../../../vitisnetp4/p4/sim/run_pkt_test_incl.svh"

    `SVUNIT_TESTS_END

endmodule



// 'Boilerplate' unit test wrapper code
//  Builds unit test for a specific axi4s_split_join configuration in a way
//  that maintains SVUnit compatibility

`define P4_ONLY_DATAPATH_UNIT_TEST(HDR_LENGTH)\
  import svunit_pkg::svunit_testcase;\
  svunit_testcase svunit_ut;\
  p4_only_datapath_unit_test #(HDR_LENGTH) test();\
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


module p4_only_datapath_hdrlen_0_unit_test;
`P4_ONLY_DATAPATH_UNIT_TEST(0)
endmodule

module p4_only_datapath_hdrlen_64_unit_test;
`P4_ONLY_DATAPATH_UNIT_TEST(64)
endmodule

module p4_only_datapath_hdrlen_256_unit_test;
`P4_ONLY_DATAPATH_UNIT_TEST(256)
endmodule

