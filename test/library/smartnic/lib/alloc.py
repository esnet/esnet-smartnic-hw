"""
Driver for the alloc regio block (src/alloc/regio/alloc.yaml).

Pass any alloc block reference directly:
    a = Alloc(some_block)
"""


class Alloc:
    def __init__(self, block):
        self._b = block
        self._active_baseline = None

    def snapshot_baseline(self):
        """Record current cnt_active as the baseline for check_balanced."""
        self._active_baseline = self.cnt_active()
        print(f'[alloc] snapshot_baseline: cnt_active={self._active_baseline}')

    # ------------------------------------------------------------------
    # Status
    # ------------------------------------------------------------------

    def is_init_done(self):
        return int(self._b.status.init_done) == 1

    def is_enabled(self):
        return int(self._b.status.enabled) == 1

    def cnt_active(self):
        """Number of pointers currently allocated (buffers in flight)."""
        return int(self._b.cnt_active)

    def status_flags(self):
        """
        Read rd_evt status_flags — clears on read.
        Returns dict with 'alloc_err' and 'dealloc_err' booleans.
        """
        f = self._b.status_flags
        return {
            'alloc_err':   bool(int(f.alloc_err)),
            'dealloc_err': bool(int(f.dealloc_err)),
        }

    # ------------------------------------------------------------------
    # Debug counters
    # ------------------------------------------------------------------

    def clear_counts(self):
        self._b.dbg_control.clear_counts = 1
        self._b.dbg_control.clear_counts = 0

    def read_counts(self):
        """
        Return all six 32-bit debug counters as a dict.
        These are free-running wrapping counters; call clear_counts() to reset.
        """
        b = self._b
        return {
            'alloc':         int(b.dbg_cnt_alloc),
            'alloc_fail':    int(b.dbg_cnt_alloc_fail),
            'alloc_err':     int(b.dbg_cnt_alloc_err),
            'dealloc':       int(b.dbg_cnt_dealloc),
            'dealloc_fail':  int(b.dbg_cnt_dealloc_fail),
            'dealloc_err':   int(b.dbg_cnt_dealloc_err),
        }

    # ------------------------------------------------------------------
    # Assertions
    # ------------------------------------------------------------------

    def check_no_errors(self, label=''):
        """
        Assert that alloc_err, dealloc_err (rd_evt flags) and the
        dbg_cnt_alloc_err / dbg_cnt_dealloc_err / dbg_cnt_alloc_fail /
        dbg_cnt_dealloc_fail counters are all zero.
        """
        tag = f' [{label}]' if label else ''
        flags = self.status_flags()
        if flags['alloc_err']:
            raise AssertionError(f'alloc_err flag set{tag}')
        if flags['dealloc_err']:
            raise AssertionError(f'dealloc_err flag set{tag}')
        c = self.read_counts()
        for key in ('alloc_err', 'alloc_fail', 'dealloc_err', 'dealloc_fail'):
            if c[key] != 0:
                raise AssertionError(
                    f'dbg_cnt_{key}{tag} = {c[key]}, expected 0')

    def check_balanced(self, label=''):
        """
        Assert that alloc count equals dealloc count (no leaked buffers/slots),
        and cnt_active has returned to its pre-test baseline (or 0 if no
        snapshot was taken).
        """
        tag = f' [{label}]' if label else ''
        c = self.read_counts()
        if c['alloc'] != c['dealloc']:
            raise AssertionError(
                f'alloc ({c["alloc"]}) != dealloc ({c["dealloc"]}){tag}: '
                f'possible buffer leak')
        expected = self._active_baseline if self._active_baseline is not None else 0
        active = self.cnt_active()
        print(f'[alloc] check_balanced{tag}: cnt_active={active}, expected={expected}, baseline={self._active_baseline}')
        if active != expected:
            raise AssertionError(
                f'cnt_active = {active}, expected {expected}{tag}')

    def check_throughput(self, exp_count, label=''):
        """Assert dbg_cnt_alloc equals exp_count (one alloc per packet/buffer)."""
        tag = f' [{label}]' if label else ''
        c = self.read_counts()
        if c['alloc'] != exp_count:
            raise AssertionError(
                f'dbg_cnt_alloc{tag}: got {c["alloc"]}, expected {exp_count}')

    def dump(self, label=''):
        tag = f' [{label}]' if label else ''
        c = self.read_counts()
        print(f'Alloc{tag}: active={self.cnt_active()}, '
              f'alloc={c["alloc"]}, alloc_fail={c["alloc_fail"]}, '
              f'alloc_err={c["alloc_err"]}, dealloc={c["dealloc"]}, '
              f'dealloc_fail={c["dealloc_fail"]}, dealloc_err={c["dealloc_err"]}')
