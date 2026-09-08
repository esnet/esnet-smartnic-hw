__all__ = ()

from robot.api.deco import keyword, library

from sar_test.lib.sar_test_config import testcase_setup, testcase_teardown
from sar_test.lib.sar_reassembly_test import (
    sar_reassembly_sanity_test,
    sar_reassembly_single_segment_test,
    sar_reassembly_multi_segment_in_order_test,
    sar_reassembly_multi_segment_out_of_order_test,
    sar_reassembly_multi_frame_interleaved_test,
    sar_reassembly_timeout_test,
    sar_reassembly_debug_counters_test,
)


@library
class Library:
    @keyword
    def testcase_setup(self, dev):
        testcase_setup(dev)

    @keyword
    def testcase_teardown(self, dev):
        testcase_teardown(dev)

    @keyword
    def sar_reassembly_sanity_test(self, dev):
        sar_reassembly_sanity_test(dev)

    @keyword
    def sar_reassembly_single_segment_test(self, dev, buf_id=0, frame_size=64):
        sar_reassembly_single_segment_test(dev, int(buf_id), int(frame_size))

    @keyword
    def sar_reassembly_multi_segment_in_order_test(self, dev, buf_id=0,
                                                   frame_size=4096, seg_len=512):
        sar_reassembly_multi_segment_in_order_test(
            dev, int(buf_id), int(frame_size), int(seg_len))

    @keyword
    def sar_reassembly_multi_segment_out_of_order_test(self, dev, buf_id=0,
                                                       frame_size=4096, seg_len=512):
        sar_reassembly_multi_segment_out_of_order_test(
            dev, int(buf_id), int(frame_size), int(seg_len))

    @keyword
    def sar_reassembly_multi_frame_interleaved_test(self, dev, num_frames=4,
                                                    frame_size=2048, seg_len=512):
        sar_reassembly_multi_frame_interleaved_test(
            dev, int(num_frames), int(frame_size), int(seg_len))

    @keyword
    def sar_reassembly_timeout_test(self, dev, buf_id=0, timeout_ms=5):
        sar_reassembly_timeout_test(dev, int(buf_id), int(timeout_ms))

    @keyword
    def sar_reassembly_debug_counters_test(self, dev, num_frames=10,
                                           frame_size=1536, seg_len=512):
        sar_reassembly_debug_counters_test(
            dev, int(num_frames), int(frame_size), int(seg_len))
