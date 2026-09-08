"""Segmentation path test functions for the sar_test example design."""

import os
import math

from sar_test.lib.sar_test_config import (
    SAR_NUM_FRAME_BUFFERS,
    SAR_MAX_FRAME_SIZE,
    SAR_DEFAULT_SEG_LEN,
    buf_chunk_addr,
    testcase_setup,
)


def _random_bytes(n):
    return list(os.urandom(n))


def _write_frame(seg_mem, buf_id, frame_data):
    """Write frame_data bytes into HBM channel 1 at the correct chunk address."""
    seg_mem.write(buf_chunk_addr(buf_id), frame_data)


def _capture_segments(capture, n_segments):
    """Arm capture and collect n_segments, returning list of byte-lists.

    Arms the first capture slot before the caller triggers segmentation
    (caller must call capture.trigger() once before seg_ctrl.trigger()).
    For segments 2..N, re-arms immediately after receiving each packet
    to minimise the window in which a segment could be dropped.
    """
    segments = []
    for i in range(n_segments):
        data, _meta = capture.wait_on_capture()
        segments.append(data)
        if i < n_segments - 1:
            capture.trigger()   # re-arm before next segment arrives
    return segments


def _expected_n_segments(frame_size, seg_len):
    return math.ceil(frame_size / seg_len)


# ---------------------------------------------------------------------------

def sar_segmentation_sanity_test(dev):
    """Check info registers and initial seg_ctrl status."""
    proto = testcase_setup(dev)

    info = proto.segmentation.get_info()
    assert info['num_buffers'] == SAR_NUM_FRAME_BUFFERS, \
        f"num_buffers: got {info['num_buffers']}, expected {SAR_NUM_FRAME_BUFFERS}"
    assert info['max_frame_size'] == SAR_MAX_FRAME_SIZE, \
        f"max_frame_size: got {info['max_frame_size']}, expected {SAR_MAX_FRAME_SIZE}"
    assert info['max_segment_len'] > 0, 'max_segment_len must be non-zero'

    seg_len = proto.segmentation.get_segment_length()
    assert seg_len == SAR_DEFAULT_SEG_LEN, \
        f'Default seg_len: got {seg_len}, expected {SAR_DEFAULT_SEG_LEN}'

    app = dev.bar2.smartnic_app_igr
    st = app.segmentation_ctrl.status().proxy
    assert not int(st.busy), 'seg_ctrl.status.busy asserted at startup'

    print(f'Segmentation sanity test passed: info={info}, seg_len={seg_len}')


def sar_segmentation_single_segment_test(dev, buf_id=0, frame_size=64):
    """Write a short frame, trigger segmentation, capture one segment, verify."""
    proto = testcase_setup(dev)
    proto.segmentation.clear_counts()

    frame = _random_bytes(frame_size)
    _write_frame(proto.seg_mem, buf_id, frame)

    # Arm capture before triggering so we don't miss the segment
    proto.capture.trigger()
    proto.seg_ctrl.trigger(buf_id, frame_size)

    (data, _meta) = proto.capture.wait_on_capture()
    proto.seg_ctrl.wait_done()

    assert list(data) == frame, \
        f'Single-segment capture mismatch (buf_id={buf_id}, size={frame_size})'

    counts = proto.segmentation.get_counts()
    assert counts['frames_in'] == 1, f"frames_in: {counts['frames_in']}"
    assert counts['segments_out'] == 1, f"segments_out: {counts['segments_out']}"
    print(f'Single-segment segmentation test passed: buf_id={buf_id}, size={frame_size}')


