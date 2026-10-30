#!/usr/bin/env -S regio-esnet-smartnic script
"""Arm the QDMA H2C packet capture, wait for host-sent packets, and analyze them.

The capture sits on the H2C stream as it arrives from the DMA engine, ahead of
the H2C CRC check, so each captured packet carries the qid and tcrc exactly as
the engine supplied them.  While the capture is enabled, H2C is diverted into
the capture buffer and the datapath receives nothing; the capture is disabled
again on exit.

For each packet the script prints the size, qid and tcrc, compares the tcrc to
the CRC-32 of the captured payload, and dumps the leading bytes.

Configuration via environment variables (regio does not forward CLI args to the script):

    regio-esnet-smartnic script run_qdma_rx_capture.py
    QDMA_RX_COUNT=5 regio-esnet-smartnic script run_qdma_rx_capture.py

Variables:
    QDMA_RX_COUNT  Number of packets to capture (default: 1)
    QDMA_RX_DUMP   Payload bytes to hex-dump per packet (default: 64)
    QDMA_RX_SCAPY  Set to 1 to also decode each packet as Ethernet with scapy

While the script waits, send traffic from the host to the QDMA queue.  Ctrl-C
abandons the wait and disables the capture.
"""

import os
import sys

# Ensure test/library/ is on the path so that the 'smartnic' package resolves.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from smartnic.lib.qdma_meta import qdma_crc
from smartnic.lib.qdma_packet_capture_protocol import QdmaPacketCaptureProtocol

COUNT = int(os.environ.get('QDMA_RX_COUNT', '1'))
DUMP  = int(os.environ.get('QDMA_RX_DUMP', '64'))
SCAPY = os.environ.get('QDMA_RX_SCAPY', '0') == '1'
DEBUG = 0


def hexdump(data, limit):
    data = bytes(data)[:limit]
    for off in range(0, len(data), 16):
        chunk = data[off:off+16]
        hex_part = ' '.join(f'{b:02x}' for b in chunk)
        asc_part = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
        print(f'    {off:04x}  {hex_part:<47}  {asc_part}')


def crc_match(tcrc, data):
    """Name the common CRC conventions that match tcrc ([] if none do)."""
    crc = qdma_crc(data)
    candidates = {
        'crc32':              crc,
        'crc32 inverted':     crc ^ 0xffffffff,
        'crc32 byte-swapped': int.from_bytes(crc.to_bytes(4, 'little'), 'big'),
    }
    return [name for name, value in candidates.items() if value == tcrc]


def analyze(index, data, meta):
    data = bytes(data)
    crc = qdma_crc(data)
    print(f'--- Packet {index} ---')
    print(f'  size:       {len(data)}B')
    print(f'  qid:        {meta.qid}')
    print(f'  tcrc:       0x{meta.tcrc:08x}')
    print(f'  payload crc: 0x{crc:08x}')

    if meta.crc_ok(data):
        verdict = 'MATCH'
    elif meta.tcrc == 0:
        verdict = 'MISMATCH (tcrc is zero)'
    else:
        other = crc_match(meta.tcrc, data)
        verdict = 'MISMATCH' + (f' (matches {", ".join(other)})' if other else '')
    print(f'  crc check:  {verdict}')

    hexdump(data, DUMP)
    if SCAPY:
        from scapy.all import Ether
        print('  scapy:')
        Ether(data).show()
    return meta.crc_ok(data)


# dev0 is injected by regio-esnet-smartnic as a global.
dev = dev0  # noqa: F821

print('\n-------------- INIT ------------\n')
capture = QdmaPacketCaptureProtocol(dev.bar2.qdma.capture, 'QDMA Capture', DEBUG)

results = []
try:
    capture.enable()

    for i in range(COUNT):
        print(f'\n-------------- WAITING FOR PACKET {i+1} of {COUNT} ------------\n')
        capture.trigger()
        (data, meta) = capture.wait_on_capture()
        results.append(analyze(i, data, meta))
except KeyboardInterrupt:
    print('\nInterrupted')
finally:
    # Return H2C to the regular datapath.
    capture.disable()

print('\n-------------- SUMMARY ------------\n')
print(f'  captured: {len(results)} of {COUNT}')
print(f'  crc ok:   {sum(results)}')
if results and not all(results):
    sys.exit(1)
