__all__ = ()

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
