import sys
import random
import string
import time

from scapy.all import *

sys.path.append('.')

from smartnic.packet_playback_protocol import PacketPlaybackProtocol
from smartnic.packet_capture_protocol  import PacketCaptureProtocol

from smartnic.config  import *

#---------------------------------------------------------------------------------------------------
def one_packet(size):
        pkt = ''
        for j in range(size): pkt += random.choice(string.ascii_lowercase)
        tx_pkt = bytes(pkt, encoding='utf-8')

        return tx_pkt

#---------------------------------------------------------------------------------------------------
def pkt_playback_config(dev, port):
    if (port==0): dev.bar2.smartnic_regs.smartnic_mux_out_sel[2]._r.value=0
    else:         dev.bar2.smartnic_regs.smartnic_mux_out_sel[3]._r.value=0

    playback = PacketPlaybackProtocol(dev.bar2.smartnic_pkt_playback, 'Playback')
    playback.enable()

#---------------------------------------------------------------------------------------------------
def pkt_playback (dev, pkt, tid=0, tdest=0):
    playback = PacketPlaybackProtocol(dev.bar2.smartnic_pkt_playback, 'Playback')
    playback.send(pkt, tid << 5 | tdest << 1)

#---------------------------------------------------------------------------------------------------
def pkt_capture_config(dev, port):
    capture  = PacketCaptureProtocol(dev.bar2.smartnic_pkt_capture, 'Capture')
    capture.enable()

    dev.bar2.smartnic_regs.switch_config.pkt_capture_enable=1

    if (port==0): dev.bar2.smartnic_regs.smartnic_demux_out_sel.port0=1
    else:         dev.bar2.smartnic_regs.smartnic_demux_out_sel.port1=1

#---------------------------------------------------------------------------------------------------
def pkt_capture_trigger (dev):
    capture = PacketCaptureProtocol(dev.bar2.smartnic_pkt_capture, 'Capture')
    capture.trigger()
    print("trigger")

#---------------------------------------------------------------------------------------------------
def pkt_capture_read (dev, exp=''):
    capture  = PacketCaptureProtocol(dev.bar2.smartnic_pkt_capture, 'Capture')

    (rx_pkt, rx_meta) = capture.wait_on_capture()

    if (exp == ''):
        Raw(raw(rx_pkt)).show()
    elif (raw(rx_pkt) != exp):
        Raw(raw(rx_pkt)).show(); Raw(exp).show()
        return False

    return True

#---------------------------------------------------------------------------------------------------
def pkt_playback_capture(dev, num, size, port=0):
    for i in range(num):
        tx_pkt = one_packet(size)

        pkt_capture_trigger (dev)
        pkt_playback (dev, tx_pkt, port, port)
        result = pkt_capture_read (dev, tx_pkt)

        if (result != True): raise AssertionError(f'Packet data received did NOT match expected!')

#---------------------------------------------------------------------------------------------------
def rnd_playback_capture(dev, num, port=0):
    bytes = 0
    for i in range(num):
        size = random.randint(64, 1500)
        bytes = bytes + size
        pkt_playback_capture (dev, 1, size, port)

    time.sleep(1) # wait in seconds, for stats collection.

    return bytes



#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
def pkt_accelerator_config(dev, port, mux_out_sel):
    if (port==0):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=int(mux_out_sel)
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[2]._r.value=int(mux_out_sel)
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port0=0

    else:
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=int(mux_out_sel)
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[3]._r.value=int(mux_out_sel)
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port1=0

    cmac_loopback_config(dev, port)

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_inject(dev, num, pkt, port):
    pkt_playback_config(dev, port)

    for i in range(num): pkt_playback (dev, pkt, port, port)

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_extract(dev, num, exp, port):
    pkt_capture_config (dev, port)

    result=True
    for i in range(num):
        pkt_capture_trigger (dev)
        result = result and pkt_capture_read (dev, exp)

    if (result != True): raise AssertionError(f'Packet data received did NOT match expected!')

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_flush(dev, port):
    if (port==0): dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=3
    else:         dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=3

#---------------------------------------------------------------------------------------------------
