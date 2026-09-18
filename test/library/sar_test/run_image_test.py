#!/usr/bin/env -S regio-esnet-smartnic script
"""End-to-end SAR test: segment an image file to pcap, reassemble from pcap, compare.

Flow:
  1. Read image file from disk (must be ≤ 65,536 bytes)
  2. Write raw bytes into HBM via the segmentation memory proxy
  3. Trigger segmentation; capture each output segment; write segments.pcap
  4. Read segments back from pcap; send each via the reassembly playback driver
  5. Wait for reassembly completion; read reconstructed frame from HBM
  6. Write output file; assert it is byte-identical to the input

Configuration via environment variables (regio does not forward CLI args to the script):

    SAR_INPUT=photo.png regio-esnet-smartnic script run_image_test.py
    SAR_INPUT=logo.png SAR_SEG_LEN=1024 regio-esnet-smartnic script run_image_test.py

Variables:
    SAR_INPUT    Path to input binary file (required)
    SAR_OUTPUT   Output path (default: <input>_out.<ext>)
    SAR_PCAP     Pcap file for captured segments (default: segments.pcap)
    SAR_SEG_LEN  Segment length in bytes, 1-9216 (default: 512)
    SAR_BUF_ID   SAR frame buffer index 0-3 (default: 0)
"""

import math
import os
import struct
import sys

# Ensure test/library/ is on the path so that 'sar_test' and 'smartnic' packages resolve.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ---------------------------------------------------------------------------
# Minimal pcap helpers (avoids scapy link-type registration issues for Raw)
# ---------------------------------------------------------------------------
_PCAP_MAGIC    = 0xa1b2c3d4
_PCAP_DLT_USER0 = 147          # DLT_USER0: raw binary payload, no network header


def _write_raw_pcap(path, segments):
    """Write raw byte segments to a pcap file (DLT_USER0, little-endian)."""
    with open(path, 'wb') as f:
        f.write(struct.pack('<IHHiIII', _PCAP_MAGIC, 2, 4, 0, 0, 65535, _PCAP_DLT_USER0))
        for seg in segments:
            data = bytes(seg)
            f.write(struct.pack('<IIII', 0, 0, len(data), len(data)))
            f.write(data)


def _read_raw_pcap(path):
    """Read raw byte segments from a pcap file. Returns list of bytes objects."""
    with open(path, 'rb') as f:
        hdr = f.read(24)
        magic = struct.unpack_from('<I', hdr)[0]
        endian = '<' if magic == _PCAP_MAGIC else '>'
        segments = []
        while True:
            pkt_hdr = f.read(16)
            if not pkt_hdr:
                break
            _, _, incl_len, _ = struct.unpack(f'{endian}IIII', pkt_hdr)
            segments.append(f.read(incl_len))
    return segments

from sar_test.lib.sar_test_config import (
    SAR_MAX_FRAME_SIZE,
    buf_chunk_addr,
    make_reassembly_meta,
    testcase_setup,
    testcase_teardown,
)

# dev0 is injected by regio-esnet-smartnic as a global.
dev = dev0  # noqa: F821

# ---------------------------------------------------------------------------
# Configuration from environment variables
# ---------------------------------------------------------------------------

class _Args:
    pass

args = _Args()

args.input   = os.environ.get('SAR_INPUT')
args.output  = os.environ.get('SAR_OUTPUT')
args.pcap    = os.environ.get('SAR_PCAP',    'segments.pcap')
args.seg_len = int(os.environ.get('SAR_SEG_LEN', '512'))
args.buf_id  = int(os.environ.get('SAR_BUF_ID',  '0'))

if not args.input:
    sys.exit('ERROR: SAR_INPUT environment variable is required\n'
             '  Example: SAR_INPUT=photo.png regio-esnet-smartnic script run_image_test.py')

# Derive default output path
if args.output is None:
    base, ext = os.path.splitext(args.input)
    args.output = f'{base}_out{ext}'

# ---------------------------------------------------------------------------
# Validate inputs
# ---------------------------------------------------------------------------

if not os.path.isfile(args.input):
    sys.exit(f'ERROR: input file not found: {args.input}')

with open(args.input, 'rb') as fh:
    image_bytes = list(fh.read())

frame_size = len(image_bytes)
if frame_size == 0:
    sys.exit('ERROR: input file is empty')
if frame_size > SAR_MAX_FRAME_SIZE:
    sys.exit(f'ERROR: input file is {frame_size} bytes, exceeds SAR_MAX_FRAME_SIZE={SAR_MAX_FRAME_SIZE}')
