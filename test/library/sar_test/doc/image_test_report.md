# ESnet SmartNIC SAR — Image Round-Trip Hardware Test Report

The `sar_test` example design implements a Segmentation and Reassembly (SAR) pipeline in the SmartNIC application layer. This report captures the design intent, test plan, hardware configuration, and results of an end-to-end functional test in which a real image file is segmented into fixed-size packets, stored to a pcap file, reassembled from that pcap, and verified to be byte-identical to the original.

## Design

The `sar_test` application (`examples/sar_test/`) instantiates two complementary SAR paths:

- **Segmentation path**: reads a variable-length frame from HBM (via a packet memory proxy), splits it into fixed-size segments, and outputs the segments as AXI4-S packets captured by a `packet_capture` monitor.
- **Reassembly path**: accepts AXI4-S segment packets (each carrying a 19-bit metadata field encoding `{buf_id[1:0], byte_offset[15:0], is_last[0]}`), writes each segment to the appropriate location in an HBM frame buffer, and signals completion when the last segment has been written.

Both paths share HBM channel resources managed via `mem_proxy` register interfaces. The segmentation and reassembly engines are the `sar_packet_segmentation` and `sar_packet_reassembly` components from `esnet-fpga-library`.

The test design parameters used in this build:

| Parameter | Value |
|-----------|-------|
| `SAR_NUM_FRAME_BUFFERS` | 4 |
| `SAR_MAX_FRAME_SIZE` | 65,536 bytes |
| `SAR_MAX_PKT_SIZE` | 9,216 bytes (jumbo) |
| HBM chunk size (`CHUNK_BYTES`) | 32 bytes |

## Test Plan

The image round-trip test was designed to provide a concrete, visually verifiable proof that both SAR paths are functionally correct and interoperable. Using an image file makes a potential data corruption immediately obvious. The pipeline, as planned, is:

```
  image.png
      │
      ▼
  seg_mem.write()          Write raw bytes into HBM frame buffer (buf_id=0)
      │
      ▼
  seg_ctrl.trigger()       Trigger SAR segmentation
  capture.wait_on_capture()  Collect each output segment
      │
      ▼
  segments.pcap            Raw-payload pcap (DLT_USER0), one packet per segment
      │
      ▼
  playback.send()          Send each segment with reconstructed reassembly meta
      │
      ▼
  reassembly.wait_done_ops()  Wait for SAR reassembly completion
  reasm_mem.read()         Read reconstructed frame from HBM
      │
      ▼
  image_out.png            Assert byte-identical to input
```

The test script (`run_image_test.py`) reconstructs the reassembly metadata from the segment's position in the pcap — `byte_offset` is accumulated from actual captured segment lengths, and `is_last` is set on the final packet. This makes the pcap a self-contained interchange format: any tool that can write correctly-sized raw packets could feed the reassembly path.

Key constraints validated upfront by the script:
- Input file ≤ 65,536 bytes (`SAR_MAX_FRAME_SIZE`)
- Segment length 1–9,216 bytes (`SAR_MAX_PKT_SIZE`)

## Hardware Configuration

| Field | Value |
|-------|-------|
| Test node | node1.fpga.es.net |
| Card name | ALVEO U280 PQ |
| Card profile | U280 |
| Serial number | 21760201R015 |
| Application | `sar_test` |
| Build ID | 1789692154 |

## Test Procedure

The script is invoked via the `regio-esnet-smartnic` runtime, which pre-configures the device register map as `dev0`. Parameters are passed via environment variables. The following invocation was used:

```bash
SAR_INPUT=ESnet-logo.png SAR_SEG_LEN=1024 regio-esnet-smartnic script run_image_test.py
```

| Parameter | Value |
|-----------|-------|
| `SAR_INPUT` | `ESnet-logo.png` |
| `SAR_SEG_LEN` | 1024 bytes |
| `SAR_BUF_ID` | 0 (default) |
| `SAR_PCAP` | `segments.pcap` (default) |

## Results

