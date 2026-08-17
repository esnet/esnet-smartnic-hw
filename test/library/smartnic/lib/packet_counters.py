"""
Driver for the packet_counters regio block (src/packet/regio/packet_counters.yaml).

Pass any packet_counters block reference directly:
    ctr = PacketCounters(some_block)

In the default LATCH_ON_CLK mode the readable registers track continuously
and no explicit latch is needed before reading.  Only LATCH_ON_CLK mode is
supported; LATCH_ON_WR_EVT requires writing latch and clear atomically in one
register write, which the regio scalar-register API does not support.
"""


def _read64(upper, lower):
    return (int(upper) << 32) | int(lower)


class PacketCounters:
    def __init__(self, block):
        self._b = block

    def clear(self):
        """Clear internal accumulators."""
        self._b.control.clear = 1

    def read(self):
        """Return a dict of all counter pairs as 64-bit values."""
        b = self._b
        return {
            'pkt_ok':    _read64(b.cnt_pkt_ok_upper,    b.cnt_pkt_ok_lower),
            'byte_ok':   _read64(b.cnt_byte_ok_upper,   b.cnt_byte_ok_lower),
            'pkt_err':   _read64(b.cnt_pkt_err_upper,   b.cnt_pkt_err_lower),
            'byte_err':  _read64(b.cnt_byte_err_upper,  b.cnt_byte_err_lower),
            'pkt_oflow': _read64(b.cnt_pkt_oflow_upper, b.cnt_pkt_oflow_lower),
            'byte_oflow':_read64(b.cnt_byte_oflow_upper,b.cnt_byte_oflow_lower),
            'pkt_long':  _read64(b.cnt_pkt_long_upper,  b.cnt_pkt_long_lower),
            'byte_long': _read64(b.cnt_byte_long_upper, b.cnt_byte_long_lower),
        }

    def check_ok(self, exp_pkts, exp_bytes, label=''):
        """Assert good-packet and good-byte counts match expected values."""
        c = self.read()
        tag = f' [{label}]' if label else ''
        if c['pkt_ok'] != exp_pkts:
            raise AssertionError(
                f'pkt_ok{tag}: got {c["pkt_ok"]}, expected {exp_pkts}')
        if c['byte_ok'] != exp_bytes:
            raise AssertionError(
                f'byte_ok{tag}: got {c["byte_ok"]}, expected {exp_bytes}')

    def check_no_errors(self, label=''):
        """Assert all error/overflow/long bins are zero."""
        c = self.read()
        tag = f' [{label}]' if label else ''
        for key in ('pkt_err', 'byte_err', 'pkt_oflow', 'byte_oflow',
                    'pkt_long', 'byte_long'):
            if c[key] != 0:
                raise AssertionError(
                    f'{key}{tag} = {c[key]}, expected 0')

    def check(self, exp_pkts, exp_bytes, label=''):
        """check_ok + check_no_errors in one call."""
        self.check_ok(exp_pkts, exp_bytes, label)
        self.check_no_errors(label)

    def dump(self, label=''):
        c = self.read()
        tag = f' [{label}]' if label else ''
        print(f'PacketCounters{tag}:')
        for k, v in c.items():
            print(f'  {k}: {v}')
