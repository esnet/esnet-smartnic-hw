import random
import time

from smartnic.lib.registers import *
from smartnic.lib.probes    import *

#---------------------------------------------------------------------------------------------------
# global variables
#---------------------------------------------------------------------------------------------------
NUM_P4_PROC = 1
VERSAL      = False

pkt_num     = 10
pkt_size    = random.randint(64, 1500)

#---------------------------------------------------------------------------------------------------
# configuration routines
#---------------------------------------------------------------------------------------------------
def query_build(dev):
    global NUM_P4_PROC, VERSAL

    try:
        status = int(dev.bar2.p4_proc_egr.p4_proc.status)
        NUM_P4_PROC = 2 if status == 0xcafebeef else 1
    except Exception:
        NUM_P4_PROC = 1

    try:
        dev.bar2.dcmac0.mac.glbl.global_mode
        VERSAL = True
    except Exception:
        VERSAL = False

    print(f'query_build: NUM_P4_PROC={NUM_P4_PROC}, VERSAL={VERSAL}')

    try:
        from robot.libraries.BuiltIn import BuiltIn
        BuiltIn().set_suite_variable('${VERSAL}', VERSAL)
    except Exception:
        pass

#---------------------------------------------------------------------------------------------------
def testcase_setup(dev):
    query_build(dev)

    if VERSAL:
        reset_dcmac0      (dev)                   # reset dcmac0.
        dev.bar2.smartnic_regs.smartnic_srst=0x1  # reset smartnic.
    else:
        reset_cmac        (dev=dev, port=2)       # reset cmacs.
        reset_box_322mhz  (dev)                   # reset box_322mhz.

    p4_bypass_config(dev=dev, enable=1, port_type=1)  # port_type=1 (PF).

    host_loopback_config(dev=dev, port=2, enable=1)

    igr_q_config(dev=dev, port=2, host_if=0, num_q=1, base=0)  # configure 1 'PF' queue at base 0.

    clear_switch_stats()  # clear stats collected in f/w.

    time.sleep(0.5) # allow time to settle.

#---------------------------------------------------------------------------------------------------
def testcase_teardown(dev):
    # read probes and dump metrics.
    metrics = read_probes()
    if len(metrics) != 0: dump_metrics(metrics, 'Metrics')

    #reg_block_rd(dev, 'dev.bar2')

#---------------------------------------------------------------------------------------------------
def reset_box_322mhz(dev):
    dev.bar2.syscfg.user_reset=0x00010000

#---------------------------------------------------------------------------------------------------
def reset_cmac(dev, port):
    if (port==0 or port==2): dev.bar2.syscfg.shell_reset=0x000000F0
    if (port==1 or port==2): dev.bar2.syscfg.shell_reset=0x00000F00

#---------------------------------------------------------------------------------------------------
def reset_dcmac0(dev):
    dev.bar2.dcmac0.mac.glbl.global_mode=0x01550022

    # set data rate.
    dev.bar2.dcmac0.mac.ch0.tx_mode_reg=0x0008_0215
    dev.bar2.dcmac0.mac.ch0.rx_mode_reg=0x0008_1a01
    dev.bar2.dcmac0.mac.ch2.tx_mode_reg=0x0008_0215
    dev.bar2.dcmac0.mac.ch2.rx_mode_reg=0x0008_1a01

    # Loopback modes.  0x0: Disabled. 0x1: Nearend PCS. 0x2: Nearend PMA.
    dev.bar2.dcmac0.regs.dcmac_gt_loopback_ctrl.gt_loopback=0x2

    for i in range(10):
        dev.bar2.dcmac0.regs.dcmac_gt_reset_ctrl.gt_reset_all=0x1  # assert reset.
        time.sleep(0.1)

        dev.bar2.dcmac0.regs.dcmac_gt_reset_ctrl.gt_reset_all=0x0  # deassert reset.
        time.sleep(0.1)

        dev.bar2.dcmac0.mac.ch0.port_tick_reg_rx=0x0000_0001 # latch all
        dev.bar2.dcmac0.mac.ch0.port_tick_reg_tx=0x0000_0001
        dev.bar2.dcmac0.mac.ch2.port_tick_reg_rx=0x0000_0001
        dev.bar2.dcmac0.mac.ch2.port_tick_reg_tx=0x0000_0001

        dev.bar2.dcmac0.mac.ch0.stat_port_rx_phy_status_reg=0xFFFF_FFFF
        dev.bar2.dcmac0.mac.ch1.stat_port_rx_phy_status_reg=0xFFFF_FFFF

        retry = False
        rd_value = reg_rd(dev, f"bar2.dcmac0.mac.ch0.stat_port_rx_phy_status_reg")
        retry = retry or rd_value != 0x00000005
        rd_value = reg_rd(dev, f"bar2.dcmac0.mac.ch1.stat_port_rx_phy_status_reg")
        retry = retry or rd_value != 0x00000005

        if retry:
            print(f"Retrying GT reset: Iteration {i}.")
        else:
            print("GT reset Done and DCMAC Aligned!")
            break