```
Input:      ESnet-logo.png (45351 bytes)
Output:     ESnet-logo_out.png
Pcap:       segments.pcap
Seg-len:    1024 bytes  →  45 segment(s)
Buf-id:     0

--- Writing image to HBM (seg_mem) ...
    Wrote 45351 bytes at chunk addr 0

--- Segmenting and capturing 45 segment(s) ...
    Segment 1/45: 1024 bytes captured
    Segment 2/45: 1024 bytes captured
    Segment 3/45: 1024 bytes captured
    Segment 4/45: 1024 bytes captured
    Segment 5/45: 1024 bytes captured
    Segment 6/45: 1024 bytes captured
    Segment 7/45: 1024 bytes captured
    Segment 8/45: 1024 bytes captured
    Segment 9/45: 1024 bytes captured
    Segment 10/45: 1024 bytes captured
    Segment 11/45: 1024 bytes captured
    Segment 12/45: 1024 bytes captured
    Segment 13/45: 1024 bytes captured
    Segment 14/45: 1024 bytes captured
    Segment 15/45: 1024 bytes captured
    Segment 16/45: 1024 bytes captured
    Segment 17/45: 1024 bytes captured
    Segment 18/45: 1024 bytes captured
    Segment 19/45: 1024 bytes captured
    Segment 20/45: 1024 bytes captured
    Segment 21/45: 1024 bytes captured
    Segment 22/45: 1024 bytes captured
    Segment 23/45: 1024 bytes captured
    Segment 24/45: 1024 bytes captured
    Segment 25/45: 1024 bytes captured
    Segment 26/45: 1024 bytes captured
    Segment 27/45: 1024 bytes captured
    Segment 28/45: 1024 bytes captured
    Segment 29/45: 1024 bytes captured
    Segment 30/45: 1024 bytes captured
    Segment 31/45: 1024 bytes captured
    Segment 32/45: 1024 bytes captured
    Segment 33/45: 1024 bytes captured
    Segment 34/45: 1024 bytes captured
    Segment 35/45: 1024 bytes captured
    Segment 36/45: 1024 bytes captured
    Segment 37/45: 1024 bytes captured
    Segment 38/45: 1024 bytes captured
    Segment 39/45: 1024 bytes captured
    Segment 40/45: 1024 bytes captured
    Segment 41/45: 1024 bytes captured
    Segment 42/45: 1024 bytes captured
    Segment 43/45: 1024 bytes captured
    Segment 44/45: 1024 bytes captured
    Segment 45/45: 295 bytes captured
    Wrote 45 packets to segments.pcap

--- Playing 45 segment(s) from pcap into reassembly ...
    Sent segment 1/45: offset=0, len=1024, is_last=False
    Sent segment 2/45: offset=1024, len=1024, is_last=False
    Sent segment 3/45: offset=2048, len=1024, is_last=False
    Sent segment 4/45: offset=3072, len=1024, is_last=False
    Sent segment 5/45: offset=4096, len=1024, is_last=False
    Sent segment 6/45: offset=5120, len=1024, is_last=False
    Sent segment 7/45: offset=6144, len=1024, is_last=False
    Sent segment 8/45: offset=7168, len=1024, is_last=False
    Sent segment 9/45: offset=8192, len=1024, is_last=False
    Sent segment 10/45: offset=9216, len=1024, is_last=False
    Sent segment 11/45: offset=10240, len=1024, is_last=False
    Sent segment 12/45: offset=11264, len=1024, is_last=False
    Sent segment 13/45: offset=12288, len=1024, is_last=False
    Sent segment 14/45: offset=13312, len=1024, is_last=False
    Sent segment 15/45: offset=14336, len=1024, is_last=False
    Sent segment 16/45: offset=15360, len=1024, is_last=False
    Sent segment 17/45: offset=16384, len=1024, is_last=False
    Sent segment 18/45: offset=17408, len=1024, is_last=False
    Sent segment 19/45: offset=18432, len=1024, is_last=False
    Sent segment 20/45: offset=19456, len=1024, is_last=False
    Sent segment 21/45: offset=20480, len=1024, is_last=False
    Sent segment 22/45: offset=21504, len=1024, is_last=False
    Sent segment 23/45: offset=22528, len=1024, is_last=False
    Sent segment 24/45: offset=23552, len=1024, is_last=False
    Sent segment 25/45: offset=24576, len=1024, is_last=False
    Sent segment 26/45: offset=25600, len=1024, is_last=False
    Sent segment 27/45: offset=26624, len=1024, is_last=False
    Sent segment 28/45: offset=27648, len=1024, is_last=False
    Sent segment 29/45: offset=28672, len=1024, is_last=False
    Sent segment 30/45: offset=29696, len=1024, is_last=False
    Sent segment 31/45: offset=30720, len=1024, is_last=False
    Sent segment 32/45: offset=31744, len=1024, is_last=False
    Sent segment 33/45: offset=32768, len=1024, is_last=False
    Sent segment 34/45: offset=33792, len=1024, is_last=False
    Sent segment 35/45: offset=34816, len=1024, is_last=False
    Sent segment 36/45: offset=35840, len=1024, is_last=False
    Sent segment 37/45: offset=36864, len=1024, is_last=False
    Sent segment 38/45: offset=37888, len=1024, is_last=False
    Sent segment 39/45: offset=38912, len=1024, is_last=False
    Sent segment 40/45: offset=39936, len=1024, is_last=False
    Sent segment 41/45: offset=40960, len=1024, is_last=False
    Sent segment 42/45: offset=41984, len=1024, is_last=False
    Sent segment 43/45: offset=43008, len=1024, is_last=False
    Sent segment 44/45: offset=44032, len=1024, is_last=False
    Sent segment 45/45: offset=45056, len=295, is_last=True

--- Waiting for reassembly ...
    Reassembly done.
    Read 45351 bytes from HBM (reasm_mem)

--- Output written: ESnet-logo_out.png

PASS: output is byte-identical to input.
```

## Discussion

The ESnet logo PNG (45,351 bytes) was successfully transported through the full SAR pipeline in hardware. The segmentation engine produced 44 full-size segments of 1,024 bytes and one short tail segment of 295 bytes (44 × 1024 + 295 = 45,351). All 45 segments were captured, written to `segments.pcap`, played back through the reassembly path in order, and the reassembled frame read from HBM matched the original file byte-for-byte.

This test validates:
- Correct HBM write behaviour via the segmentation `mem_proxy` interface
- Correct segment extraction and output sizing by `sar_packet_segmentation`, including the short final segment
- Correct metadata encoding (`{buf_id, byte_offset, is_last}`) and decoding by `sar_packet_reassembly`
- Correct HBM write-gather by the reassembly engine across 45 non-contiguous write operations
- Correct HBM readback via the reassembly `mem_proxy` interface

The pcap interchange layer (DLT_USER0, raw binary payload) provides a useful artifact: the `segments.pcap` file can be independently inspected, replayed, or modified to exercise specific reassembly scenarios such as out-of-order delivery or dropped segments.
