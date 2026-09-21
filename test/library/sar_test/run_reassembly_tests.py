#!/usr/bin/env -S regio-esnet-smartnic script
"""Standalone runner for sar_test reassembly hardware tests.

Invoke via regio:
    regio-esnet-smartnic script run_reassembly_tests.py
    regio-esnet-smartnic script run_reassembly_tests.py -- --tests sanity timeout
    regio-esnet-smartnic script run_reassembly_tests.py -- --list

regio pre-configures dev0 (and dev1, dev2, ...) as global device objects.
"""

import argparse
import os
import sys

# Ensure test/library/ is on the path so that 'sar_test' and 'smartnic' packages resolve.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# dev0 is injected by regio-esnet-smartnic as a global.
# If running against a specific device index use dev1, dev2, etc.
dev = dev0  # noqa: F821

from sar_test.lib.sar_test_config import testcase_teardown
from sar_test.lib.sar_reassembly_test import (
    sar_reassembly_sanity_test,
    sar_reassembly_single_segment_test,
    sar_reassembly_multi_segment_in_order_test,
    sar_reassembly_multi_segment_out_of_order_test,
    sar_reassembly_multi_frame_interleaved_test,
    sar_reassembly_timeout_test,
    sar_reassembly_debug_counters_test,
)

TESTS = {
    'sanity':         (sar_reassembly_sanity_test,                     {}),
    'single_64':      (sar_reassembly_single_segment_test,             {'buf_id': 0, 'frame_size': 64}),
    'single_512':     (sar_reassembly_single_segment_test,             {'buf_id': 1, 'frame_size': 512}),
    'in_order_4096':  (sar_reassembly_multi_segment_in_order_test,     {'buf_id': 0, 'frame_size': 4096,  'seg_len': 512}),
    'in_order_9216':  (sar_reassembly_multi_segment_in_order_test,     {'buf_id': 0, 'frame_size': 9216,  'seg_len': 512}),
    'out_of_order':   (sar_reassembly_multi_segment_out_of_order_test, {'buf_id': 0, 'frame_size': 4096,  'seg_len': 512}),
    'interleaved':    (sar_reassembly_multi_frame_interleaved_test,    {'num_frames': 4, 'frame_size': 2048, 'seg_len': 512}),
    'timeout':        (sar_reassembly_timeout_test,                    {'buf_id': 0, 'timeout_ms': 50, 'wait_factor': 20}),
    'debug_counters': (sar_reassembly_debug_counters_test,             {'num_frames': 10, 'frame_size': 1536, 'seg_len': 512}),
}

# ---------------------------------------------------------------------------

parser = argparse.ArgumentParser(
    prog='run_reassembly_tests.py',
    description='SAR reassembly hardware tests',
)
parser.add_argument('--tests', nargs='+', metavar='TEST',
                    choices=list(TESTS), default=list(TESTS),
                    help='Tests to run (default: all)')
parser.add_argument('--list', action='store_true',
                    help='List available tests and exit')
args = parser.parse_args()

if args.list:
    print('Available reassembly tests:')
    for name in TESTS:
        print(f'  {name}')
    sys.exit(0)

# ---------------------------------------------------------------------------

passed = []
failed = []

for name in args.tests:
    fn, kwargs = TESTS[name]
    print(f'\n{"="*60}')
    print(f'TEST: {name}')
    print(f'{"="*60}')
    try:
        fn(dev, **kwargs)
        print(f'PASS: {name}')
        passed.append(name)
    except Exception as exc:
        print(f'FAIL: {name} — {exc}')
        failed.append(name)
    finally:
        try:
            testcase_teardown(dev)
        except Exception:
            pass

print(f'\n{"="*60}')
print(f'Results: {len(passed)} passed, {len(failed)} failed')
if failed:
    print(f'Failed:  {", ".join(failed)}')
print(f'{"="*60}')

sys.exit(0 if not failed else 1)
