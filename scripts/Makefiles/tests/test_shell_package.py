"""Check the local firmware archive contract without FPGA tools."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile


SCRIPT = Path(__file__).resolve().parents[2] / "package_hwapi.py"


class PackageTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.board = "au55c"
        self.hwapi = self.root / "installed"
        self.output = self.root / "artifacts" / "firmware.zip"
        for name in ("firmware", "regmap/spec", "wireshark", "libvitisnetp4drv"):
            (self.hwapi / name).mkdir(parents=True)
        for name in ("firmware/esnet-smartnic.bin.zst", "firmware/esnet-smartnic.bit.zst",
                     "firmware/esnet-smartnic.ltx", "regmap/esnet-smartnic-top-ir.yaml"):
            (self.hwapi / name).write_bytes(name.encode())

    def run_package(self, success=True):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--hwapi-dir", str(self.hwapi),
             "--output", str(self.output), "--board", self.board], capture_output=True, text=True,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)

    def test_usplus_archive_preserves_payloads_and_empty_importer_directories(self):
        self.run_package()
        with zipfile.ZipFile(self.output) as archive:
            self.assertIsNone(archive.testzip())
            for name in ("regmap/spec/", "wireshark/", "libvitisnetp4drv/"):
                self.assertIn(f"esnet-smartnic-hwapi/{self.board}/" + name, archive.namelist())
            for path in self.hwapi.rglob("*"):
                if path.is_file():
                    name = f"esnet-smartnic-hwapi/{self.board}/" + path.relative_to(self.hwapi).as_posix()
                    self.assertEqual(archive.read(name), path.read_bytes())

    def test_versal_archive_uses_its_board_directory(self):
        self.board = "av80"
        (self.hwapi / "firmware/esnet-smartnic.bit.zst").rename(
            self.hwapi / "firmware/esnet-smartnic.pdi.zst")
        self.run_package()
        with zipfile.ZipFile(self.output) as archive:
            self.assertIn("esnet-smartnic-hwapi/av80/firmware/esnet-smartnic.pdi.zst",
                          archive.namelist())

    def test_board_archives_can_be_gathered_without_overwriting(self):
        self.run_package()
        gathered = self.root / "gathered"
        with zipfile.ZipFile(self.output) as archive:
            archive.extractall(gathered)
        self.board = "av80"
        (self.hwapi / "firmware/esnet-smartnic.bit.zst").rename(
            self.hwapi / "firmware/esnet-smartnic.pdi.zst")
        self.run_package()
        with zipfile.ZipFile(self.output) as archive:
            archive.extractall(gathered)
        self.assertTrue((gathered / "esnet-smartnic-hwapi/au55c/firmware/esnet-smartnic.bit.zst").is_file())
        self.assertTrue((gathered / "esnet-smartnic-hwapi/av80/firmware/esnet-smartnic.pdi.zst").is_file())

    def test_missing_programming_export_preserves_previous_archive(self):
        self.run_package()
        original = self.output.read_bytes()
        (self.hwapi / "firmware/esnet-smartnic.bin.zst").unlink()
        self.run_package(success=False)
        self.assertEqual(self.output.read_bytes(), original)

    def test_missing_importer_directory_is_rejected(self):
        (self.hwapi / "wireshark").rmdir()
        self.run_package(success=False)
        self.assertFalse(self.output.exists())

    def test_output_inside_source_is_rejected(self):
        self.output = self.hwapi / "firmware.zip"
        self.run_package(success=False)
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
