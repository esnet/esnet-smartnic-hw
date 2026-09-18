#!/usr/bin/env -S regio-esnet-smartnic script
"""Standalone runner for sar_test segmentation hardware tests.

Invoke via regio:
    regio-esnet-smartnic script run_segmentation_tests.py
    regio-esnet-smartnic script run_segmentation_tests.py -- --tests sanity multi_4096
    regio-esnet-smartnic script run_segmentation_tests.py -- --list

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
from sar_test.lib.sar_segmentation_test import (
    sar_segmentation_sanity_test,
    sar_segmentation_single_segment_test,
    sar_segmentation_multi_segment_test,
    sar_segmentation_boundary_test,
    sar_segmentation_configure_seg_len_test,
    sar_segmentation_sequential_frames_test,
    sar_segmentation_debug_counters_test,
)

TESTS = {
    'sanity':       (sar_segmentation_sanity_test,           {}),
    'single_64':    (sar_segmentation_single_segment_test,   {'buf_id': 0, 'frame_size': 64}),
    'single_512':   (sar_segmentation_single_segment_test,   {'buf_id': 0, 'frame_size': 512}),
    'multi_4096':   (sar_segmentation_multi_segment_test,    {'buf_id': 0, 'frame_size': 4096,  'seg_len': 512}),
    'multi_9216':   (sar_segmentation_multi_segment_test,    {'buf_id': 0, 'frame_size': 9216,  'seg_len': 512}),
    'boundary':     (sar_segmentation_boundary_test,         {'buf_id': 0, 'seg_len': 512}),
    'reconfig_256': (sar_segmentation_configure_seg_len_test, {'buf_id': 0, 'frame_size': 3000, 'new_seg_len': 256}),
    'reconfig_128': (sar_segmentation_configure_seg_len_test, {'buf_id': 0, 'frame_size': 1024, 'new_seg_len': 128}),
    'sequential':   (sar_segmentation_sequential_frames_test, {'num_frames': 4}),
    'debug_counters': (sar_segmentation_debug_counters_test, {'num_frames': 5}),
}

# ---------------------------------------------------------------------------

parser = argparse.ArgumentParser(
    prog='run_segmentation_tests.py',
    description='SAR segmentation hardware tests',
)
parser.add_argument('--tests', nargs='+', metavar='TEST',
                    choices=list(TESTS), default=list(TESTS),
                    help='Tests to run (default: all)')
parser.add_argument('--list', action='store_true',
                    help='List available tests and exit')
args = parser.parse_args()

if args.list:
    print('Available segmentation tests:')
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
