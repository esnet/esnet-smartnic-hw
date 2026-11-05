#!/usr/bin/env -S regio-esnet-smartnic script
"""Play packets into the QDMA C2H stream, toward the DMA engine.

The playback sits on the C2H stream ahead of the DMA engine, after the C2H CRC
generation.  While the playback is enabled, C2H from the core is held off and
the engine receives only the injected packets; the playback is disabled again
on exit.  Each packet is sent with a qid, a size and a tcrc computed from its
payload (see qdma_crc).

Packets come from a pcap file or, by default, are random bytes.

Configuration via environment variables (regio does not forward CLI args to the script):

    regio-esnet-smartnic script run_qdma_tx_playback.py
    QDMA_TX_PCAP=capture.pcap regio-esnet-smartnic script run_qdma_tx_playback.py
    QDMA_TX_COUNT=10 QDMA_TX_SIZE=64-1500 regio-esnet-smartnic script run_qdma_tx_playback.py

Variables:
    QDMA_TX_PCAP     Pcap file to play; packets are sent in file order
    QDMA_TX_COUNT    Packets to send: random packets to generate (default: 1), or
                     the first N packets of the pcap (default: all)
    QDMA_TX_SIZE     Random packet size in bytes, N or MIN-MAX (default: 64)
    QDMA_TX_SEED     Seed for the random packets (default: unseeded)
    QDMA_TX_QID      QDMA queue ID (default: 0)
    QDMA_TX_BURST    Times each packet is repeated back to back (default: 1)
    QDMA_TX_BAD_CRC  Set to 1 to invert each tcrc, injecting a CRC error

Each packet occupies the playback buffer one at a time, so the packet size is
limited to the buffer size.
"""

import os
import random
import sys

# Ensure test/library/ is on the path so that the 'smartnic' package resolves.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from smartnic.lib.qdma_meta import qdma_crc
from smartnic.lib.qdma_packet_playback_protocol import QdmaPacketPlaybackProtocol

PCAP    = os.environ.get('QDMA_TX_PCAP')
COUNT   = os.environ.get('QDMA_TX_COUNT')
SIZE    = os.environ.get('QDMA_TX_SIZE', '64')
SEED    = os.environ.get('QDMA_TX_SEED')
QID     = int(os.environ.get('QDMA_TX_QID', '0'), 0)
BURST   = int(os.environ.get('QDMA_TX_BURST', '1'))
BAD_CRC = os.environ.get('QDMA_TX_BAD_CRC', '0') == '1'
DEBUG   = 0


def parse_size(text):
    lo, _, hi = text.partition('-')
    lo = int(lo)
    hi = int(hi) if hi else lo
    if not 0 < lo <= hi:
        raise ValueError(f'invalid QDMA_TX_SIZE {text!r}')
    return lo, hi


def load_packets():
    if PCAP:
        from scapy.all import rdpcap
        packets = [bytes(p) for p in rdpcap(PCAP)]
        return packets[:int(COUNT)] if COUNT else packets

    rng = random.Random(int(SEED, 0) if SEED else None)
    lo, hi = parse_size(SIZE)
    return [rng.randbytes(rng.randint(lo, hi)) for _ in range(int(COUNT or 1))]


# dev0 is injected by regio-esnet-smartnic as a global.
dev = dev0  # noqa: F821

print('\n-------------- INIT ------------\n')
packets = load_packets()
source = f'pcap {PCAP}' if PCAP else 'random'
print(f'  source:  {source}, {len(packets)} packet(s)')

playback = QdmaPacketPlaybackProtocol(dev.bar2.qdma.playback, 'QDMA Playback', DEBUG)
mem_size = int(dev.bar2.qdma.playback.control.info.mem_size)

sent = 0
skipped = 0
try:
    playback.enable()

    print('\n-------------- SENDING ------------\n')
    for i, data in enumerate(packets):
        if not 0 < len(data) <= mem_size:
            print(f'  packet {i}: {len(data)}B outside 1..{mem_size}B, skipped')
            skipped += 1
            continue
        tcrc = qdma_crc(data)
        if BAD_CRC:
            tcrc ^= 0xffffffff
        playback.send(data, qid=QID, tcrc=tcrc, burst=BURST)
        sent += 1
        print(f'  packet {i}: {len(data)}B  qid {QID}  tcrc 0x{tcrc:08x}'
              f'{"  (bad)" if BAD_CRC else ""}  x{BURST}')
except KeyboardInterrupt:
    print('\nInterrupted')
finally:
    # Return C2H to the regular datapath.
    playback.disable()

print('\n-------------- SUMMARY ------------\n')
print(f'  sent:    {sent} of {len(packets)}')
if skipped:
    print(f'  skipped: {skipped}')
    sys.exit(1)
