`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 500us

module smartnic_250mhz_datapath_unit_test;
    import smartnic_250mhz_pkg::*;
    import axi4s_verif_pkg::*;
    import packet_verif_pkg::*;

    // Testcase name
    string name = "smartnic_250mhz_datapath_ut";

    // SVUnit base testcase
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // Parameters
    //===================================
    localparam int NUM_INTF = 2;

    //===================================
    // Typedefs
    //===================================
    typedef enum {C2H, H2C} ch_type_t;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common smartnic_250mhz
    // testbench top level. The 'tb' module is
    // loaded into the tb_glbl scope, so is available
    // at tb_glbl.tb.
    //
    // Interaction with the testbench is expected to occur
    // via the testbench environment class (tb_env). A
    // reference to the testbench environment is provided
    // here for convenience.
    tb_pkg::tb_env#(NUM_INTF) env;

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

    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // Reset environment
        env.reset();

        // Put interfaces in quiescent state
        env.idle();

        // Issue reset
        reset();

        // Start environment (ready to process transactions)
        env.start();
    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        svunit_ut.teardown();

        // Stop processing transactions
        env.stop();
    endtask

    //=======================================================================
    // TESTS
    //=======================================================================
    // (Global) variables
    string msg;

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

    `SVTEST(reset)
    `SVTEST_END

    `SVTEST(h2c_one_packet)
        for (int i = 0; i < NUM_INTF; i++) begin
            one_packet(H2C, i);
        end
        #10us;
        for (int i = 0; i < NUM_INTF; i++) begin
            `FAIL_IF_LOG(report(H2C, i, msg) > 0, msg);
        end
    `SVTEST_END

    `SVTEST(c2h_one_packet)
        for (int i = 0; i < NUM_INTF; i++) begin
            one_packet(C2H, i);
        end
        #10us;
        for (int i = 0; i < NUM_INTF; i++) begin
            `FAIL_IF_LOG(report(C2H, i, msg) > 0, msg);
        end
    `SVTEST_END

    `SVTEST(h2c_stream)
        for (int i = 0; i < NUM_INTF; i++) begin
            packet_stream(H2C, i, 100);
        end
        #10us;
        for (int i = 0; i < NUM_INTF; i++) begin
            `FAIL_IF_LOG(report(H2C, i, msg) > 0, msg);
        end
    `SVTEST_END

    `SVTEST(c2h_stream)
        for (int i = 0; i < NUM_INTF; i++) begin
            packet_stream(C2H, i, 100);
        end
        #10us;
        for (int i = 0; i < NUM_INTF; i++) begin
            `FAIL_IF_LOG(report(C2H, i, msg) > 0, msg);
        end
    `SVTEST_END

    `SVUNIT_TESTS_END

    //=======================================================================
    // TASKS
    //=======================================================================
    task automatic one_packet(input ch_type_t CH_TYPE=H2C, input int ch_id=0, input int pkt_id=0, input int len=$urandom_range(64,1500));
        automatic packet_raw packet;
        packet = new($sformatf("pkt_%0d", pkt_id), len);
        packet.randomize();
        if (CH_TYPE==C2H) begin
            automatic axi4s_transaction#(bit,bit,tuser_c2h_t) axis_transaction;
            tuser_c2h_t tuser;
            void'(std::randomize(tuser));
            tuser.dst = 1 << ch_id;
            axis_transaction = new($sformatf("trans_%0d",pkt_id), packet, .tuser(tuser));
            env.env_c2h[ch_id].inbox.put(axis_transaction);
        end else begin
            automatic axi4s_transaction#(bit,bit,tuser_h2c_t) axis_transaction;
            tuser_h2c_t tuser;
            void'(std::randomize(tuser));
            tuser.dst = 1 << (6 + ch_id);
            axis_transaction = new($sformatf("trans_%0d",pkt_id), packet, .tuser(tuser));
            env.env_h2c[ch_id].inbox.put(axis_transaction);
        end
    endtask

    task automatic packet_stream(input ch_type_t CH_TYPE=H2C, input int ch_id=0, input int NUM_PKTS);
       for (int i = 0; i < NUM_PKTS; i++) begin
           one_packet(CH_TYPE, ch_id);
       end
    endtask

    function automatic int report(input ch_type_t CH_TYPE=H2C, input bit ch_id=0, output string msg);
        if (CH_TYPE==C2H) return env.env_c2h[ch_id].scoreboard.report(msg);
        else              return env.env_h2c[ch_id].scoreboard.report(msg);
    endfunction

endmodule
