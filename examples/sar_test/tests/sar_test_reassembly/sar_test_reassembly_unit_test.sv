`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 10ms

module sar_test_reassembly_unit_test;

    string name = "sar_test_reassembly_ut";
    svunit_pkg::svunit_testcase svunit_ut;

    //===================================
    // DUT + testbench
    //===================================
    tb_pkg::tb_env env;

    //===================================
    // Shared agents + helpers
    //===================================
    `include "../common/sar_test_helpers.svh"

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);
        env = tb.build();
        sar_test_build(env);
    endfunction

    //===================================
    // Setup
    //===================================
    task setup();
        svunit_ut.setup();
        env.run();
        #100ns;
        sar_test_setup();
    endtask

    //===================================
    // Teardown
    //===================================
    task teardown();
        env.stop();
        svunit_ut.teardown();
    endtask

    //=======================================================================
    // TESTS
    //=======================================================================
    `SVUNIT_TESTS_BEGIN

    // -----------------------------------------------------------------------
    // Register sanity: verify sar_test ID register and info registers.
    // Mirrors: SAR Reassembly - Register Sanity
    // -----------------------------------------------------------------------
    `SVTEST(reasm_sanity)
        sar_reassembly_reg_pkg::reg_info_t       info;
        sar_reassembly_reg_pkg::reg_info_frame_t info_frame;

        reasm_ra.read_info(info);
        `FAIL_UNLESS_LOG(info.num_frame_buffers == SAR_NUM_FRAME_BUFFERS,
            $sformatf("info.num_frame_buffers: got %0d, expected %0d",
                      info.num_frame_buffers, SAR_NUM_FRAME_BUFFERS))
        `FAIL_UNLESS_LOG(info.max_fragments > 0, "info.max_fragments must be > 0")

        reasm_ra.read_info_frame(info_frame);
        `FAIL_UNLESS_LOG(info_frame.max_size == SAR_MAX_FRAME_SIZE,
            $sformatf("info_frame.max_size: got %0d, expected %0d",
                      info_frame.max_size, SAR_MAX_FRAME_SIZE))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Single-segment frame: 64 B into buf_id=0
    // Mirrors: SAR Reassembly - Single Segment Frame - 64B
    // -----------------------------------------------------------------------
    `SVTEST(reasm_single_64)
        automatic int  frame_size = 64;
        automatic int  buf_id     = 0;
        automatic byte frame[];
        automatic byte readback[];
        automatic bit  ok;

        random_bytes(frame_size, frame);
        reasm_clear_dbg_counts();

        // Send single segment with is_last=1
        begin
            automatic bit[18:0] meta = make_reassembly_meta(buf_id, 0, 1'b1);
            send_segment(frame, meta);
        end

        reasm_wait_done(1, ok);
        `FAIL_IF_LOG(!ok, "reasm_single_64: timed out waiting for done count")

        read_frame_from_hbm(buf_id, frame_size, readback);
        foreach (frame[i])
            `FAIL_UNLESS_LOG(readback[i] == frame[i],
                $sformatf("byte[%0d]: got 0x%02x, expected 0x%02x",
                          i, readback[i], frame[i]))

        begin
            automatic int done_cnt;
            reasm_ra.get_done_cnt(done_cnt);
            `FAIL_UNLESS_LOG(done_cnt == 1,
                $sformatf("done_cnt: got %0d, expected 1", done_cnt))
        end
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Single-segment frame: 512 B into buf_id=1
    // Mirrors: SAR Reassembly - Single Segment Frame - 512B
    // -----------------------------------------------------------------------
    `SVTEST(reasm_single_512)
        automatic int  frame_size = 512;
        automatic int  buf_id     = 1;
        automatic byte frame[];
        automatic byte readback[];
        automatic bit  ok;

        random_bytes(frame_size, frame);
        reasm_clear_dbg_counts();

        begin
            automatic bit[18:0] meta = make_reassembly_meta(buf_id, 0, 1'b1);
            send_segment(frame, meta);
        end

        reasm_wait_done(1, ok);
        `FAIL_IF_LOG(!ok, "reasm_single_512: timed out waiting for done count")

        read_frame_from_hbm(buf_id, frame_size, readback);
        foreach (frame[i])
            `FAIL_UNLESS_LOG(readback[i] == frame[i],
                $sformatf("byte[%0d]: got 0x%02x, expected 0x%02x",
                          i, readback[i], frame[i]))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Multi-segment in-order: 4096 B (8 x 512 B) into buf_id=0
    // Mirrors: SAR Reassembly - In-Order 4096B
    // -----------------------------------------------------------------------
    `SVTEST(reasm_multi_in_order_4096)
        automatic int  frame_size = 4096;
        automatic int  seg_len    = SAR_DEFAULT_SEG_LEN;
        automatic int  buf_id     = 0;
        automatic byte frame[];
        automatic byte readback[];
        automatic bit  ok;

        random_bytes(frame_size, frame);
        reasm_clear_dbg_counts();

        send_frame_segments(frame, buf_id, seg_len);

        reasm_wait_done(1, ok);
        `FAIL_IF_LOG(!ok, "reasm_multi_in_order_4096: timed out waiting for done count")

        read_frame_from_hbm(buf_id, frame_size, readback);
        foreach (frame[i])
            `FAIL_UNLESS_LOG(readback[i] == frame[i],
                $sformatf("byte[%0d]: got 0x%02x, expected 0x%02x",
                          i, readback[i], frame[i]))

        begin
            automatic int done_cnt;
            reasm_ra.get_done_cnt(done_cnt);
            `FAIL_UNLESS_LOG(done_cnt == 1,
                $sformatf("done_cnt: got %0d, expected 1", done_cnt))
        end
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Multi-segment in-order: 9216 B (18 x 512 B) into buf_id=0
    // Mirrors: SAR Reassembly - In-Order 9216B
    // -----------------------------------------------------------------------
    `SVTEST(reasm_multi_in_order_9216)
        automatic int  frame_size = 9216;
        automatic int  seg_len    = SAR_DEFAULT_SEG_LEN;
        automatic int  buf_id     = 0;
        automatic byte frame[];
        automatic byte readback[];
        automatic bit  ok;

        random_bytes(frame_size, frame);
        reasm_clear_dbg_counts();

        send_frame_segments(frame, buf_id, seg_len);

        reasm_wait_done(1, ok);
        `FAIL_IF_LOG(!ok, "reasm_multi_in_order_9216: timed out waiting for done count")

        read_frame_from_hbm(buf_id, frame_size, readback);
        foreach (frame[i])
            `FAIL_UNLESS_LOG(readback[i] == frame[i],
                $sformatf("byte[%0d]: got 0x%02x, expected 0x%02x",
                          i, readback[i], frame[i]))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Out-of-order segments: 4096 B, shuffle non-last segments
    // Mirrors: SAR Reassembly - Out-of-Order
    // -----------------------------------------------------------------------
    `SVTEST(reasm_out_of_order)
        automatic int  frame_size = 4096;
        automatic int  seg_len    = SAR_DEFAULT_SEG_LEN;
        automatic int  buf_id     = 0;
        automatic int  n_segs     = n_segments(frame_size, seg_len);
        automatic byte frame[];
        automatic byte readback[];
        automatic bit  ok;

        random_bytes(frame_size, frame);
        reasm_clear_dbg_counts();

        // Send in reverse order (last segment first as non-last, then others, then real last)
        // Strategy: send segs n-2..0 (non-last, shuffled), then send seg n-1 (last)
        begin
            automatic byte seg_data[];
            automatic bit[18:0] meta;
            // Non-last segments in reverse order
            for (int i = n_segs - 2; i >= 0; i--) begin
                automatic int offset    = i * seg_len;
                automatic int seg_bytes = (frame_size - offset < seg_len) ?
                                           frame_size - offset : seg_len;
                seg_data = new[seg_bytes];
                for (int j = 0; j < seg_bytes; j++)
                    seg_data[j] = frame[offset + j];
                meta = make_reassembly_meta(buf_id, offset, 1'b0);
                send_segment(seg_data, meta);
            end
            // Last segment
            begin
                automatic int offset    = (n_segs - 1) * seg_len;
                automatic int seg_bytes = frame_size - offset;
                seg_data = new[seg_bytes];
                for (int j = 0; j < seg_bytes; j++)
                    seg_data[j] = frame[offset + j];
                meta = make_reassembly_meta(buf_id, offset, 1'b1);
                send_segment(seg_data, meta);
            end
        end

        reasm_wait_done(1, ok);
        `FAIL_IF_LOG(!ok, "reasm_out_of_order: timed out waiting for done count")

        read_frame_from_hbm(buf_id, frame_size, readback);
        foreach (frame[i])
            `FAIL_UNLESS_LOG(readback[i] == frame[i],
                $sformatf("byte[%0d]: got 0x%02x, expected 0x%02x", i, readback[i], frame[i]))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Multi-frame interleaved: 4 frames, round-robin segment ordering
    // Mirrors: SAR Reassembly - Multi-Frame Interleaved
    // -----------------------------------------------------------------------
    `SVTEST(reasm_interleaved)
        automatic int  num_frames = 4;
        automatic int  frame_size = SAR_DEFAULT_SEG_LEN * 4; // 4 segs each
        automatic int  seg_len    = SAR_DEFAULT_SEG_LEN;
        automatic int  n_segs     = n_segments(frame_size, seg_len);
        automatic byte frames[][]; // [frame_idx][byte_idx]
        automatic bit  ok;

        frames = new[num_frames];
        reasm_clear_dbg_counts();

        for (int fi = 0; fi < num_frames; fi++)
            random_bytes(frame_size, frames[fi]);

        // Interleave: for each segment position, send one segment from each frame
        for (int si = 0; si < n_segs; si++) begin
            for (int fi = 0; fi < num_frames; fi++) begin
                automatic int  buf_id     = fi;
                automatic int  offset     = si * seg_len;
                automatic int  seg_bytes  = (frame_size - offset < seg_len) ?
                                             frame_size - offset : seg_len;
                automatic bit  is_last    = (si == n_segs - 1) ? 1'b1 : 1'b0;
                automatic byte seg_data[];
                automatic bit[18:0] meta;
                seg_data = new[seg_bytes];
                for (int j = 0; j < seg_bytes; j++)
                    seg_data[j] = frames[fi][offset + j];
                meta = make_reassembly_meta(buf_id, offset, is_last);
                send_segment(seg_data, meta);
            end
        end

        reasm_wait_done(num_frames, ok);
        `FAIL_IF_LOG(!ok, "reasm_interleaved: timed out waiting for done count")

        // Verify all frames
        for (int fi = 0; fi < num_frames; fi++) begin
            automatic byte readback[];
            read_frame_from_hbm(fi, frame_size, readback);
            foreach (frames[fi][i])
                `FAIL_UNLESS_LOG(readback[i] == frames[fi][i],
                    $sformatf("frame[%0d] byte[%0d]: got 0x%02x, expected 0x%02x",
                              fi, i, readback[i], frames[fi][i]))
        end

        begin
            automatic int done_cnt;
            reasm_ra.get_done_cnt(done_cnt);
            `FAIL_UNLESS_LOG(done_cnt == num_frames,
                $sformatf("done_cnt: got %0d, expected %0d", done_cnt, num_frames))
        end
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Fragment timeout: send one incomplete segment, wait for expiry.
    // Mirrors: SAR Reassembly - Fragment Timeout
    //
    // Timing: ms_tick fires every TCLK_PER_TICK=125_000 DUT clk cycles
    // (~364 µs at 343.75 MHz).  cfg_timeout=1 tick means expiry after the
    // very first ms_tick.  We wait 5 ticks to give state_notify_fsm time
    // to complete one full scan after the tick fires.  A single AXI-L read
    // is then enough; no tight polling loop (which would drive thousands of
    // AXI-L transactions and make xsim run for hours on a complex design).
    // -----------------------------------------------------------------------
    `SVTEST(reasm_timeout)
        automatic byte seg_data[];
        automatic bit[18:0] meta;
        automatic int expired_cnt;
        automatic int frag_exp_cnt;

        // Set a short timeout: expire after the first ms_tick (1 tick ≈ 364 µs)
        reasm_ra.state.check.set_timeout(FRAG_TIMEOUT_SIM_TICKS);

        reasm_clear_dbg_counts();

        // Send one segment without is_last — leaves an incomplete reassembly entry
        random_bytes(64, seg_data);
        meta = make_reassembly_meta(0, 0, 1'b0); // is_last=0
        send_segment(seg_data, meta);

        // Wait 5 ms_ticks so the timer definitely advances past the threshold
        // and state_notify_fsm has time to complete at least one full scan.
        // Each tick = 125_000 DUT clk cycles = ~364 µs sim time.
        #(5 * FRAG_TICK_NS * 1ns);

        // One read — no polling loop
        reasm_ra.state.check.get_fragment_expired_cnt(frag_exp_cnt);
        `FAIL_UNLESS_LOG(frag_exp_cnt >= 1,
            $sformatf("fragment_expired: got %0d, expected >= 1", frag_exp_cnt))

        // Give deletion FSM a moment to process the expired entry, then check
        #(2 * FRAG_TICK_NS * 1ns);
        reasm_ra.get_expired_cnt(expired_cnt);
        `FAIL_UNLESS_LOG(expired_cnt >= 1,
            $sformatf("expired_ops: got %0d, expected >= 1", expired_cnt))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Debug counter verification: 10 frames, check done_ops total
    // Mirrors: SAR Reassembly - Debug Counters
    // -----------------------------------------------------------------------
    `SVTEST(reasm_debug_counters)
        automatic int  num_frames  = 10;
        automatic int  seg_len     = SAR_DEFAULT_SEG_LEN;
        automatic bit  ok;
        automatic int  done_cnt;

        reasm_clear_dbg_counts();

        for (int i = 0; i < num_frames; i++) begin
            automatic int  frame_size = 512 * ((i % 4) + 1); // 512, 1024, 1536, 2048 cycling
            automatic int  buf_id     = i % SAR_NUM_FRAME_BUFFERS;
            automatic byte frame[];
            random_bytes(frame_size, frame);
            send_frame_segments(frame, buf_id, seg_len);
        end

        reasm_wait_done(num_frames, ok);
        `FAIL_IF_LOG(!ok, $sformatf("reasm_debug_counters: timed out before %0d frames done",
                                    num_frames))

        reasm_ra.get_done_cnt(done_cnt);
        `FAIL_UNLESS_LOG(done_cnt == num_frames,
            $sformatf("done_cnt: got %0d, expected %0d", done_cnt, num_frames))
    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
