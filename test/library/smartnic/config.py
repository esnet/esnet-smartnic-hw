import sys
import random
import string
import time

from smartnic.probes  import *

#---------------------------------------------------------------------------------------------------
# global variables
#---------------------------------------------------------------------------------------------------
num_p4_proc = 1

num  = 10
size = random.randint(64, 1500)


#---------------------------------------------------------------------------------------------------
# configuration routines
#---------------------------------------------------------------------------------------------------
def testcase_setup(dev, num_p4_proc):
    dev.bar2.cmac0.gt_reset=1; dev.bar2.cmac1.gt_reset=1;

    reset_box_322mhz(dev)

    p4_bypass_config(dev, 'igr', 1)
    if (num_p4_proc == 2): p4_bypass_config(dev, 'egr', 1)

    clear_switch_stats()  # clears stats collection in f/w.

#---------------------------------------------------------------------------------------------------
def testcase_teardown(dev):
    dev.bar2.cmac0.gt_loopback=0
    dev.bar2.cmac0.conf_rx_1.ctl_rx_enable=0
    dev.bar2.cmac0.conf_tx_1.ctl_tx_enable=0

    dev.bar2.cmac1.gt_loopback=0
    dev.bar2.cmac1.conf_rx_1.ctl_rx_enable=0
    dev.bar2.cmac1.conf_tx_1.ctl_tx_enable=0

    time.sleep(1) # allow 1 second to settle.

#---------------------------------------------------------------------------------------------------
def reset_box_322mhz(dev):
    dev.bar2.syscfg.user_reset=0x00010000

    time.sleep(0.01) # pause for reset recovery.

#---------------------------------------------------------------------------------------------------
def p4_bypass_config(dev, p4_proc, enable):
    if (p4_proc == 'igr'): dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)
    else:                  dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)

    time.sleep(0.01) # pause for configuration.

#---------------------------------------------------------------------------------------------------
def hdr_length_config(dev, p4_proc, length):
    if (p4_proc == 'igr'): dev.bar2.p4_proc_igr.p4_proc.p4_proc_config.hdr_length=int(length)
    else:                  dev.bar2.p4_proc_egr.p4_proc.p4_proc_config.hdr_length=int(length)

    time.sleep(0.01) # pause for configuration.

#---------------------------------------------------------------------------------------------------
def cmac_loopback_config(dev, port):
    if (port==0 or port==2):
        dev.bar2.cmac0.gt_loopback=1
        dev.bar2.cmac0.conf_rx_1.ctl_rx_enable=1
        dev.bar2.cmac0.conf_tx_1.ctl_tx_enable=1

    if (port==1 or port==2):
        dev.bar2.cmac1.gt_loopback=1
        dev.bar2.cmac1.conf_rx_1.ctl_rx_enable=1
        dev.bar2.cmac1.conf_tx_1.ctl_tx_enable=1

    time.sleep(1) # pause for cmac configuration and synchronization.

#---------------------------------------------------------------------------------------------------
