import importlib.util
from pathlib import Path
import tempfile
import subprocess
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("build_info", REPO / "scripts/generate_shell_build_info.py")
build_info = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build_info)


class BuildInfoTest(unittest.TestCase):
    def test_metadata_values_and_incremental_refresh(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "include/info.svh"
            env = {"SHELL_VPD_BUILD_ID": "123", "SHELL_VPD_APPLICATION_ID": 'app "name"',
                   "SHELL_VPD_BUILD_TIMESTAMP": "1700000000"}
            build_info.generate(path, REPO, env)
            text = path.read_text()
            self.assertIn('VPD_APPLICATION_ID = "app \\"name\\"";', text)
            self.assertIn("VPD_BUILD_ID = 32'h0000007b;", text)
            self.assertIn('2023-11-14 22:13:20 UTC', text)
            before = path.stat().st_mtime_ns
            build_info.generate(path, REPO, env)
            self.assertEqual(path.stat().st_mtime_ns, before)
            env["SHELL_VPD_APPLICATION_ID"] = "other_app"
            build_info.generate(path, REPO, env)
            self.assertIn('VPD_APPLICATION_ID = "other_app";', path.read_text())

    def test_default_timestamp_is_preserved_for_the_same_build_identity(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "info.svh"
            env = {"SHELL_VPD_BUILD_ID": "123"}
            build_info.generate(path, REPO, env)
            before = path.read_text(), path.stat().st_mtime_ns
            with patch.object(build_info, "datetime", wraps=build_info.datetime) as dt:
                build_info.generate(path, REPO, env)
                dt.now.assert_not_called()
            self.assertEqual((path.read_text(), path.stat().st_mtime_ns), before)

    def test_clean_source_collection_tracks_generated_metadata(self):
        for build_dir in ("src/xilinx/alveo/usplus/shell/build",
                          "src/xilinx/alveo/versal/shell/av80/build"):
            with self.subTest(build_dir=build_dir):
                with tempfile.TemporaryDirectory() as tmp:
                    root = Path(tmp)
                    sources = root / "synth/sources.tcl"
                    header = root / "include/shell_build_info.svh"
                    cmd = ["make", "-s", "-C", str(REPO / build_dir),
                           str(sources), f"COMPONENT_OUT_PATH={root}", "SUBCOMPONENTS=", "BUILD_ID=123",
                           "SHELL_VPD_APPLICATION_ID=first"]
                    def run(args):
                        result = subprocess.run(args, capture_output=True, text=True, timeout=30)
                        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    run(cmd)
                    self.assertIn(str(header), sources.read_text())
                    before = header.stat().st_mtime_ns, sources.stat().st_mtime_ns
                    run(cmd)
                    self.assertEqual((header.stat().st_mtime_ns, sources.stat().st_mtime_ns), before)
                    old_sources = sources.read_text()
                    run(cmd[:-1] + ["SHELL_VPD_APPLICATION_ID=second"])
                    self.assertIn('VPD_APPLICATION_ID = "second";', header.read_text())
                    self.assertNotEqual(sources.read_text(), old_sources)

    def test_invalid_numeric_and_text_values_are_rejected(self):
        for env in ({"SHELL_VPD_BUILD_ID": "-1"}, {"SHELL_VPD_BUILD_ID": "4294967296"},
                    {"SHELL_VPD_BUILD_TIMESTAMP": "4294967296"},
                    {"SHELL_VPD_APPLICATION_ID": "bad\nname"}):
            with self.subTest(env=env), tempfile.TemporaryDirectory() as tmp:
                with self.assertRaises(ValueError):
                    build_info.generate(Path(tmp) / "info.svh", REPO, env)
