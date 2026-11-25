"""Check that normalized CIPS settings cannot silently change the PCIe contract."""

from pathlib import Path
import re
import subprocess
import unittest


REPO = Path(__file__).resolve().parents[3]
SOURCE = REPO / "src/xilinx/alveo/versal/bd/xilinx_aved.tcl"


class AvedPcieConfigTest(unittest.TestCase):
    def check(self, modification=""):
        source = SOURCE.read_text()
        guard = re.search(r"(?ms)^proc xilinx_aved_check_pcie_config .*?^}", source).group()
        script = guard + '''
set expected [dict create \\
    CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_ENABLED 1 \\
    CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SIZE 8 \\
    CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SCALE Megabytes \\
    CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 0x0000020300000000 \\
    CPM_PCIE0_PF1_SRIOV_CAP_TOTAL_VF 4 \\
    CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE 7]
set actual $expected
dict set actual CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 2211908157440
dict set actual CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE 007
dict set actual CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SCALE megabytes
''' + modification + '\nxilinx_aved_check_pcie_config $expected $actual\n'
        # Tcl stdin mode can continue after an error, so use an explicit exit code.
        driver = "if {[catch {\n" + script + "\n} message]} {puts stderr $message; exit 1}\n"
        return subprocess.run(["tclsh"], input=driver, text=True, capture_output=True, timeout=30)

    def test_equivalent_numeric_and_enum_formats_pass(self):
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_or_changed_resolved_settings_fail(self):
        for change in (
            "dict unset actual CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_ENABLED",
            "dict set actual CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_ENABLED 0",
            "dict set actual CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SIZE 4",
            "dict set actual CPM_PCIE0_PF0_BAR2_SRIOV_QDMA_SCALE Kilobytes",
            "dict set actual CPM_PCIE0_PF0_PCIEBAR2AXIBAR_SRIOV_QDMA_2 0",
            "dict set actual CPM_PCIE0_PF1_SRIOV_CAP_TOTAL_VF 0",
            "dict set actual CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE 8",
        ):
            with self.subTest(change=change):
                result = self.check(change)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("PCIe setting", result.stderr)


if __name__ == "__main__":
    unittest.main()
