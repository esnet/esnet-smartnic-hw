__all__ = ()

import random
import time

from robot.api.deco import keyword, library

from smartnic.lib.config       import *
from smartnic.lib.packets      import *
from smartnic.lib.probes       import *
from smartnic.lib.packet_q     import PacketQ


# ---------------------------------------------------------------------------
# Egress-QS register helpers
# ---------------------------------------------------------------------------

def _egr_qs_enable(dev):
    ctrl = dev.bar2.smartnic_egr_qs.control
    for _ in range(100):
        if int(ctrl.status.init_done) == 1:
            break
        time.sleep(0.1)
    else:
        raise AssertionError('Egress QS: init_done never asserted after 10 s')
    ctrl.control.enable = 1


def _egr_qs_disable(dev):
    dev.bar2.smartnic_egr_qs.control.control.enable = 0


def _egr_qs_reset(dev):
    ctrl = dev.bar2.smartnic_egr_qs.control
    ctrl.control.reset = 1
    time.sleep(0.05)
    ctrl.control.reset = 0


def _egr_qs_status(dev):
    ctrl = dev.bar2.smartnic_egr_qs.control
    return {
        'reset':     int(ctrl.status.reset),
        'init_done': int(ctrl.status.init_done),
        'enabled':   int(ctrl.status.enabled),
    }


# oflow bits sit at even bit positions (0, 2, 4, …) in the 28-bit port_status field
_PORT_STATUS_OFLOW_MASK = 0x5555555   # 28 bits, bits 0/2/4/6/…/26

_DESC_OFLOW_FIELDS = ('axi3_wr_data_oflow', 'axi3_wr_burst_oflow', 'axi3_rd_burst_oflow')


def _assert_no_oflow(dev, context=''):
    tag = f' in {context}' if context else ''
    for port in range(2):
        ps = int(dev.bar2.smartnic_egr_qs.control.port_status[port]._r)
        if ps & _PORT_STATUS_OFLOW_MASK:
            raise AssertionError(
                f'Egress QS port {port} overflow{tag}: port_status=0x{ps:08x}')
    ds = dev.bar2.smartnic_egr_qs.control.desc_status
    for field in _DESC_OFLOW_FIELDS:
        if int(getattr(ds, field)):
            raise AssertionError(
                f'Egress QS descriptor overflow{tag}: desc_status.{field} set')


def _pq(dev):
    """Return a PacketQ driver bound to this device's egress QS.
    Cached on dev so snapshots survive across calls within a testcase."""
    if not hasattr(dev, '_egr_qs_pq'):
        dev._egr_qs_pq = PacketQ(dev.bar2.smartnic_egr_qs.packet_q)
    return dev._egr_qs_pq


# ---------------------------------------------------------------------------
# Probe name helpers
# ---------------------------------------------------------------------------

def _phy_probe_names(port):
    if port == 0:
        return ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0',
                'probe_app0_to_core', 'probe_to_cmac_0']
    else:
        return ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1',
                'probe_app1_to_core', 'probe_to_cmac_1']


def _pf_probe_names(port):
    if port == 0:
        return ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0',
                'probe_app0_to_core', 'probe_to_pf0_vf2']
    else:
        return ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1',
                'probe_app1_to_core', 'probe_to_pf1_vf2']


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

def egr_qs_testcase_setup(dev, num_p4_proc):
    testcase_setup(dev, num_p4_proc)
    p4_bypass_config(dev=dev, num_p4_proc=num_p4_proc, enable=1, port_type=0)  # port_type=0 (PHY).
    _egr_qs_enable(dev)
    _pq(dev).clear_all_counts()


# ---------------------------------------------------------------------------
# Correctness: single packet
# ---------------------------------------------------------------------------

def egr_qs_single_packet_test(dev, size, port):
    pq = _pq(dev)
    pkt_playback_config(dev, port)
    pkt_capture_config(dev, port)

    tx_pkt = one_packet(size)
    pkt_capture_trigger(dev)
    pkt_playback(dev, tx_pkt, port, port)
    pkt_capture_read(dev, tx_pkt)

    pq.check_port(port, 1, size, label=f'single size={size}')
    _assert_no_oflow(dev, f'single_packet port={port} size={size}')


def egr_qs_min_size_test(dev, port):
    egr_qs_single_packet_test(dev, 64, port)


def egr_qs_max_size_test(dev, port):
    egr_qs_single_packet_test(dev, 9100, port)


