"""Check validation scheduling, environment selection, and read-only Make dispatch."""
import copy
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import yaml

REPO = Path(__file__).resolve().parents[3]


class Loader(yaml.SafeLoader):
    pass


Loader.add_constructor("!reference", lambda loader, node: loader.construct_sequence(node))


def merge(left, right):
    result = copy.deepcopy(left)
    for key, value in right.items():
        result[key] = merge(result[key], value) if isinstance(value, dict) and isinstance(result.get(key), dict) else copy.deepcopy(value)
    return result


class NativeValidationCI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ci = yaml.load((REPO / ".gitlab-ci.yml").read_text(), Loader=Loader)

    def resolve(self, name):
        job = self.ci[name]
        parents = job.get("extends", [])
        if isinstance(parents, str):
            parents = [parents]
        result = {}
        for parent in parents:
            result = merge(result, self.resolve(parent))
        return merge(result, {key: value for key, value in job.items() if key != "extends"})

    def test_every_native_image_has_advisory_validation_in_its_tool_environment(self):
        builds = [name for name, value in self.ci.items() if not name.startswith(".")
                  and isinstance(value, dict) and value.get("extends") in (".shell_image_usplus", ".shell_image_versal")]
        self.assertEqual(len(builds), 7)
        for build in builds:
            name = "validate_" + build.removeprefix("build_")
            job = self.resolve(name)
            self.assertEqual(job["needs"], [{"job": build, "artifacts": True}])
            self.assertEqual(job["image"], self.resolve(build)["image"])
            self.assertTrue(job["allow_failure"])
            self.assertEqual(job["stage"], "validate")
            self.assertEqual(job["artifacts"]["when"], "always")
            self.assertIn("junit", job["artifacts"]["reports"])
            self.assertIn("ht-synth", job["tags"])
            self.assertNotIn("when", job)  # Run after successful builds, without an extra manual step.

    def test_packaging_and_downstream_jobs_are_not_gated_by_validation(self):
        for name, value in self.ci.items():
            if not isinstance(value, dict) or name == "variables":
                continue
            job = self.resolve(name)
            if job.get("stage") in ("package", "trigger_downstream"):
                for need in job.get("needs", []):
                    self.assertFalse((need if isinstance(need, str) else need["job"]).startswith("validate_"), name)
        self.assertEqual(self.ci["validate_p4_only_u280"]["extends"], ".validate")

    def test_ip_job_transcripts_preserve_failure_from_nested_make(self):
        for template in (".shell_ip", ".shell_ip_versal"):
            with self.subTest(template=template), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / "bin").mkdir()
                fake = root / "bin/make"
                fake.write_text("#!/bin/sh\necho \"$*\" >> \"$CALLS\"\ncase \" $* \" in *' synth '*) echo 'CRITICAL WARNING: [TEST-1] Nested failure'; exit 17;; esac\n")
                fake.chmod(0o755)
                script = self.resolve(template)["script"][0].replace("esnet-fpga-library/scripts/vivado/validation/run_logged.py", str(REPO / "esnet-fpga-library/scripts/vivado/validation/run_logged.py"))
                env = os.environ.copy()
                env.update(PATH=str(root / "bin") + os.pathsep + env["PATH"], SN_HW_BOARD="av80" if template.endswith("versal") else "au55c", BUILD_ID="1234", CI_PROJECT_DIR=tmp, CALLS=str(root / "calls"))
                result = subprocess.run(["bash", "-eu", "-c", script], cwd=root, env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 17, result.stdout + result.stderr)
                log = root / "examples/esnet_shell/build" / env["SN_HW_BOARD"] / "out/validation-inputs/ip.log"
                self.assertIn("CRITICAL WARNING", log.read_text())
                self.assertTrue(log.read_text().endswith("BUILD_EXIT_CODE=17\n"))
                calls = (root / "calls").read_text().splitlines()
                self.assertEqual(len(calls), 4 if template.endswith("versal") else 3)

    def test_make_validate_only_schedules_the_checker_for_all_native_examples(self):
        for example, board in [("esnet_shell", "au55c"), ("esnet_shell", "au280"), ("esnet_shell", "au250"),
                               ("esnet_shell", "av80"), ("p4_only_av80", "av80"), ("udplb_fec_av80", "av80")]:
            with self.subTest(example=example, board=board), tempfile.TemporaryDirectory() as tmp:
                env = os.environ.copy()
                for key in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL"):
                    env.pop(key, None)
                env["XILINX_VIVADO"] = "/tools/Xilinx/2025.2/Vivado"
                result = subprocess.run(["make", "-sn", "-f", str(REPO / "examples" / example / "Makefile"), "validate",
                                         f"BOARD={board}", f"SMARTNIC_ROOT={REPO}", f"BUILD_DIR={tmp}/build"],
                                        cwd=tmp, env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("validate_build.py", result.stdout)
                self.assertIn(("esnet_shell" if board.startswith("au") else "esnet_smartnic") + ".route_opt.dcp", result.stdout)
                self.assertNotIn("vivado -", result.stdout)
                self.assertNotIn("Configuring", result.stdout)
                self.assertFalse((Path(tmp) / "build").exists())


if __name__ == "__main__":
    unittest.main()
