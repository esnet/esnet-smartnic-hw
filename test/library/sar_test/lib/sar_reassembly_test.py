"""Reassembly path test functions for the sar_test example design."""

import os
import math
import random

from sar_test.lib.sar_test_config import (
    SAR_NUM_FRAME_BUFFERS,
    SAR_MAX_FRAME_SIZE,
    SAR_DEFAULT_SEG_LEN,
    make_reassembly_meta,
    buf_chunk_addr,
    testcase_setup,
)


def _random_bytes(n):
    return list(os.urandom(n))


def _send_segment(playback, data, buf_id, byte_offset, is_last):
    meta = make_reassembly_meta(buf_id, byte_offset, is_last)
    playback.send(data, meta)


def _send_frame(playback, frame_data, buf_id, seg_len):
    """Split frame_data into seg_len-byte segments and send in order."""
    size = len(frame_data)
    offset = 0
    while offset < size:
        chunk = frame_data[offset:offset + seg_len]
        is_last = (offset + seg_len >= size)
        _send_segment(playback, chunk, buf_id, offset, is_last)
        offset += len(chunk)


# ---------------------------------------------------------------------------

def sar_reassembly_sanity_test(dev):
    """Check id register, scratchpad round-trip, and info register values."""
    app = dev.bar2.smartnic_app_igr

    # id register
    id_val = int(app.sar_test.id)
    assert id_val == 0x53415254, f'Unexpected id: 0x{id_val:08x} (expected 0x53415254)'

    # scratchpad round-trip
    for val in (0xDEADBEEF, 0x00000000, 0xFFFFFFFF, 0xA5A5A5A5):
        app.sar_test.scratchpad = val
        got = int(app.sar_test.scratchpad)
        assert got == val, f'Scratchpad: wrote 0x{val:08x}, read 0x{got:08x}'

    # sar_reassembly info registers
    proto = testcase_setup(dev)
    info = proto.reassembly.get_info()
    assert info['num_frame_buffers'] == SAR_NUM_FRAME_BUFFERS, \
        f"num_frame_buffers: got {info['num_frame_buffers']}, expected {SAR_NUM_FRAME_BUFFERS}"
    assert info['max_frame_size'] == SAR_MAX_FRAME_SIZE, \
        f"max_frame_size: got {info['max_frame_size']}, expected {SAR_MAX_FRAME_SIZE}"
    assert info['max_fragments'] > 0, 'max_fragments must be non-zero'

    print(f'SAR reassembly info: {info}')


def sar_reassembly_single_segment_test(dev, buf_id=0, frame_size=64):
    """Send one segment (offset=0, last=1) and verify HBM readback."""
    proto = testcase_setup(dev)
    proto.reassembly.clear_counts()

    frame = _random_bytes(frame_size)
    baseline = proto.reassembly.done_ops_count()
    _send_segment(proto.playback, frame, buf_id, byte_offset=0, is_last=True)

    proto.reassembly.wait_done_ops(expected_delta=1, baseline=baseline)

    readback = proto.reasm_mem.read(buf_chunk_addr(buf_id), frame_size)
    assert readback == frame, \
        f'Single-segment readback mismatch (buf_id={buf_id}, size={frame_size})'

    counts = proto.reassembly.get_counts()
    assert counts['buffer_done'] >= 1, f"buffer_done: {counts['buffer_done']}"
    assert counts['alloc_drop'] == 0, f"alloc_drop: {counts['alloc_drop']}"
    assert counts['lookup_error'] == 0, f"lookup_error: {counts['lookup_error']}"
    print(f'Single segment test passed: buf_id={buf_id}, size={frame_size}')