#---------------------------------------------------------------------------------------------------
def reset_dcmac2(dev):
    dev.bar2.dcmac0.mac.glbl.global_control_reg_rx=0xffff_ffff # assert all resets

    dev.bar2.dcmac0.mac.ch0.port_control_reg_rx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch1.port_control_reg_rx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch2.port_control_reg_rx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch3.port_control_reg_rx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch4.port_control_reg_rx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch5.port_control_reg_rx=0xffff_ffff

    dev.bar2.dcmac0.mac.glbl.global_control_reg_tx=0xffff_ffff

    dev.bar2.dcmac0.mac.ch0.port_control_reg_tx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch1.port_control_reg_tx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch2.port_control_reg_tx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch3.port_control_reg_tx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch4.port_control_reg_tx=0xffff_ffff
    dev.bar2.dcmac0.mac.ch5.port_control_reg_tx=0xffff_ffff

    dev.bar2.dcmac0.mac.ch0.channel_control_reg_rx=0x0000_0001 # client reset flush
    dev.bar2.dcmac0.mac.ch0.channel_control_reg_tx=0x0000_0001
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch0.port_control_reg_rx=0x0000_0003
    dev.bar2.dcmac0.mac.ch0.port_control_reg_tx=0x0000_0003

    dev.bar2.dcmac0.mac.ch1.channel_control_reg_rx=0x0000_0001
    dev.bar2.dcmac0.mac.ch1.channel_control_reg_tx=0x0000_0001
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch1.port_control_reg_rx=0x0000_0003
    dev.bar2.dcmac0.mac.ch1.port_control_reg_tx=0x0000_0003

    dev.bar2.dcmac0.mac.ch2.channel_control_reg_rx=0x0000_0001
    dev.bar2.dcmac0.mac.ch2.channel_control_reg_tx=0x0000_0001
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch2.port_control_reg_rx=0x0000_0003
    dev.bar2.dcmac0.mac.ch2.port_control_reg_tx=0x0000_0003

    dev.bar2.dcmac0.mac.ch3.channel_control_reg_rx=0x0000_0001
    dev.bar2.dcmac0.mac.ch3.channel_control_reg_tx=0x0000_0001
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch3.port_control_reg_rx=0x0000_0003
    dev.bar2.dcmac0.mac.ch3.port_control_reg_tx=0x0000_0003

    dev.bar2.dcmac0.mac.ch4.channel_control_reg_rx=0x0000_0001
    dev.bar2.dcmac0.mac.ch4.channel_control_reg_tx=0x0000_0001
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch4.port_control_reg_rx=0x0000_0003
    dev.bar2.dcmac0.mac.ch4.port_control_reg_tx=0x0000_0003

    dev.bar2.dcmac0.mac.ch5.channel_control_reg_rx=0x0000_0001
    dev.bar2.dcmac0.mac.ch5.channel_control_reg_tx=0x0000_0001
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch5.port_control_reg_rx=0x0000_0003
    dev.bar2.dcmac0.mac.ch5.port_control_reg_tx=0x0000_0003

    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch0.tx_mode_reg=0x0008_0215 # set data rate
    dev.bar2.dcmac0.mac.ch0.rx_mode_reg=0x0008_1a01
    dev.bar2.dcmac0.mac.ch2.tx_mode_reg=0x0008_0215
    dev.bar2.dcmac0.mac.ch2.rx_mode_reg=0x0008_1a01

    dev.bar2.dcmac0.mac.glbl.global_control_reg_rx=0x0000_0000 # release all resets

    dev.bar2.dcmac0.mac.ch0.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch1.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch2.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch3.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch4.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch5.port_control_reg_rx=0x0000_0000

    dev.bar2.dcmac0.mac.glbl.global_control_reg_tx=0x0000_0000

    dev.bar2.dcmac0.mac.ch0.port_control_reg_tx=0x0000_0000
    dev.bar2.dcmac0.mac.ch1.port_control_reg_tx=0x0000_0000
    dev.bar2.dcmac0.mac.ch2.port_control_reg_tx=0x0000_0000
    dev.bar2.dcmac0.mac.ch3.port_control_reg_tx=0x0000_0000
    dev.bar2.dcmac0.mac.ch4.port_control_reg_tx=0x0000_0000
    dev.bar2.dcmac0.mac.ch5.port_control_reg_tx=0x0000_0000

    dev.bar2.dcmac0.mac.ch0.port_control_reg_rx=0x0000_0000 # client release flush
    dev.bar2.dcmac0.mac.ch0.port_control_reg_tx=0x0000_0000
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch0.channel_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch0.channel_control_reg_tx=0x0000_0000

    dev.bar2.dcmac0.mac.ch1.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch1.port_control_reg_tx=0x0000_0000
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch1.channel_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch1.channel_control_reg_tx=0x0000_0000

    dev.bar2.dcmac0.mac.ch2.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch2.port_control_reg_tx=0x0000_0000
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch2.channel_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch2.channel_control_reg_tx=0x0000_0000

    dev.bar2.dcmac0.mac.ch3.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch3.port_control_reg_tx=0x0000_0000
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch3.channel_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch3.channel_control_reg_tx=0x0000_0000

    dev.bar2.dcmac0.mac.ch4.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch4.port_control_reg_tx=0x0000_0000
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch4.channel_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch4.channel_control_reg_tx=0x0000_0000

    dev.bar2.dcmac0.mac.ch5.port_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch5.port_control_reg_tx=0x0000_0000
    time.sleep(0.1)
    dev.bar2.dcmac0.mac.ch5.channel_control_reg_rx=0x0000_0000
    dev.bar2.dcmac0.mac.ch5.channel_control_reg_tx=0x0000_0000

    dev.bar2.dcmac0.mac.ch0.port_tick_reg_rx=0x0000_0001 # latch all
    dev.bar2.dcmac0.mac.ch0.port_tick_reg_tx=0x0000_0001
    dev.bar2.dcmac0.mac.ch2.port_tick_reg_rx=0x0000_0001
    dev.bar2.dcmac0.mac.ch2.port_tick_reg_tx=0x0000_0001

    time.sleep(0.1)

