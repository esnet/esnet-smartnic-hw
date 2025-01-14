`include "svunit_defines.svh"

import smartnic_pkg::*;
import axi4s_verif_pkg::*;

// Environment class for 'smartnic' component verification.
class smartnic_env extends std_verif_pkg::basic_env;
    //===================================
    // Parameters
    //===================================
    localparam int  DATA_BYTE_WID = 64;
    localparam type TID_IN_T      = adpt_tx_tid_t;
    localparam type TID_OUT_T     = port_t;
    localparam type TDEST_T       = port_t;
    localparam type TUSER_T       = tuser_smartnic_meta_t;

    localparam type TRANSACTION_IN_T  = axi4s_transaction#(TID_IN_T, TDEST_T, TUSER_T);
    localparam type TRANSACTION_OUT_T = axi4s_transaction#(TID_OUT_T, TDEST_T, TUSER_T);
    localparam type DRIVER_T          = axi4s_driver  #(DATA_BYTE_WID, TID_IN_T,  TDEST_T, TUSER_T);
    localparam type MONITOR_T         = axi4s_monitor #(DATA_BYTE_WID, TID_OUT_T, TDEST_T, TUSER_T);
    localparam type MODEL_T           = smartnic_model;
    localparam type SCOREBOARD_T      = std_verif_pkg::event_scoreboard#(TRANSACTION_OUT_T);

    local static const string __CLASS_NAME = "std_verif_pkg::smartnic_env";

    //===================================
    // Properties
    //===================================
    DRIVER_T     driver  [4];
    MONITOR_T    monitor [4];
    MODEL_T      model   [4];
    // SCOREBOARD_T scoreboard [4];
    SCOREBOARD_T scoreboard0;
    SCOREBOARD_T scoreboard1;
    SCOREBOARD_T scoreboard2;
    SCOREBOARD_T scoreboard3;

    mailbox #(TRANSACTION_IN_T)  inbox [4];

    local mailbox #(TRANSACTION_IN_T)  __drv_inbox    [4];
    local mailbox #(TRANSACTION_OUT_T) __mon_outbox   [4];
    local mailbox #(TRANSACTION_IN_T)  __model_inbox  [4];
    local mailbox #(TRANSACTION_OUT_T) __model_outbox [4];

    virtual axi4s_intf #(
        .DATA_BYTE_WID(DATA_BYTE_WID),
        .TID_T   (TID_IN_T),
        .TDEST_T (TDEST_T),
        .TUSER_T (TUSER_T)
    ) axis_in_vif [4];

    virtual axi4s_intf #(
        .DATA_BYTE_WID(DATA_BYTE_WID),
        .TID_T   (TID_OUT_T),
        .TDEST_T (TDEST_T),
        .TUSER_T (TUSER_T)
    ) axis_out_vif [4];

    //===================================
    // Methods
    //===================================
    // Constructor
    function new(input string name="smartnic_env");
        super.new(name);
        for (int i=0; i < 4; i++) inbox[i] = new();
        for (int i=0; i < 4; i++) __drv_inbox[i]    = new();
        for (int i=0; i < 4; i++) __mon_outbox[i]   = new();
        for (int i=0; i < 4; i++) __model_inbox[i]  = new();
        for (int i=0; i < 4; i++) __model_outbox[i] = new();
        for (int i=0; i < 4; i++) driver[i]  = new(.name($sformatf("axi4s_driver[%0d]",i)), .BIGENDIAN(1'b1));
        for (int i=0; i < 4; i++) monitor[i] = new(.name($sformatf("axi4s_monitor[%0d]",i)), .BIGENDIAN(1'b1));

        model[0] = new(.name("model[0]"), .dest_if(CMAC0));
        model[1] = new(.name("model[1]"), .dest_if(CMAC1));
        model[2] = new(.name("model[2]"), .dest_if(PF0));
        model[3] = new(.name("model[3]"), .dest_if(PF1));

        //for (int i=0; i < 4; i++) scoreboard[i] = new();
        scoreboard0 = new("scoreboard[0]");
        scoreboard1 = new("scoreboard[1]");
        scoreboard2 = new("scoreboard[2]");
        scoreboard3 = new("scoreboard[3]");

    endfunction

    // Destructor
    // [[ implements std_verif_pkg::base.destroy() ]]
    function automatic void destroy();
        for (int i=0; i < 4; i++) driver[i]  = null;
        for (int i=0; i < 4; i++) monitor[i] = null;
        for (int i=0; i < 4; i++) model[i]   = null;

        for (int i=0; i < 4; i++) inbox[i] = null;
        for (int i=0; i < 4; i++) __drv_inbox[i]    = null;
        for (int i=0; i < 4; i++) __mon_outbox[i]   = null;
        for (int i=0; i < 4; i++) __model_inbox[i]  = null;
        for (int i=0; i < 4; i++) __model_outbox[i] = null;

        //for (int i=0; i < 4; i++) scoreboard[i] = null;
        scoreboard0 = null;
        scoreboard1 = null;
        scoreboard2 = null;
        scoreboard3 = null;

        super.destroy();
    endfunction

    // Configure trace output
    // [[ overrides std_verif_pkg::base.trace_msg() ]]
    function automatic void trace_msg(input string msg);
        _trace_msg(msg, __CLASS_NAME);
    endfunction

    // Build environment
    // [[ implements std_verif_pkg::env._build() ]]
    virtual protected function automatic void _build();
        trace_msg("_build()");
        for (int i=0; i < 4; i++) driver[i].inbox   = __drv_inbox[i];
        for (int i=0; i < 4; i++) model[i].inbox    = __model_inbox[i];
        for (int i=0; i < 4; i++) model[i].outbox   = __model_outbox[i];
        for (int i=0; i < 4; i++) monitor[i].outbox = __mon_outbox[i];

        //for (int i=0; i < 4; i++) scoreboard[i].got_inbox = __mon_outbox[i];
        scoreboard0.got_inbox = __mon_outbox[0];
        scoreboard1.got_inbox = __mon_outbox[1];
        scoreboard2.got_inbox = __mon_outbox[2];
        scoreboard3.got_inbox = __mon_outbox[3];

        //for (int i=0; i < 4; i++) scoreboard[i].exp_inbox = __model_outbox[i];
        scoreboard0.exp_inbox = __model_outbox[0];
        scoreboard1.exp_inbox = __model_outbox[1];
        scoreboard2.exp_inbox = __model_outbox[2];
        scoreboard3.exp_inbox = __model_outbox[3];

        for (int i=0; i < 4; i++) this.driver[i].axis_vif  = axis_in_vif[i];
        for (int i=0; i < 4; i++) this.monitor[i].axis_vif = axis_out_vif[i];
        for (int i=0; i < 4; i++) register_subcomponent(driver[i]);
        for (int i=0; i < 4; i++) register_subcomponent(monitor[i]);
        for (int i=0; i < 4; i++) register_subcomponent(model[i]);

        //for (int i=0; i < 4; i++) register_subcomponent(scoreboard[i]);
        register_subcomponent(scoreboard0);
        register_subcomponent(scoreboard1);
        register_subcomponent(scoreboard2);
        register_subcomponent(scoreboard3);

        trace_msg("_build() Done.");
    endfunction

    // Start environment execution (run loop)
    // [[ implements std_verif_pkg::component._run() ]]
    protected task _run();
        TRANSACTION_IN_T transaction [4];
        int              dest_if     [4];

        trace_msg("_run()");
        super._run();
        trace_msg("Running...");

        fork
            forever begin
                inbox[0].get(transaction[0]);
                __drv_inbox[0].put(transaction[0]);
                case (transaction[0].get_tdest())
                    CMAC0:  dest_if[0]=0;  PF0_VF2: dest_if[0]=2;  PF0_VF1: dest_if[0]=2;  PF0_VF0: dest_if[0]=2;  PF0: dest_if[0]=2;
                    CMAC1:  dest_if[0]=1;  PF1_VF2: dest_if[0]=3;  PF1_VF1: dest_if[0]=3;  PF1_VF0: dest_if[0]=3;  PF1: dest_if[0]=3;
                    default dest_if[0]=0;
                endcase
                __model_inbox[dest_if[0]].put(transaction[0]);
            end
            forever begin
                inbox[1].get(transaction[1]);
                __drv_inbox[1].put(transaction[1]);
                case (transaction[1].get_tdest())
                    CMAC0:  dest_if[1]=0;  PF0_VF2: dest_if[1]=2;  PF0_VF1: dest_if[1]=2;  PF0_VF0: dest_if[1]=2;  PF0: dest_if[1]=2;
                    CMAC1:  dest_if[1]=1;  PF1_VF2: dest_if[1]=3;  PF1_VF1: dest_if[1]=3;  PF1_VF0: dest_if[1]=3;  PF1: dest_if[1]=3;
                    default dest_if[1]=0;
                endcase
                __model_inbox[dest_if[1]].put(transaction[1]);
            end
            forever begin
                inbox[2].get(transaction[2]);
                __drv_inbox[2].put(transaction[2]);
                case (transaction[2].get_tdest())
                    CMAC0:  dest_if[2]=0;  PF0_VF2: dest_if[2]=2;  PF0_VF1: dest_if[2]=2;  PF0_VF0: dest_if[2]=2;  PF0: dest_if[2]=2;
                    CMAC1:  dest_if[2]=1;  PF1_VF2: dest_if[2]=3;  PF1_VF1: dest_if[2]=3;  PF1_VF0: dest_if[2]=3;  PF1: dest_if[2]=3;
                    default dest_if[2]=0;
                endcase
                __model_inbox[dest_if[2]].put(transaction[2]);
            end
            forever begin
                inbox[3].get(transaction[3]);
                __drv_inbox[3].put(transaction[3]);
                case (transaction[3].get_tdest())
                    CMAC0:  dest_if[3]=0;  PF0_VF2: dest_if[3]=2;  PF0_VF1: dest_if[3]=2;  PF0_VF0: dest_if[3]=2;  PF0: dest_if[3]=2;
                    CMAC1:  dest_if[3]=1;  PF1_VF2: dest_if[3]=3;  PF1_VF1: dest_if[3]=3;  PF1_VF0: dest_if[3]=3;  PF1: dest_if[3]=3;
                    default dest_if[3]=0;
                endcase
                __model_inbox[dest_if[3]].put(transaction[3]);
            end
        join_any

        trace_msg("_run() Done.");
    endtask

endclass : smartnic_env


// Model
class smartnic_model extends std_verif_pkg::model#(axi4s_transaction#(adpt_tx_tid_t, port_t, tuser_smartnic_meta_t),
                                                   axi4s_transaction#(       port_t, port_t, tuser_smartnic_meta_t));
    port_t dest_if;

    function new(string name="smartnic_model", port_t dest_if=CMAC0);
        super.new(name);
        this.dest_if = dest_if;
    endfunction

    protected task _process(input axi4s_transaction#(adpt_tx_tid_t, port_t, tuser_smartnic_meta_t) transaction);
        axi4s_transaction#(port_t, port_t, tuser_smartnic_meta_t) transaction_out;
        port_t  tid_out;
        port_t  tdest_out;
        tuser_smartnic_meta_t  tuser_out;

        tid_out   = 'x; // egr tid is disconnected.
        tdest_out = 'x; // egr tdest is disconnected.

        if ((dest_if==CMAC0) || (dest_if==CMAC1)) begin
            tuser_out = 1'b0; // m_axis_adpt_rx_322mhz_tuser_err=0 for egr CMAC ifs.
        end else begin
            tuser_out = 'x;
            tuser_out.rss_enable = 1'b1;
            case (transaction.get_tdest())
                PF0:     tuser_out.rss_entropy = 12'd2048;  // set entropy=qid based on egr queue (hash2qid) config.
                PF0_VF0: tuser_out.rss_entropy = 12'd2560;
                PF0_VF1: tuser_out.rss_entropy = 12'd3072;
                PF0_VF2: tuser_out.rss_entropy = 12'd3584;
                PF1:     tuser_out.rss_entropy = 12'd0;
                PF1_VF0: tuser_out.rss_entropy = 12'd512;
                PF1_VF1: tuser_out.rss_entropy = 12'd1024;
                PF1_VF2: tuser_out.rss_entropy = 12'd1536;
                default  tuser_out.rss_entropy = 12'd0;
            endcase
        end

        transaction_out = new ($sformatf("trans_%0d_out", num_output_transactions()), transaction.payload().size(),
                               tid_out, tdest_out, tuser_out);
        transaction_out.from_bytes(transaction.payload());
        _enqueue(transaction_out);
    endtask

endclass



module smartnic_unit_test;
    import svunit_pkg::svunit_testcase;
    import packet_verif_pkg::*;
    import axi4s_verif_pkg::*;
    import axi4l_verif_pkg::*;
    import smartnic_pkg::*;

    string name = "smartnic_ut";
    svunit_testcase svunit_ut;

    //===================================
    // DUT
    //===================================
    `include "../common/DUT.svh"

    axi4s_intf #(.DATA_BYTE_WID(64), .TID_T(adpt_tx_tid_t), .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_in_if  [4] ();
    axi4s_intf #(.DATA_BYTE_WID(64), .TID_T(port_t),        .TDEST_T(port_t), .TUSER_T(tuser_smartnic_meta_t)) axis_out_if [4] ();

    generate for (genvar i = 0; i < 2; i += 1) begin
        axi4s_intf_connector cmac_igr_connector (.axi4s_from_tx(axis_in_if[i]),    .axi4s_to_rx(axis_cmac_igr[i]));
        axi4s_intf_connector cmac_egr_connector (.axi4s_from_tx(axis_cmac_egr[i]), .axi4s_to_rx(axis_out_if[i]));

        axi4s_intf_connector      h2c_connector (.axi4s_from_tx(axis_in_if[i+2]),  .axi4s_to_rx(axis_h2c[i]));
        axi4s_intf_connector      c2h_connector (.axi4s_from_tx(axis_c2h[i]),      .axi4s_to_rx(axis_out_if[i+2]));
    end endgenerate

    //===================================
    // Testbench
    //===================================
    smartnic_env env;

    axi4l_reg_agent #() reg_agent;
    smartnic_reg_verif_pkg::smartnic_reg_blk_agent          #() smartnic_reg_blk_agent;
    smartnic_reg_verif_pkg::smartnic_hash2qid_reg_blk_agent #() smartnic_hash2qid_0_reg_blk_agent;
    smartnic_reg_verif_pkg::smartnic_hash2qid_reg_blk_agent #() smartnic_hash2qid_1_reg_blk_agent;

    // Assign axis clock (333MHz)
    logic axis_clk;
    `SVUNIT_CLK_GEN(axis_clk, 1.5ns);

    // Assign axil clock (100MHz)
    `SVUNIT_CLK_GEN(axil_aclk, 4ns);

    // Assign clks
    assign axil_if.aclk = axil_aclk;

    generate for (genvar i = 0; i < 4; i += 1) assign axis_in_if[i].aclk    = axis_clk; endgenerate

    generate for (genvar i = 0; i < 2; i += 1) assign cmac_clk[i]           = axis_clk; endgenerate
    generate for (genvar i = 0; i < 2; i += 1) assign axis_cmac_egr[i].aclk = axis_clk; endgenerate
    generate for (genvar i = 0; i < 2; i += 1) assign axis_c2h[i].aclk      = axis_clk; endgenerate

    // Assign resets
    std_reset_intf axis_reset_if (.clk(axis_clk));
    assign mod_rstn = ~axis_reset_if.reset;
    assign axis_reset_if.ready = mod_rst_done;

    generate for (genvar i = 0; i < 4; i += 1) assign axis_in_if[i].aresetn  = !axis_reset_if.reset; endgenerate
    generate for (genvar i = 0; i < 4; i += 1) assign axis_out_if[i].aresetn = !axis_reset_if.reset; endgenerate

    assign axil_if.aresetn = !axis_reset_if.reset;


    // output monitors