def sar_reassembly_multi_segment_in_order_test(dev, buf_id=0, frame_size=4096, seg_len=512):
    """Send a multi-segment frame in order and verify readback."""
    proto = testcase_setup(dev)
    proto.reassembly.clear_counts()

    frame = _random_bytes(frame_size)
    baseline = proto.reassembly.done_ops_count()
    _send_frame(proto.playback, frame, buf_id, seg_len)

    proto.reassembly.wait_done_ops(expected_delta=1, baseline=baseline)

    readback = proto.reasm_mem.read(buf_chunk_addr(buf_id), frame_size)
    assert readback == frame, \
        f'In-order multi-segment readback mismatch (size={frame_size}, seg_len={seg_len})'

    counts = proto.reassembly.get_counts()
    assert counts['buffer_done'] >= 1
    assert counts['alloc_drop'] == 0
    assert counts['lookup_error'] == 0
    n_segs = math.ceil(frame_size / seg_len)
    print(f'In-order test passed: buf_id={buf_id}, frame={frame_size}B, '
          f'{n_segs} segments of {seg_len}B')


def sar_reassembly_multi_segment_out_of_order_test(dev, buf_id=0, frame_size=4096, seg_len=512):
    """Send segments in shuffled order and verify correct reassembly."""
    proto = testcase_setup(dev)
    proto.reassembly.clear_counts()

    frame = _random_bytes(frame_size)

    # Build list of (data, offset, is_last) then shuffle
    segments = []
    offset = 0
    while offset < frame_size:
        chunk = frame[offset:offset + seg_len]
        is_last = (offset + seg_len >= frame_size)
        segments.append((chunk, offset, is_last))
        offset += len(chunk)

    # Shuffle but keep the last segment last to avoid premature timeout
    non_last = [s for s in segments if not s[2]]
    last_seg = [s for s in segments if s[2]]
    random.shuffle(non_last)
    shuffled = non_last + last_seg

    baseline = proto.reassembly.done_ops_count()
    for data, off, last in shuffled:
        _send_segment(proto.playback, data, buf_id, off, last)

    proto.reassembly.wait_done_ops(expected_delta=1, timeout_ms=2000, baseline=baseline)

    readback = proto.reasm_mem.read(buf_chunk_addr(buf_id), frame_size)
    assert readback == frame, 'Out-of-order multi-segment readback mismatch'

    counts = proto.reassembly.get_counts()
    assert counts['alloc_drop'] == 0
    assert counts['lookup_error'] == 0
    n_segs = math.ceil(frame_size / seg_len)
    print(f'Out-of-order test passed: {n_segs} segments shuffled for buf_id={buf_id}')


def sar_reassembly_multi_frame_interleaved_test(dev, num_frames=4, frame_size=2048, seg_len=512):
    """Interleave segments from multiple frames and verify each buffer."""
    assert num_frames <= SAR_NUM_FRAME_BUFFERS, \
        f'num_frames ({num_frames}) > SAR_NUM_FRAME_BUFFERS ({SAR_NUM_FRAME_BUFFERS})'

    proto = testcase_setup(dev)
    proto.reassembly.clear_counts()

    frames = [_random_bytes(frame_size) for _ in range(num_frames)]

    # Build all segments across all frames
    all_segs = []
    for buf_id in range(num_frames):
        offset = 0
        while offset < frame_size:
            chunk = frames[buf_id][offset:offset + seg_len]
            is_last = (offset + seg_len >= frame_size)
            all_segs.append((chunk, buf_id, offset, is_last))
            offset += len(chunk)

    # Interleave by round-robining frame index, keeping last segment last per frame
    non_last_by_frame = [[] for _ in range(num_frames)]
    last_by_frame = []
    for seg in all_segs:
        if seg[3]:
            last_by_frame.append(seg)
        else:
            non_last_by_frame[seg[1]].append(seg)

    interleaved = []
    while any(non_last_by_frame):
        for lst in non_last_by_frame:
            if lst:
                interleaved.append(lst.pop(0))
    interleaved.extend(last_by_frame)

    baseline = proto.reassembly.done_ops_count()
    for data, buf_id, off, last in interleaved:
        _send_segment(proto.playback, data, buf_id, off, last)

    proto.reassembly.wait_done_ops(expected_delta=num_frames, timeout_ms=1000, baseline=baseline)

    for buf_id in range(num_frames):
        readback = proto.reasm_mem.read(buf_chunk_addr(buf_id), frame_size)
        assert readback == frames[buf_id], \
            f'Interleaved multi-frame readback mismatch for buf_id={buf_id}'

    counts = proto.reassembly.get_counts()
    assert counts['buffer_done'] >= num_frames
    assert counts['alloc_drop'] == 0
    assert counts['lookup_error'] == 0
    print(f'Interleaved test passed: {num_frames} frames x {frame_size}B, seg_len={seg_len}B')


