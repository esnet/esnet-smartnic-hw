"""Exercise the real shell stage rules with synthetic checkpoints, without Vivado.

Run with: python3 scripts/Makefiles/tests/test_shell_build_incremental.py
"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest


REPO = Path(__file__).resolve().parents[3]
SCRIPT = Path(__file__).resolve()
STAGES = ["link", "opt", "place", "place_opt", "route", "route_opt"]


def mock_tool(mode, root, args):
    """Replace only recursive synthesis and Vivado; Make owns stage scheduling."""
    root = Path(root)
    with (root / "events").open("a") as stream:
        stage = "pre" if mode == "--synth" else args[args.index("-tclargs") + 1]
        stream.write(stage + "\n")
    if mode == "--synth":
        if os.environ.get("FAIL_PRE") == "1":
            raise SystemExit("simulated synthesis failure")
        for filename in args:
            output = Path(filename)
            if output.name == os.environ.get("OMIT_INPUT"):
                continue
            source = root / "sources" / output.name
            if not output.exists() or source.stat().st_mtime_ns > output.stat().st_mtime_ns:
                output.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, output)
    else:
        if stage == "link":
            inputs = json.loads((root / "inputs.json").read_text())
            content = json.dumps({Path(p).name: Path(p).read_text() for p in inputs})
        else:
            previous = STAGES[STAGES.index(stage) - 1]
            content = Path(f"esnet_shell.{previous}.dcp").read_text()
        Path(f"esnet_shell.{stage}.dcp").write_text(content)


class Fixture:
    def __init__(self, root, jobs=1, duplicate=False):
        self.root = Path(root)
        self.jobs = jobs
        self.out = self.root / "out"
        self.inputs = [self.root / "inputs" / p for p in (
            "shell.build/esnet_shell.synth.dcp", "core.dcp", "app.dcp", "nested.dcp"
        )]
        self.sources = self.root / "sources"
        self.sources.mkdir()
        for checkpoint in self.inputs:
            (self.sources / checkpoint.name).write_text("initial")
        (self.root / "inputs.json").write_text(json.dumps([str(p) for p in self.inputs]))
        toolchain = self.root / "toolchain/Makefiles"
        toolchain.mkdir(parents=True)
        library = REPO / "esnet-fpga-library/scripts/Makefiles"
        for name in ("vivado_build_non_proj.mk", "vivado_base.mk", "vivado_validate.mk"):
            (toolchain / name).symlink_to(library / name)
        (toolchain / "vivado_compile.mk").write_text(
            ".PHONY: FORCE _compile_synth\nFORCE:\n_compile_synth:\n"
            "\t@$(PYTHON) $(TEST_SCRIPT) --synth $(TEST_DIR) "
            "$(TOP_DCP_FILE) $(__SB_ALL_CELL_DCP_PATHS)\n"
        )
        app_dcps = f"i_app:{self.inputs[2]} i_nested:{self.inputs[3]}"
        if duplicate:
            app_dcps += f" i_nested_copy:{self.inputs[3]}"
        (self.root / "Makefile").write_text(f"""
