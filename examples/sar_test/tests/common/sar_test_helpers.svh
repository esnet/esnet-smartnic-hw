// ============================================================
// sar_test_helpers.svh
// Shared constants, agent declarations, and helper tasks for
// sar_test segmentation and reassembly SVUnit test suites.
//
// Include this file inside the test module body, after the
// tb_pkg::tb_env declaration and before build().
// ============================================================

// ------------------------------------------------------------
// Constants (must match sar_test.sv localparams)
// ------------------------------------------------------------
localparam int SAR_NUM_FRAME_BUFFERS  = 4;
localparam int SAR_MAX_FRAME_SIZE     = 65536;  // bytes per frame buffer
localparam int SAR_DEFAULT_SEG_LEN    = 512;    // default _config.seg_len
localparam int SAR_MAX_PKT_SIZE       = 9216;
localparam int DATA_BYTE_WID          = 32;     // HBM AXI data width (bytes)
localparam int CHUNK_BYTES            = 32;     // mem_proxy minimum burst = 1 chunk
localparam int BUF_ID_WID             = 2;      // clog2(SAR_NUM_FRAME_BUFFERS)
localparam int OFFSET_WID             = 16;     // clog2(SAR_MAX_FRAME_SIZE)

// sar_test decoder base offset within smartnic_app_igr AXI-L space
localparam int BASE = 'h100000;

// Fragment timeout in cycles for simulation (100 us @ 250 MHz)
localparam int FRAG_TIMEOUT_CYCLES = 25000;

// Short fragment timeout for reasm_timeout test: 1 tick (1 ms)
localparam int FRAG_TIMEOUT_SIM_TICKS = 1;

// One ms_tick period expressed in ns.
// timer_tick uses axil_if.aclk (125 MHz) as clk, div2 (62.5 MHz) as tclk.
// TCLK_PER_TICK=62_500 rising edges of tclk → 62_500 × 16 ns = 1 ms = 1_000_000 ns.
localparam int FRAG_TICK_NS = 1_000_000;

// Polling guards for non-timeout tests.
localparam int SEG_CTRL_POLL_CYCLES  = 3000;
localparam int REASM_POLL_CYCLES     = 3000;
localparam int REASM_DONE_MAX_ITERS  = 20000;

// ------------------------------------------------------------
// Agent declarations (module-level; shared across all SVTESTs)
// ------------------------------------------------------------

// Segmentation control (triggers HBM→segment path)
sar_test_reg_verif_pkg::sar_test_seg_ctrl_reg_blk_agent seg_ctrl_ra;

// Segmentation register block (enable/reset/config/counters)
sar_verif_pkg::sar_segmentation_reg_agent seg_ra;

// Segmentation HBM write proxy (writes frames into HBM channel 1)
mem_proxy_verif_pkg::mem_proxy_agent seg_mem_ra;

// Segment capture monitor (reads segments coming out of segmentation)
// META_T=bit: we only inspect packet data, not metadata
packet_verif_pkg::packet_capture_monitor #(bit) capture_mon;

// Reassembly playback driver (sends segments into reassembly path)
// META_T=bit[18:0]: encodes {buf_id[1:0], offset[15:0], is_last}
packet_verif_pkg::packet_playback_driver #(bit[18:0]) playback_drv;

// Reassembly HBM read proxy (reads reassembled frames from HBM channel 0)
mem_proxy_verif_pkg::mem_proxy_agent reasm_mem_ra;

// Reassembly register block (enable/reset/counters/timeout)
sar_verif_pkg::sar_reassembly_reg_agent reasm_ra;

