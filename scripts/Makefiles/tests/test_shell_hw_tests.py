"""Exercise native hardware test packaging without Vivado or Robot Framework."""

from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[3]
SCRIPT = REPO / "scripts/package_hw_tests.py"


class HardwareTestsPackageTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "test"
        self.output = self.root / "out/robot-framework-test.tar.bz2"
        for name in ("library/variables.py", "library/__pycache__/variables.pyc",
                     "suites/smartnic/suite.robot", "suites/p4_only/suite.robot",
                     "suites/unrelated/suite.robot"):
            path = self.source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(name)

    def package(self, app, success=True):
        result = subprocess.run([sys.executable, str(SCRIPT), "--test-root", str(self.source),
                                 "--output", str(self.output), "--app", app],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stderr)
        if success:
            with tarfile.open(self.output) as archive:
                return set(archive.getnames())

    def test_shell_and_apps_without_suites_get_shared_tests(self):
        for app in ("shell", "udplb_fec_av80"):
            names = self.package(app)
            self.assertIn("library/variables.py", names)
            self.assertIn("suites/smartnic/suite.robot", names)
            self.assertNotIn("suites/p4_only/suite.robot", names)
            self.assertFalse(any("__pycache__" in name for name in names))

    def test_selected_suite_is_included_and_stale_suite_is_removed(self):
        self.assertIn("suites/p4_only/suite.robot", self.package("p4_only"))
        self.assertNotIn("suites/p4_only/suite.robot", self.package("shell"))

    def test_missing_shared_tests_fail_without_replacing_previous_archive(self):
        self.package("shell")
        original = self.output.read_bytes()
        (self.source / "suites/smartnic/suite.robot").unlink()
        (self.source / "suites/smartnic").rmdir()
        self.package("shell", success=False)
        self.assertEqual(self.output.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