def sar_reassembly_timeout_test(dev, buf_id=0, timeout_ms=50, wait_factor=20):
    """Send an incomplete frame, verify the fragment-expired counter increments."""
    import time
    proto = testcase_setup(dev)
    proto.reassembly.set_timeout(enable=True, value_ms=timeout_ms)
    proto.reassembly.clear_counts()

    # Send a first segment but never send the last one
    seg = _random_bytes(64)
    _send_segment(proto.playback, seg, buf_id, byte_offset=0, is_last=False)

    # Wait several times the configured timeout
    time.sleep((timeout_ms * wait_factor) / 1000)

    counts = proto.reassembly.get_counts()
    print(f'Timeout test counts: seg_rx={counts["seg_rx"]}, '
          f'fragment_expired={counts["fragment_expired"]}')
    assert counts['seg_rx'] >= 1, \
        f"Segment not received by SAR: seg_rx={counts['seg_rx']}"
    assert counts['fragment_expired'] >= 1, \
        f"Expected fragment_expired >= 1, got {counts['fragment_expired']}"

    flags = proto.reassembly.get_flags()
    assert flags['q_expired_oflow'] == 0, 'Unexpected q_expired_oflow'

    print(f'Timeout test passed: fragment_expired={counts["fragment_expired"]}')


def sar_reassembly_debug_counters_test(dev, num_frames=10, frame_size=1536, seg_len=512):
    """Send N complete frames and verify debug counters."""
    proto = testcase_setup(dev)
    proto.reassembly.clear_counts()

    n_segs = math.ceil(frame_size / seg_len)

    for i in range(num_frames):
        buf_id = i % SAR_NUM_FRAME_BUFFERS
        frame = _random_bytes(frame_size)
        baseline = proto.reassembly.done_ops_count()
        _send_frame(proto.playback, frame, buf_id, seg_len)
        # Wait for each frame before sending the next to avoid buffer collisions
        proto.reassembly.wait_done_ops(expected_delta=1, timeout_ms=500, baseline=baseline)
        proto.reassembly.clear_counts()

    # Re-run one final batch to check counts atomically
    proto.reassembly.clear_counts()
    frames = []
    for i in range(num_frames):
        buf_id = i % SAR_NUM_FRAME_BUFFERS
        frame = _random_bytes(frame_size)
        frames.append((buf_id, frame))
        baseline = proto.reassembly.done_ops_count()
        _send_frame(proto.playback, frame, buf_id, seg_len)
        proto.reassembly.wait_done_ops(expected_delta=1, timeout_ms=500, baseline=baseline)

    counts = proto.reassembly.get_counts()
    assert counts['done_ops'] == num_frames, \
        f"done_ops: got {counts['done_ops']}, expected {num_frames}"
    assert counts['alloc_drop'] == 0, f"alloc_drop: {counts['alloc_drop']}"
    assert counts['lookup_error'] == 0, f"lookup_error: {counts['lookup_error']}"

    print(f'Debug counters test passed: {num_frames} frames, '
          f"buffer_done={counts['buffer_done']}, merge_ops={counts['merge_ops']}, "
          f"seg_rx={counts['seg_rx']}")
