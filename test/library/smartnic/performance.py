__all__ = ()

from robot.api.deco import keyword, library

from smartnic.config  import *
from smartnic.packets import *
from smartnic.probes  import *

import time

#---------------------------------------------------------------------------------------------------
@library
class Library:
    @keyword
    def performance_test(self, dev, port, num, size, mpps, gbps, mux_out_sel=0):
        performance_test(dev, port, num, size, mpps, gbps, mux_out_sel)

    @keyword
    def testcase_setup(self, dev, num_p4_proc):
        testcase_setup(dev, num_p4_proc)
        
    @keyword
    def testcase_teardown(self, dev):
        testcase_teardown(dev)
        
    @keyword
    def hdr_length_config(self, dev, p4_proc, length):
        hdr_length_config(dev, p4_proc, length)



#---------------------------------------------------------------------------------------------------
def performance_test(dev, port, num, size, mpps, gbps, mux_out_sel=0):
    tx_pkt = []
    clear_switch_stats()

    # configure and enable packet accelerator(s).
    for _port in range(2):
        tx_pkt.append(one_packet(size))

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
