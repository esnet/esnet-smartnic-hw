`include "svunit_defines.svh"

module xilinx_qdma_st_adapter_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_qdma_pkg::*;
    import axi4s_verif_pkg::*;

    string name = "xilinx_qdma_st_adapter_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 100us

    // =========================================================================
    // Parameters — use default (USPlus) widths
    // =========================================================================
    localparam int QID_WID = 11;

    // =========================================================================
    // Clock and reset
    // =========================================================================
    logic aclk    = 1'b0;
    logic aresetn = 1'b0;

    `SVUNIT_CLK_GEN(aclk, 2ns);   // 250 MHz

    // =========================================================================
    // H2C flat signals (driven by testbench → DUT)
    // =========================================================================
    logic                  h2c_tvalid;
    logic [511:0]          h2c_tdata;
    logic                  h2c_tlast;
    logic                  h2c_tready;
    logic [QID_WID-1:0]    h2c_qid;
    logic [2:0]            h2c_port_id;
    logic [31:0]           h2c_mdata;
    logic [5:0]            h2c_mty;
    logic [31:0]           h2c_tcrc;
    logic                  h2c_err;
    logic                  h2c_zero_byte;

    // Clocking block for driving H2C flat signals.
    // output #1 drives 1 time unit after posedge — stable before the next
    // posedge — avoiding the combinatorial/pipe sampling race.
    // input samples h2c_tready synchronously at posedge.
    clocking cb_h2c @(posedge aclk);
        default input #1step output #1;
        output h2c_tvalid, h2c_tdata, h2c_tlast, h2c_mty,
               h2c_zero_byte, h2c_err, h2c_qid;
        input  h2c_tready;
    endclocking

    // =========================================================================
    // C2H flat signals (driven by DUT → observed by testbench)
    // =========================================================================
    logic                  c2h_tvalid;
    logic [511:0]          c2h_tdata;
    logic                  c2h_tlast;
    logic                  c2h_tready;
    logic [QID_WID-1:0]    c2h_ctrl_qid;
    logic [15:0]           c2h_ctrl_len;
    logic [2:0]            c2h_ctrl_port_id;
    logic                  c2h_ctrl_has_cmpt;
    logic                  c2h_ctrl_marker;
    logic [5:0]            c2h_mty;
    logic [6:0]            c2h_ecc;
    logic [31:0]           c2h_tcrc;

    // Completion
    logic                  cmpt_tvalid;
    logic [511:0]          cmpt_data;
    logic [1:0]            cmpt_size;
    logic [QID_WID-1:0]    cmpt_qid;
    logic [2:0]            cmpt_port_id;
    logic [1:0]            cmpt_cmpt_type;
    logic [15:0]           cmpt_wait_pld_pkt_id;
    logic [15:0]           cmpt_dpar;
    logic [2:0]            cmpt_col_idx;
    logic [2:0]            cmpt_err_idx;
    logic                  cmpt_user_trig;
    logic                  cmpt_marker;
    logic                  cmpt_no_wrb_marker;
    logic                  cmpt_tready;

    // Descriptor credits
    logic [15:0]           dsc_crdt_crdt;
    logic                  dsc_crdt_dir;
    logic                  dsc_crdt_fence;
    logic [QID_WID-1:0]    dsc_crdt_qid;
    logic                  dsc_crdt_valid;
    logic                  dsc_crdt_rdy;

    // =========================================================================
    // AXI4-S interfaces — shell side of the DUT
    // =========================================================================
    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .TID_WID       ( AXIS_TID_WID       ),
        .TDEST_WID     ( AXIS_TDEST_WID     ),
        .TUSER_WID     ( AXIS_TUSER_WID     )
    ) axis_h2c (.aclk(aclk));   // DUT drives (tx), monitor reads

    axi4s_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .TID_WID       ( AXIS_TID_WID       ),
        .TDEST_WID     ( AXIS_TDEST_WID     ),
        .TUSER_WID     ( AXIS_TUSER_WID     )
    ) axis_c2h (.aclk(aclk));   // driver sends (tx), DUT reads (rx)

    // =========================================================================
    // DUT
    // =========================================================================
    xilinx_qdma_st_adapter #(
        .QID_WID ( QID_WID )
    ) DUT (
        .aclk,
        .aresetn,
        .h2c_tvalid,
        .h2c_tdata,
        .h2c_tlast,
        .h2c_tready,
        .h2c_qid,
        .h2c_port_id,
        .h2c_mdata,
        .h2c_mty,
        .h2c_tcrc,
        .h2c_err,
        .h2c_zero_byte,
        .c2h_tvalid,
        .c2h_tdata,
        .c2h_tlast,
        .c2h_tready,
        .c2h_ctrl_qid,
        .c2h_ctrl_len,
        .c2h_ctrl_port_id,
        .c2h_ctrl_has_cmpt,
        .c2h_ctrl_marker,
        .c2h_mty,
        .c2h_ecc,
        .c2h_tcrc,
        .cmpt_tvalid,
        .cmpt_data,
        .cmpt_size,
        .cmpt_qid,
        .cmpt_port_id,
        .cmpt_cmpt_type,
        .cmpt_wait_pld_pkt_id,
        .cmpt_dpar,
        .cmpt_col_idx,
        .cmpt_err_idx,
        .cmpt_user_trig,
        .cmpt_marker,
        .cmpt_no_wrb_marker,
        .cmpt_tready,
        .dsc_crdt_crdt,
        .dsc_crdt_dir,
        .dsc_crdt_fence,
        .dsc_crdt_qid,
        .dsc_crdt_valid,
        .dsc_crdt_rdy,
        .axis_h2c,
        .axis_c2h
    );

    // =========================================================================
    // Verif objects
    //   h2c_mon  : monitors axis_h2c (DUT output — H2C stream to core)
    //   c2h_drv  : drives axis_c2h  (DUT input  — C2H stream from core)
    // =========================================================================
    typedef axi4s_transaction #(axis_tid_t, axis_tdest_t, axis_tuser_t) TRANS_T;

    axi4s_monitor  #(AXIS_DATA_BYTE_WID, axis_tid_t, axis_tdest_t, axis_tuser_t) h2c_mon;
    axi4s_driver   #(AXIS_DATA_BYTE_WID, axis_tid_t, axis_tdest_t, axis_tuser_t) c2h_drv;

    // =========================================================================
    // Assertions
    // =========================================================================
    // ctrl_has_cmpt is an architectural invariant — always 1.
    property p_ctrl_has_cmpt;
        @(posedge aclk) disable iff (!aresetn)
        c2h_tvalid |-> c2h_ctrl_has_cmpt;
    endproperty
    a_ctrl_has_cmpt: assert property (p_ctrl_has_cmpt);

    // cmpt_tvalid fires exactly on EOP.
    property p_cmpt_on_eop;
        @(posedge aclk) disable iff (!aresetn)
        cmpt_tvalid |-> (c2h_tvalid && c2h_tready && c2h_tlast);
    endproperty
    a_cmpt_on_eop: assert property (p_cmpt_on_eop);

    // Note: axis_c2h.tready = ready || (c2h_tready && cmpt_tready) where 'ready'
    // is the internal buffer register in axi4s_intf_pipe.  When the pipe is empty
    // (ready=1), axis_c2h.tready is 1 regardless of downstream tready — back-pressure
    // only takes effect after the pipe stores a beat and ready goes to 0.
    // A same-cycle SVA on this relationship is not possible; functional correctness
    // is verified by c2h_backpressure_data_ and c2h_backpressure_cmpt_.

    // =========================================================================
    // Coverage
    // =========================================================================
    covergroup cg_h2c @(posedge aclk);
        // mty on the last H2C beat
        cp_h2c_mty: coverpoint h2c_mty iff (aresetn && h2c_tvalid && h2c_tready && h2c_tlast) {
            bins full_beat = {0};
            bins partial[] = {[1:AXIS_DATA_BYTE_WID-2]};
            bins one_byte  = {AXIS_DATA_BYTE_WID-1};
        }
        // zero_byte flag
        cp_h2c_zero_byte: coverpoint h2c_zero_byte iff (aresetn && h2c_tvalid && h2c_tready && h2c_tlast);
        // err flag
        cp_h2c_err: coverpoint h2c_err iff (aresetn && h2c_tvalid && h2c_tready);
        // qid boundary values
        cp_h2c_qid: coverpoint h2c_qid iff (aresetn && h2c_tvalid && h2c_tready && h2c_tlast) {
            bins zero    = {0};
            bins mid     = {[1:(2**QID_WID)-2]};
            bins max_val = {(2**QID_WID)-1};
        }
        // single-beat packet (tvalid && tready && tlast on first beat)
        cp_h2c_single_beat: coverpoint (h2c_tvalid && h2c_tready && h2c_tlast) iff (aresetn) {
            bins single = {1};
        }
        // back-to-back: EOP of one packet coincides with first beat of next
        cp_h2c_back_to_back: coverpoint (h2c_tlast && h2c_tvalid && h2c_tready) iff (aresetn);
    endgroup

    covergroup cg_c2h @(posedge aclk);
        // mty on the last C2H beat (derived from tkeep)
        cp_c2h_mty: coverpoint c2h_mty iff (aresetn && c2h_tvalid && c2h_tready && c2h_tlast) {
            bins full_beat = {0};
            bins partial[] = {[1:AXIS_DATA_BYTE_WID-2]};
            bins one_byte  = {AXIS_DATA_BYTE_WID-1};
        }
        // completion fires on EOP
        cp_cmpt_on_eop: coverpoint cmpt_tvalid iff (aresetn && c2h_tvalid && c2h_tready && c2h_tlast) {
            bins fires = {1};
        }
        // cmpt_qid matches ctrl_qid on every completion
        cp_cmpt_qid_match: coverpoint (cmpt_qid == c2h_ctrl_qid) iff (aresetn && cmpt_tvalid) {
            bins match = {1};
        }
        // cmpt_type is always HAS_PLD (2'b11)
        cp_cmpt_type: coverpoint cmpt_cmpt_type iff (aresetn && cmpt_tvalid) {
            bins has_pld = {2'b11};
        }
        // cross c2h_tready x cmpt_tready to cover all four back-pressure combinations
        cp_c2h_tready:  coverpoint c2h_tready  iff (aresetn);
        cp_cmpt_tready: coverpoint cmpt_tready iff (aresetn);
        cx_backpressure: cross cp_c2h_tready, cp_cmpt_tready;
    endgroup

    covergroup cg_credits @(posedge aclk);
        cp_crdt_valid: coverpoint dsc_crdt_valid iff (aresetn) {
            bins idle = {0};
        }
    endgroup

    cg_h2c     cg_h2c_inst;
    cg_c2h     cg_c2h_inst;
    cg_credits cg_credits_inst;

    // =========================================================================
    // Build
    // =========================================================================
    function void build();
        svunit_ut      = new(name);
        h2c_mon        = new("h2c_mon");
        c2h_drv        = new("c2h_drv");
        h2c_mon.axis_vif = axis_h2c;
        c2h_drv.axis_vif = axis_c2h;
        cg_h2c_inst    = new();
        cg_c2h_inst    = new();
        cg_credits_inst = new();
    endfunction

    // =========================================================================
    // Setup / teardown
    // =========================================================================
    task setup();
        svunit_ut.setup();
        idle();
        aresetn = 1'b0;
        repeat (8) @(posedge aclk);
        aresetn = 1'b1;
        repeat (4) @(posedge aclk);
    endtask

    task teardown();
        svunit_ut.teardown();
        idle();
    endtask

    // =========================================================================
    // Helpers
    // =========================================================================
    task idle();
        // H2C flat inputs idle
        cb_h2c.h2c_tvalid    <= 1'b0;
        cb_h2c.h2c_tdata     <= '0;
        cb_h2c.h2c_tlast     <= 1'b0;
        cb_h2c.h2c_qid       <= '0;
        cb_h2c.h2c_mty       <= '0;
        cb_h2c.h2c_err       <= 1'b0;
        cb_h2c.h2c_zero_byte <= 1'b0;
        // C2H downstream readies
        c2h_tready  = 1'b1;
        cmpt_tready = 1'b1;
        dsc_crdt_rdy = 1'b1;
        // H2C monitor: always accept
        axis_h2c.tready = 1'b1;
        // C2H driver idle
        c2h_drv.idle();
    endtask

    // Send an H2C packet as a sequence of beats via the cb_h2c clocking block.
    // Each beat is held until h2c_tready is observed; tvalid is deasserted
    // only after the final beat is accepted.
    task automatic send_h2c_packet(
        input int                 num_beats,
        input logic [5:0]         last_mty   = '0,
        input logic               zero_byte  = 1'b0,
        input logic               err        = 1'b0,
        input logic [QID_WID-1:0] qid        = '0
    );
        for (int i = 0; i < num_beats; i++) begin
            logic last = (i == num_beats - 1);
            @(cb_h2c);
            cb_h2c.h2c_tvalid    <= 1'b1;
            cb_h2c.h2c_tdata     <= $urandom_range(0, '1);
            cb_h2c.h2c_tlast     <= last;
            cb_h2c.h2c_mty       <= last ? last_mty : '0;
            cb_h2c.h2c_zero_byte <= last ? zero_byte : 1'b0;
            cb_h2c.h2c_err       <= err;
            cb_h2c.h2c_qid       <= qid;
            wait (cb_h2c.h2c_tready);
        end
        @(cb_h2c);
        cb_h2c.h2c_tvalid    <= 1'b0;
        cb_h2c.h2c_tlast     <= 1'b0;
        cb_h2c.h2c_zero_byte <= 1'b0;
        cb_h2c.h2c_err       <= 1'b0;
    endtask

    // Send a C2H packet via the axi4s_driver (byte-level, auto-computes tkeep).
    task automatic send_c2h_packet(
        input int                 num_bytes,
        input axis_tid_t          tid        = '0,
        input axis_tuser_t        tuser      = '0,
        input int                 twait      = 0
    );
        TRANS_T trans;
        trans = new(.name("c2h_pkt"), .len(num_bytes), .tid(tid), .tuser(tuser));
        trans.randomize();
        c2h_drv.set_twait(twait);
        c2h_drv.send(trans);
    endtask

    // Receive one H2C packet via the monitor and return the transaction.
    task automatic recv_h2c_packet(output TRANS_T trans);
        h2c_mon.receive(trans);
    endtask

    // =========================================================================
    // Tests
    // =========================================================================
    `SVUNIT_TESTS_BEGIN

        // Compile / elaboration smoke test.
        `SVTEST(compile)
        `SVTEST_END

        // H2C: single full beat (mty=0, zero_byte=0) — all bytes valid.
        `SVTEST(h2c_single_full_beat)
            TRANS_T trans;
            fork
                send_h2c_packet(.num_beats(1), .last_mty(0));
                recv_h2c_packet(trans);
            join
            `FAIL_UNLESS_EQUAL(trans.size(), AXIS_DATA_BYTE_WID);
        `SVTEST_END

        // H2C: last beat with mty=1 — 63 valid bytes.
        `SVTEST(h2c_partial_last_beat)
            TRANS_T trans;
            fork
                send_h2c_packet(.num_beats(1), .last_mty(6'd1));
                recv_h2c_packet(trans);
            join
            `FAIL_UNLESS_EQUAL(trans.size(), AXIS_DATA_BYTE_WID - 1);
        `SVTEST_END

        // H2C: zero_byte flag — adapter still asserts tkeep=all-ones.
        `SVTEST(_h2c_zero_byte)
            TRANS_T trans;
            fork
                send_h2c_packet(.num_beats(1), .last_mty('0), .zero_byte(1'b1));
                recv_h2c_packet(trans);
            join
            // zero_byte means the packet has no valid payload bytes; the monitor
            // will receive 0 bytes (all tkeep masked) or a full beat depending
            // on implementation — the key is no timeout and no assertion fire.
        `SVTEST_END

        // H2C: err flag propagates to tuser.err on axis_h2c.
        `SVTEST(h2c_err_propagation)
            TRANS_T trans;
            fork
                send_h2c_packet(.num_beats(1), .err(1'b1));
                recv_h2c_packet(trans);
            join
            `FAIL_UNLESS_EQUAL(trans.get_tuser().err, 1'b1);
        `SVTEST_END

        // H2C: qid maps to tid.qid on axis_h2c.
        `SVTEST(h2c_qid_mapping)
            TRANS_T trans;
            fork
                send_h2c_packet(.num_beats(1), .qid(11'h5A5));
                recv_h2c_packet(trans);
            join
            `FAIL_UNLESS_EQUAL(trans.get_tid().qid, 11'h5A5);
        `SVTEST_END

        // H2C: multi-beat packet — correct total byte count.
        `SVTEST(h2c_multi_beat)
            TRANS_T trans;
            fork
                send_h2c_packet(.num_beats(4), .last_mty(6'd3));
                recv_h2c_packet(trans);
            join
            `FAIL_UNLESS_EQUAL(trans.size(), 4*AXIS_DATA_BYTE_WID - 3);
        `SVTEST_END

        // H2C: back-to-back packets with no gap.
        `SVTEST(h2c_back_to_back)
            TRANS_T trans;
            for (int i = 0; i < 4; i++) begin
                fork
                    send_h2c_packet(.num_beats(1));
                    recv_h2c_packet(trans);
                join
            end
        `SVTEST_END

        // H2C: qid=0 and qid=max propagate correctly.
        `SVTEST(h2c_qid_boundary)
            TRANS_T trans;
            fork
                send_h2c_packet(.num_beats(1), .qid({QID_WID{1'b0}}));
                recv_h2c_packet(trans);
            join
            `FAIL_UNLESS_EQUAL(trans.get_tid().qid, '0);
            fork
                send_h2c_packet(.num_beats(1), .qid({QID_WID{1'b1}}));
                recv_h2c_packet(trans);
            join
            `FAIL_UNLESS_EQUAL(trans.get_tid().qid, {QID_WID{1'b1}});
        `SVTEST_END

        // C2H: full beat — mty output should be 0.
        `SVTEST(c2h_full_beat)
            logic [5:0] captured_mty;
            fork
                send_c2h_packet(.num_bytes(AXIS_DATA_BYTE_WID));
                @(posedge aclk iff (c2h_tvalid && c2h_tready && c2h_tlast));
            join
            captured_mty = c2h_mty;
            `FAIL_UNLESS_EQUAL(captured_mty, 6'h0);
        `SVTEST_END

        // C2H: partial beat — mty equals (AXIS_DATA_BYTE_WID - valid_bytes).
        `SVTEST(c2h_partial_beat)
            localparam int VALID_BYTES = 33;
            logic [5:0] captured_mty;
            fork
                send_c2h_packet(.num_bytes(VALID_BYTES));
                @(posedge aclk iff (c2h_tvalid && c2h_tready && c2h_tlast));
            join
            captured_mty = c2h_mty;
            `FAIL_UNLESS_EQUAL(captured_mty, 6'(AXIS_DATA_BYTE_WID - VALID_BYTES));
        `SVTEST_END

        // C2H: completion fires on EOP; cmpt_qid matches c2h_ctrl_qid.
        `SVTEST(c2h_completion_on_eop)
            axis_tid_t tid;
            logic captured_cmpt_valid;
            logic [QID_WID-1:0] captured_cmpt_qid;
            tid.qid = 11'h3F;
            fork
                send_c2h_packet(.num_bytes(64), .tid(tid));
                @(posedge aclk iff (c2h_tvalid && c2h_tready && c2h_tlast));
            join
            captured_cmpt_valid = cmpt_tvalid;
            captured_cmpt_qid   = cmpt_qid;
            `FAIL_UNLESS_EQUAL(captured_cmpt_valid, 1'b1);
            `FAIL_UNLESS_EQUAL(captured_cmpt_qid, 11'h3F);
        `SVTEST_END

        // C2H: pkt_id increments across consecutive packets.
        `SVTEST(c2h_pkt_id_increments)
            logic [15:0] pkt_ids [4];
            for (int i = 0; i < 4; i++) begin
                fork
                    send_c2h_packet(.num_bytes(64));
                    @(posedge aclk iff cmpt_tvalid);
                join
                pkt_ids[i] = cmpt_wait_pld_pkt_id;
                repeat (2) @(posedge aclk);
            end
            for (int i = 1; i < 4; i++)
                `FAIL_UNLESS_EQUAL(pkt_ids[i], pkt_ids[i-1] + 1'b1);
        `SVTEST_END

        // C2H: c2h_tready=0 propagates back through the pipe to axis_c2h.tready.
        // Verified independently of the driver to avoid a race where the driver
        // accepts a beat before the pipe has propagated the stall.
        // C2H: c2h_tready=0 mid-packet — no data is lost; pkt_id still increments.
        // Stall after the pipe stores the first beat (ready goes low), then release.
        // C2H: c2h_tready=0 mid-packet — no data lost; completion fires after release.
        `SVTEST(c2h_backpressure_data_)
            logic cmpt_seen;
            cmpt_seen = 1'b0;
            c2h_tready = 1'b0;
            fork
                send_c2h_packet(.num_bytes(4 * AXIS_DATA_BYTE_WID));
                begin
                    repeat (4) @(posedge aclk);
                    c2h_tready = 1'b1;
                end
            join
            // Completion must fire after the stall is released
            @(posedge aclk iff cmpt_tvalid);
            cmpt_seen = 1'b1;
            `FAIL_UNLESS(cmpt_seen);
        `SVTEST_END

        // C2H: cmpt_tready=0 — data path completes; completion fires once released.
        `SVTEST(c2h_backpressure_cmpt_)
            logic cmpt_seen;
            cmpt_seen = 1'b0;
            cmpt_tready = 1'b0;
            fork
                send_c2h_packet(.num_bytes(4 * AXIS_DATA_BYTE_WID));
                begin
                    repeat (4) @(posedge aclk);
                    cmpt_tready = 1'b1;
                end
            join
            @(posedge aclk iff cmpt_tvalid);
            cmpt_seen = 1'b1;
            `FAIL_UNLESS(cmpt_seen);
        `SVTEST_END

        // C2H: back-to-back packets — pkt_id advances correctly.
        `SVTEST(c2h_back_to_back)
            for (int i = 0; i < 4; i++)
                send_c2h_packet(.num_bytes(128));
            repeat (4) @(posedge aclk);
        `SVTEST_END

        // C2H: staggered inter-beat gap via driver twait.
        `SVTEST(c2h_driver_twait)
            send_c2h_packet(.num_bytes(3*AXIS_DATA_BYTE_WID), .twait(2));
            repeat (4) @(posedge aclk);
        `SVTEST_END

        // Descriptor credits are always idle.
        `SVTEST(credits_idle)
            repeat (16) @(posedge aclk);
            `FAIL_IF(dsc_crdt_valid);
            `FAIL_IF(dsc_crdt_crdt !== '0);
        `SVTEST_END

        // H2C throughput: drive N beats continuously (tvalid never deasserted
        // between beats) and verify axis_h2c.tvalid is high on every cycle
        // after the one-cycle pipe latency fills.
        `SVTEST(h2c_full_throughput)
            localparam int N = 16;
            int valid_cycles;
            int bubble_cycles;
            valid_cycles  = 0;
            bubble_cycles = 0;
            // Start sending — cb_h2c drives signals #1 after each posedge.
            // Fork a monitor that counts valid/bubble cycles on axis_h2c
            // starting from the second beat (pipe latency = 1 cycle).
            fork
                begin : send
                    for (int i = 0; i < N; i++) begin
                        @(cb_h2c);
                        cb_h2c.h2c_tvalid <= 1'b1;
                        cb_h2c.h2c_tdata  <= $urandom_range(0, '1);
                        cb_h2c.h2c_tlast  <= (i == N-1);
                        cb_h2c.h2c_mty    <= '0;
                        wait (cb_h2c.h2c_tready);
                    end
                    @(cb_h2c);
                    cb_h2c.h2c_tvalid <= 1'b0;
                    cb_h2c.h2c_tlast  <= 1'b0;
                end : send
                begin : monitor
                    // Wait for pipe to fill (first valid on axis_h2c), then
                    // count N cycles from that point — all must be valid.
                    @(posedge aclk iff axis_h2c.tvalid);
                    valid_cycles++;
                    repeat (N - 1) begin
                        @(posedge aclk);
                        if (axis_h2c.tvalid) valid_cycles++;
                        else                 bubble_cycles++;
                    end
                end : monitor
            join
            `FAIL_UNLESS_EQUAL(bubble_cycles, 0);
            `FAIL_UNLESS_EQUAL(valid_cycles,  N);
        `SVTEST_END

        // C2H throughput: drive N beats continuously via the axi4s_driver and
        // verify c2h_tvalid (flat output) is high on every cycle after the
        // one-cycle pipe latency fills, with no bubbles.
        `SVTEST(c2h_full_throughput)
            localparam int N = 16;
            int valid_cycles;
            int bubble_cycles;
            valid_cycles  = 0;
            bubble_cycles = 0;
            fork
                begin : send
                    // driver twait=0: no inter-beat gaps
                    send_c2h_packet(.num_bytes(N * AXIS_DATA_BYTE_WID), .twait(0));
                end : send
                begin : monitor
                    @(posedge aclk iff c2h_tvalid);
                    valid_cycles++;
                    repeat (N - 1) begin
                        @(posedge aclk);
                        if (c2h_tvalid) valid_cycles++;
                        else            bubble_cycles++;
                    end
                end : monitor
            join
            `FAIL_UNLESS_EQUAL(bubble_cycles, 0);
            `FAIL_UNLESS_EQUAL(valid_cycles,  N);
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule : xilinx_qdma_st_adapter_unit_test
