import sys
import random
import string
import time

from scapy.all import *

sys.path.append('.')

from smartnic.config  import *

from smartnic.packet_playback_protocol import PacketPlaybackProtocol
from smartnic.packet_capture_protocol  import PacketCaptureProtocol

#---------------------------------------------------------------------------------------------------
def one_packet(size):
        pkt = ''
        for j in range(size): pkt += random.choice(string.ascii_lowercase)
        tx_pkt = bytes(pkt, encoding='utf-8')

        return tx_pkt

#---------------------------------------------------------------------------------------------------
def pkt_playback_config(dev, port, mux_out_sel=0):
    if (port==0):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[2]._r.value=int(mux_out_sel) # default=0 (APP).
    else:
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[3]._r.value=int(mux_out_sel) # default=0 (APP).

    playback = PacketPlaybackProtocol(dev.bar2.smartnic_pkt_playback, 'Playback')
    playback.enable()

#---------------------------------------------------------------------------------------------------
def pkt_playback (dev, pkt, tid=0, tdest=0):
    playback = PacketPlaybackProtocol(dev.bar2.smartnic_pkt_playback, 'Playback')
    playback.send(pkt, tid << 5 | tdest << 1)   # meta = {tid[3:0], tdest[3:0], tuser}

#---------------------------------------------------------------------------------------------------
def rnd_playback(dev, num, port):
    bytes = 0
    for i in range(num):
        size = random.randint(64, 1500)
        bytes = bytes + size
        tx_pkt = one_packet(size)

        pkt_playback (dev, tx_pkt, port, port)

    return bytes

#---------------------------------------------------------------------------------------------------
def pkt_capture_config(dev, port):
    capture  = PacketCaptureProtocol(dev.bar2.smartnic_pkt_capture, 'Capture')
    capture.enable()

    if (port==0):
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port0=1  # P0 to PF0_VF2.
        dev.bar2.smartnic_regs.switch_config.pkt_capture_enable_0=1
    else:
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port1=1  # P1 to PF1_VF2.
        dev.bar2.smartnic_regs.switch_config.pkt_capture_enable_1=1

#---------------------------------------------------------------------------------------------------
def pkt_capture_trigger (dev):
    capture = PacketCaptureProtocol(dev.bar2.smartnic_pkt_capture, 'Capture')
    capture.trigger()

#---------------------------------------------------------------------------------------------------
def pkt_capture_read (dev, exp=''):
    capture  = PacketCaptureProtocol(dev.bar2.smartnic_pkt_capture, 'Capture')

    (rx_pkt, rx_meta) = capture.wait_on_capture()

    if (exp == ''):
        print("Received: "); Raw(raw(rx_pkt)).show()
    elif (raw(rx_pkt) != exp):
        print("Received: "); Raw(raw(rx_pkt)).show();
        print("Expected: "); Raw(exp).show()
        raise AssertionError(f'Packet data received did NOT match expected!')

#---------------------------------------------------------------------------------------------------
def pkt_playback_capture(dev, num, size, port):
    for i in range(num):
        tx_pkt = one_packet(size)

        print(f'Packet #{i} size: {size}')
        pkt_capture_trigger (dev)
        pkt_playback        (dev, tx_pkt, port, port)
        pkt_capture_read    (dev, tx_pkt)

#---------------------------------------------------------------------------------------------------
def rnd_playback_capture(dev, num, port):
    bytes = 0
    for i in range(num):
        print(f'Packet #{i}')
        size = random.randint(64, 1500)
        bytes = bytes + size
        pkt_playback_capture (dev, 1, size, port)

    return bytes

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_config(dev, port, mux_out_sel=0, gt=True):
    pkt_playback_config(dev, port, mux_out_sel)

    if (port==0):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=int(mux_out_sel)
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port0=0

    else:
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=int(mux_out_sel)
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port1=0

    cmac_loopback_config(dev=dev, port=port, enable=1, gt=gt)

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_inject(dev, num, pkt, port):
    for i in range(num):
        pkt_playback (dev, pkt, port, port)
        print(f'Port {port} - pkt_accelerator_inject - Packet #{i} size {len(pkt)}')

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_extract(dev, num, exp, port):
    dev.bar2.smartnic_regs.switch_config.igr_sw_tpause = 1  # assert tpause to igr FIFOs.

    if (port==0): dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=2  # PHY0 to BYPASS.
    else:         dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=2  # PHY1 to BYPASS.

    pkt_capture_config (dev, port)

    dev.bar2.smartnic_regs.switch_config.igr_sw_tpause = 0  # deassert tpause to igr FIFOs.

    for i in range(num):
        pkt_capture_trigger (dev)
        pkt_capture_read    (dev, exp)
        print(f'Port {port} - pkt_accelerator_extract - Packet #{i} size {len(exp)}')

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_flush(dev, port):
    if (port==0): dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=3  # PHY0 to BYPASS DROP.
    else:         dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=3  # PHY1 to BYPASS DROP.

#---------------------------------------------------------------------------------------------------
