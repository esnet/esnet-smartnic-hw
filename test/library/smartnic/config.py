import sys
import random
import string
import time
import json

from smartnic.probes import *

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

    time.sleep(0.5) # allow time to settle.

#---------------------------------------------------------------------------------------------------
def testcase_teardown(dev):
    # read probes and dump metrics.
    metrics = read_probes()
    if len(metrics) != 0: dump_metrics(metrics, 'Metrics')

    #reg_block_rd(dev, 'dev.bar2.cmac0')
    #reg_block_rd(dev, 'dev.bar2.cmac1')

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
    if not gt:
        if (port==0 or port==2):
            dev.bar2.smartnic_regs.switch_config.cmac_0_lpbk_enable=int(enable)

        if (port==1 or port==2):
            dev.bar2.smartnic_regs.switch_config.cmac_1_lpbk_enable=int(enable)

    else:
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
# register access routines
#---------------------------------------------------------------------------------------------------
def reg_wr(dev, reg, value):
    exec(f"dev.{reg}={value}")   # writes 'value' to 'reg'.

#---------------------------------------------------------------------------------------------------
def reg_rd(dev, reg):
    value = 0

    vars = locals()
    exec(f"value = dev.{reg}", vars)   # reads 'value' from 'reg'.
    value = int(vars['value'])

    #print(f"value = dev.{reg}", value)
    return value

#---------------------------------------------------------------------------------------------------
def reg_block_rd(dev, block):
    paths = []; vars = locals()
    exec(f"paths = str({block}(formatter='json'))", globals(), vars)

    # extract and read all fields in 'block'.
    fields = parse_reg_json(vars['paths'], 'Field', None)
    for field in fields:
        rd_value = reg_rd(dev, field['path'])
        print(f"{field['path']} = 0x{rd_value:x}")

    # extract and read all remaining registers in 'block' (not already covered by 'field' reads).
    registers = parse_reg_json(vars['paths'], 'Register', None)
    for register in registers:
        skip = False
        for field in fields:
            if field['path'] and field['path'].startswith(register['path']):
                skip = True
                break

        if not skip:
            rd_value = reg_rd(dev, register['path'])
            print(f"{register['path']} = 0x{rd_value:x}")

#---------------------------------------------------------------------------------------------------
def reg_blocks(paths, root, num_p4_proc):
    # parses path list and extracts list of top-level blocks within specified root block.

    blocks = []
    prefix = root.rstrip('.') + '.'
    depth  = len(root.split('.'))

    # omit specified open-nic-shell blocks.
    omit = ['syscfg','qdma_func0','qdma_func1','qdma_subsystem',
            'cmac0','qsfp28_i2c0','cmac_adapter0','cmac1','qsfp28_i2c1','cmac_adapter1',
            'sysmon0','sysmon1','sysmon2','qspi','cms']

    if (num_p4_proc==1): omit.append('p4_proc_egr')

    for path in paths:
        if path and path.startswith(prefix):
            levels = path.split('.')
            if len(levels) >= depth:
                block = levels[depth]
                if (block not in blocks) and (block not in omit): blocks.append(block)

    return blocks

#---------------------------------------------------------------------------------------------------
def parse_reg_json(json_str, record_type=None, access_type=None):
    # parses reg json string and extracts records of specified type and access.
    # returns list of dictionaries, each record has keys: 'type','access','path',and 'width'.

    data = json.loads(json_str)

    records = []
    for record in data:
        if record_type is None or record.get('type') == record_type:
            if access_type is None or record.get('access') == access_type:
                field_info = {
                    'type':   record.get('type'),
                    'access': record.get('access'),
                    'path':   record.get('path'),
                    'width':  record.get('data', {}).get('width')
                }
                records.append(field_info)

    return records

#---------------------------------------------------------------------------------------------------