def sar_segmentation_multi_segment_test(dev, buf_id=0, frame_size=4096, seg_len=512):
    """Write a large frame, trigger, capture all segments, verify concatenation."""
    proto = testcase_setup(dev)
    proto.segmentation.set_segment_length(seg_len)
    proto.segmentation.clear_counts()

    n_segs = _expected_n_segments(frame_size, seg_len)
    frame = _random_bytes(frame_size)
    _write_frame(proto.seg_mem, buf_id, frame)

    # Trigger capture for all segments before starting segmentation
    # The first trigger is non-blocking; we interleave trigger+wait below.
    proto.capture.trigger()     # arm before triggering to avoid missing first segment
    proto.seg_ctrl.trigger(buf_id, frame_size)
    segments = _capture_segments(proto.capture, n_segs)
    proto.seg_ctrl.wait_done()

    reassembled = []
    for i, seg in enumerate(segments):
        expected = frame[i*seg_len : i*seg_len + len(seg)]
        if list(seg)[:len(expected)] != expected:
            # Check if the captured data matches a DIFFERENT segment
            alias = next(
                (j for j in range(n_segs)
                 if list(seg)[:seg_len] == frame[j*seg_len : j*seg_len + seg_len]),
                None
            )
            # Check if the captured data appears at any byte offset in the frame
            probe = list(seg)[:16]
            frame_off = next(
                (off for off in range(frame_size - 16)
                 if frame[off:off + 16] == probe),
                None
            )
            alias_str = f'matches segment {alias}' if alias is not None else 'no segment match'
            frame_off_str = (f'data at frame byte {frame_off} (seg {frame_off // seg_len})'
                             if frame_off is not None else 'data not found in frame')
            raise AssertionError(
                f'Multi-segment mismatch at segment {i}/{n_segs-1} '
                f'(frame={frame_size}B, seg_len={seg_len}B): '
                f'got {len(seg)}B, expected {len(expected)}B; '
                f'{alias_str}; {frame_off_str}; '
                f'first 8B got={list(seg)[:8]} exp={expected[:8]}'
            )
        reassembled.extend(seg)
    reassembled = reassembled[:frame_size]

    assert reassembled == frame, \
        f'Multi-segment reassembled mismatch (frame={frame_size}B, seg_len={seg_len}B)'

    counts = proto.segmentation.get_counts()
    assert counts['frames_in'] == 1
    assert counts['segments_out'] == n_segs, \
        f"segments_out: got {counts['segments_out']}, expected {n_segs}"
    print(f'Multi-segment test passed: {frame_size}B → {n_segs} x {seg_len}B segments')


def sar_segmentation_boundary_test(dev, buf_id=0, seg_len=512):
    """Test frame sizes at segment-length boundaries."""
    proto = testcase_setup(dev)
    proto.segmentation.set_segment_length(seg_len)

    test_cases = [
        (seg_len - 1, 1),       # just under: 1 segment
        (seg_len,     1),       # exactly one: 1 segment
        (seg_len + 1, 2),       # just over: 2 segments
        (2 * seg_len, 2),       # exactly two: 2 segments
        (2 * seg_len + 1, 3),   # just over two: 3 segments
    ]

    for frame_size, expected_n_segs in test_cases:
        proto.segmentation.clear_counts()
        frame = _random_bytes(frame_size)
        _write_frame(proto.seg_mem, buf_id, frame)

        proto.capture.trigger()
        proto.seg_ctrl.trigger(buf_id, frame_size)
        segments = _capture_segments(proto.capture, expected_n_segs)
        proto.seg_ctrl.wait_done()

        reassembled = []
        for seg in segments:
            reassembled.extend(seg)
        reassembled = reassembled[:frame_size]

        assert reassembled == frame, \
            f'Boundary test mismatch: frame_size={frame_size}, seg_len={seg_len}'

        counts = proto.segmentation.get_counts()
        assert counts['segments_out'] == expected_n_segs, \
            (f"segments_out: got {counts['segments_out']}, "
             f"expected {expected_n_segs} for frame_size={frame_size}")

        print(f'  Boundary: frame={frame_size}B → {expected_n_segs} segments ✓')

    print(f'Boundary test passed for seg_len={seg_len}')