TEST_DIR := {self.root}
TEST_SCRIPT := {SCRIPT}
PYTHON := {sys.executable}
SCRIPTS_ROOT := $(TEST_DIR)/toolchain
SMARTNIC_ROOT := {REPO}
LIB_OUTPUT_ROOT := $(TEST_DIR)/out
COMPONENT_OUT_PATH := $(TEST_DIR)/out
COMPONENT_OUT_SYNTH_PATH := $(COMPONENT_OUT_PATH)/synth
get_lib_component_out_path_from_ref = $(TEST_DIR)/inputs/$(1)
TOP := esnet_shell
SHELL_BUILD_REF := shell.build
CORE_BUILD_REF := core.build
APP_BUILD_REF := app.build
CORE_CELL_DCPS := i_core:{self.inputs[1]}
APP_CELL_DCPS := {app_dcps}
override VIVADO_NP_CMD = $(PYTHON) $(TEST_SCRIPT) --vivado $(TEST_DIR)
export OMIT_INPUT FAIL_PRE
include {REPO}/scripts/Makefiles/shell_build_base.mk
""")

    def run(self, *goals, success=True, **variables):
        events = self.root / "events"
        events.unlink(missing_ok=True)
        env = os.environ.copy()
        for name in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL"):
            env.pop(name, None)
        result = subprocess.run(
            ["make", "--no-print-directory", f"-j{self.jobs}",
             *(goals or ("_np_route_opt",)),
             *(f"{name}={value}" for name, value in variables.items())],
            cwd=self.root, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            timeout=30,
        )
        if (result.returncode == 0) != success:
            raise AssertionError(result.stdout)
        self.events = events.read_text().splitlines() if events.exists() else []
        return result.stdout

    def age(self):
        # Keep all timestamps in the past, with inputs older than completed stages.
        base = time.time() - 30
        for path in self.sources.iterdir():
            os.utime(path, (base, base))
        for path in self.inputs:
            os.utime(path, (base + 1, base + 1))
        for path in self.out.rglob("*"):
            if path.is_file():
                os.utime(path, (base + 2, base + 2))


class IncrementalShellBuildTest(unittest.TestCase):
    def fixture(self, **kwargs):
        temporary = tempfile.TemporaryDirectory(prefix="shell-incremental-")
        self.addCleanup(temporary.cleanup)
        return Fixture(temporary.name, **kwargs)

    def assert_stages(self, fixture, stages):
        self.assertEqual(fixture.events.count("pre"), 1)
        self.assertEqual([e for e in fixture.events if e != "pre"], stages)

    def test_clean_build(self):
        for jobs in (1, 4):
            with self.subTest(jobs=jobs):
                fixture = self.fixture(jobs=jobs)
                fixture.run()
                self.assert_stages(fixture, STAGES)

    def test_no_op_preserves_stage_timestamps(self):
        fixture = self.fixture(jobs=4)
        fixture.run()
        stamps = {p: p.stat().st_mtime_ns for p in (fixture.out / ".done").iterdir()}
        fixture.run()
        self.assert_stages(fixture, [])
        self.assertEqual(stamps, {p: p.stat().st_mtime_ns for p in stamps})

    def test_source_changes_propagate_in_one_invocation(self):
        for jobs in (1, 4):
            for index in range(4):
                with self.subTest(jobs=jobs, input=index):
                    fixture = self.fixture(jobs=jobs)
                    fixture.run()
                    fixture.age()
                    name = fixture.inputs[index].name
                    (fixture.sources / name).write_text("updated")
                    fixture.run()
                    self.assert_stages(fixture, STAGES)
                    output = json.loads((fixture.out / "esnet_shell.route_opt.dcp").read_text())
                    self.assertEqual(output[name], "updated")

    def test_external_checkpoint_change(self):
        fixture = self.fixture()
        fixture.run()
        fixture.age()
        fixture.inputs[1].write_text("externally rebuilt")
        fixture.run()
        self.assert_stages(fixture, STAGES)

    def test_deleted_checkpoint_is_rebuilt(self):
        fixture = self.fixture(jobs=4)
        fixture.run()
        fixture.inputs[1].unlink()
        fixture.run()
        self.assert_stages(fixture, STAGES)

    def test_missing_synthesis_output_stops_assembly(self):
        fixture = self.fixture(jobs=4)
        output = fixture.run(success=False, OMIT_INPUT="core.dcp")
        self.assertIn("core.dcp", output)
        self.assert_stages(fixture, [])

    def test_synthesis_failure_stops_assembly(self):
        fixture = self.fixture(jobs=4)
        fixture.run()
        fixture.run(success=False, FAIL_PRE="1")
        self.assert_stages(fixture, [])

    def test_shared_checkpoint_and_multiple_goals(self):
        fixture = self.fixture(jobs=4, duplicate=True)
        output = fixture.run("_np_opt", "_np_route_opt")
        self.assertNotIn("given more than once", output)
        self.assert_stages(fixture, STAGES)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ("--synth", "--vivado"):
        mock_tool(sys.argv[1], sys.argv[2], sys.argv[3:])
    else:
        unittest.main()
