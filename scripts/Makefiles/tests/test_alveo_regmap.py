"""Keep firmware-facing Alveo registers aligned with the hardware decoder."""
from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml

REPO = Path(__file__).resolve().parents[3]
REGIO = REPO / 'esnet-fpga-library/tools/regio/regio-elaborate'


class AlveoRegmapTest(unittest.TestCase):
    def check_architecture(self, arch):
        with tempfile.TemporaryDirectory() as temporary:
            work = Path(temporary)

            def elaborate(source, output):
                result = subprocess.run([
                    str(REGIO), '-f', 'decoder', '-i', str(REPO / 'esnet-fpga-library'),
                    '-i', str(work), '-o', str(output), str(REPO / source)],
                    text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                return yaml.safe_load(output.read_text())

            result = subprocess.run([
                str(REGIO.parent / 'regio-flatten'), '-i', str(REPO / 'esnet-fpga-library'),
                '-o', str(work / 'core_decoder-ir.yaml'),
                str(REPO / 'src/core/stub/regio/core_decoder.yaml')],
                text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            hardware = elaborate('src/xilinx/alveo/regio/xilinx_alveo_shell_decoder.yaml',
                                 work / 'hardware.yaml')
            software = elaborate(f'src/xilinx/alveo/{arch}/shell/regio/shell_decoder_core.yaml',
                                 work / 'software.yaml')
            hw = next(i for i in hardware['interfaces'] if i['name'] == 'vpd')
            sw = next(i for i in software['interfaces'] if i['name'] == 'vpd')
            self.assertEqual(hw['address'], 0x1000)
            self.assertEqual((hw['address'], hw['width']), (sw['address'], sw['width']))
            self.assertEqual(hw['block']['regs'], sw['block']['regs'])
            self.assertEqual([r['name'] for r in sw['block']['regs']],
                             ['control', 'status', 'card_info'])

    def test_usplus_export_matches_hardware(self):
        self.check_architecture('usplus')

    def test_versal_export_matches_hardware(self):
        self.check_architecture('versal')
