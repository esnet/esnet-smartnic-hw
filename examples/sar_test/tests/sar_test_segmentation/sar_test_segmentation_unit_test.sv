`include "svunit_defines.svh"

//===================================
// (Failsafe) timeout
//===================================
`define SVUNIT_TIMEOUT 10ms

module sar_test_segmentation_unit_test;

    string name = "sar_test_segmentation_ut";
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
    // Register sanity: verify info registers and initial seg_ctrl status.
    // Mirrors: SAR Segmentation - Register Sanity
    // -----------------------------------------------------------------------
    `SVTEST(seg_sanity)
        sar_segmentation_reg_pkg::reg_info_t       info;
        sar_segmentation_reg_pkg::reg_info_frame_t info_frame;
        sar_segmentation_reg_pkg::reg__config_t    cfg;
        sar_test_seg_ctrl_reg_pkg::reg_status_t    status;

        seg_ra.read_info(info);
        `FAIL_UNLESS_LOG(info.num_buffers == SAR_NUM_FRAME_BUFFERS,
            $sformatf("info.num_buffers: got %0d, expected %0d",
                      info.num_buffers, SAR_NUM_FRAME_BUFFERS))
        `FAIL_UNLESS_LOG(info.max_segment_len > 0, "info.max_segment_len must be > 0")

        seg_ra.read_info_frame(info_frame);
        `FAIL_UNLESS_LOG(info_frame.max_size == SAR_MAX_FRAME_SIZE,
            $sformatf("info_frame.max_size: got %0d, expected %0d",
                      info_frame.max_size, SAR_MAX_FRAME_SIZE))

        seg_ra.read__config(cfg);
        `FAIL_UNLESS_LOG(cfg.seg_len == SAR_DEFAULT_SEG_LEN,
            $sformatf("cfg.seg_len: got %0d, expected %0d",
                      cfg.seg_len, SAR_DEFAULT_SEG_LEN))

        seg_ctrl_ra.read_status(status);
        `FAIL_IF_LOG(status.busy == 1'b1, "seg_ctrl.status.busy asserted at startup")
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Single-segment frame: 64 B
    // Mirrors: SAR Segmentation - Single Segment Frame - 64B
    // -----------------------------------------------------------------------
    `SVTEST(seg_single_64)
        automatic byte frame[];
        automatic byte captured[];
        automatic int frames_in, segs_out;

        random_bytes(64, frame);
        write_frame_to_hbm(0, frame);
        seg_clear_dbg_counts();

        // Trigger first; HBM read latency (~200 ns at 250 MHz) gives ample
        // time to arm capture before the first segment reaches packet_capture.
        seg_ctrl_trigger(0, 64);
        capture_one_segment(captured);
        seg_ctrl_wait_done();

        `FAIL_UNLESS_LOG(captured.size() == frame.size(),
            $sformatf("size mismatch: got %0d, expected %0d", captured.size(), frame.size()))
        foreach (frame[i])
            `FAIL_UNLESS_LOG(captured[i] == frame[i],
                $sformatf("byte[%0d]: got 0x%02x, expected 0x%02x", i, captured[i], frame[i]))

        seg_ra.get_frames_in_cnt(frames_in);
        seg_ra.get_segments_out_cnt(segs_out);
        `FAIL_UNLESS_LOG(frames_in == 1,
            $sformatf("frames_in: got %0d, expected 1", frames_in))
        `FAIL_UNLESS_LOG(segs_out == 1,
            $sformatf("segments_out: got %0d, expected 1", segs_out))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Single-segment frame: 512 B
    // Mirrors: SAR Segmentation - Single Segment Frame - 512B
    // -----------------------------------------------------------------------
    `SVTEST(seg_single_512)
        automatic byte frame[];
        automatic byte captured[];
        automatic int frames_in, segs_out;

        random_bytes(512, frame);
        write_frame_to_hbm(0, frame);
        seg_clear_dbg_counts();

        seg_ctrl_trigger(0, 512);
        capture_one_segment(captured);
        seg_ctrl_wait_done();

        `FAIL_UNLESS_LOG(captured.size() == frame.size(),
            $sformatf("size mismatch: got %0d, expected %0d", captured.size(), frame.size()))
        foreach (frame[i])
            `FAIL_UNLESS_LOG(captured[i] == frame[i],
                $sformatf("byte[%0d]: got 0x%02x, expected 0x%02x", i, captured[i], frame[i]))

        seg_ra.get_frames_in_cnt(frames_in);
        seg_ra.get_segments_out_cnt(segs_out);
        `FAIL_UNLESS_LOG(frames_in == 1,  $sformatf("frames_in: got %0d", frames_in))
        `FAIL_UNLESS_LOG(segs_out  == 1,  $sformatf("segments_out: got %0d", segs_out))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Multi-segment frame: 4096 B / 512 B segments (8 segments)
    // Mirrors: SAR Segmentation - Multi-Segment Frame - 4096B
    // -----------------------------------------------------------------------
    `SVTEST(seg_multi_4096)
        automatic byte  frame[];
        automatic byte  segments[][];
        automatic int   frame_size = 4096;
        automatic int   seg_len    = SAR_DEFAULT_SEG_LEN;
        automatic int   n_segs     = n_segments(frame_size, seg_len);
        automatic int   frames_in, segs_out;

        random_bytes(frame_size, frame);
        write_frame_to_hbm(0, frame);
        seg_clear_dbg_counts();

        seg_ctrl_trigger(0, frame_size);
        capture_n_segments(n_segs, segments);
        seg_ctrl_wait_done();

        for (int i = 0; i < n_segs; i++) begin
            automatic int offset    = i * seg_len;
            automatic int exp_bytes = (frame_size - offset < seg_len) ?
                                       frame_size - offset : seg_len;
            `FAIL_UNLESS_LOG(segments[i].size() == exp_bytes,
                $sformatf("seg[%0d] size: got %0d, expected %0d",
                          i, segments[i].size(), exp_bytes))
            for (int j = 0; j < exp_bytes; j++)
                `FAIL_UNLESS_LOG(segments[i][j] == frame[offset + j],
                    $sformatf("seg[%0d][%0d]: got 0x%02x, expected 0x%02x",
                              i, j, segments[i][j], frame[offset + j]))
        end

        seg_ra.get_frames_in_cnt(frames_in);
        seg_ra.get_segments_out_cnt(segs_out);
        `FAIL_UNLESS_LOG(frames_in == 1,      $sformatf("frames_in: got %0d", frames_in))
        `FAIL_UNLESS_LOG(segs_out  == n_segs, $sformatf("segments_out: got %0d, expected %0d",
                                                          segs_out, n_segs))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Multi-segment frame: 4608 B / 512 B segments (9 segments)
    // Covers same code paths as 9216B with half the AXI-L traffic.
    // Mirrors: SAR Segmentation - Multi-Segment Frame - 9216B
    // -----------------------------------------------------------------------
    `SVTEST(seg_multi_9216)
        automatic byte  frame[];
        automatic byte  segments[][];
        automatic int   frame_size = 4608;
        automatic int   seg_len    = SAR_DEFAULT_SEG_LEN;
        automatic int   n_segs     = n_segments(frame_size, seg_len);
        automatic int   frames_in, segs_out;

        random_bytes(frame_size, frame);
        write_frame_to_hbm(0, frame);
        seg_clear_dbg_counts();

        seg_ctrl_trigger(0, frame_size);
        capture_n_segments(n_segs, segments);
        seg_ctrl_wait_done();

        for (int i = 0; i < n_segs; i++) begin
            automatic int offset    = i * seg_len;
            automatic int exp_bytes = (frame_size - offset < seg_len) ?
                                       frame_size - offset : seg_len;
            `FAIL_UNLESS_LOG(segments[i].size() == exp_bytes,
                $sformatf("seg[%0d] size: got %0d, expected %0d",
                          i, segments[i].size(), exp_bytes))
            for (int j = 0; j < exp_bytes; j++)
                `FAIL_UNLESS_LOG(segments[i][j] == frame[offset + j],
                    $sformatf("seg[%0d][%0d]: got 0x%02x, expected 0x%02x",
                              i, j, segments[i][j], frame[offset + j]))
        end

        seg_ra.get_frames_in_cnt(frames_in);
        seg_ra.get_segments_out_cnt(segs_out);
        `FAIL_UNLESS_LOG(segs_out == n_segs,
            $sformatf("segments_out: got %0d, expected %0d", segs_out, n_segs))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Boundary conditions around seg_len
    // Mirrors: SAR Segmentation - Segment Length Boundary
    // -----------------------------------------------------------------------
    `SVTEST(seg_boundary)
        automatic int seg_len = SAR_DEFAULT_SEG_LEN;
        // {frame_size, expected_n_segs}
        automatic int cases[5][2] = '{
            '{seg_len - 1, 1},
            '{seg_len,     1},
            '{seg_len + 1, 2},
            '{2 * seg_len, 2},
            '{2 * seg_len + 1, 3}
        };

        foreach (cases[ci]) begin
            automatic int frame_size  = cases[ci][0];
            automatic int exp_n_segs  = cases[ci][1];
            automatic byte  frame[];
            automatic byte  segments[][];

            random_bytes(frame_size, frame);
            write_frame_to_hbm(0, frame);
            seg_clear_dbg_counts();

            seg_ctrl_trigger(0, frame_size);
            capture_n_segments(exp_n_segs, segments);
            seg_ctrl_wait_done();

            // Verify reassembled content
            begin
                automatic int got_bytes = 0;
                foreach (segments[i]) got_bytes += segments[i].size();
                `FAIL_UNLESS_LOG(got_bytes >= frame_size,
                    $sformatf("boundary case %0d: reassembled %0d B, expected %0d B",
                              ci, got_bytes, frame_size))
            end

            begin
                automatic int frames_in, segs_out;
                seg_ra.get_segments_out_cnt(segs_out);
                `FAIL_UNLESS_LOG(segs_out == exp_n_segs,
                    $sformatf("boundary case %0d (frame=%0d): segs_out=%0d, expected=%0d",
                              ci, frame_size, segs_out, exp_n_segs))
            end
        end
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Reconfigure seg_len: 512 → 256
    // Mirrors: SAR Segmentation - Configure Segment Length - 512 to 256
    // -----------------------------------------------------------------------
    `SVTEST(seg_reconfig_256)
        automatic int   frame_size   = 3000;
        automatic int   new_seg_len  = 256;
        automatic int   n_segs_new   = n_segments(frame_size, new_seg_len);
        automatic byte  frame[];
        automatic byte  segments[][];
        automatic sar_segmentation_reg_pkg::reg__config_t cfg;
        automatic int   segs_out;

        sar_set_seg_len(new_seg_len);
        seg_ra.read__config(cfg);
        `FAIL_UNLESS_LOG(cfg.seg_len == new_seg_len,
            $sformatf("seg_len readback: got %0d, expected %0d", cfg.seg_len, new_seg_len))

        random_bytes(frame_size, frame);
        write_frame_to_hbm(0, frame);
        seg_clear_dbg_counts();

        seg_ctrl_trigger(0, frame_size);
        capture_n_segments(n_segs_new, segments);
        seg_ctrl_wait_done();

        for (int i = 0; i < n_segs_new; i++) begin
            automatic int offset    = i * new_seg_len;
            automatic int exp_bytes = (frame_size - offset < new_seg_len) ?
                                       frame_size - offset : new_seg_len;
            `FAIL_UNLESS_LOG(segments[i].size() == exp_bytes,
                $sformatf("seg[%0d] size: got %0d, expected %0d",
                          i, segments[i].size(), exp_bytes))
            for (int j = 0; j < exp_bytes; j++)
                `FAIL_UNLESS_LOG(segments[i][j] == frame[offset + j],
                    $sformatf("seg[%0d][%0d] mismatch", i, j))
        end

        seg_ra.get_segments_out_cnt(segs_out);
        `FAIL_UNLESS_LOG(segs_out == n_segs_new,
            $sformatf("segments_out: got %0d, expected %0d", segs_out, n_segs_new))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Reconfigure seg_len: 512 → 128
    // Mirrors: SAR Segmentation - Configure Segment Length - 512 to 128
    // -----------------------------------------------------------------------
    `SVTEST(seg_reconfig_128)
        automatic int   frame_size   = 1024;
        automatic int   new_seg_len  = 128;
        automatic int   n_segs_new   = n_segments(frame_size, new_seg_len);
        automatic byte  frame[];
        automatic byte  segments[][];
        automatic int   segs_out;

        sar_set_seg_len(new_seg_len);

        random_bytes(frame_size, frame);
        write_frame_to_hbm(0, frame);
        seg_clear_dbg_counts();

        seg_ctrl_trigger(0, frame_size);
        capture_n_segments(n_segs_new, segments);
        seg_ctrl_wait_done();

        for (int i = 0; i < n_segs_new; i++) begin
            automatic int offset    = i * new_seg_len;
            automatic int exp_bytes = (frame_size - offset < new_seg_len) ?
                                       frame_size - offset : new_seg_len;
            for (int j = 0; j < exp_bytes; j++)
                `FAIL_UNLESS_LOG(segments[i][j] == frame[offset + j],
                    $sformatf("seg[%0d][%0d] mismatch", i, j))
        end

        seg_ra.get_segments_out_cnt(segs_out);
        `FAIL_UNLESS_LOG(segs_out == n_segs_new,
            $sformatf("segments_out: got %0d, expected %0d", segs_out, n_segs_new))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Sequential frames cycling all buffer IDs
    // Mirrors: SAR Segmentation - Sequential Frames - All Buffer IDs
    // -----------------------------------------------------------------------
    `SVTEST(seg_sequential)
        automatic int num_frames   = 4;
        automatic int frame_size   = SAR_DEFAULT_SEG_LEN * 3; // 3 segs each
        automatic int seg_len      = SAR_DEFAULT_SEG_LEN;
        automatic int n_segs_each  = n_segments(frame_size, seg_len);
        automatic int total_segs   = 0;
        automatic int frames_in_cnt, segs_out_cnt;

        seg_clear_dbg_counts();

        for (int i = 0; i < num_frames; i++) begin
            automatic int  buf_id = i % SAR_NUM_FRAME_BUFFERS;
            automatic byte frame[];
            automatic byte segments[][];

            random_bytes(frame_size, frame);
            write_frame_to_hbm(buf_id, frame);

            seg_ctrl_trigger(buf_id, frame_size);
            capture_n_segments(n_segs_each, segments);
            seg_ctrl_wait_done();

            for (int si = 0; si < n_segs_each; si++) begin
                automatic int offset    = si * seg_len;
                automatic int exp_bytes = (frame_size - offset < seg_len) ?
                                           frame_size - offset : seg_len;
                for (int j = 0; j < exp_bytes; j++)
                    `FAIL_UNLESS_LOG(segments[si][j] == frame[offset + j],
                        $sformatf("frame[%0d] seg[%0d][%0d] mismatch", i, si, j))
            end
            total_segs += n_segs_each;
        end

        seg_ra.get_frames_in_cnt(frames_in_cnt);
        seg_ra.get_segments_out_cnt(segs_out_cnt);
        `FAIL_UNLESS_LOG(frames_in_cnt == num_frames,
            $sformatf("frames_in: got %0d, expected %0d", frames_in_cnt, num_frames))
        `FAIL_UNLESS_LOG(segs_out_cnt == total_segs,
            $sformatf("segments_out: got %0d, expected %0d", segs_out_cnt, total_segs))
    `SVTEST_END

    // -----------------------------------------------------------------------
    // Debug counter verification: 5 frames of varying sizes
    // Mirrors: SAR Segmentation - Debug Counters
    // -----------------------------------------------------------------------
    `SVTEST(seg_debug_counters)
        automatic int frame_sizes[5] = '{64, 512, 1000, 2048, 4000};
        automatic int seg_len        = SAR_DEFAULT_SEG_LEN;
        automatic int exp_total_segs = 0;
        automatic int frames_in_cnt, segs_out_cnt;

        seg_clear_dbg_counts();

        for (int i = 0; i < 5; i++) begin
            automatic int  frame_size = frame_sizes[i];
            automatic int  n_segs     = n_segments(frame_size, seg_len);
            automatic int  buf_id     = i % SAR_NUM_FRAME_BUFFERS;
            automatic byte frame[];
            automatic byte segments[][];

            random_bytes(frame_size, frame);
            write_frame_to_hbm(buf_id, frame);

            seg_ctrl_trigger(buf_id, frame_size);
            capture_n_segments(n_segs, segments);
            seg_ctrl_wait_done();

            exp_total_segs += n_segs;
        end

        seg_ra.get_frames_in_cnt(frames_in_cnt);
        seg_ra.get_segments_out_cnt(segs_out_cnt);
        `FAIL_UNLESS_LOG(frames_in_cnt == 5,
            $sformatf("frames_in: got %0d, expected 5", frames_in_cnt))
        `FAIL_UNLESS_LOG(segs_out_cnt == exp_total_segs,
            $sformatf("segments_out: got %0d, expected %0d", segs_out_cnt, exp_total_segs))
    `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