// ------------------------------------------------------------
// Build function: construct all agents from env.app_reg_agent.
// Call from the module's build() function after env = tb.build().
// ------------------------------------------------------------
function automatic void sar_test_build(tb_pkg::tb_env env);
    // seg_ctrl lives at BASE + 0x14000
    seg_ctrl_ra = new("seg_ctrl_ra", BASE + 'h14000);
    seg_ctrl_ra.reg_agent = env.app_reg_agent;

    // segmentation regs: BASE + 0x11000
    seg_ra = new("seg_ra", env.app_reg_agent, BASE + 'h11000);

    // segmentation mem proxy: BASE + 0x12000
    seg_mem_ra = new("seg_mem_ra", DATA_BYTE_WID * 8, env.app_reg_agent, BASE + 'h12000);

    // segment capture: BASE + 0x13000; mem_size=SAR_MAX_FRAME_SIZE
    capture_mon = new("capture_mon", SAR_MAX_FRAME_SIZE, DATA_BYTE_WID * 8,
                      env.app_reg_agent, BASE + 'h13000);
    // The packet_capture's mem_proxy runs on the data-path clock domain (343 MHz)
    // while the AXI-L bus runs at 125 MHz. Two-phase CDC handshake adds latency
    // beyond the default 128-cycle op timeout; use a generous limit instead.
    capture_mon.mem_agent.set_op_timeout(32768);

    // reassembly playback: BASE + 0x01000; mem_size=SAR_MAX_PKT_SIZE
    playback_drv = new("playback_drv", SAR_MAX_PKT_SIZE, DATA_BYTE_WID * 8,
                       env.app_reg_agent, BASE + 'h01000);

    // reassembly mem proxy: BASE + 0x02000
    reasm_mem_ra = new("reasm_mem_ra", DATA_BYTE_WID * 8, env.app_reg_agent, BASE + 'h02000);
    // mem_proxy runs in the data-path clock domain (343 MHz); AXI-L CDC adds
    // latency beyond the default 128-cycle op timeout — use a generous limit.
    reasm_mem_ra.set_op_timeout(32768);

    // reassembly regs: BASE + 0x0C000; MAX_FRAGMENTS=64 (safe upper bound)
    reasm_ra = new("reasm_ra", 64, env.app_reg_agent, BASE + 'h0C000);
endfunction

// ------------------------------------------------------------
// Setup: mirror Python testcase_setup().
// Call at the start of each SVTEST (or from the SVUnit setup task).
// ------------------------------------------------------------
task automatic sar_test_setup();
    // --- Reassembly path ---
    reasm_ra.soft_reset();          // RMW: preserves enable=1 (INIT default)
    reasm_ra.wait_ready();
    reasm_clear_dbg_counts();
    // Set fragment timeout (default for most tests; timeout test overrides)
    reasm_ra.state.check.set_timeout(FRAG_TIMEOUT_CYCLES);

    // --- Segmentation path ---
    seg_ra.soft_reset();            // RMW: preserves enable=1 (INIT default)
    seg_ra.wait_ready();
    seg_clear_dbg_counts();
    // Restore default segment length
    begin
        sar_segmentation_reg_pkg::reg__config_t cfg;
        cfg.seg_len = SAR_DEFAULT_SEG_LEN;
        seg_ra.write__config(cfg);
    end

    // --- Packet drivers/monitors ---
    capture_mon.enable();
    capture_mon.wait_ready();
    playback_drv.enable();
    playback_drv.wait_ready();

    // --- Memory proxies ---
    seg_mem_ra.wait_ready();
    reasm_mem_ra.wait_ready();
endtask

// ------------------------------------------------------------
// Helper: set segmentation segment length
// ------------------------------------------------------------
task automatic sar_set_seg_len(int seg_len);
    sar_segmentation_reg_pkg::reg__config_t cfg;
    cfg.seg_len = seg_len;
    seg_ra.write__config(cfg);
endtask

// ------------------------------------------------------------
// Helper: compute mem_proxy chunk address for a frame buffer.
// Each buffer occupies SAR_MAX_FRAME_SIZE bytes = 2048 chunks.
// ------------------------------------------------------------
function automatic int buf_chunk_addr(int buf_id);
    return (buf_id * SAR_MAX_FRAME_SIZE) / CHUNK_BYTES;
endfunction

// ------------------------------------------------------------
// Helper: encode reassembly playback metadata.
// Format: {buf_id[1:0], byte_offset[15:0], is_last[0]} = 19 bits
// ------------------------------------------------------------
function automatic bit [18:0] make_reassembly_meta(int buf_id, int byte_offset, bit is_last);
    automatic logic [31:0] tmp;
    tmp = (buf_id << (OFFSET_WID + 1)) | (byte_offset << 1) | is_last;
    return tmp[18:0];
endfunction

// ------------------------------------------------------------
// Helper: generate n random bytes
// ------------------------------------------------------------
task automatic random_bytes(int n, output byte data[]);
    data = new[n];
    foreach (data[i])
        data[i] = byte'($urandom_range(0, 255));
endtask

// ------------------------------------------------------------
// Helper: write a frame (byte array) into HBM via seg_mem_ra.
// addr is chunk-addressed; one chunk = CHUNK_BYTES bytes.
// ------------------------------------------------------------
task automatic write_frame_to_hbm(int buf_id, const ref byte data[]);
    automatic bit error, timeout;
    seg_mem_ra.write(buf_chunk_addr(buf_id), data, error, timeout);
    assert (!error && !timeout) else
        $fatal(2, "write_frame_to_hbm: mem_proxy write failed (buf_id=%0d)", buf_id);
endtask

// ------------------------------------------------------------
// Helper: read a frame back from HBM via reasm_mem_ra.
// ------------------------------------------------------------
task automatic read_frame_from_hbm(int buf_id, int size, output byte data[]);
    automatic bit error, timeout;
    reasm_mem_ra.read(buf_chunk_addr(buf_id), size, data, error, timeout);
    assert (!error && !timeout) else
        $fatal(2, "read_frame_from_hbm: mem_proxy read failed (buf_id=%0d)", buf_id);
endtask

// ------------------------------------------------------------
// Helper: trigger seg_ctrl for buf_id / frame_len
// ------------------------------------------------------------
task automatic seg_ctrl_trigger(int buf_id, int frame_len);
    seg_ctrl_ra.write_frame_buf_id(sar_test_seg_ctrl_reg_pkg::reg_frame_buf_id_t'(buf_id));
    seg_ctrl_ra.write_frame_len(sar_test_seg_ctrl_reg_pkg::reg_frame_len_t'(frame_len));
    seg_ctrl_ra.write_trigger(32'h1);
endtask

// ------------------------------------------------------------
// Helper: poll seg_ctrl until done (not busy).
// Fails simulation with $fatal if it doesn't complete in time.
// ------------------------------------------------------------
task automatic seg_ctrl_wait_done();
    automatic sar_test_seg_ctrl_reg_pkg::reg_status_t status;
    automatic int iters = 0;
    do begin
        #1us; // stall one poll interval before re-checking
        seg_ctrl_ra.read_status(status);
        iters++;
    end while (status.busy == 1'b1 && iters < SEG_CTRL_POLL_CYCLES);
    assert (status.busy == 1'b0) else
        $fatal(2, "seg_ctrl_wait_done: timed out after %0d iters", iters);
endtask

// ------------------------------------------------------------
// Helper: capture one segment from capture_mon.
// Returns raw byte array. Caller owns the allocation.
// ------------------------------------------------------------
task automatic capture_one_segment(output byte data[]);
    automatic packet_verif_pkg::packet #(bit) pkt;
    automatic bit error, timeout;
    // TIMEOUT=0 means rely on SVUnit module-level timeout
    capture_mon.capture(pkt, error, timeout, 0);
    assert (!error && !timeout) else
        $fatal(2, "capture_one_segment: capture error=%0b timeout=%0b", error, timeout);
    data = pkt.to_bytes();
endtask

// ------------------------------------------------------------
// Helper: capture n segments sequentially.
// Returns a dynamic array of dynamic byte arrays.
// ------------------------------------------------------------
task automatic capture_n_segments(int n, output byte segments[][]);
    segments = new[n];
    for (int i = 0; i < n; i++)
        capture_one_segment(segments[i]);
endtask

// ------------------------------------------------------------
// Helper: send one segment via playback_drv to reassembly path.
// meta encodes {buf_id[1:0], byte_offset[15:0], is_last[0]}.
// Uses the public send_one() API (avoids protected _send_raw).
// ------------------------------------------------------------
task automatic send_segment(const ref byte data[], bit[18:0] meta);
    automatic packet_verif_pkg::packet_raw #(bit[18:0]) pkt;
    automatic bit err_unused = 1'b0;
    automatic bit error, timeout;
    pkt = packet_verif_pkg::packet_raw #(bit[18:0])::create_from_bytes(
            "seg_pkt", data, meta, err_unused);
    playback_drv.send_one(pkt, error, timeout);
    assert (!error && !timeout) else
        $fatal(2, "send_segment: send_one error=%0b timeout=%0b", error, timeout);
endtask

// ------------------------------------------------------------
// Helper: split frame into seg_len-byte segments and send all
// via the reassembly playback driver, setting is_last on final.
// ------------------------------------------------------------
task automatic send_frame_segments(const ref byte frame[], int buf_id, int seg_len);
    automatic int frame_size  = frame.size();
    automatic int n_segs      = (frame_size + seg_len - 1) / seg_len;
    automatic byte seg_data[];
    automatic int byte_offset;
    automatic int seg_bytes;
    automatic bit is_last;
    automatic bit[18:0] meta;

    for (int i = 0; i < n_segs; i++) begin
        byte_offset = i * seg_len;
        seg_bytes   = (frame_size - byte_offset < seg_len) ?
                       frame_size - byte_offset : seg_len;
        is_last     = (i == n_segs - 1) ? 1'b1 : 1'b0;
        seg_data = new[seg_bytes];
        for (int j = 0; j < seg_bytes; j++)
            seg_data[j] = frame[byte_offset + j];
        meta = make_reassembly_meta(buf_id, byte_offset, is_last);
        send_segment(seg_data, meta);
    end
endtask

// ------------------------------------------------------------
// Helper: poll reassembly done counter until it reaches target.
// Returns 1 on success, 0 on timeout.
// ------------------------------------------------------------
task automatic reasm_wait_done(int target_cnt, output bit ok);
    automatic int cnt;
    automatic int iters = 0;
    ok = 1'b0;
    do begin
        #200ns; // one state_notify_fsm scan period before re-polling
        reasm_ra.get_done_cnt(cnt);
        iters++;
    end while (cnt < target_cnt && iters < REASM_DONE_MAX_ITERS);
    ok = (cnt >= target_cnt);
endtask


// ------------------------------------------------------------
// Helper: pulse seg clear_counts (rw field — must write 0 back)
// ------------------------------------------------------------
task automatic seg_clear_dbg_counts();
    sar_segmentation_reg_pkg::reg_dbg_control_t ctrl;
    seg_ra.clear_dbg_counts();   // writes clear_counts=1
    ctrl = '0;
    seg_ra.write_dbg_control(ctrl);  // deassert clear_counts=0
endtask

// ------------------------------------------------------------
// Helper: pulse reasm clear_counts (rw field — must write 0 back)
// ------------------------------------------------------------
task automatic reasm_clear_dbg_counts();
    sar_reassembly_reg_pkg::reg_dbg_control_t ctrl;
    reasm_ra.clear_dbg_counts();
    ctrl = '0;
    reasm_ra.write_dbg_control(ctrl);
endtask

// ------------------------------------------------------------
// Helper: compute expected segment count
// ------------------------------------------------------------
function automatic int n_segments(int frame_size, int seg_len);
    return (frame_size + seg_len - 1) / seg_len;
endfunction
