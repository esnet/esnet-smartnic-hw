"""
Convenience wrapper for the full packet_q_decoder register space
(src/packet/regio/packet_q_decoder.yaml).

    pq = PacketQ(some_block.packet_q)

Exposes:
    pq.sg_alloc              -> Alloc  (scatter-gather buffer pool)
    pq.input_cnt[port]       -> PacketCounters  (per-input-port scatter events)
    pq.output_cnt[port]      -> PacketCounters  (per-output-port gather events)
    pq.q_mgr[port]           -> Alloc  (linked-list queue manager per output port)

The decoder always wires four of each; unused ports are terminated in hardware
and read back as zero.
"""

from smartnic.lib.alloc           import Alloc
from smartnic.lib.packet_counters import PacketCounters


class PacketQ:
    def __init__(self, block):
        sg = block.sg
        self.sg_alloc    = Alloc(sg.alloc)
        self.input_cnt   = [PacketCounters(getattr(sg, f'input_cnt_{i}'))  for i in range(4)]
        self.output_cnt  = [PacketCounters(getattr(sg, f'output_cnt_{i}')) for i in range(4)]
        self.q_mgr       = [Alloc(getattr(block, f'q_mgr_{i}'))            for i in range(4)]
        self.snapshot_baseline()

    # ------------------------------------------------------------------
    # Bulk helpers
    # ------------------------------------------------------------------

    def clear_all_counts(self):
        """Clear all packet counter and alloc debug counter blocks."""
        for c in self.input_cnt + self.output_cnt:
            c.clear()
        self.sg_alloc.clear_counts()
        for q in self.q_mgr:
            q.clear_counts()

    def snapshot_baseline(self, timeout_s=10.0):
        """Poll until all alloc blocks report init_done, then snapshot
        cnt_active as the baseline for subsequent check_balanced() calls."""
        import time
        deadline = time.monotonic() + timeout_s
        for label, alloc in [('sg_alloc', self.sg_alloc)] + \
                             [(f'q_mgr_{i}', q) for i, q in enumerate(self.q_mgr)]:
            while not alloc.is_init_done():
                if time.monotonic() > deadline:
                    raise AssertionError(
                        f'PacketQ {label}: init_done never asserted after {timeout_s} s')
                time.sleep(0.05)
            alloc.snapshot_baseline()

    def check_port(self, port, exp_pkts, exp_bytes, label=''):
        """
        For a single active port (0 or 1), assert:
          - input_cnt[port]:  pkt_ok/byte_ok == exp and no errors
          - output_cnt[port]: pkt_ok/byte_ok == exp and no errors
          - q_mgr[port]:      no errors, balanced alloc/dealloc
          - sg_alloc:         no errors
        """
        tag = label or f'port {port}'
        self.input_cnt[port].check(exp_pkts, exp_bytes, f'input_cnt[{port}] {tag}')
        self.output_cnt[port].check(exp_pkts, exp_bytes, f'output_cnt[{port}] {tag}')
        self.q_mgr[port].check_no_errors(f'q_mgr[{port}] {tag}')
        self.q_mgr[port].check_balanced(f'q_mgr[{port}] {tag}')
        self.sg_alloc.check_no_errors(f'sg_alloc {tag}')

    def check_both_ports(self, exp_pkts, exp_bytes, label=''):
        """check_port for ports 0 and 1."""
        for port in range(2):
            self.check_port(port, exp_pkts, exp_bytes, label)

    def check_no_errors(self, label=''):
        """Assert all error/overflow bins are zero across all blocks."""
        tag = label or 'packet_q'
        self.sg_alloc.check_no_errors(f'sg_alloc {tag}')
        for i in range(2):
            self.input_cnt[i].check_no_errors(f'input_cnt[{i}] {tag}')
            self.output_cnt[i].check_no_errors(f'output_cnt[{i}] {tag}')
            self.q_mgr[i].check_no_errors(f'q_mgr[{i}] {tag}')

    def dump(self, label=''):
        tag = f' [{label}]' if label else ''
        print(f'PacketQ{tag}:')
        self.sg_alloc.dump('sg_alloc')
        for i in range(2):
            self.input_cnt[i].dump(f'input_cnt[{i}]')
            self.output_cnt[i].dump(f'output_cnt[{i}]')
            self.q_mgr[i].dump(f'q_mgr[{i}]')
