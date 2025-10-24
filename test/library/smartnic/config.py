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
    reset_cmac        (dev=dev, port=2)  # reset cmacs.
    reset_box_322mhz  (dev)              # reset smartnic.

    p4_bypass_config(dev=dev, num_p4_proc=num_p4_proc, enable=1, port_type=1)  # port_type=1 (PF).

    host_loopback_config(dev=dev, port=2, enable=1)

    igr_q_config(dev=dev, port=2, host_if=0, num_q=1, base=0)  # configure 1 'PF' queue at base 0.

    clear_switch_stats()  # clear stats collected in f/w.

    time.sleep(1) # allow 1 second to settle.

#---------------------------------------------------------------------------------------------------
def testcase_teardown(dev):
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
def p4_bypass_config(dev, num_p4_proc, enable, port_type):
    dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_0 = int(port_type)
    dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_1 = int(port_type)

    dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)
    if num_p4_proc == 2: dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)

#---------------------------------------------------------------------------------------------------
def hdr_length_config(dev, num_p4_proc, length):
    dev.bar2.p4_proc_igr.p4_proc.p4_proc_config.hdr_length=int(length)
    if num_p4_proc == 2: dev.bar2.p4_proc_egr.p4_proc.p4_proc_config.hdr_length=int(length)

#---------------------------------------------------------------------------------------------------
def cmac_loopback_config(dev, port, enable, gt=True):
    if gt:
        if (port==0 or port==2):
            dev.bar2.cmac0.gt_loopback=int(enable)
            dev.bar2.cmac0.conf_rx_1.ctl_rx_enable=int(enable)
            dev.bar2.cmac0.conf_tx_1.ctl_tx_enable=int(enable)

        if (port==1 or port==2):
            dev.bar2.cmac1.gt_loopback=int(enable)
            dev.bar2.cmac1.conf_rx_1.ctl_rx_enable=int(enable)
            dev.bar2.cmac1.conf_tx_1.ctl_tx_enable=int(enable)

        time.sleep(1) # pause for cmac configuration and synchronization.

    else:
        if (port==0 or port==2):
            dev.bar2.smartnic_regs.switch_config.cmac_0_lpbk_enable=int(enable)

        if (port==1 or port==2):
            dev.bar2.smartnic_regs.switch_config.cmac_1_lpbk_enable=int(enable)

#---------------------------------------------------------------------------------------------------
def host_loopback_config(dev, port, enable):
    if (port==0 or port==2):
        dev.bar2.smartnic_regs.switch_config.host_0_lpbk_enable = int(enable)

    if (port==1 or port==2):
        dev.bar2.smartnic_regs.switch_config.host_1_lpbk_enable = int(enable)

#---------------------------------------------------------------------------------------------------
def igr_q_config(dev, port, host_if, num_q, base):
    if (port==0 or port==2):
        dev.bar2.smartnic_regs.igr_q_config_0[host_if]._r.num_q = num_q
        dev.bar2.smartnic_regs.igr_q_config_0[host_if]._r.base  = base

    if (port==1 or port==2):
        dev.bar2.smartnic_regs.igr_q_config_1[host_if]._r.num_q = num_q
        dev.bar2.smartnic_regs.igr_q_config_1[host_if]._r.base  = base

#---------------------------------------------------------------------------------------------------
