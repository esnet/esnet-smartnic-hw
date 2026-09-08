__all__ = (
    'SarSegCtrlProtocol',
)

import time


class SarSegCtrlProtocol:
    """Driver for the sar_test_seg_ctrl register block.

    Pass the segmentation_ctrl block proxy:
        SarSegCtrlProtocol(dev.bar2.smartnic_app_igr.segmentation_ctrl)

    Registers (from sar_test_seg_ctrl.yaml):
        frame_buf_id  rw  -- frame buffer index to read from HBM
        frame_len     rw  -- frame length in bytes
        trigger       wr_evt -- write any value to start segmentation
        status        ro  -- fields: busy, done, error
    """

    def __init__(self, proxy):
        self._p = proxy

    def trigger(self, buf_id, frame_len):
        self._p.frame_buf_id = int(buf_id)
        self._p.frame_len = int(frame_len)
        self._p.trigger = 1

    def wait_done(self, timeout_ms=500):
        deadline = time.monotonic() + timeout_ms / 1000
        while time.monotonic() < deadline:
            st = self._p.status().proxy
            if int(st.error):
                raise IOError('SAR seg_ctrl: error during segmentation')
            if int(st.done):
                return
            time.sleep(1e-3)
        raise TimeoutError('SAR seg_ctrl: segmentation did not complete')

    def trigger_and_wait(self, buf_id, frame_len, timeout_ms=500):
        self.trigger(buf_id, frame_len)
        self.wait_done(timeout_ms)
