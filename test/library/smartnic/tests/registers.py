__all__ = ()

import random
import time

from typing import List, Dict, Any
from robot.api.deco import keyword, library

from smartnic.lib.config import *

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
    def timestamp_test(self, dev):
        timestamp_test(dev)

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
def timestamp_test(dev):
    # test free-running timestamp counter.  expect delta = 2.00 sec (200 x 10ms).
    check_rd_timestamp(dev, 'bar2.smartnic_regs.freerun_rd', 200)

    # test programmable timestamp counter (including programmable increment).
    cases = [ {'incr': 0x2dbed634, 'exp': 196},    # incr = 2.859091 ns/clk, exp = 1.96 sec.
              {'incr': 0x2e8ba2e9, 'exp': 200},    # incr = 2.909091 ns/clk, exp = 2.00 sec.
              {'incr': 0x2f586fce, 'exp': 203} ]   # incr = 2.959091 ns/clk, exp = 2.03 sec.

    for case in cases:
        dev.bar2.smartnic_regs.timestamp_incr = case['incr']  # write timestamp increment.

        check_rd_timestamp(dev, 'bar2.smartnic_regs.timestamp_rd', case['exp'])

    # test timestamp write logic.
    check_wr_timestamp(dev)

#---------------------------------------------------------------------------------------------------
def check_rd_timestamp(dev, reg, exp):
    # read t0, wait (in seconds), read t1.
    t0 = rd_timestamp(dev, reg); time.sleep(2.005)
    t1 = rd_timestamp(dev, reg)

    delta = int((t1-t0)/10000000)  # calculate timestamp delta (10ms units).

    if delta != exp:
        raise AssertionError(f"Timestamp {reg} FAILED.  Expected delta={exp}, got delta={delta}.")
    else:
        print(f"Timestamp {reg} PASSED.  Expected delta={exp}, got delta={delta}.")

#---------------------------------------------------------------------------------------------------
def rd_timestamp(dev, reg):
    dev.bar2.smartnic_regs.timestamp_rd_latch = 1

    upper = reg_rd(dev, reg + '_upper')
    lower = reg_rd(dev, reg + '_lower')

    #print(f'Read timestamp: {upper << 32 | lower}. upper: 0x{upper:x}, lower: 0x{lower:x}')

    return upper << 32 | lower

#---------------------------------------------------------------------------------------------------
def check_wr_timestamp(dev):
    wr_upper = random.randint(0, ((1 << 32) - 1))
    wr_lower = random.randint(0, ((1 << 28) - 1)) << 4

    dev.bar2.smartnic_regs.timestamp_incr = 0
    dev.bar2.smartnic_regs.timestamp_wr_upper = wr_upper
    dev.bar2.smartnic_regs.timestamp_wr_lower = wr_lower

    dev.bar2.smartnic_regs.timestamp_rd_latch = 1
    rd_freerun = reg_rd(dev, 'bar2.smartnic_regs.freerun_rd_upper')
    rd_upper   = reg_rd(dev, 'bar2.smartnic_regs.timestamp_rd_upper')
    rd_lower   = reg_rd(dev, 'bar2.smartnic_regs.timestamp_rd_lower')

    if rd_freerun != wr_upper:
        raise AssertionError(f"Timestamp write FAILED. Expected wr_upper=0x{wr_upper:x}, got rd_freerun=0x{rd_freerun:x}.")
    else:
        print(f"Timestamp write PASSED. Expected wr_upper=0x{wr_upper:x}, got rd_freerun=0x{rd_freerun:x}.")

    if rd_upper != wr_upper:
        raise AssertionError(f"Timestamp write FAILED. Expected wr_upper=0x{wr_upper:x}, got rd_upper=0x{rd_upper:x}.")
    else:
        print(f"Timestamp write PASSED. Expected wr_upper=0x{wr_upper:x}, got rd_upper=0x{rd_upper:x}.")

    if rd_lower != wr_lower:
        raise AssertionError(f"Timestamp write FAILED. Expected wr_lower=0x{wr_lower:x}, got rd_lower=0x{rd_lower:x}.")
    else:
        print (f"Timestamp write PASSED. Expected wr_lower=0x{wr_lower:x}, got rd_lower=0x{rd_lower:x}.")

#---------------------------------------------------------------------------------------------------
