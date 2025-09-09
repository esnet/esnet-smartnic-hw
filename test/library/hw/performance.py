__all__ = ()

from robot.api.deco import keyword, library

from config  import *
from packets import *
from probes  import *
from .tests.performance import *

#---------------------------------------------------------------------------------------------------
@library
class Library:
    @keyword
    def performance_test(self, dev, port, num, size, mpps, gbps, mux_out_sel=0):
        performance_test(dev, port, num, size, mpps, gbps, mux_out_sel)

    @keyword
    def testcase_setup(self, dev):
        testcase_setup(dev)
        
    @keyword
    def testcase_teardown(self, dev):
        testcase_teardown(dev)
        
    @keyword
    def p4_bypass_config(self, dev, enable):
        p4_bypass_config(dev, enable)

    @keyword
    def hdr_length_config(self, dev, length):
        hdr_length_config(dev, length)