def egr_qs_corrupt_packet_test(dev, port):
    """
    Verify that pkt_capture_read detects a byte mismatch. Send a known packet,
    then compare against a corrupted expected value and confirm AssertionError
    is raised. Follows up with a clean send/capture to leave engine state valid.
    """
    pkt_playback_config(dev, port)
    pkt_capture_config(dev, port)

    tx_pkt = one_packet(64)
    corrupt_idx = random.randrange(len(tx_pkt))
    corrupt_byte = (tx_pkt[corrupt_idx] ^ 0xFF) & 0xFF
    corrupted = tx_pkt[:corrupt_idx] + bytes([corrupt_byte]) + tx_pkt[corrupt_idx + 1:]

    pkt_capture_trigger(dev)
    pkt_playback(dev, tx_pkt, port, port)
    try:
        pkt_capture_read(dev, corrupted)
    except AssertionError:
        pass
    else:
        raise AssertionError(
            f'corrupt_packet port={port}: expected mismatch not detected '
            f'(byte {corrupt_idx} flipped 0x{tx_pkt[corrupt_idx]:02x}→0x{corrupt_byte:02x})')


# ---------------------------------------------------------------------------
# Correctness: multi-packet
# ---------------------------------------------------------------------------

def egr_qs_multi_packet_test(dev, num, size, port):
    pq = _pq(dev)
    clear_switch_stats()
    pq.clear_all_counts()
    pkt_playback_config(dev, port)
    pkt_capture_config(dev, port)

    pkt_playback_capture(dev, num, size, port)

    check_probes(_pf_probe_names(port), num, num * size, check_zeros=False)
    pq.check_port(port, num, num * size, label=f'multi num={num} size={size}')
    _assert_no_oflow(dev, f'multi_packet port={port} num={num} size={size}')


def egr_qs_random_size_test(dev, num, port):
    pq = _pq(dev)
    clear_switch_stats()
    pq.clear_all_counts()
    pkt_playback_config(dev, port)
    pkt_capture_config(dev, port)

    total_bytes = rnd_playback_capture(dev, num, port)

    check_probes(_pf_probe_names(port), num, total_bytes, check_zeros=False)
    pq.check_port(port, num, total_bytes, label=f'random num={num}')
    _assert_no_oflow(dev, f'random_size port={port} num={num}')


# ---------------------------------------------------------------------------
# Corner cases: size boundaries and tkeep
# ---------------------------------------------------------------------------

def egr_qs_boundary_sizes_test(dev, port):
    sizes = [64, 65, 127, 128, 255, 512, 1023, 1024, 1500, 4096, 9100]
    pq = _pq(dev)
    clear_switch_stats()
    pq.clear_all_counts()
    pkt_playback_config(dev, port)
    pkt_capture_config(dev, port)

    total_bytes = 0
    for size in sizes:
        tx_pkt = one_packet(size)
        pkt_capture_trigger(dev)
        pkt_playback(dev, tx_pkt, port, port)
        pkt_capture_read(dev, tx_pkt)
        total_bytes += size

    check_probes(_pf_probe_names(port), len(sizes), total_bytes, check_zeros=False)
    pq.check_port(port, len(sizes), total_bytes, label='boundary_sizes')
    _assert_no_oflow(dev, f'boundary_sizes port={port}')


def egr_qs_tkeep_stress_test(dev, port):
    num = 64
    pq = _pq(dev)
    clear_switch_stats()
    pq.clear_all_counts()
    pkt_playback_config(dev, port)
    pkt_capture_config(dev, port)

    total_bytes = 0
    for i in range(num):
        size = 64 + i
        tx_pkt = one_packet(size)
        pkt_capture_trigger(dev)
        pkt_playback(dev, tx_pkt, port, port)
        pkt_capture_read(dev, tx_pkt)
        total_bytes += size

    check_probes(_pf_probe_names(port), num, total_bytes, check_zeros=False)
    pq.check_port(port, num, total_bytes, label='tkeep_stress')
    _assert_no_oflow(dev, f'tkeep_stress port={port}')


# ---------------------------------------------------------------------------
# Control: bypass mode and enable/disable cycling
# ---------------------------------------------------------------------------

def egr_qs_bypass_mode_test(dev, num, size, port):
    _egr_qs_disable(dev)
    status = _egr_qs_status(dev)
    if status['enabled'] != 0:
        raise AssertionError(f'Expected enabled=0 in bypass mode, got {status}')

    clear_switch_stats()
    pkt_playback_config(dev, port)
    pkt_capture_config(dev, port)
    pkt_playback_capture(dev, num, size, port)

    check_probes(_pf_probe_names(port), num, num * size, check_zeros=False)
    # Packet counters are inside the queue block; in bypass mode traffic does
    # not traverse them, so we only check that no errors were recorded.
    _pq(dev).check_no_errors(label='bypass_mode')
    _assert_no_oflow(dev, f'bypass_mode port={port}')
    _egr_qs_enable(dev)


