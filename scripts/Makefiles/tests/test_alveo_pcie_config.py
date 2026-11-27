"""Check that Alveo RTL function counts match PCIe IP generation."""
from pathlib import Path
import re
import unittest

REPO = Path(__file__).resolve().parents[3]


class AlveoPcieConfigTest(unittest.TestCase):
    def check_function_count(self, arch, config_path, config_pattern):
        package = REPO / f"src/xilinx/alveo/{arch}/pkg/src/xilinx_alveo_{arch}_pkg.sv"
        match = re.search(r"localparam\s+int\s+NUM_PHYS_FUNC\s*=\s*(\d+)\s*;",
                          package.read_text())
        self.assertIsNotNone(match, f"Missing literal NUM_PHYS_FUNC in {package}")
        rtl_count = int(match.group(1))
        self.assertGreater(rtl_count, 0)
        config = REPO / config_path
        match = re.search(config_pattern, config.read_text())
        self.assertIsNotNone(match, f"Missing PF count in {config}")
        self.assertEqual(rtl_count, int(match.group(1)),
                         f"{arch} package and PCIe IP physical-function counts differ")

    def test_usplus_function_count_matches_qdma(self):
        self.check_function_count(
            "usplus", "src/xilinx/alveo/usplus/ip/xilinx_alveo_usplus_qdma.tcl",
            r"CONFIG\.tl_pf_enable_reg\s+\{(\d+)\}")

    def test_versal_function_count_matches_cpm5(self):
        self.check_function_count(
            "versal", "src/xilinx/alveo/versal/bd/xilinx_aved.tcl",
            r"CPM_PCIE0_TL_PF_ENABLE_REG\s+(\d+)\s")