def sar_segmentation_configure_seg_len_test(dev, buf_id=0, frame_size=3000, new_seg_len=256):
    """Change seg_len register and verify segmentation adapts."""
    proto = testcase_setup(dev)

    # Baseline with default seg_len
    default_n = _expected_n_segments(frame_size, SAR_DEFAULT_SEG_LEN)
    frame = _random_bytes(frame_size)
    _write_frame(proto.seg_mem, buf_id, frame)
    proto.capture.trigger()
    proto.seg_ctrl.trigger(buf_id, frame_size)
    segs = _capture_segments(proto.capture, default_n)
    proto.seg_ctrl.wait_done()
    reassembled = []
    for s in segs:
        reassembled.extend(s)
    assert reassembled[:frame_size] == frame, 'Baseline segmentation mismatch'

    # Reconfigure seg_len
    proto.segmentation.set_segment_length(new_seg_len)
    assert proto.segmentation.get_segment_length() == new_seg_len, \
        f'seg_len readback mismatch after reconfigure'

    proto.segmentation.clear_counts()
    new_n = _expected_n_segments(frame_size, new_seg_len)
    frame2 = _random_bytes(frame_size)
    _write_frame(proto.seg_mem, buf_id, frame2)
    proto.capture.trigger()
    proto.seg_ctrl.trigger(buf_id, frame_size)
    segs2 = _capture_segments(proto.capture, new_n)
    proto.seg_ctrl.wait_done()

    reassembled2 = []
    for s in segs2:
        reassembled2.extend(s)
    assert reassembled2[:frame_size] == frame2, \
        f'Reconfigured seg_len={new_seg_len} segmentation mismatch'

    counts = proto.segmentation.get_counts()
    assert counts['segments_out'] == new_n, \
        f"segments_out: got {counts['segments_out']}, expected {new_n}"

    print(f'Configure seg_len test passed: {SAR_DEFAULT_SEG_LEN}→{new_seg_len}B, '
          f'{frame_size}B frame → {new_n} segments')


def sar_segmentation_sequential_frames_test(dev, num_frames=4):
    """Cycle through all buf_ids sequentially, each with unique frame data."""
    proto = testcase_setup(dev)
    proto.segmentation.clear_counts()

    seg_len = SAR_DEFAULT_SEG_LEN
    frame_size = seg_len * 3  # 3 segments each

    total_segments = 0
    for i in range(num_frames):
        buf_id = i % SAR_NUM_FRAME_BUFFERS
        n_segs = _expected_n_segments(frame_size, seg_len)
        frame = _random_bytes(frame_size)
        _write_frame(proto.seg_mem, buf_id, frame)

        proto.capture.trigger()
        proto.seg_ctrl.trigger(buf_id, frame_size)
        segments = _capture_segments(proto.capture, n_segs)
        proto.seg_ctrl.wait_done()

        reassembled = []
        for seg in segments:
            reassembled.extend(seg)
        assert reassembled[:frame_size] == frame, \
            f'Sequential frame mismatch for buf_id={buf_id}, frame #{i}'

        total_segments += n_segs

    counts = proto.segmentation.get_counts()
    assert counts['frames_in'] == num_frames, \
        f"frames_in: got {counts['frames_in']}, expected {num_frames}"
    assert counts['segments_out'] == total_segments, \
        f"segments_out: got {counts['segments_out']}, expected {total_segments}"

    print(f'Sequential frames test passed: {num_frames} frames, '
          f'{total_segments} total segments')


def sar_segmentation_debug_counters_test(dev, num_frames=5):
    """Send frames of varying sizes and verify debug counter totals."""
    proto = testcase_setup(dev)
    seg_len = SAR_DEFAULT_SEG_LEN
    proto.segmentation.clear_counts()

    frame_sizes = [64, 512, 1000, 2048, 4000][:num_frames]
    expected_segments_total = sum(
        _expected_n_segments(sz, seg_len) for sz in frame_sizes
    )

    for i, frame_size in enumerate(frame_sizes):
        buf_id = i % SAR_NUM_FRAME_BUFFERS
        n_segs = _expected_n_segments(frame_size, seg_len)
        frame = _random_bytes(frame_size)
        _write_frame(proto.seg_mem, buf_id, frame)

        proto.capture.trigger()
        proto.seg_ctrl.trigger(buf_id, frame_size)
        _capture_segments(proto.capture, n_segs)
        proto.seg_ctrl.wait_done()

    counts = proto.segmentation.get_counts()
    assert counts['frames_in'] == num_frames, \
        f"frames_in: got {counts['frames_in']}, expected {num_frames}"
    assert counts['segments_out'] == expected_segments_total, \
        (f"segments_out: got {counts['segments_out']}, "
         f"expected {expected_segments_total}")

    print(f'Debug counters test passed: frames_in={counts["frames_in"]}, '
          f'segments_out={counts["segments_out"]}')