#---------------------------------------------------------------------------------------------------
def p4_bypass_config(dev, enable, port_type):
    dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_0 = int(port_type)
    dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_1 = int(port_type)

    dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)
    if NUM_P4_PROC == 2: dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_enable=int(enable)

#---------------------------------------------------------------------------------------------------
def hdr_length_config(dev, length):
    dev.bar2.p4_proc_igr.p4_proc.p4_proc_config.hdr_length=int(length)
    if NUM_P4_PROC == 2: dev.bar2.p4_proc_egr.p4_proc.p4_proc_config.hdr_length=int(length)

#---------------------------------------------------------------------------------------------------
def cmac_loopback_config(dev, port, enable, gt=True):
    if not gt:
        if (port==0 or port==2):
            dev.bar2.smartnic_regs.switch_config.cmac_0_lpbk_enable=int(enable)

        if (port==1 or port==2):
            dev.bar2.smartnic_regs.switch_config.cmac_1_lpbk_enable=int(enable)

    elif not VERSAL:
        gt_flags = [{'name':'stat_tx_status',      'value':0},
                    {'name':'stat_rx_status',      'value':3},  # stat_rx_aligned=1, stat_rx_status=1.
                    {'name':'stat_rx_bad_code',    'value':0},
                    {'name':'stat_tx_frame_error', 'value':0},
                    {'name':'stat_rx_bip_err_0',   'value':0},
                    {'name':'stat_rx_bip_err_1',   'value':0},
                    {'name':'stat_rx_bip_err_2',   'value':0},
                    {'name':'stat_rx_bip_err_3',   'value':0},
                    {'name':'stat_rx_bip_err_4',   'value':0},
                    {'name':'stat_rx_bip_err_5',   'value':0},
                    {'name':'stat_rx_bip_err_6',   'value':0},
                    {'name':'stat_rx_bip_err_7',   'value':0},
                    {'name':'stat_rx_bip_err_8',   'value':0},
                    {'name':'stat_rx_bip_err_9',   'value':0},
                    {'name':'stat_rx_bip_err_10',  'value':0},
                    {'name':'stat_rx_bip_err_11',  'value':0},
                    {'name':'stat_rx_bip_err_12',  'value':0},
                    {'name':'stat_rx_bip_err_13',  'value':0},
                    {'name':'stat_rx_bip_err_14',  'value':0},
                    {'name':'stat_rx_bip_err_15',  'value':0},
                    {'name':'stat_rx_bip_err_16',  'value':0},
                    {'name':'stat_rx_bip_err_17',  'value':0},
                    {'name':'stat_rx_bip_err_18',  'value':0},
                    {'name':'stat_rx_bip_err_19',  'value':0}]

        for i in range(10):
            cmacs = []
            if (port==0 or port==2): cmacs.append('cmac0')
            if (port==1 or port==2): cmacs.append('cmac1')

            reset_cmac (dev, port) # reset cmacs.

            for cmac in cmacs:
                exec(f"dev.bar2.{cmac}.gt_loopback=int({enable})")
                exec(f"dev.bar2.{cmac}.conf_rx_1.ctl_rx_enable=int({enable})")
                exec(f"dev.bar2.{cmac}.conf_tx_1.ctl_tx_enable=int({enable})")

            time.sleep(0.5) # pause for cmac synchronization.

            # test 'gt_flags' for expected values, and set 'retry' if mismatched.
            retry = False
            for cmac in cmacs:
                for flag in gt_flags:
                    # read twice to collect historical (since last read) and current status.
                    for j in range(2): rd_value = reg_rd(dev, f"bar2.{cmac}.{flag['name']}")

                    retry = retry or rd_value != flag['value']

            if retry:
                print(f"Retrying GT Configuration: Iteration {i}.")
            else:
                print("GT Configuration Done!")
                break

        #if (port==0 or port==2): reg_block_rd(dev, 'dev.bar2.cmac0')
        #if (port==1 or port==2): reg_block_rd(dev, 'dev.bar2.cmac1')

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