/*
    always @(negedge axis_cmac_egr[0].tvalid) if (axis_cmac_egr[0].tready && !axis_cmac_egr[0].tlast) $display ("Port0: tvalid gap.  May lead to ONS underflow!");
    always @(negedge axis_cmac_egr[1].tvalid) if (axis_cmac_egr[1].tready && !axis_cmac_egr[1].tlast) $display ("Port1: tvalid gap.  May lead to ONS underflow!");
    always @(negedge      axis_c2h[0].tvalid) if (axis_c2h[0].tready && !axis_c2h[0].tlast)           $display ("Port2: tvalid gap.  May lead to ONS underflow!");
    always @(negedge      axis_c2h[1].tvalid) if (axis_c2h[1].tready && !axis_c2h[1].tlast)           $display ("Port3: tvalid gap.  May lead to ONS underflow!");

    always @(posedge axis_cmac_egr[0].aclk) if (axis_cmac_egr[0].tready && axis_cmac_egr[0].tvalid) $display ("Port0: Valid transaction!");
    always @(posedge axis_cmac_egr[1].aclk) if (axis_cmac_egr[1].tready && axis_cmac_egr[1].tvalid) $display ("Port1: Valid transaction!");
*/

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);
        env = new("env");       

        env.reset_vif = axis_reset_if;
        // for (int i=0; i < 4; i++) env.axis_in_vif[i] = axis_in_if[i];  // commented out due to simulator errors.
        env.axis_in_vif[0] = axis_in_if[0];
        env.axis_in_vif[1] = axis_in_if[1];
        env.axis_in_vif[2] = axis_in_if[2];
        env.axis_in_vif[3] = axis_in_if[3];

        //for (int i=0; i < 2; i++) env.axis_out_vif[i] = axis_out_if[i];  // commented out due to simulator errors.
        env.axis_out_vif[0] = axis_out_if[0];
        env.axis_out_vif[1] = axis_out_if[1];
        env.axis_out_vif[2] = axis_out_if[2];
        env.axis_out_vif[3] = axis_out_if[3];

        env.build();
        env.set_debug_level(1);

        reg_agent = new("axi4l_reg_agent");
        reg_agent.axil_vif = axil_if;

        smartnic_reg_blk_agent            = new("smartnic_reg_blk_agent");
        smartnic_hash2qid_0_reg_blk_agent = new("smartnic_hash2qid_0_reg_blk_agent", 'h12000);
        smartnic_hash2qid_1_reg_blk_agent = new("smartnic_hash2qid_1_reg_blk_agent", 'h13000);

        smartnic_reg_blk_agent.reg_agent            = reg_agent;
        smartnic_hash2qid_0_reg_blk_agent.reg_agent = reg_agent;
        smartnic_hash2qid_1_reg_blk_agent.reg_agent = reg_agent;
    endfunction

    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();

        // Start environment
        env.run();

        // set igr switch destination to the BYPASS path for all igr ports.
        reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[0], 2 );
        reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[1], 2 );
        reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[2], 2 );
        reg_agent.write_reg( smartnic_reg_pkg::OFFSET_IGR_SW_TDEST[3], 2 );

        // set igr queue configuration for all igr ports. 512 queues per if x 8 ifs.
        smartnic_reg_blk_agent.write_igr_q_config_0(0, {12'd512, 12'd0});
        smartnic_reg_blk_agent.write_igr_q_config_0(1, {12'd512, 12'd512});
        smartnic_reg_blk_agent.write_igr_q_config_0(2, {12'd512, 12'd1024});
        smartnic_reg_blk_agent.write_igr_q_config_0(3, {12'd512, 12'd1536});

        smartnic_reg_blk_agent.write_igr_q_config_1(0, {12'd512, 12'd2048});
        smartnic_reg_blk_agent.write_igr_q_config_1(1, {12'd512, 12'd2560});
        smartnic_reg_blk_agent.write_igr_q_config_1(2, {12'd512, 12'd3072});
        smartnic_reg_blk_agent.write_igr_q_config_1(3, {12'd512, 12'd3584});

        // set egr queue configuration for all egr ports. base qid per if x 8 ifs.
        smartnic_hash2qid_0_reg_blk_agent.write_q_config (0, 12'd2048);
        smartnic_hash2qid_0_reg_blk_agent.write_q_config (1, 12'd2560);
        smartnic_hash2qid_0_reg_blk_agent.write_q_config (2, 12'd3072);
        smartnic_hash2qid_0_reg_blk_agent.write_q_config (3, 12'd3584);

        smartnic_hash2qid_1_reg_blk_agent.write_q_config (0, 12'd0);
        smartnic_hash2qid_1_reg_blk_agent.write_q_config (1, 12'd512);
        smartnic_hash2qid_1_reg_blk_agent.write_q_config (2, 12'd1024);
        smartnic_hash2qid_1_reg_blk_agent.write_q_config (3, 12'd1536);
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

    // Create and send input transaction
    task automatic one_packet(input int idx=0, len=64, input port_t tid=CMAC0, tdest=tid);
        axi4s_transaction#(adpt_tx_tid_t, port_t, tuser_smartnic_meta_t)  transaction_in;

        transaction_in = new(.name($sformatf("trans_%0d_in", idx)), .len(len));
        transaction_in.randomize();
        transaction_in.set_tdest(tdest);
        case (tid)
            CMAC0:   begin  transaction_in.set_tid($urandom_range(0,511) + 16'd0);     env.inbox[0].put(transaction_in);  end
            CMAC1:   begin  transaction_in.set_tid($urandom_range(0,511) + 16'd0);     env.inbox[1].put(transaction_in);  end
            PF0:     begin  transaction_in.set_tid($urandom_range(0,511) + 16'd0);     env.inbox[2].put(transaction_in);  end
            PF0_VF0: begin  transaction_in.set_tid($urandom_range(0,511) + 16'd512);   env.inbox[2].put(transaction_in);  end
            PF0_VF1: begin  transaction_in.set_tid($urandom_range(0,511) + 16'd1024);  env.inbox[2].put(transaction_in);  end
            PF0_VF2: begin  transaction_in.set_tid($urandom_range(0,511) + 16'd1536);  env.inbox[2].put(transaction_in);  end
            PF1:     begin  transaction_in.set_tid($urandom_range(0,511) + 16'd2048);  env.inbox[3].put(transaction_in);  end
            PF1_VF0: begin  transaction_in.set_tid($urandom_range(0,511) + 16'd2560);  env.inbox[3].put(transaction_in);  end
            PF1_VF1: begin  transaction_in.set_tid($urandom_range(0,511) + 16'd3072);  env.inbox[3].put(transaction_in);  end
            PF1_VF2: begin  transaction_in.set_tid($urandom_range(0,511) + 16'd3584);  env.inbox[3].put(transaction_in);  end
        endcase
    endtask

    task automatic packet_stream(input int num=10, input port_t tid=CMAC0, tdest=tid);
       for (int i = 0; i < num; i++) begin
           one_packet(.idx(i), .len($urandom_range(64, 1500)), .tid(tid), .tdest(tdest));
       end
    endtask

    string msg;

    `SVUNIT_TESTS_BEGIN

        `SVTEST(reset)
        `SVTEST_END

        `SVTEST(CMAC0_passthru_test)
            packet_stream(.tid(CMAC0));
            #2us;
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_matched(), 10);
            `FAIL_IF_LOG(env.scoreboard0.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(CMAC1_passthru_test)
            packet_stream(.tid(CMAC1));
            #2us;
            `FAIL_IF_LOG(env.scoreboard1.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(CMAC0_to_PF0_VF2_test)
            smartnic_reg_blk_agent.write_egr_demux_sel('1);

            packet_stream(.tid(CMAC0), .tdest(PF0_VF2));
            #2us;
            `FAIL_IF_LOG(env.scoreboard2.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(CMAC1_to_PF1_VF2_test)
            smartnic_reg_blk_agent.write_egr_demux_sel('1);

            packet_stream(.tid(CMAC1), .tdest(PF1_VF2));
            #2us;
            `FAIL_IF_LOG(env.scoreboard3.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF0_VF2_to_CMAC0_test)
            packet_stream(.tid(PF0_VF2), .tdest(CMAC0));
            #2us;
            `FAIL_IF_LOG(env.scoreboard0.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF1_VF2_to_CMAC1_test)
            packet_stream(.tid(PF1_VF2), .tdest(CMAC1));
            #2us;
            `FAIL_IF_LOG(env.scoreboard1.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF0_VF2_passthru_test)
            smartnic_reg_blk_agent.write_egr_demux_sel('1);

            packet_stream(.tid(PF0_VF2));
            #2us
            `FAIL_IF_LOG(env.scoreboard2.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF1_VF2_passthru_test)
            smartnic_reg_blk_agent.write_egr_demux_sel('1);

            packet_stream(.tid(PF1_VF2));
            #2us
            `FAIL_IF_LOG(env.scoreboard3.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF0_VF1_loopback_test)
            packet_stream(.tid(PF0_VF1));
            #2us;
            `FAIL_IF_LOG(env.scoreboard2.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF1_VF1_loopback_test)
            packet_stream(.tid(PF1_VF1));
            #2us;
            `FAIL_IF_LOG(env.scoreboard3.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF0_VF0_to_CMAC0_test)
            packet_stream(.tid(PF0_VF0), .tdest(CMAC0));
            #2us;
            `FAIL_IF_LOG(env.scoreboard0.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF1_VF0_to_CMAC1_test)
            packet_stream(.tid(PF1_VF0), .tdest(CMAC1));
            #2us;
            `FAIL_IF_LOG(env.scoreboard1.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF0_to_CMAC0_test)
            packet_stream(.tid(PF0), .tdest(CMAC0));
            #2us;
            `FAIL_IF_LOG(env.scoreboard0.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF1_to_CMAC1_test)
            packet_stream(.tid(PF1), .tdest(CMAC1));
            #2us;
            `FAIL_IF_LOG(env.scoreboard1.report(msg), msg);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_matched(), 10);
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF0_out_of_range_test)
            smartnic_reg_blk_agent.write_igr_q_config_0(0, {12'd0, 12'd0});

            packet_stream(.tid(PF0), .tdest(CMAC0));
            #2us;
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(PF1_out_of_range_test)
            smartnic_reg_blk_agent.write_igr_q_config_1(0, {12'd0, 12'd0});

            packet_stream(.tid(PF1), .tdest(CMAC1));
            #2us;
            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_processed(), 0);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_processed(), 0);
        `SVTEST_END

        `SVTEST(random_in_test)
            port_t   tid, tdest;
            int      num, exp_cnt[4];

            for (int i = 0; i < 4; i++) exp_cnt[i] = 0;

            for (int i = 0; i < 10; i++) begin
                case ($urandom_range(0,9))
                    0: tid=CMAC0;  1: tid=PF0_VF2;  2: tid=PF0_VF1;  3: tid=PF0_VF0;  4: tid=PF0;
                    5: tid=CMAC1;  6: tid=PF1_VF2;  7: tid=PF1_VF1;  8: tid=PF1_VF0;  9: tid=PF1;
                endcase

                case (tid)
                    CMAC0: tdest=CMAC0;  PF0_VF2: tdest=CMAC0;  PF0_VF1: tdest=PF0_VF1;  PF0_VF0: tdest=CMAC0;  PF0: tdest=CMAC0;
                    CMAC1: tdest=CMAC1;  PF1_VF2: tdest=CMAC1;  PF1_VF1: tdest=PF1_VF1;  PF1_VF0: tdest=CMAC1;  PF1: tdest=CMAC1;
                endcase

                num = $urandom_range(1,5);
                packet_stream(.num(num), .tid(tid), .tdest(tdest));

                case (tdest)
                    CMAC0:   exp_cnt[0] = exp_cnt[0] + num;
                    CMAC1:   exp_cnt[1] = exp_cnt[1] + num;
                    PF0_VF1: exp_cnt[2] = exp_cnt[2] + num;
                    PF1_VF1: exp_cnt[3] = exp_cnt[3] + num;
                endcase

                #1us;
            end             

            `FAIL_IF_LOG(env.scoreboard0.report(msg), msg);
            `FAIL_IF_LOG(env.scoreboard1.report(msg), msg);
            `FAIL_IF_LOG(env.scoreboard2.report(msg), msg);
            `FAIL_IF_LOG(env.scoreboard3.report(msg), msg);

            `FAIL_UNLESS_EQUAL(env.scoreboard0.got_matched(), exp_cnt[0]);
            `FAIL_UNLESS_EQUAL(env.scoreboard1.got_matched(), exp_cnt[1]);
            `FAIL_UNLESS_EQUAL(env.scoreboard2.got_matched(), exp_cnt[2]);
            `FAIL_UNLESS_EQUAL(env.scoreboard3.got_matched(), exp_cnt[3]);
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
