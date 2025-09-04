import sys
import random
import string
import time

#---------------------------------------------------------------------------------------------------
def testcase_setup(dev):
    reset_box_322mhz(dev)
    
#---------------------------------------------------------------------------------------------------
def testcase_teardown(dev):
    time.sleep(1) # allow 1 second to settle.

#---------------------------------------------------------------------------------------------------
def reset_box_322mhz(dev):
    dev.bar2.syscfg.user_reset=0x00010000

    time.sleep(0.01) # pause for reset recovery.

#---------------------------------------------------------------------------------------------------
def p4_bypass_config(dev, enable):
    dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)
    dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)

    time.sleep(0.01) # pause for configuration.

#---------------------------------------------------------------------------------------------------
def hdr_length_config(dev, length):
    dev.bar2.p4_proc_igr.p4_proc.p4_proc_config.hdr_length=int(length)
    dev.bar2.p4_proc_egr.p4_proc.p4_proc_config.hdr_length=int(length)

    time.sleep(0.01) # pause for configuration.

#---------------------------------------------------------------------------------------------------

