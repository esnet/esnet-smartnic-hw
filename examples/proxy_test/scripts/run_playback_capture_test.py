#!/usr/bin/env -S regio-esnet-smartnic script

import sys
import random
import string

from scapy.all import *

sys.path.append('.')

from packet_playback_protocol import PacketPlaybackProtocol
from packet_capture_protocol import PacketCaptureProtocol

DEBUG=1

print('\n-------------- INIT ------------\n')

# Configure playback/capture drivers
playback = PacketPlaybackProtocol(dev0.bar2.packet_playback, 'Playback', DEBUG)
capture = PacketCaptureProtocol(dev0.bar2.packet_capture, 'Capture', DEBUG)

# Enable
capture.enable()
playback.enable()

print('\n-------------- TEST 1 ------------\n')

# Trigger capture
capture.trigger()
## Send packet
playback.send(bytes('Hello World!', encoding='utf-8'))
## Read (and display) captured packet
(rx_pkt, rx_meta) = capture.wait_on_capture()
print('---')
Raw(raw(rx_pkt)).show()

print('\n-------------- TEST 2 ------------\n')

# Create packet
l2 = Ether(dst="01:02:03:04:05:06", src="07:08:09:0A:0B:0C")
l3 = IP(dst='lbl.gov/27',src='es.net/28')
l4 = TCP(sport=1024,dport=2048)

payload = ''
for i in range(1000): payload += random.choice(string.ascii_lowercase) # 64B pkt
pkt = l2/l3/l4/Raw(load=payload)

# Trigger capture
capture.trigger()
# Send packet
playback.send(raw(pkt), 0xABAB)
# Read (and display) captured packet
(rx_pkt, rx_meta) = capture.wait_on_capture()
print('---')
Ether(raw(rx_pkt)).show()

print('\n-------------- TEST 3 ------------\n')

BURST_SIZE = 20

# Create packet
l2 = Ether(dst="0a:0b:0c:0d:0e:0f", src="a0:b0:c0:d0:e0:f0")
l3 = IP(dst='12.34.56.78',src='88.99.100.111')
l4 = TCP(sport=22,dport=29210)

payload = ''
for i in range(500): payload += random.choice(string.ascii_lowercase) # 64B pkt
pkt = l2/l3/l4/Raw(load=payload)

# Send packet burst
playback.send(raw(pkt), 0x1234567, burst=BURST_SIZE)

# Capture
for i in range(BURST_SIZE):
    print(f'--- Packet {i+1}/{BURST_SIZE} ---')
    (rx_pkt, rx_meta) = capture.capture()
    Ether(raw(rx_pkt)).show()

