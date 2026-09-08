__all__ = (
    'SarReassemblyProtocol',
)

import time


class SarReassemblyProtocol:
    """Driver for the sar_packet_reassembly register interface.

    Pass the reassembly decoder sub-block proxy:
        SarReassemblyProtocol(dev.bar2.smartnic_app_igr.reassembly)

    Sub-block layout (from sar_packet_reassembly_decoder.yaml):
        proxy.packets                -- packet_counters block
        proxy.reassembly.regs        -- sar_reassembly registers
        proxy.reassembly.state.check -- sar_reassembly_state_check registers
        proxy.reassembly.cache       -- sar_reassembly_cache registers (block at offset 0,
                                        exposed directly on the cache decoder object)
    """

    def __init__(self, proxy):
        self._p = proxy
        self._regs = proxy.reassembly.regs
        self._check = proxy.reassembly.state.check
        self._cache = proxy.reassembly.cache

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
        raise TimeoutError('SAR reassembly did not become ready')

    # ------------------------------------------------------------------
    # Info
    # ------------------------------------------------------------------

    def get_info(self):
        return {
            'num_frame_buffers': int(self._regs.info.num_frame_buffers),
            'max_fragments':     int(self._regs.info.max_fragments),
            'max_frame_size':    int(self._regs.info_frame.max_size),
        }

    # ------------------------------------------------------------------
    # Debug counters / flags — sar_reassembly block
    # ------------------------------------------------------------------

    def clear_counts(self):
        for blk in (self._regs, self._cache, self._check):
            blk.dbg_control.clear_counts = 1
        for blk in (self._regs, self._cache, self._check):
            blk.dbg_control.clear_counts = 0

    def get_counts(self):
        r = self._regs
        c = self._cache
        k = self._check
        return {
            'done_ops':         int(r.dbg_cnt_done_ops),
            'merge_ops':        int(r.dbg_cnt_merge_ops),
            'expired_ops':      int(r.dbg_cnt_expired_ops),
            'dealloc_ops':      int(r.dbg_cnt_dealloc_ops),
            'seg_rx':           int(c.dbg_cnt_seg_rx),
            'frag_create':      int(c.dbg_cnt_frag_create),
            'frag_append':      int(c.dbg_cnt_frag_append),
            'frag_prepend':     int(c.dbg_cnt_frag_prepend),
            'frag_merge':       int(c.dbg_cnt_frag_merge),
            'alloc_drop':       int(c.dbg_cnt_alloc_drop),
            'lookup_error':     int(c.dbg_cnt_lookup_error),
            'buffer_done':      int(k.dbg_cnt_buffer_done),
            'fragment_expired': int(k.dbg_cnt_fragment_expired),
        }

    def get_flags(self):
        """Read (and clear) all clear-on-read debug flags."""
        rf = self._regs.dbg_flags().proxy
        cf = self._cache.dbg_flags().proxy
        return {
            'q_done_oflow':            int(rf.q_done_oflow),
            'q_expired_oflow':         int(rf.q_expired_oflow),
            'q_merged_oflow':          int(rf.q_merged_oflow),
            'ctxt_fifo_oflow':         int(cf.ctxt_fifo_oflow),
            'ctxt_fifo_uflow':         int(cf.ctxt_fifo_uflow),
            'delete_q_append_oflow':   int(cf.delete_q_append_oflow),
            'delete_q_prepend_oflow':  int(cf.delete_q_prepend_oflow),
        }

    # ------------------------------------------------------------------
    # State-check timeout configuration
    # ------------------------------------------------------------------

    def set_timeout(self, enable, value_ms):
        cfg = self._check.cfg_timeout().proxy
        cfg.enable = int(bool(enable))
        cfg.value = int(value_ms)
        self._check.cfg_timeout = cfg

    # ------------------------------------------------------------------
    # Wait for N frame completions
    # ------------------------------------------------------------------

    def done_ops_count(self):
        """Return the current done_ops counter value.
        Capture this BEFORE sending segments, then pass to wait_done_ops.
        """
        return int(self._regs.dbg_cnt_done_ops)

    def wait_done_ops(self, expected_delta, timeout_ms=500, baseline=None):
        """Wait until done_ops has increased by expected_delta from baseline.

        baseline should be captured before sending segments to avoid a race
        where the counter increments before this method runs.
        If baseline is not provided it is captured at call time.
        """
        if baseline is None:
            baseline = self.done_ops_count()
        deadline = time.monotonic() + timeout_ms / 1000
        while time.monotonic() < deadline:
            if self.done_ops_count() - baseline >= expected_delta:
                return
            time.sleep(1e-3)
        raise TimeoutError(
            f'SAR reassembly: expected {expected_delta} done_ops in {timeout_ms} ms')
