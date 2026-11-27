"""The CMAC license exception requires both complete licensing and generated configuration evidence."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
import zipfile

REPO = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location(
    "cmac_validator", REPO / "esnet-fpga-library/scripts/vivado/validation/validate_build.py")
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)

HEADER = ("Evaluation License Warning: This design contains one or more IP cores that use separately licensed features. "
          "If the design has been configured to make use of evaluation features, please note that these features will cease "
          "to function after a certain period of time. Please consult the core datasheet to determine whether the core "
          "which you have configured will be affected. Evaluation features should NOT be used in production systems.")


def license_block(n):
    return (f"    IP core 'xilinx_cmac_{n}' (cmac_usplus_core) was generated with multiple features:\n"
            "        IP feature 'cmac_an_lt@2020.05' was enabled using a design_linking license.\n"
            "        IP feature 'cmac_usplus@2020.05' was enabled using a bought license.\n")


def warning(order=(1, 0)):
    return (f"CRITICAL WARNING: [Vivado 12-1790] {HEADER}\n\nEvaluation cores found in this design:\n"
            + "".join(license_block(n) for n in order) + "\nResolution: Regenerate output products.\n")


class CmacLicenseWaiverTests(unittest.TestCase):
    def setUp(self):
        self.waivers = v.load_waivers([REPO / "cfg/validation/usplus.json"])
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.route = self.root / "routed.dcp"
        self.route.touch()
        self.log = self.root / "bitstream.log"

    def artifacts(self, edits=None):
        inputs = []
        for n in (0, 1):
            core = f"xilinx_cmac_{n}"
            text = (f'(* CORE_GENERATION_INFO = "{core},cmac_usplus_core,{{'
                    'x_ipProduct=Vivado 2025.2,C_CMAC_CAUI4_MODE=1,C_INCLUDE_AUTO_NEG_LT_LOGIC=0,'
                    'C_INCLUDE_AN_LT_TX_TRAINER=0,x_ipLicense=cmac_usplus@2020.05(bought),'
                    'x_ipLicense=cmac_an_lt@2020.05(design_linking)}" *)')
            if n == 1 and edits:
                text = text.replace(*edits)
            path = self.root / (core + ".dcp")
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr(core + "_stub.v", text)
            age = self.route.stat().st_mtime_ns - 1
            os.utime(path, ns=(age, age))
            inputs.append((f"cmac_{n}", path))
        return inputs

    def test_only_two_expected_log_copies_with_both_complete_licensed_cores_are_waived(self):
        eligible, records, errors = v.check_waiver_evidence(self.waivers, self.artifacts(), self.route, "au55c.esnet_shell")
        self.assertFalse(errors)
        self.assertEqual(len(records), 2)
        for order in ((0, 1), (1, 0)):
            self.log.write_text(warning(order))
            findings = v.log_findings([(self.log, "image"), (self.log, "products/esnet_smartnic/build/esnet_shell.bitstream.log")])
            active, waived, unused = v.apply_waivers(findings, eligible, "au55c.esnet_shell")
            self.assertFalse(active)
            self.assertEqual(len(waived), 2)
            self.assertFalse(unused)

    def test_enabled_features_changed_licenses_or_missing_configuration_block_the_waiver(self):
        for edits in (("C_INCLUDE_AUTO_NEG_LT_LOGIC=0", "C_INCLUDE_AUTO_NEG_LT_LOGIC=1"),
                      ("C_INCLUDE_AN_LT_TX_TRAINER=0", "C_INCLUDE_AN_LT_TX_TRAINER=1"),
                      ("C_CMAC_CAUI4_MODE=1", "C_CMAC_CAUI4_MODE=0"),
                      ("cmac_usplus@2020.05(bought)", "cmac_usplus@2020.05(design_linking)"),
                      ("C_INCLUDE_AUTO_NEG_LT_LOGIC=0,", "")):
            with self.subTest(edits=edits):
                eligible, records, errors = v.check_waiver_evidence(self.waivers, self.artifacts(edits), self.route, "au55c.esnet_shell")
                self.assertFalse(eligible)
                self.assertTrue(errors)
                self.assertFalse(records[1]["passed"])

    def test_other_license_problems_extra_or_missing_cores_and_truncation_remain_visible(self):
        eligible, _, _ = v.check_waiver_evidence(self.waivers, self.artifacts(), self.route, "au55c.esnet_shell")
        good = warning()
        for text in (good.replace("cmac_usplus@2020.05' was enabled using a bought", "cmac_usplus@2020.05' was enabled using a design_linking"),
                     good.replace("\nResolution:", "\n" + license_block(2) + "\nResolution:"),
                     warning((0,)), warning((0, 0)), good.split("\nResolution:")[0],
                     good.replace("xilinx_cmac_0", "other_ip"),
                     f"CRITICAL WARNING: [Vivado 12-1790] {HEADER}\n"):
            with self.subTest(text=text):
                self.log.write_text(text)
                findings = v.log_findings([(self.log, "image")])
                active, waived, _ = v.apply_waivers(findings, eligible, "au55c.esnet_shell")
                self.assertEqual(len(active), 1)
                self.assertFalse(waived)
        self.log.write_text(good)
        findings = v.log_findings([(self.log, "unreviewed_source")])
        self.assertTrue(v.apply_waivers(findings, eligible, "au55c.esnet_shell")[0])


if __name__ == "__main__":
    unittest.main()
