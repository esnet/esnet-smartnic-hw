__all__ = ()

from robot.api.deco import keyword, library

from config  import *
from packets import *
from probes  import *
from .tests.datapath import *

#---------------------------------------------------------------------------------------------------
@library
class Library:
    @keyword
    def pkt_playback_capture_test(self, dev, num, size, port):
        pkt_playback_capture_test(dev, num, size, port)

    @keyword
    def pkt_accelerator_test(self, dev, port):
        pkt_accelerator_test(dev, port)

    @keyword
    def testcase_setup(self, dev):
        testcase_setup(dev)
        
    @keyword
    def testcase_teardown(self, dev):
        testcase_teardown(dev)
        
    @keyword
    def clear_switch_stats(self):
        clear_switch_stats()