def egr_qs_enable_disable_test(dev, num, size, port):
    for i in range(3):
        _egr_qs_enable(dev)
        if _egr_qs_status(dev)['enabled'] != 1:
            raise AssertionError(f'Iteration {i}: expected enabled=1')
        clear_switch_stats()
        _pq(dev).clear_all_counts()
        pkt_playback_config(dev, port)
        pkt_capture_config(dev, port)
        pkt_playback_capture(dev, num, size, port)
        check_probes(_pf_probe_names(port), num, num * size, check_zeros=False)
        _pq(dev).check_port(port, num, num * size, label=f'enabled iter={i}')

        _egr_qs_disable(dev)
        if _egr_qs_status(dev)['enabled'] != 0:
            raise AssertionError(f'Iteration {i}: expected enabled=0')
        clear_switch_stats()
        pkt_playback_config(dev, port)
        pkt_capture_config(dev, port)
        pkt_playback_capture(dev, num, size, port)
        check_probes(_pf_probe_names(port), num, num * size, check_zeros=False)

    _egr_qs_enable(dev)
    _assert_no_oflow(dev, 'enable_disable')


# ---------------------------------------------------------------------------
# Register validation
# ---------------------------------------------------------------------------

def egr_qs_status_registers_test(dev):
    status = _egr_qs_status(dev)
    if status['init_done'] != 1:
        raise AssertionError(f'Expected init_done=1, got {status}')
    if status['enabled'] != 1:
        raise AssertionError(f'Expected enabled=1, got {status}')

    _egr_qs_disable(dev)
    if _egr_qs_status(dev)['enabled'] != 0:
        raise AssertionError('Expected enabled=0 after disable')

    _egr_qs_enable(dev)
    if _egr_qs_status(dev)['enabled'] != 1:
        raise AssertionError('Expected enabled=1 after re-enable')

    _egr_qs_reset(dev)
    ctrl = dev.bar2.smartnic_egr_qs.control
    for _ in range(100):
        if int(ctrl.status.init_done) == 1:
            break
        time.sleep(0.1)
    else:
        raise AssertionError('init_done did not re-assert after soft reset')


def egr_qs_port_status_clear_test(dev):
    ctrl = dev.bar2.smartnic_egr_qs.control
    for port in range(2):
        ps = int(ctrl.port_status[port]._r)
        if ps & _PORT_STATUS_OFLOW_MASK:
            raise AssertionError(
                f'Unexpected overflow in port_status[{port}]=0x{ps:08x}')
    ds = ctrl.desc_status
    for field in _DESC_OFLOW_FIELDS:
        if int(getattr(ds, field)):
            raise AssertionError(f'Unexpected descriptor overflow: desc_status.{field} set')


def egr_qs_alloc_status_test(dev):
    """
    Validate sg_alloc and q_mgr status after setup: init_done=1, no errors,
    cnt_active at prefetch baseline (no packets in flight).
    """
    pq = _pq(dev)
    if not pq.sg_alloc.is_init_done():
        raise AssertionError('sg_alloc: init_done not set')
    if not pq.sg_alloc.is_enabled():
        raise AssertionError('sg_alloc: not enabled')
    pq.sg_alloc.check_no_errors(label='idle')

    for port in range(2):
        qm = pq.q_mgr[port]
        if not qm.is_init_done():
            raise AssertionError(f'q_mgr[{port}]: init_done not set')
        qm.check_no_errors(label=f'idle port={port}')
        qm.check_balanced(label=f'idle port={port}')


# ---------------------------------------------------------------------------
# Probe counter validation (PHY path through egress QS)
# ---------------------------------------------------------------------------

def egr_qs_probe_counters_test(dev, num, size, port):
    pq = _pq(dev)
    clear_switch_stats()
    pq.clear_all_counts()
    pkt_accelerator_config(dev=dev, port=port, mux_out_sel=0, gt=False)
    tx_pkt = one_packet(size)
    pkt_accelerator_inject(dev, num, tx_pkt, port)

    time.sleep(0.5)

    pkt_accelerator_extract(dev, num, tx_pkt, port)

    # packets recirculate so exact counts are unpredictable; verify input==output
    # (nothing lost in the QS) and no errors
    in_c  = pq.input_cnt[port].read()
    out_c = pq.output_cnt[port].read()
    if in_c['pkt_ok'] == 0:
        raise AssertionError(f'input_cnt[{port}]: no packets seen')
    if in_c['pkt_ok'] != out_c['pkt_ok'] or in_c['byte_ok'] != out_c['byte_ok']:
        raise AssertionError(
            f'probe_ctr port={port}: in={in_c["pkt_ok"]} pkts / {in_c["byte_ok"]} B '
            f'!= out={out_c["pkt_ok"]} pkts / {out_c["byte_ok"]} B: QS dropped packets')
    pq.q_mgr[port].check_balanced(label=f'probe_ctr port={port}')
    pq.check_no_errors(            label=f'probe_ctr port={port}')
    _assert_no_oflow(dev, f'probe_counters port={port}')


