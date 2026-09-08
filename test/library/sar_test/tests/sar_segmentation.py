__all__ = ()

from robot.api.deco import keyword, library

from sar_test.lib.sar_test_config import testcase_setup, testcase_teardown
from sar_test.lib.sar_segmentation_test import (
    sar_segmentation_sanity_test,
    sar_segmentation_single_segment_test,
    sar_segmentation_multi_segment_test,
    sar_segmentation_boundary_test,
    sar_segmentation_configure_seg_len_test,
    sar_segmentation_sequential_frames_test,
    sar_segmentation_debug_counters_test,
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
    def sar_segmentation_sanity_test(self, dev):
        sar_segmentation_sanity_test(dev)

    @keyword
    def sar_segmentation_single_segment_test(self, dev, buf_id=0, frame_size=64):
        sar_segmentation_single_segment_test(dev, int(buf_id), int(frame_size))

    @keyword
    def sar_segmentation_multi_segment_test(self, dev, buf_id=0,
                                            frame_size=4096, seg_len=512):
        sar_segmentation_multi_segment_test(
            dev, int(buf_id), int(frame_size), int(seg_len))

    @keyword
    def sar_segmentation_boundary_test(self, dev, buf_id=0, seg_len=512):
        sar_segmentation_boundary_test(dev, int(buf_id), int(seg_len))

    @keyword
    def sar_segmentation_configure_seg_len_test(self, dev, buf_id=0,
                                                frame_size=3000, new_seg_len=256):
        sar_segmentation_configure_seg_len_test(
            dev, int(buf_id), int(frame_size), int(new_seg_len))

    @keyword
    def sar_segmentation_sequential_frames_test(self, dev, num_frames=4):
        sar_segmentation_sequential_frames_test(dev, int(num_frames))

    @keyword
    def sar_segmentation_debug_counters_test(self, dev, num_frames=5):
        sar_segmentation_debug_counters_test(dev, int(num_frames))
