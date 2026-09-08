__all__ = (
    'SarSegmentationProtocol',
)

import time


class SarSegmentationProtocol:
    """Driver for the sar_packet_segmentation register interface.

    Pass the segmentation decoder sub-block proxy:
        SarSegmentationProtocol(dev.bar2.smartnic_app_igr.segmentation)

    Sub-block layout (from sar_packet_segmentation_decoder.yaml):
        proxy.packets       -- packet_counters block
        proxy.segmentation  -- sar_segmentation registers
    """

    def __init__(self, proxy):
        self._p = proxy
        self._regs = proxy.segmentation

    # ------------------------------------------------------------------
    # Reset / enable
    # ------------------------------------------------------------------

    def reset(self):
        ctrl = self._regs.control().proxy
        ctrl.reset = 1
        self._regs.control = ctrl
        ctrl.reset = 0
        self._regs.control = ctrl

    def enable(self):
        ctrl = self._regs.control().proxy
        ctrl.enable = 1
        self._regs.control = ctrl

    def disable(self):
        ctrl = self._regs.control().proxy
        ctrl.enable = 0
        self._regs.control = ctrl

    def wait_ready(self, timeout_ms=500):
        deadline = time.monotonic() + timeout_ms / 1000
        while time.monotonic() < deadline:
            if int(self._regs.status.ready_mon):
                return
            time.sleep(1e-3)
        raise TimeoutError('SAR segmentation did not become ready')

    # ------------------------------------------------------------------
    # Info
    # ------------------------------------------------------------------

    def get_info(self):
        return {
            'num_buffers':    int(self._regs.info.num_buffers),
            'max_segment_len': int(self._regs.info.max_segment_len),
            'max_frame_size': int(self._regs.info_frame.max_size),
        }

    # ------------------------------------------------------------------
    # Configuration
    # ------------------------------------------------------------------

    def set_segment_length(self, seg_len):
        cfg = self._regs._config().proxy
        cfg.seg_len = int(seg_len)
        self._regs._config = cfg

    def get_segment_length(self):
        return int(self._regs._config.seg_len)

    # ------------------------------------------------------------------
    # Debug counters
    # ------------------------------------------------------------------

    def clear_counts(self):
        self._regs.dbg_control.clear_counts = 1
        self._regs.dbg_control.clear_counts = 0

    def get_counts(self):
        return {
            'frames_in':    int(self._regs.dbg_cnt_frames_in),
            'segments_out': int(self._regs.dbg_cnt_segments_out),
        }