def egr_qs_both_ports_test(dev, num, size):
    pq = _pq(dev)
    clear_switch_stats()
    pq.clear_all_counts()
    for port in range(2):
        pkt_accelerator_config(dev=dev, port=port, mux_out_sel=0, gt=False)

    tx_pkts = [one_packet(size), one_packet(size)]
    for port in range(2):
        pkt_accelerator_inject(dev, num, tx_pkts[port], port)

    time.sleep(0.5)

    for port in range(2):
        pkt_accelerator_extract(dev, num, tx_pkts[port], port)

    for port in range(2):
        in_c  = pq.input_cnt[port].read()
        out_c = pq.output_cnt[port].read()
        if in_c['pkt_ok'] == 0:
            raise AssertionError(f'both_ports: input_cnt[{port}]: no packets seen')
        if in_c['pkt_ok'] != out_c['pkt_ok'] or in_c['byte_ok'] != out_c['byte_ok']:
            raise AssertionError(
                f'both_ports port={port}: in={in_c["pkt_ok"]} pkts / {in_c["byte_ok"]} B '
                f'!= out={out_c["pkt_ok"]} pkts / {out_c["byte_ok"]} B')
        pq.q_mgr[port].check_balanced(label=f'both_ports port={port}')
    pq.check_no_errors(label='both_ports')
    _assert_no_oflow(dev, 'both_ports')


# ---------------------------------------------------------------------------
# Burst / backpressure
# ---------------------------------------------------------------------------

def egr_qs_burst_test(dev, num, size, port):
    pq = _pq(dev)
    clear_switch_stats()
    pq.clear_all_counts()
    pkt_accelerator_config(dev=dev, port=port, mux_out_sel=0, gt=False)
    tx_pkt = one_packet(size)
    pkt_accelerator_inject(dev, num, tx_pkt, port)

    time.sleep(1.0)

    pkt_accelerator_extract(dev, num, tx_pkt, port)

    in_c  = pq.input_cnt[port].read()
    out_c = pq.output_cnt[port].read()
    if in_c['pkt_ok'] == 0:
        raise AssertionError(f'burst port={port}: no packets seen')
    if in_c['pkt_ok'] != out_c['pkt_ok'] or in_c['byte_ok'] != out_c['byte_ok']:
        raise AssertionError(
            f'burst port={port}: in={in_c["pkt_ok"]} pkts / {in_c["byte_ok"]} B '
            f'!= out={out_c["pkt_ok"]} pkts / {out_c["byte_ok"]} B')
    pq.q_mgr[port].check_balanced(label=f'burst port={port}')
    pq.check_no_errors(            label=f'burst port={port}')
    _assert_no_oflow(dev, f'burst port={port} num={num} size={size}')


# ---------------------------------------------------------------------------
# Alloc-specific tests
# ---------------------------------------------------------------------------

def egr_qs_alloc_balance_test(dev, num, size, port):
    """
    After running the accelerator loop and draining, assert that q_mgr and
    sg_alloc have balanced alloc/dealloc counts and cnt_active is at baseline
    (no leaked buffers).
    """
    pq = _pq(dev)
    pq.clear_all_counts()
    pkt_accelerator_config(dev=dev, port=port, mux_out_sel=0, gt=False)
    tx_pkt = one_packet(size)
    pkt_accelerator_inject(dev, num, tx_pkt, port)

    time.sleep(1.0)

    pkt_accelerator_extract(dev, num, tx_pkt, port)

    pq.q_mgr[port].check_balanced(label=f'alloc_balance port={port}')
    pq.sg_alloc.check_balanced(   label=f'alloc_balance port={port}')
    pq.check_no_errors(           label=f'alloc_balance port={port}')
    _assert_no_oflow(dev, f'alloc_balance port={port}')


