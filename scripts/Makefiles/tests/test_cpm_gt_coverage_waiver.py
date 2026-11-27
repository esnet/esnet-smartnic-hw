"""Keep the CPM5 coverage exception confined to its dedicated hard GT control pins."""
import importlib.util
from pathlib import Path
import unittest

REPO = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location(
    'cpm_validator', REPO / 'esnet-fpga-library/scripts/vivado/validation/validate_build.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)

FAMILIES = ('PHYESMADAPTSAVE', 'RXDLYALIGNREQ', 'RXMLDCHAINDONE', 'RXMLDCHAINREQ',
            'RXPHALIGNREQ', 'RXPHSETINITREQ', 'RXPHSHIFT180')
PINS = [f'top_i/cips/inst/cpm_0/inst/gt_quad_inst{quad}/inst/quad_inst/CH{channel}_{family}'
        for quad in range(4) for channel in range(4) for family in FAMILIES]


def coverage(pins=PINS, ordinary=()):
    count = len(pins) + len(ordinary)
    return (f'1. checking unconstrained_internal_endpoints ({count})\n------------------------\n'
            f'There are {len(ordinary)} pins that are not constrained for maximum delay.\n'
            + '\n'.join(ordinary) + '\n'
            f' There are {len(pins)} pins that are not constrained for maximum delay due to constant clock. (MEDIUM)\n\n'
            + '\n'.join(pins) + '\n')


class CpmGtCoverageWaiverTests(unittest.TestCase):
    def setUp(self):
        self.waivers = v.load_waivers([REPO / 'cfg/validation/av80.json'])

    def test_only_the_complete_reviewed_constant_clock_section_is_waived(self):
        for pins in (PINS, list(reversed(PINS))):
            findings = v.coverage_findings(coverage(pins))
            active, waived, unused = v.apply_waivers(findings, self.waivers, 'av80.esnet_shell')
            self.assertFalse(active)
            self.assertEqual(len(waived), 1)
            self.assertEqual(waived[0]['count'], 112)
            self.assertFalse(unused)

    def test_ordinary_endpoints_unknown_pins_hierarchies_and_count_changes_remain_visible(self):
        damaged = [coverage(ordinary=['i_core/unsafe_reg/D']),
                   coverage(PINS[:-1]), coverage(PINS + ['i_core/unsafe_reg/D']),
                   coverage([p.replace('RXPHSHIFT180', 'RXRESET') for p in PINS]),
                   coverage([p.replace('gt_quad_inst3', 'gt_quad_inst4') for p in PINS]),
                   coverage([p.replace('CH3_', 'CH4_') for p in PINS]),
                   coverage([p.replace('top_i/cips/inst/cpm_0', 'i_other_gt') for p in PINS]),
                   coverage([p.replace('gt_quad_inst0', 'dcmac_gt') for p in PINS])]
        for report in damaged:
            with self.subTest(report=report):
                findings = v.coverage_findings(report)
                active, waived, _ = v.apply_waivers(findings, self.waivers, 'av80.esnet_shell')
                self.assertTrue(active)
                self.assertFalse(waived)
        # Classifying these as ordinary untimed paths must also prevent a match.
        report = (f'1. checking unconstrained_internal_endpoints (112)\n------------------------\n'
                  'There are 112 pins that are not constrained for maximum delay.\n\n'
                  + '\n'.join(PINS) + '\n\n'
                  'There are 0 pins that are not constrained for maximum delay due to constant clock. (MEDIUM)\n')
        self.assertTrue(v.apply_waivers(v.coverage_findings(report), self.waivers, 'av80.esnet_shell')[0])

    def test_dcmac_coverage_cdc_and_other_findings_are_unchanged(self):
        remaining = [v.finding('constraints', 'pulse_width_clock', 'DCMAC MBUFG_GT/CLR', 4),
                     v.finding('cdc', 'CDC-10', 'Combinational logic before synchronizer', 3),
                     v.finding('critical_warnings', 'Vivado 12-2285', 'GTM LOC conflict', source='image'),
                     v.finding('constraints', 'no_clock', 'i_core/CCLK')]
        active, waived, _ = v.apply_waivers(v.coverage_findings(coverage()) + remaining,
                                           self.waivers, 'av80.esnet_shell')
        self.assertEqual(active, remaining)
        self.assertEqual(sum(f['count'] for f in waived), 112)


if __name__ == '__main__':
    unittest.main()
