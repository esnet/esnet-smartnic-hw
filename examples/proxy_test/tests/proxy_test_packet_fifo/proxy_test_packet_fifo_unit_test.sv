`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 10ms

module proxy_test_packet_fifo_unit_test;

    import svunit_pkg::svunit_testcase;
    import axi4l_verif_pkg::*;
    import packet_verif_pkg::*;

    string name = "proxy_test_packet_fifo_ut";
    svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    // This test suite references the common proxy_test
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
    `include "../common/tasks.svh"

    //===================================
    // Parameters
    //===================================
    localparam int DATA_BYTE_WID = 32;
    localparam int DATA_WID = DATA_BYTE_WID*8;
    localparam int PACKET_MEM_SIZE = 16384;

    localparam type META_T = logic[5:0];

    typedef packet#(META_T) PACKET_T;

    //===================================
    // Testbench
    //===================================
    // Environment
    packet_component_env #(META_T) packet_env;

    // Driver
    packet_playback_driver#(META_T) driver;

    // Monitor
    packet_capture_monitor#(META_T) monitor;

    // Model
    std_verif_pkg::wire_model#(PACKET_T) model;

    // Scoreboard
    std_verif_pkg::event_scoreboard#(PACKET_T) scoreboard;

    assign tb.mgmt_reset_if.reset = !tb.reset_if.reset;

    //===================================
    // Build
    //===================================
    function void build();

        svunit_ut = new(name);

        // Build testbench
        tb.build();

        // Retrieve reference to testbench environment class
        env = tb.env;

        // Driver
        driver = new("packet_playback_driver", PACKET_MEM_SIZE, DATA_WID, env.reg_agent, 'h4000 );
        driver.set_op_timeout(16384);

        // Monitor
        monitor = new("packet_capture_monitor", PACKET_MEM_SIZE, DATA_WID, env.reg_agent, 'h5000 );
        monitor.disable_autostart();

        // Model
        model = new();

        // Scoreboard
        scoreboard = new();

        // Environment
        packet_env = new("packet env", driver, monitor, model, scoreboard);
        packet_env.reset_vif = tb.reset_if;
        packet_env.register_subcomponent(env.reg_agent);
        packet_env.build();

    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // Start environment
        packet_env.run();
    endtask


    //===================================
    // Here we deconstruct anything we
    // need after running the Unit Tests
    //===================================
    task teardown();
        // Stop environment
        packet_env.stop();

        svunit_ut.teardown();
    endtask


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
    META_T meta;
    bit error;
    bit timeout;
    int got_int;

    string msg;
    int len;

    task one_packet(int id=0, int len=$urandom_range(64, 1500));
        packet_raw#(META_T) packet;
        packet = new($sformatf("pkt_%0d", id), len);
        packet.randomize();
        void'(std::randomize(meta));
        packet.set_meta(meta);
        packet_env.inbox.put(packet);
    endtask

    `SVUNIT_TESTS_BEGIN

        `SVTEST(hard_reset)
        `SVTEST_END

        `SVTEST(info)
            // Check packet memory size
            driver.read_mem_size(got_int);
            `FAIL_UNLESS_EQUAL(got_int, PACKET_MEM_SIZE);

            // Check metadata width
            driver.read_meta_width(got_int);
            `FAIL_UNLESS_EQUAL(got_int, $bits(META_T));
        `SVTEST_END

        `SVTEST(nop)
            driver.nop(error, timeout);
            `FAIL_IF(error);
            `FAIL_IF(timeout);
        `SVTEST_END

        `SVTEST(single_packet)
            monitor.start();
            one_packet();
            fork
                begin
                    #1ms;
                end
                begin
                    do
                        #10us;
                    while(scoreboard.got_processed() < 1);
                    #10us;
                end
            join_any
            disable fork;
            `FAIL_IF_LOG(scoreboard.report(msg) > 0, msg );
            `FAIL_UNLESS_EQUAL(scoreboard.got_matched(), 1);
        `SVTEST_END

        `SVTEST(packet_stream)
            localparam NUM_PKTS = 10;
            monitor.start();
            for (int i = 0; i < NUM_PKTS; i++) begin
                one_packet(i);
            end
            fork
                begin
                    #10ms;
                end
                begin
                    do
                        #10us;
                    while(scoreboard.got_processed() < NUM_PKTS);
                    #10us;
                end
            join_any
            disable fork;
            `FAIL_IF_LOG(scoreboard.report(msg) > 0, msg );
            `FAIL_UNLESS_EQUAL(scoreboard.got_matched(), NUM_PKTS);
        `SVTEST_END

        `SVTEST(finalize)
            packet_env.finalize();
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
