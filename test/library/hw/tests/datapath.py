import time

from packets import *
from probes  import *

#---------------------------------------------------------------------------------------------------
def pkt_playback_capture_test(dev, num, size, port):
    pkt_playback_capture (dev, num, size, port)

    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0):
        check_probe ('probe_from_pf0_vf2', num, num*size)
        check_probe ('probe_to_pf0_vf2',   num, num*size)
    else:
        check_probe ('probe_from_pf1_vf2', num, num*size)
        check_probe ('probe_to_pf1_vf2',   num, num*size)

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_test(dev, port):
    num  = 125
    size = 64

    pkt = ''
    for i in range(size): pkt += random.choice(string.ascii_lowercase)             
    tx_pkt = bytes(pkt, encoding='utf-8')

    clear_switch_stats()

    pkt_accelerator_config (dev, port, 0)  # mux_out_sel = 0 = APP
    pkt_accelerator_inject (dev, num, tx_pkt, port)

    time.sleep(5) # wait in seconds, pkt_accelerator run time.

    _num  = 100
    _size = random.randint(64, 1500)
    if (port==0): _port = 1
    else:         _port = 0

    pkt_playback_capture_test (dev, _num, _size, _port)

    pkt_accelerator_extract (dev, num, tx_pkt, port)
    #pkt_accelerator_flush (dev, port)

#---------------------------------------------------------------------------------------------------
