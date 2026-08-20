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

    // smartnic_app reg blk agents.
    smartnic_app_igr_reg_verif_pkg::smartnic_app_igr_reg_blk_agent #() smartnic_app_igr_reg_blk_agent;
    smartnic_app_egr_reg_verif_pkg::smartnic_app_egr_reg_blk_agent #() smartnic_app_egr_reg_blk_agent;

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

        // Create smartnic_app reg block agents
        smartnic_app_igr_reg_blk_agent = new("smartnic_app_igr_reg_blk_agent", 'h20000);
        smartnic_app_igr_reg_blk_agent.reg_agent = env.app_reg_agent;

        smartnic_app_egr_reg_blk_agent = new("smartnic_app_egr_reg_blk_agent", 'h30000);
        smartnic_app_egr_reg_blk_agent.reg_agent = env.app_reg_agent;

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

    localparam COL_LEN = 4096; // in bits.

    // derived parameters.
    localparam SGMT_SIZE = COL_LEN / 8; // in bytes.
    localparam BLK_SIZE  = SGMT_SIZE * 32;

    int pkts=0, bytes=0, fec_pkts=0, fec_bytes=0;
    int offset;


    task automatic send_fec_event (
        input int               size = BLK_SIZE,
        input port_t            in_port=0, out_port=0,
        tuser_smartnic_meta_t   tuser = '0
    );
        int num_pkts = size / SGMT_SIZE;
        int num_blks = (size + BLK_SIZE-1) / BLK_SIZE; // round up.
        int last_sgmt_size = size % SGMT_SIZE;

        smartnic_app_igr_reg_blk_agent.write_fec_evt_size_dec(size);
        smartnic_app_egr_reg_blk_agent.write_fec_evt_size_enc(size);

       `INFO("Starting FEC event...");
        env.send_packets (
            .num(num_pkts), .len(SGMT_SIZE),
            .driver(env.driver[in_port]), .scoreboard(env.scoreboard[out_port])
        );

        pkts  = pkts  + num_pkts;
        bytes = bytes + num_pkts * SGMT_SIZE;

       `INFO("Sending last FEC segment.");
        if (last_sgmt_size != 0) begin
            env.send_packets (
                .num(1), .len(last_sgmt_size),
                .driver(env.driver[in_port]), .scoreboard(env.scoreboard[out_port])
            );

            pkts  = pkts  + 1;
            bytes = bytes + last_sgmt_size;
        end

        fec_pkts  = fec_pkts  + num_blks * 40;
        fec_bytes = fec_bytes + num_blks * 40 * SGMT_SIZE;

    endtask


    task automatic run_fec_test (
        input port_t            in_port=0, out_port=0,
        tuser_smartnic_meta_t   tuser='0
    );
        bit rx_done=0;

       `INFO("Starting simulation...");
        for (int i=0; i<10; i++) begin
            rx_done=0;
            send_fec_event (.size($urandom_range(3*BLK_SIZE, BLK_SIZE/3)), .in_port(in_port), .out_port(out_port), .tuser(tuser));
            //send_fec_event (.size(BLK_SIZE+(i*SGMT_SIZE)+1+i), .in_port(in_port), .out_port(out_port), .tuser(tuser));

            #1us;
            fork
                #10us if (!rx_done) `INFO("run_fec_test task TIMEOUT!");

                while (!rx_done) #100ns if (env.scoreboard[out_port].exp_pending()==0) rx_done=1;
            join_any

        end

        #100ns;
        for (int i=0; i < env.N; i++) `FAIL_IF_LOG(env.scoreboard[i].report(msg) > 0, msg);

    endtask



    `SVUNIT_TESTS_BEGIN

        `SVTEST(fec_lpbk_test) // smartnic_egr (rs encode) -> port_lpbk -> smartnic_igr (fec_decode).
            tb.port_lpbk_en = 1;

            for (int i=0; i<1; i++) begin
                debug_msg($sformatf("Testing PF%0b VF0 -> rs_encode -> lpbk -> rs_decode -> PF%0b VF0...", i, i), 1);
                run_fec_test(.in_port(PF0_VF0+i), .out_port(PF0_VF0+i), .tuser(tuser));
                offset = 'h100 * i;

                check_probe (offset + PROBE_FROM_PF0_VF0,            pkts,     bytes);
                check_probe (offset + PROBE_TO_APP_EGR_OUT0,     fec_pkts, fec_bytes);
                check_probe (offset + PROBE_TO_APP_EGR_P4_IN0,   fec_pkts, fec_bytes);
                check_probe (offset + PROBE_TO_APP_IGR_P4_OUT0,  fec_pkts, fec_bytes);
                check_probe (offset + PROBE_TO_APP_IGR_IN0,      fec_pkts, fec_bytes);
                check_probe (offset + PROBE_TO_PF0_VF0,              pkts,     bytes);

            end

            check_cleared_probes;
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
