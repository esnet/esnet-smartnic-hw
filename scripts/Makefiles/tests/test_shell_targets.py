"""Exercise shell configuration and image dispatch without running FPGA tools."""

import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[3]
BOARDS = ("au55c", "au280", "au250", "av80")


class ShellTargetsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="shell-targets-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        makefile = (REPO / "examples/esnet_shell/Makefile").read_text()
        makefile = makefile.replace("$(abspath ../..)", str(REPO))
        (self.root / "Makefile").write_text(makefile)
        (self.root / "inspect.mk").write_text(".PHONY: inspect\ninspect:;@:\n")
        self.env = os.environ.copy()
        for name in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL"):
            self.env.pop(name, None)
        self.env["XILINX_VIVADO"] = "/tools/Xilinx/2025.2/Vivado"

    def make(self, board, *args, cwd=None):
        result = subprocess.run(
            ["make", "--no-print-directory", f"BOARD={board}", *args],
            cwd=cwd or self.root, env=self.env, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        return result.stdout

    def component(self, board):
        return self.root / "build" / board / "src/esnet_smartnic/build"

    def test_default_goal_dispatches_image_for_every_board(self):
        for board in BOARDS:
            with self.subTest(board=board):
                output = self.make(board, "SMARTNIC_COMP_CMD=echo EXPORT")
                self.assertIn("EXPORT image", output)

    def test_generated_targets_route_to_native_export(self):
        for board in BOARDS:
            with self.subTest(board=board):
                self.make(board, "config")
                component = self.component(board)
                database = self.make(board, "-p", "-f", "Makefile", "-f",
                                     str(self.root / "inspect.mk"), "inspect", cwd=component)
                def prerequisites(target):
                    match = re.search(r"^" + re.escape(target) + r":(.*)$", database, re.M)
                    self.assertIsNotNone(match, target)
                    return match[1].split()
                self.assertEqual(prerequisites("image"), [".shell_build_image"])
                self.assertEqual(prerequisites(".shell_build"), ["_np_route_opt"])
                if board == "av80":
                    self.assertEqual(prerequisites(".shell_build_image"),
                                     [".versal_shell_build_pdi"])
                    export = prerequisites(".versal_shell_build_pdi")
                    self.assertIn("_np_xsa", export)
                    self.assertTrue(any(p.endswith("_app.pdi") for p in export))
                else:
                    self.assertEqual(prerequisites(".shell_build_image"), ["_np_bitstream"])

    def test_refreshes_generated_targets_without_removing_outputs(self):
        board = "au55c"
        self.make(board, "config")
        component = self.component(board)
        makefile = component / "Makefile"
        makefile.write_text(makefile.read_text().replace("image:", "old_image:"))
        os.utime(component / ".configured", (1, 1))
        output = self.root / "build" / board / "out/esnet_smartnic/build/esnet_shell.route_opt.dcp"
        output.parent.mkdir(parents=True)
        output.write_bytes(b"existing routed checkpoint")
        self.make(board, "config")
        self.assertIn("\nimage:", makefile.read_text())
        self.assertEqual(output.read_bytes(), b"existing routed checkpoint")


if __name__ == "__main__":
    unittest.main()
