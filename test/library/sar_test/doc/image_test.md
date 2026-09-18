# SAR Image Round-Trip Test

## Overview

`run_image_test.py` is a standalone end-to-end test for the `sar_test` example
design. It loads a binary file (e.g. a PNG or JPEG image), drives it through the
hardware segmentation and reassembly paths, and verifies the output is
byte-identical to the input.

## Pipeline

```
  image.png
      │
      ▼
  seg_mem.write()          Write raw bytes into HBM frame buffer (buf_id)
      │
      ▼
  seg_ctrl.trigger()       Trigger SAR segmentation
      │
  capture.wait_on_capture()  Capture each output segment
      │
      ▼
  segments.pcap            Raw-payload pcap, one packet per segment
      │
      ▼
  rdpcap()
      │
  playback.send()          Send each segment with reassembly metadata
      │
      ▼
  reassembly.wait_done_ops()  Wait for SAR reassembly to complete
      │
  reasm_mem.read()         Read reconstructed frame from HBM
      │
      ▼
  image_out.png            Byte-identical copy of the input
```

## Usage

Parameters are passed via environment variables (the regio script runner does
not forward CLI arguments to the Python script).

```bash
# Minimum: input file only, all other options default
SAR_INPUT=photo.png regio-esnet-smartnic script run_image_test.py

# Custom segment length and pcap path
SAR_INPUT=logo.png SAR_SEG_LEN=1024 SAR_PCAP=logo_segments.pcap \
    regio-esnet-smartnic script run_image_test.py

# Full options
SAR_INPUT=photo.png SAR_OUTPUT=photo_reconstructed.png \
    SAR_PCAP=photo_segments.pcap SAR_SEG_LEN=256 SAR_BUF_ID=1 \
    regio-esnet-smartnic script run_image_test.py
```

## Environment Variables

| Variable      | Default                 | Description |
|---------------|-------------------------|-------------|
| `SAR_INPUT`   | (required)              | Input binary file path |
| `SAR_OUTPUT`  | `<input>_out.<ext>`     | Output file path |
| `SAR_PCAP`    | `segments.pcap`         | Pcap file for captured segments |
| `SAR_SEG_LEN` | `512`                   | Segment length in bytes (1–9216) |
| `SAR_BUF_ID`  | `0`                     | SAR frame buffer index (0–3) |

## Constraints

| Parameter | Value | Source |
|-----------|-------|--------|
| Max input file size | 65,536 bytes | `SAR_MAX_FRAME_SIZE` |
| Max segment length | 9,216 bytes | `SAR_MAX_PKT_SIZE` in RTL |
| Frame buffer count | 4 | `SAR_NUM_FRAME_BUFFERS` |
| HBM chunk size | 32 bytes | `CHUNK_BYTES` (min mem_proxy burst) |

## Pcap Format

Each packet in the pcap contains the raw segment payload with no network
headers (link type USER0). Segments can be inspected directly in Wireshark
as binary data.

## Reassembly Metadata

When playing segments back from the pcap, the script reconstructs the 19-bit
reassembly metadata `{buf_id[1:0], byte_offset[15:0], is_last[0]}` from the
segment's position in the pcap sequence. Byte offsets are accumulated from
actual captured segment lengths, so boundary segments shorter than `seg_len`
are handled correctly.
