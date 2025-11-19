`include "svunit_defines.svh"

module smartnic_hash2qid_unit_test;

    import svunit_pkg::svunit_testcase;
    import packet_verif_pkg::*;
    import axi4s_verif_pkg::*;
    import axi4l_verif_pkg::*;
    import smartnic_pkg::*;

    string name = "smartnic_hash2qid_ut";
    svunit_testcase svunit_ut;

    //===================================
    // Parameters
    //===================================
    localparam int  DATA_BYTE_WID = 64;
    localparam type TID_T   = port_t;
    localparam type TDEST_T = port_t;
    localparam type TUSER_T = tuser_smartnic_meta_t;

    localparam int TID_WID = $bits(TID_T);
    localparam int TDEST_WID = $bits(TDEST_T);
    localparam int TUSER_WID = $bits(TUSER_T);

    typedef axi4s_transaction#(TID_T,TDEST_T,TUSER_T) AXI4S_TRANSACTION_T;

    //===================================
    // DUT
    //===================================
    logic core_clk;
    logic core_srst;

    axi4s_intf #(.DATA_BYTE_WID(DATA_BYTE_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID), .TUSER_WID(TUSER_WID)) axis_in_if (.aclk (core_clk));
    axi4s_intf #(.DATA_BYTE_WID(DATA_BYTE_WID), .TID_WID(TID_WID), .TDEST_WID(TDEST_WID), .TUSER_WID(TUSER_WID)) axis_out_if (.aclk (core_clk));

    axi4l_intf axil_if ();

    smartnic_hash2qid DUT (
        .core_clk,
        .core_srst,
        .axi4s_in      (axis_in_if),
        .axi4s_out     (axis_out_if),
        .axil_if       (axil_if)
    );

    //===================================
    // Testbench
    //===================================
    axi4s_component_env #(
        DATA_BYTE_WID,
        TID_T,
        TDEST_T,
        TUSER_T
    ) env;

    axi4l_reg_agent #() reg_agent;

    smartnic_reg_verif_pkg::smartnic_hash2qid_reg_blk_agent #() smartnic_hash2qid_reg_blk_agent;

    // Model
    class axi4s_hash2qid_model extends std_verif_pkg::model#(AXI4S_TRANSACTION_T,AXI4S_TRANSACTION_T);
        function new(string name="axi4s_hash2qid_model");
            super.new(name);
        endfunction
        protected task _process(input AXI4S_TRANSACTION_T transaction_in);
            AXI4S_TRANSACTION_T transaction_out;
            TUSER_T tuser_out;

            // tuser_out assignment, based on table_init() programming below.
            tuser_out = transaction_in.get_tuser();
            if (tuser_out.rss_enable) begin
                tuser_out.rss_entropy = {~tuser_out.rss_entropy[11:10], 10'h000} +
                                         {2'h0, ~tuser_out.rss_entropy[11:10], 1'b0, ~tuser_out.rss_entropy[6:0]};
            end else begin
                tuser_out.rss_entropy = {~tuser_out.rss_entropy[11:10], 10'h000};
            end

            tuser_out.rss_enable=1'b1;

            transaction_out = transaction_in.dup($sformatf("trans_%0d_out", num_output_transactions()));
            transaction_out.set_tuser(tuser_out);
            _enqueue(transaction_out);
        endtask
    endclass

    axi4s_hash2qid_model model;
    std_verif_pkg::event_scoreboard#(AXI4S_TRANSACTION_T) scoreboard;

    // Assign axis clock (333MHz)
    `SVUNIT_CLK_GEN(core_clk, 1.5ns);

    // Assign axil clock (100MHz)
    `SVUNIT_CLK_GEN(axil_if.aclk, 4ns);

    // Assign resets
    std_reset_intf axis_reset_if (.clk(axis_in_if.aclk));
    assign axis_reset_if.ready = !axis_reset_if.reset;
    assign core_srst  = axis_reset_if.reset;
    assign axil_if.aresetn     = !axis_reset_if.reset;

    //===================================
    // Build
    //===================================
    function void build();

        svunit_ut = new(name);

        model = new();
        scoreboard = new();

        reg_agent = new("axi4l_reg_agent");
        reg_agent.axil_vif = axil_if;

        smartnic_hash2qid_reg_blk_agent = new("smartnic_hash2qid_reg_blk_agent");
        smartnic_hash2qid_reg_blk_agent.reg_agent = reg_agent;

        env = new("env", model, scoreboard);
        env.reset_vif = axis_reset_if;
        env.axis_in_vif = axis_in_if;
        env.axis_out_vif = axis_out_if;
        env.build();

        env.set_debug_level(1);
    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // Start environment
        env.run();
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

    string msg;

    // Create and send input transaction
    task automatic one_packet(input int idx=0, len=64, input TUSER_T tuser=0);
        AXI4S_TRANSACTION_T  transaction_in;
        transaction_in = new(.name($sformatf("trans_%0d_in", idx)), .len(len), .tuser(tuser));
        transaction_in.randomize();
        env.inbox.put(transaction_in);
    endtask

    task automatic packet_stream(input logic rss_enable=0);
       TUSER_T tuser=0;
       for (int i = 0; i < 256; i++) begin
           tuser.rss_enable  = rss_enable;
           tuser.rss_entropy = $random;
           one_packet(.idx(i), .tuser(tuser));
       end
    endtask

    task automatic table_init();
       logic [6:0] q_id;
       logic [1:0] t_id;

       for (int i = 0; i < 4; i++) begin // for all tables
           t_id = i;
           smartnic_hash2qid_reg_blk_agent.write_q_config (i, {~t_id, 10'h000});  // write base qid
           for (int j = 0; j < 128; j++) begin
               q_id = j;
               case(i)  // write unique and incrementing table entries
                   0: smartnic_hash2qid_reg_blk_agent.write_pf_table  (j, {2'h0, ~t_id, 1'b0, ~q_id});
                   1: smartnic_hash2qid_reg_blk_agent.write_vf0_table (j, {2'h0, ~t_id, 1'b0, ~q_id});
                   2: smartnic_hash2qid_reg_blk_agent.write_vf1_table (j, {2'h0, ~t_id, 1'b0, ~q_id});
                   3: smartnic_hash2qid_reg_blk_agent.write_vf2_table (j, {2'h0, ~t_id, 1'b0, ~q_id});
               endcase
           end
       end
    endtask

    `SVUNIT_TESTS_BEGIN

        `SVTEST(reset)
        `SVTEST_END

        `SVTEST(packet_stream_w_rss_enable)
            table_init();
            packet_stream(.rss_enable(1'b1));
            #10us
            `FAIL_IF_LOG(scoreboard.report(msg), msg);
            `FAIL_UNLESS_EQUAL(scoreboard.got_matched(), 256);
        `SVTEST_END

        `SVTEST(packet_stream_wout_rss_enable)
            table_init();
            packet_stream(.rss_enable(1'b0));
            #10us
            `FAIL_IF_LOG(scoreboard.report(msg), msg);
            `FAIL_UNLESS_EQUAL(scoreboard.got_matched(), 256);
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
