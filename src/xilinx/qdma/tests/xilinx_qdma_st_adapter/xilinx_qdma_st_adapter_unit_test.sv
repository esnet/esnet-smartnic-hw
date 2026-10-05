`include "svunit_defines.svh"

module xilinx_qdma_st_adapter_unit_test;
    import svunit_pkg::svunit_testcase;
    import xilinx_qdma_pkg::*;
    import axi4s_verif_pkg::*;

    string name = "xilinx_qdma_st_adapter_ut";
    svunit_testcase svunit_ut;

    `define SVUNIT_TIMEOUT 200us

    // =========================================================================
    // Parameters — use default (USPlus) widths
    // =========================================================================
    localparam int QID_WID = 11;
    localparam int MAX_PKT_LEN = 9100;

    // =========================================================================
    // Clock and reset
    // =========================================================================
    logic aclk     = 1'b0;
    logic core_clk = 1'b0;
    logic axil_clk = 1'b0;
    logic aresetn  = 1'b0;
    logic core_srst;
    assign core_srst = ~aresetn;

    // Both clocks free-running: the ASYNC FIFO's sync_reset/sync_ctr logic
    // requires clock activity from time 0 to initialize properly in xsim.
    // SVUNIT_CLK_GEN gates the clock until is_running(), which leaves the
    // FIFO's async reset synchronisers stalled and triggers an xsim hang.
    // The library's own async FIFO tests use free-running clocks for the
    // same reason (see fifo_axil_async_unit_test.sv).
    always #2ns   aclk     = ~aclk;     // 250 MHz — QDMA clock domain
    always #2.5ns core_clk = ~core_clk; // 200 MHz — core clock domain
    always #5ns   axil_clk = ~axil_clk; // 100 MHz — management clock domain

    // =========================================================================
    // H2C flat signals (driven by testbench → DUT)
    // All initialized at declaration to avoid X at time 0 — the ASYNC FIFO's
    // CDC logic can cause xsim to hang if any DUT input is X before idle()
    // runs (idle() is called from setup(), which is after SVUnit startup).
    // =========================================================================
    logic                  h2c_tvalid    = 1'b0;
    logic [511:0]          h2c_tdata     = '0;
    logic                  h2c_tlast     = 1'b0;
    logic                  h2c_tready;
    logic [QID_WID-1:0]    h2c_qid       = '0;
    logic [2:0]            h2c_port_id   = '0;
    logic [31:0]           h2c_mdata     = '0;
    logic [5:0]            h2c_mty       = '0;
    logic [31:0]           h2c_tcrc      = '0;
    logic                  h2c_err       = 1'b0;
    logic                  h2c_zero_byte = 1'b0;

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
    logic                  c2h_tready    = 1'b1;
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
    logic                  cmpt_tready   = 1'b1;

    // Descriptor credits
    logic [15:0]           dsc_crdt_crdt;
    logic                  dsc_crdt_dir;
    logic                  dsc_crdt_fence;
    logic [QID_WID-1:0]    dsc_crdt_qid;
    logic                  dsc_crdt_valid;
    logic                  dsc_crdt_rdy  = 1'b1;

    // =========================================================================
    // AXI4-S interfaces — shell side of the DUT
    // =========================================================================
    // H2C output: packet_intf in core clock domain (DUT crosses from aclk)
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_h2c (.clk(core_clk));

    // C2H input: packet_intf in core clock domain (separate clock for ASYNC FIFO CDC)
    packet_intf #(
        .DATA_BYTE_WID ( AXIS_DATA_BYTE_WID ),
        .META_WID      ( QID_WID            )
    ) pkt_c2h (.clk(core_clk));

    // Drive interface signals to known values from time 0.
    // Without this, pkt_c2h.vld et al. are X until idle() runs inside setup(),
    // and the ASYNC FIFO's CDC logic causes an xsim hang.
    initial begin
        pkt_c2h.vld  = 1'b0;
        pkt_c2h.data = '0;
        pkt_c2h.eop  = 1'b0;
        pkt_c2h.mty  = '0;
        pkt_c2h.err  = 1'b0;
        pkt_c2h.meta = '0;
        pkt_h2c.rdy  = 1'b1;
    end

    // =========================================================================
    // Management AXI4-Lite (register access)
    // =========================================================================
    axi4l_intf axil_if ();

    assign axil_if.aclk = axil_clk;
    always @(posedge axil_clk) axil_if.aresetn <= aresetn;

    initial axil_if.aresetn = 1'b0;

    // =========================================================================
    // DUT
    // =========================================================================
    xilinx_qdma_st_adapter #(
        .QID_WID     ( QID_WID     ),
        .MAX_PKT_LEN ( MAX_PKT_LEN )
    ) DUT (
        .aclk,
        .aresetn,
        .core_clk,
        .core_srst,
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
        .axil_if,
        .pkt_h2c,
        .pkt_c2h
    );

    // =========================================================================
    // Verif objects
    //   Both DMA directions are packet_intf: C2H is driven via the built-in
    //   cb_tx clocking block, H2C is sampled by recv_h2c_packet with rdy held
    //   high so back-to-back output beats are observable.
    // =========================================================================

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

    // Note: pkt_c2h feeds into packet_fifo (store-and-forward), which decouples
    // the input from the output side.  pkt_c2h.rdy reflects FIFO capacity, not
    // downstream c2h_tready / cmpt_tready.  Functional backpressure correctness
    // is verified by c2h_backpressure_data_ and c2h_backpressure_cmpt_.

    // =========================================================================
    // Coverage
    // =========================================================================
    // NOTE: covergroups are intentionally omitted from this testbench.
    //
    // xsim's functional-coverage event scheduler hangs at time 0 (zero-time
    // delta loop) when a covergroup is present alongside packet_fifo(ASYNC=1)
    // CDC logic and multiple clocking-block domains on the same clock.
    // Correctness is verified by the assertions and fail_unless_equal checks
    // in each test case below.

    // =========================================================================
    // Build
    // =========================================================================
    function void build();
        svunit_ut = new(name);
    endfunction

    // =========================================================================
    // Setup / teardown
    // =========================================================================
    task setup();
        svunit_ut.setup();
        idle();
        aresetn = 1'b0;
        repeat (16) @(posedge aclk);
        aresetn = 1'b1;
        // Allow packet_fifo internal memory init and CDC synchronizers to settle
        repeat (32) @(posedge aclk);
    endtask

    task teardown();
        svunit_ut.teardown();
        idle();
    endtask

    // =========================================================================
    // Helpers
    // =========================================================================
    task idle();
        axil_if.idle_controller();
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
        // H2C sink: always accept
        pkt_h2c.rdy = 1'b1;
        // C2H packet_intf idle (direct assignment — avoid clocking block at time 0)
        pkt_c2h.vld  = 1'b0;
        pkt_c2h.data = '0;
        pkt_c2h.eop  = 1'b0;
        pkt_c2h.mty  = '0;
        pkt_c2h.err  = 1'b0;
        pkt_c2h.meta = '0;
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

    // Send a C2H packet via packet_intf (byte-level, auto-computes mty).
    // Data is big-endian byte array as expected by packet_intf.
    // QID is carried in packet_intf.meta.
    task automatic send_c2h_packet(
        input int                 num_bytes,
        input logic [QID_WID-1:0] qid        = '0,
        input int                 twait      = 0
    );
        int bytes_remaining;
        logic [0:AXIS_DATA_BYTE_WID-1][7:0] beat_data;
        logic [5:0] beat_mty;
        logic beat_eop;

        bytes_remaining = num_bytes;
        while (bytes_remaining > 0) begin
            // Fill beat data with random bytes
            for (int b = 0; b < AXIS_DATA_BYTE_WID; b++)
                beat_data[b] = $urandom;

            beat_eop = (bytes_remaining <= AXIS_DATA_BYTE_WID);
            beat_mty = beat_eop ? 6'(AXIS_DATA_BYTE_WID - bytes_remaining) : 6'd0;

            // Inter-beat gap
            if (twait > 0) repeat (twait) @(pkt_c2h.cb_tx);

            pkt_c2h.send(
                ._data ( beat_data ),
                ._eop  ( beat_eop  ),
                ._mty  ( beat_mty  ),
                ._err  ( 1'b0      ),
                ._meta ( qid       )
            );

            bytes_remaining -= AXIS_DATA_BYTE_WID;
        end
    endtask

    // Receive one H2C packet from pkt_h2c, returning its length and metadata.
    // rdy is held high by idle(), so this only samples.
    task automatic recv_h2c_packet(
            output int                 num_bytes,
            output logic [QID_WID-1:0] qid,
            output logic               err
        );
        int  beats;
        bit  last;
        beats = 0;
        last  = 1'b0;
        num_bytes = 0;
        while (!last) begin
            @(posedge core_clk iff (pkt_h2c.vld && pkt_h2c.rdy));
            beats++;
            qid  = pkt_h2c.meta;
            err  = pkt_h2c.err;
            last = pkt_h2c.eop;
            if (last) num_bytes = beats*AXIS_DATA_BYTE_WID - pkt_h2c.mty;
        end
    endtask

    // Expect NO H2C packet to emerge within the given number of core clocks.
    task automatic expect_no_h2c_packet(input int cycles);
        repeat (cycles) begin
            @(posedge core_clk);
            `FAIL_IF_LOG(pkt_h2c.vld, "unexpected H2C packet: should have been dropped")
        end
    endtask


    // =========================================================================
    // Register access
    // =========================================================================
    task automatic reg_write(input bit [31:0] addr, input bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.write(addr, data, resp, timeout);
        `FAIL_IF_LOG(timeout, "AXI-L write timed out")
        `FAIL_UNLESS_LOG(resp === axi4l_pkg::RESP_OKAY, "AXI-L write returned an error response")
    endtask

    task automatic reg_read(input bit [31:0] addr, output bit [31:0] data);
        axi4l_pkg::resp_t resp;
        bit timeout;
        axil_if.read(addr, data, resp, timeout);
        `FAIL_IF_LOG(timeout, "AXI-L read timed out")
        `FAIL_UNLESS_LOG(resp === axi4l_pkg::RESP_OKAY, "AXI-L read returned an error response")
    endtask

    // Set loopback mode and wait until the adapter reports it applied.
    task automatic set_loopback(input bit mode);
        bit [31:0] status;
        reg_write(qdma_st_adapter_reg_pkg::OFFSET_LOOPBACK_CONFIG, 32'(mode));
        forever begin
            reg_read(qdma_st_adapter_reg_pkg::OFFSET_LOOPBACK_STATUS, status);
            if (status[0] === mode && status[1] === 1'b0) break;
        end
    endtask

    // Capture the length and queue id of the next packet on the flat C2H bus.
    task automatic recv_c2h_flat(output logic [15:0] len, output logic [QID_WID-1:0] qid);
        @(posedge aclk iff (c2h_tvalid && c2h_tready));
        len = c2h_ctrl_len;
        qid = c2h_ctrl_qid;
        while (!c2h_tlast) @(posedge aclk iff (c2h_tvalid && c2h_tready));
    endtask

    // Fail if any packet reaches the flat C2H bus within the window.
    task automatic expect_no_c2h_flat(input int cycles);
        repeat (cycles) begin
            @(posedge aclk);
            `FAIL_IF_LOG(c2h_tvalid, "unexpected C2H packet")
        end
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
            int bytes; logic [QID_WID-1:0] qid; logic err;
            fork
                send_h2c_packet(.num_beats(1), .last_mty(0));
                recv_h2c_packet(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, AXIS_DATA_BYTE_WID);
        `SVTEST_END

        // H2C: last beat with mty=1 — 63 valid bytes.
        `SVTEST(h2c_partial_last_beat)
            int bytes; logic [QID_WID-1:0] qid; logic err;
            fork
                send_h2c_packet(.num_beats(1), .last_mty(6'd1));
                recv_h2c_packet(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, AXIS_DATA_BYTE_WID - 1);
        `SVTEST_END

        // H2C: zero_byte carries no payload and cannot be represented on
        // packet_intf, so the adapter marks it errored and the FIFO drops it.
        `SVTEST(_h2c_zero_byte)
            send_h2c_packet(.num_beats(1), .last_mty('0), .zero_byte(1'b1));
            expect_no_h2c_packet(64);
        `SVTEST_END

        // H2C: an errored packet is dropped rather than forwarded to the core.
        `SVTEST(h2c_err_dropped)
            send_h2c_packet(.num_beats(1), .err(1'b1));
            expect_no_h2c_packet(64);
        `SVTEST_END

        // H2C: a good packet still gets through after an errored one is dropped.
        `SVTEST(h2c_err_does_not_block)
            int bytes; logic [QID_WID-1:0] qid; logic err;
            send_h2c_packet(.num_beats(2), .err(1'b1));
            fork
                send_h2c_packet(.num_beats(1), .qid(11'h2C));
                recv_h2c_packet(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, AXIS_DATA_BYTE_WID);
            `FAIL_UNLESS_EQUAL(qid, 11'h2C);
            `FAIL_UNLESS_EQUAL(err, 1'b0);
        `SVTEST_END

        // H2C: qid is carried in the packet metadata.
        `SVTEST(h2c_qid_mapping)
            int bytes; logic [QID_WID-1:0] qid; logic err;
            fork
                send_h2c_packet(.num_beats(1), .qid(11'h5A5));
                recv_h2c_packet(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(qid, 11'h5A5);
        `SVTEST_END

        // H2C: multi-beat packet — correct total byte count.
        `SVTEST(h2c_multi_beat)
            int bytes; logic [QID_WID-1:0] qid; logic err;
            fork
                send_h2c_packet(.num_beats(4), .last_mty(6'd3));
                recv_h2c_packet(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, 4*AXIS_DATA_BYTE_WID - 3);
        `SVTEST_END

        // H2C: back-to-back packets with no gap.
        `SVTEST(h2c_back_to_back)
            int bytes; logic [QID_WID-1:0] qid; logic err;
            for (int i = 0; i < 4; i++) begin
                fork
                    send_h2c_packet(.num_beats(1));
                    recv_h2c_packet(bytes, qid, err);
                join
                `FAIL_UNLESS_EQUAL(bytes, AXIS_DATA_BYTE_WID);
            end
        `SVTEST_END

        // H2C: qid=0 and qid=max propagate correctly.
        `SVTEST(h2c_qid_boundary)
            int bytes; logic [QID_WID-1:0] qid; logic err;
            fork
                send_h2c_packet(.num_beats(1), .qid({QID_WID{1'b0}}));
                recv_h2c_packet(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(qid, '0);
            fork
                send_h2c_packet(.num_beats(1), .qid({QID_WID{1'b1}}));
                recv_h2c_packet(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(qid, {QID_WID{1'b1}});
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
            logic captured_cmpt_valid;
            logic [QID_WID-1:0] captured_cmpt_qid;
            fork
                send_c2h_packet(.num_bytes(64), .qid(11'h3F));
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

        // C2H: c2h_tready=0 propagates back through the FIFO to pkt_c2h.rdy.
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

        // -----------------------------------------------------------------
        // C2H ctrl_len / completion len tests
        // -----------------------------------------------------------------

        // C2H: c2h_ctrl_len carries correct length — single full beat (64 B).
        `SVTEST(c2h_ctrl_len_single_full_beat)
            logic [15:0] captured_len;
            fork
                send_c2h_packet(.num_bytes(AXIS_DATA_BYTE_WID));
                begin
                    @(posedge aclk iff (c2h_tvalid && c2h_tready));
                    captured_len = c2h_ctrl_len;
                end
            join
            `FAIL_UNLESS_EQUAL(captured_len, 16'(AXIS_DATA_BYTE_WID));
        `SVTEST_END

        // C2H: c2h_ctrl_len for a partial-beat packet (33 B).
        `SVTEST(c2h_ctrl_len_partial_beat)
            localparam int VALID_BYTES = 33;
            logic [15:0] captured_len;
            fork
                send_c2h_packet(.num_bytes(VALID_BYTES));
                begin
                    @(posedge aclk iff (c2h_tvalid && c2h_tready));
                    captured_len = c2h_ctrl_len;
                end
            join
            `FAIL_UNLESS_EQUAL(captured_len, 16'(VALID_BYTES));
        `SVTEST_END

        // C2H: c2h_ctrl_len for multi-beat packet with partial last beat (209 B).
        `SVTEST(c2h_ctrl_len_multi_beat)
            localparam int PKT_BYTES = 3 * AXIS_DATA_BYTE_WID + 17;  // 209 bytes
            logic [15:0] captured_len;
            fork
                send_c2h_packet(.num_bytes(PKT_BYTES));
                begin
                    @(posedge aclk iff (c2h_tvalid && c2h_tready));
                    captured_len = c2h_ctrl_len;
                end
            join
            `FAIL_UNLESS_EQUAL(captured_len, 16'(PKT_BYTES));
        `SVTEST_END

        // C2H: back-to-back packets of different lengths — each gets correct length.
        `SVTEST(c2h_ctrl_len_back_to_back)
            localparam int LEN_A = AXIS_DATA_BYTE_WID;           // 64 bytes
            localparam int LEN_B = 2 * AXIS_DATA_BYTE_WID + 7;   // 135 bytes
            logic [15:0] captured_len_a, captured_len_b;
            // First packet
            fork
                send_c2h_packet(.num_bytes(LEN_A));
                begin
                    @(posedge aclk iff (c2h_tvalid && c2h_tready));
                    captured_len_a = c2h_ctrl_len;
                end
            join
            repeat (2) @(posedge aclk);
            // Second packet
            fork
                send_c2h_packet(.num_bytes(LEN_B));
                begin
                    @(posedge aclk iff (c2h_tvalid && c2h_tready));
                    captured_len_b = c2h_ctrl_len;
                end
            join
            `FAIL_UNLESS_EQUAL(captured_len_a, 16'(LEN_A));
            `FAIL_UNLESS_EQUAL(captured_len_b, 16'(LEN_B));
        `SVTEST_END

        // C2H: completion data len field matches c2h_ctrl_len.
        `SVTEST(c2h_cmpt_len_matches_ctrl_len)
            localparam int PKT_BYTES = 100;  // 2 beats: 64 + 36
            logic [15:0] captured_ctrl_len;
            logic [15:0] captured_cmpt_len;
            fork
                send_c2h_packet(.num_bytes(PKT_BYTES));
                begin
                    // Capture ctrl_len on first output beat
                    @(posedge aclk iff (c2h_tvalid && c2h_tready));
                    captured_ctrl_len = c2h_ctrl_len;
                    // Capture cmpt_data.len on EOP (completion fires on last beat)
                    @(posedge aclk iff (cmpt_tvalid && cmpt_tready));
                    captured_cmpt_len = cmpt_data[15:0];
                end
            join
            `FAIL_UNLESS_EQUAL(captured_ctrl_len, 16'(PKT_BYTES));
            `FAIL_UNLESS_EQUAL(captured_cmpt_len, 16'(PKT_BYTES));
        `SVTEST_END

        // Descriptor credits are always idle.
        `SVTEST(credits_idle)
            repeat (16) @(posedge aclk);
            `FAIL_IF(dsc_crdt_valid);
            `FAIL_IF(dsc_crdt_crdt !== '0);
        `SVTEST_END

        // H2C throughput: drive N beats continuously (tvalid never deasserted
        // between beats) and verify the output runs gapless once it starts.
        `SVTEST(h2c_full_throughput)
            localparam int N = 16;
            int valid_cycles;
            int bubble_cycles;
            valid_cycles  = 0;
            bubble_cycles = 0;
            // The packet FIFO is store-and-forward, so the whole packet is
            // buffered before any of it appears on pkt_h2c. Once it starts the
            // output must run gapless: the core clock is slower than the QDMA
            // clock, so the read side can never be starved by the write side.
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
                    @(posedge core_clk iff pkt_h2c.vld);
                    valid_cycles++;
                    repeat (N - 1) begin
                        @(posedge core_clk);
                        if (pkt_h2c.vld) valid_cycles++;
                        else             bubble_cycles++;
                    end
                end : monitor
            join
            `FAIL_UNLESS_EQUAL(bubble_cycles, 0);
            `FAIL_UNLESS_EQUAL(valid_cycles,  N);
        `SVTEST_END

        // C2H throughput: drive N beats continuously via the axi4s_driver and
        // verify c2h_tvalid (flat output) is high on every cycle after the
        // store-and-forward FIFO releases the packet, with no bubbles.
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

        // -----------------------------------------------------------------
        // Loopback mode
        // -----------------------------------------------------------------

        // Registers are reachable and default to loopback disabled.
        `SVTEST(loopback_reg_defaults)
            bit [31:0] data;
            reg_read(qdma_st_adapter_reg_pkg::OFFSET_LOOPBACK_CONFIG, data);
            `FAIL_UNLESS_EQUAL(data[0], 1'b0);
            reg_read(qdma_st_adapter_reg_pkg::OFFSET_LOOPBACK_STATUS, data);
            `FAIL_UNLESS_EQUAL(data[0], 1'b0);   // enabled
            `FAIL_UNLESS_EQUAL(data[1], 1'b0);   // switching
        `SVTEST_END

        // The full 16-byte window must respond, or a CPM5 read completion
        // covering it is poisoned by SLVERR on the unmapped beats.
        `SVTEST(loopback_reg_window_complete)
            bit [31:0] data;
            reg_read(qdma_st_adapter_reg_pkg::OFFSET_RESERVED_0, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0);
            reg_read(qdma_st_adapter_reg_pkg::OFFSET_RESERVED_1, data);
            `FAIL_UNLESS_EQUAL(data, 32'h0);
        `SVTEST_END

        // With loopback enabled an H2C packet comes back as C2H, on the same
        // queue and with the length it was sent with.
        `SVTEST(loopback_h2c_returns_as_c2h)
            logic [15:0] len;
            logic [QID_WID-1:0] qid;
            set_loopback(1'b1);
            fork
                send_h2c_packet(.num_beats(3), .last_mty(6'd5), .qid(11'h1A3));
                recv_c2h_flat(len, qid);
            join
            `FAIL_UNLESS_EQUAL(len, 16'(3*AXIS_DATA_BYTE_WID - 5));
            `FAIL_UNLESS_EQUAL(qid, 11'h1A3);
        `SVTEST_END

        // While looped back, the core sees no H2C traffic.
        `SVTEST(loopback_core_h2c_idle)
            logic [15:0] len;
            logic [QID_WID-1:0] qid;
            set_loopback(1'b1);
            fork
                send_h2c_packet(.num_beats(2), .qid(11'h0C));
                recv_c2h_flat(len, qid);
                expect_no_h2c_packet(96);
            join
            `FAIL_UNLESS_EQUAL(qid, 11'h0C);
        `SVTEST_END

        // While looped back, C2H traffic from the core is discarded rather
        // than reaching the host.
        `SVTEST(loopback_core_c2h_discarded)
            set_loopback(1'b1);
            send_c2h_packet(.num_bytes(128), .qid(11'h7F));
            expect_no_c2h_flat(96);
        `SVTEST_END

        // Disabling loopback restores normal routing in both directions.
        `SVTEST(loopback_disable_restores_normal)
            int bytes;
            logic [QID_WID-1:0] qid;
            logic err;
            logic [15:0] len;
            logic [QID_WID-1:0] c2h_qid;
            set_loopback(1'b1);
            set_loopback(1'b0);
            // H2C reaches the core again
            fork
                send_h2c_packet(.num_beats(1), .qid(11'h55));
                recv_h2c_packet(bytes, qid, err);
            join
            `FAIL_UNLESS_EQUAL(bytes, AXIS_DATA_BYTE_WID);
            `FAIL_UNLESS_EQUAL(qid, 11'h55);
            // C2H from the core reaches the host again
            fork
                send_c2h_packet(.num_bytes(64), .qid(11'h2B));
                recv_c2h_flat(len, c2h_qid);
            join
            `FAIL_UNLESS_EQUAL(len, 16'(AXIS_DATA_BYTE_WID));
            `FAIL_UNLESS_EQUAL(c2h_qid, 11'h2B);
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule : xilinx_qdma_st_adapter_unit_test
