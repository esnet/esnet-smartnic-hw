import time

from packets import *
from probes  import *

#---------------------------------------------------------------------------------------------------
def performance_test(dev, port, num, size, mpps, gbps, mux_out_sel=0):
    tx_pkt = []
    clear_switch_stats()

    # configure and enable packet accelerator(s).
    for _port in range(2):
        pkt = ''
        for i in range(size): pkt += random.choice(string.ascii_lowercase)             
        tx_pkt.append(bytes(pkt, encoding='utf-8'))

        if (port==2 or port==_port):
            pkt_accelerator_config (dev, _port, mux_out_sel)
            pkt_accelerator_inject (dev, num, tx_pkt[_port], _port)

    # check packet rates
    for _port in range(2):
        if (port==2 or port==_port): check_rates(_port, mpps, gbps)

    # extract packets
    for _port in range(2):
        if (port==2 or port==_port):
            pkt_accelerator_extract (dev, num, tx_pkt[_port], _port)
            #pkt_accelerator_flush (dev, _port)
            time.sleep(1)

#---------------------------------------------------------------------------------------------------
