import sys
import random
import string
import time

from smartnic.probes  import *

#---------------------------------------------------------------------------------------------------
# global variables
#---------------------------------------------------------------------------------------------------
num_p4_proc = 1

pkt_num     = 10
pkt_size    = random.randint(64, 1500)

#---------------------------------------------------------------------------------------------------
# configuration routines
#---------------------------------------------------------------------------------------------------
def testcase_setup(dev, num_p4_proc):
    reset_cmac        (dev, 2)   # reset cmacs.
    reset_box_322mhz  (dev)      # reset smartnic.

    p4_bypass_config(dev, num_p4_proc, 1)   # enable 'p4_bypass' mode for all tests.

    clear_switch_stats()   # clear stats collected in f/w.

    time.sleep(1) # allow 1 second to settle.

#---------------------------------------------------------------------------------------------------
def testcase_teardown(dev):
    cmac_loopback_config(dev, 2, 0)   # disable both cmacs.

    # read probes and dump metrics.
    metrics = read_probes()
    if len(metrics) != 0: dump_metrics(metrics, 'Metrics')

#---------------------------------------------------------------------------------------------------
def reset_box_322mhz(dev):
    dev.bar2.syscfg.user_reset=0x00010000

#---------------------------------------------------------------------------------------------------
def reset_cmac(dev, port):
    if (port==0 or port==2): dev.bar2.syscfg.shell_reset=0x000000F0
    if (port==1 or port==2): dev.bar2.syscfg.shell_reset=0x00000F00

#---------------------------------------------------------------------------------------------------
def p4_bypass_config(dev, num_p4_proc, enable):
    dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)
    if num_p4_proc == 2: dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)

#---------------------------------------------------------------------------------------------------
def hdr_length_config(dev, num_p4_proc, length):
    dev.bar2.p4_proc_igr.p4_proc.p4_proc_config.hdr_length=int(length)
    if num_p4_proc == 2: dev.bar2.p4_proc_egr.p4_proc.p4_proc_config.hdr_length=int(length)

#---------------------------------------------------------------------------------------------------
def cmac_loopback_config(dev, port, enable):
    if (port==0 or port==2):
        dev.bar2.cmac0.gt_loopback=int(enable)
        dev.bar2.cmac0.conf_rx_1.ctl_rx_enable=int(enable)
        dev.bar2.cmac0.conf_tx_1.ctl_tx_enable=int(enable)

    if (port==1 or port==2):
        dev.bar2.cmac1.gt_loopback=int(enable)
        dev.bar2.cmac1.conf_rx_1.ctl_rx_enable=int(enable)
        dev.bar2.cmac1.conf_tx_1.ctl_tx_enable=int(enable)

    time.sleep(1) # pause for cmac configuration and synchronization.

#---------------------------------------------------------------------------------------------------