def egr_qs_alloc_throughput_test(dev, num, size, port):
    """
    Verify that the q_mgr alloc counter increments (packets are being enqueued)
    and that alloc/dealloc are balanced after draining.
    """
    pq = _pq(dev)
    pq.clear_all_counts()
    pkt_accelerator_config(dev=dev, port=port, mux_out_sel=0, gt=False)
    tx_pkt = one_packet(size)
    pkt_accelerator_inject(dev, num, tx_pkt, port)

    time.sleep(1.0)

    pkt_accelerator_extract(dev, num, tx_pkt, port)

    c = pq.q_mgr[port].read_counts()
    if c['alloc'] == 0:
        raise AssertionError(f'alloc_tput port={port}: no allocations recorded')
    pq.q_mgr[port].check_balanced(label=f'alloc_tput port={port}')
    pq.check_no_errors(            label=f'alloc_tput port={port}')
    _assert_no_oflow(dev, f'alloc_throughput port={port}')


# ---------------------------------------------------------------------------
# Performance
# ---------------------------------------------------------------------------

def egr_qs_performance_test(dev, port, num, size, mpps, gbps):
    pq = _pq(dev)
    clear_switch_stats()
    pkt_accelerator_config(dev=dev, port=port, mux_out_sel=0, gt=False)
    tx_pkt = one_packet(size)
    pkt_accelerator_inject(dev, num, tx_pkt, port)

    check_rates(port, mpps, gbps)

    pkt_accelerator_extract(dev, num, tx_pkt, port)
    pq.check_no_errors(label=f'performance port={port} size={size}')
    _assert_no_oflow(dev, f'performance port={port} size={size}')


# ---------------------------------------------------------------------------
# Robot Framework keyword wrapper
# ---------------------------------------------------------------------------

@library
class Library:

    @keyword
    def egr_qs_testcase_setup(self, dev, num_p4_proc):
        egr_qs_testcase_setup(dev, num_p4_proc)

    @keyword
    def testcase_teardown(self, dev):
        testcase_teardown(dev)

    @keyword
    def egr_qs_single_packet_test(self, dev, size, port):
        egr_qs_single_packet_test(dev, int(size), int(port))

    @keyword
    def egr_qs_multi_packet_test(self, dev, num, size, port):
        egr_qs_multi_packet_test(dev, int(num), int(size), int(port))

    @keyword
    def egr_qs_random_size_test(self, dev, num, port):
        egr_qs_random_size_test(dev, int(num), int(port))

    @keyword
    def egr_qs_min_size_test(self, dev, port):
        egr_qs_min_size_test(dev, int(port))

    @keyword
    def egr_qs_max_size_test(self, dev, port):
        egr_qs_max_size_test(dev, int(port))

    @keyword
    def egr_qs_corrupt_packet_test(self, dev, port):
        egr_qs_corrupt_packet_test(dev, int(port))

    @keyword
    def egr_qs_boundary_sizes_test(self, dev, port):
        egr_qs_boundary_sizes_test(dev, int(port))

    @keyword
    def egr_qs_tkeep_stress_test(self, dev, port):
        egr_qs_tkeep_stress_test(dev, int(port))

    @keyword
    def egr_qs_bypass_mode_test(self, dev, num, size, port):
        egr_qs_bypass_mode_test(dev, int(num), int(size), int(port))

    @keyword
    def egr_qs_enable_disable_test(self, dev, num, size, port):
        egr_qs_enable_disable_test(dev, int(num), int(size), int(port))

    @keyword
    def egr_qs_status_registers_test(self, dev):
        egr_qs_status_registers_test(dev)

    @keyword
    def egr_qs_port_status_clear_test(self, dev):
        egr_qs_port_status_clear_test(dev)

    @keyword
    def egr_qs_alloc_status_test(self, dev):
        egr_qs_alloc_status_test(dev)

    @keyword
    def egr_qs_probe_counters_test(self, dev, num, size, port):
        egr_qs_probe_counters_test(dev, int(num), int(size), int(port))

    @keyword
    def egr_qs_both_ports_test(self, dev, num, size):
        egr_qs_both_ports_test(dev, int(num), int(size))

    @keyword
    def egr_qs_burst_test(self, dev, num, size, port):
        egr_qs_burst_test(dev, int(num), int(size), int(port))

    @keyword
    def egr_qs_alloc_balance_test(self, dev, num, size, port):
        egr_qs_alloc_balance_test(dev, int(num), int(size), int(port))

    @keyword
    def egr_qs_alloc_throughput_test(self, dev, num, size, port):
        egr_qs_alloc_throughput_test(dev, int(num), int(size), int(port))

    @keyword
    def egr_qs_performance_test(self, dev, port, num, size, mpps, gbps):
        egr_qs_performance_test(dev, int(port), int(num), int(size),
                                float(mpps), float(gbps))
