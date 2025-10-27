__all__ = ()

import random
import json

from typing import List, Dict, Any
from robot.api.deco import keyword, library

from smartnic.config  import *

#---------------------------------------------------------------------------------------------------
@library
class Library:
    @keyword
    def endian_check_packed_to_unpacked(self, dev, exp_data):
        endian_check_packed_to_unpacked(dev, exp_data)

    @keyword
    def endian_check_unpacked_to_packed(self, dev, exp_data):
        endian_check_unpacked_to_packed(dev, exp_data)

    @keyword
    def reg_wr_rd_test(self, dev, num_p4_proc):
        reg_wr_rd_test(dev, num_p4_proc)

    @keyword
    def testcase_setup(self, dev, num_p4_proc):
        testcase_setup(dev, num_p4_proc)
        
    @keyword
    def testcase_teardown(self, dev):
        testcase_teardown(dev)



#---------------------------------------------------------------------------------------------------
def endian_check_packed_to_unpacked(dev, exp_data):
    # esnet-fpga-library/src/reg/endian/tests/reg_endian_check/reg_endian_check_unit_test.sv
    blk = dev.bar2.endian_check

    blk.scratchpad_packed = exp_data
    got_data = blk.scratchpad_packed_monitor_byte_0 & 0xff
    got_data |= (blk.scratchpad_packed_monitor_byte_1 & 0xff) << 8
    got_data |= (blk.scratchpad_packed_monitor_byte_2 & 0xff) << 16
    got_data |= (blk.scratchpad_packed_monitor_byte_3 & 0xff) << 24

    if got_data != exp_data:
        raise AssertionError(f'Wrote packed 0x{exp_data:08x}, got unpacked 0x{got_data:08x}')

#---------------------------------------------------------------------------------------------------
def endian_check_unpacked_to_packed(dev, exp_data):
    # esnet-fpga-library/src/reg/endian/tests/reg_endian_check/reg_endian_check_unit_test.sv
    blk = dev.bar2.endian_check

    blk.scratchpad_unpacked_byte_0 = exp_data & 0xff
    blk.scratchpad_unpacked_byte_1 = (exp_data >> 8) & 0xff
    blk.scratchpad_unpacked_byte_2 = (exp_data >> 16) & 0xff
    blk.scratchpad_unpacked_byte_3 = (exp_data >> 24) & 0xff
    got_data = int(blk.scratchpad_unpacked_monitor)

    if got_data != exp_data:
        raise AssertionError(f'Wrote unpacked 0x{exp_data:08x}, got packed 0x{got_data:08x}')

#---------------------------------------------------------------------------------------------------
def reg_wr_rd_test(dev, num_p4_proc):
    # extract all 'bar2' register paths
    paths = str(dev.bar2(formatter='path')).split()

    # list all 'smartnic' blocks, but omit 'open-nic-shell' blocks.
    smartnic_blocks = reg_blocks(paths, 'bar2', num_p4_proc)

    for block in smartnic_blocks:
        # list all 'block' register paths.
        paths = []; vars = locals()
        exec(f"paths = str(dev.bar2.{block}(formatter='json'))", globals(), vars)

        # extract and test all 'RW' fields in 'block'.
        fields = parse_reg_json(vars['paths'], 'Field', 'RW')
        for field in fields:
            reg_wr_rd(dev, field['path'], field['width'])

        # extract and test remaining 'RW' registers in 'block' (not already covered by 'field' tests).
        registers = parse_reg_json(vars['paths'], 'Register', 'RW')
        for register in registers:
            skip = False
            for field in fields:
                if field['path'] and field['path'].startswith(register['path']):
                    skip = True
                    break

            if not skip: reg_wr_rd(dev, register['path'], register['width'])

#---------------------------------------------------------------------------------------------------
def reg_wr(dev, reg, value):
    exec(f"dev.{reg}={value}")   # writes 'value' to 'reg'.

#---------------------------------------------------------------------------------------------------
def reg_rd(dev, reg):
    value = 0

    vars = locals()
    exec(f"value = dev.{reg}", vars)   # reads 'value' from 'reg'.
    value = int(vars['value'])

    return value

#---------------------------------------------------------------------------------------------------
def reg_wr_rd(dev, reg, width):
    max = (1 << width) - 1;
    wr_value = random.randint(0, max)   # generates random 'wr_value' of wordlength 'width'.

    reg_wr(dev, reg, wr_value)   # writes 'value' to 'reg'.

    rd_value = reg_rd(dev, reg)   # reads 'value' from 'reg'.

    if rd_value != wr_value:
        raise AssertionError(f'Register {reg} FAILED.  Wrote 0x{wr_value:x}, Read 0x{rd_value:x}')
    else:
        print(f'Register {reg} PASSED.  Wrote 0x{wr_value:x}, Read 0x{rd_value:x}')

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