if args.seg_len < 1 or args.seg_len > 9216:
    sys.exit(f'ERROR: --seg-len must be 1–9216, got {args.seg_len}')
if args.buf_id < 0 or args.buf_id > 3:
    sys.exit(f'ERROR: --buf-id must be 0–3, got {args.buf_id}')

n_segs = math.ceil(frame_size / args.seg_len)

print(f'Input:      {args.input} ({frame_size} bytes)')
print(f'Output:     {args.output}')
print(f'Pcap:       {args.pcap}')
print(f'Seg-len:    {args.seg_len} bytes  →  {n_segs} segment(s)')
print(f'Buf-id:     {args.buf_id}')

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

proto = testcase_setup(dev)
proto.segmentation.set_segment_length(args.seg_len)
proto.segmentation.clear_counts()
proto.reassembly.clear_counts()

# ---------------------------------------------------------------------------
# Step 1: Write image into HBM (segmentation memory)
# ---------------------------------------------------------------------------

print('\n--- Writing image to HBM (seg_mem) ...')
proto.seg_mem.write(buf_chunk_addr(args.buf_id), image_bytes)
print(f'    Wrote {frame_size} bytes at chunk addr {buf_chunk_addr(args.buf_id)}')

# ---------------------------------------------------------------------------
# Step 2: Segment → capture → pcap
# ---------------------------------------------------------------------------

print(f'\n--- Segmenting and capturing {n_segs} segment(s) ...')
captured_segments = []

# Arm capture BEFORE triggering segmentation to avoid missing the first segment
proto.capture.trigger()
proto.seg_ctrl.trigger(args.buf_id, frame_size)

for i in range(n_segs):
    (data, _meta) = proto.capture.wait_on_capture()
    captured_segments.append(bytes(data))
    print(f'    Segment {i+1}/{n_segs}: {len(data)} bytes captured')
    if i < n_segs - 1:
        proto.capture.trigger()   # re-arm for next segment

proto.seg_ctrl.wait_done()

# Sanity-check that data volumes add up
total_captured = sum(len(s) for s in captured_segments)
if total_captured < frame_size:
    sys.exit(f'ERROR: captured {total_captured} bytes, expected at least {frame_size}')

# Write pcap (DLT_USER0: raw binary payload, no network headers)
_write_raw_pcap(args.pcap, captured_segments)
print(f'    Wrote {len(captured_segments)} packets to {args.pcap}')

# ---------------------------------------------------------------------------
# Step 3: Pcap → playback → reassemble
# ---------------------------------------------------------------------------

print(f'\n--- Playing {n_segs} segment(s) from pcap into reassembly ...')
pcap_segs = _read_raw_pcap(args.pcap)
if len(pcap_segs) != n_segs:
    sys.exit(f'ERROR: pcap has {len(pcap_segs)} packets, expected {n_segs}')

baseline = proto.reassembly.done_ops_count()
byte_offset = 0

for i, pkt in enumerate(pcap_segs):
    seg_data = list(pkt)
    is_last  = (i == len(pcap_segs) - 1)
    meta     = make_reassembly_meta(args.buf_id, byte_offset, is_last)
    proto.playback.send(seg_data, meta)
    print(f'    Sent segment {i+1}/{n_segs}: offset={byte_offset}, '
          f'len={len(seg_data)}, is_last={is_last}')
    byte_offset += len(seg_data)

# ---------------------------------------------------------------------------
# Step 4: Wait for reassembly, read back from HBM
# ---------------------------------------------------------------------------

print('\n--- Waiting for reassembly ...')
proto.reassembly.wait_done_ops(expected_delta=1, baseline=baseline)
print('    Reassembly done.')

readback = proto.reasm_mem.read(buf_chunk_addr(args.buf_id), frame_size)
print(f'    Read {len(readback)} bytes from HBM (reasm_mem)')

# ---------------------------------------------------------------------------
# Step 5: Write output and compare
# ---------------------------------------------------------------------------

with open(args.output, 'wb') as fh:
    fh.write(bytes(readback))
print(f'\n--- Output written: {args.output}')

if list(readback) == image_bytes:
    print('\nPASS: output is byte-identical to input.')
else:
    # Find first mismatch for a helpful error message
    first_diff = next(
        i for i, (a, b) in enumerate(zip(image_bytes, readback)) if a != b
    ) if list(readback) != image_bytes else -1
    print(f'\nFAIL: mismatch — first differing byte at offset {first_diff} '
          f'(input=0x{image_bytes[first_diff]:02x}, '
          f'output=0x{readback[first_diff]:02x})')
    testcase_teardown(dev)
    sys.exit(1)

testcase_teardown(dev)
