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

    def test_every_native_image_collects_reports_for_a_lightweight_gate(self):
        builds = [name for name, value in self.ci.items() if not name.startswith(".")
                  and isinstance(value, dict) and value.get("extends") in (".shell_image_usplus", ".shell_image_versal")]
        self.assertEqual(len(builds), 7)
        for build in builds:
            name = "validate_" + build.removeprefix("build_")
            job = self.resolve(name)
            self.assertEqual(job["needs"], [{"job": build, "artifacts": True}])
            self.assertEqual(job["image"], self.resolve(".common")["image"])
            self.assertEqual(job["before_script"], [])
            image = self.resolve(build)
            self.assertEqual(image["after_script"], self.ci[".shell_image"]["after_script"])
            self.assertIn("SN_HW_BUILD_JOB_NUMBER=$CI_JOB_ID", image["script"][0])
            self.assertEqual(image["variables"]["RUNNER_AFTER_SCRIPT_TIMEOUT"], "1h")
            self.assertNotIn("make ", "\n".join(job["script"]))
            self.assertEqual(job["stage"], "validate")
            self.assertEqual(job["artifacts"]["when"], "always")
            self.assertIn("junit", job["artifacts"]["reports"])
            self.assertEqual(job["tags"], ["ht-misc"])
            self.assertNotIn("when", job)  # Run after successful builds, without an extra manual step.

    def test_validation_policy_defaults_to_advisory_and_can_be_required(self):
        self.assertEqual(self.ci["variables"]["SHELL_VALIDATION_REQUIRED"], "0")
        self.assertEqual(self.resolve(".validate_shell")["rules"], [
            {"if": '$SHELL_VALIDATION_REQUIRED == "1"', "allow_failure": False},
            {"when": "on_success", "allow_failure": True},
        ])

    def run_ci_script(self, script, root, **variables):
        env = os.environ.copy()
        env.update(PATH=str(root / "bin") + os.pathsep + env["PATH"],
                   EXAMPLES_DIR="examples", SN_HW_APP_DIR="esnet_shell", SN_HW_BOARD="au55c",
                   CI_JOB_ID="1234", CI_JOB_STATUS="success", SN_HW_BUILD_JOB_NUMBER="1234",
                   VALIDATION_EXIT="0")
        env.update(variables)
        script = script.replace("esnet-fpga-library/scripts/", str(REPO / "esnet-fpga-library/scripts") + "/")
        return subprocess.run(["bash", "-eu", "-c", script], cwd=root, env=env,
                              capture_output=True, text=True)

    def prepare_collection(self, root):
        (root / "bin").mkdir()
        fake = root / "bin/make"
        fake.write_text("""#!/bin/sh
echo called >> calls
report_dir=examples/esnet_shell/build/au55c/validation
mkdir -p "$report_dir"
printf '%s\\n' '{"name":"fixture","passed":true,"findings":[],"unused_waivers":[],"checked":{"integrity":true,"timing":true,"routing":true,"constraints":true,"critical_warnings":true,"cdc":true,"drc":true,"methodology":true}}' > "$report_dir/summary.json"
printf '<testsuites/>\\n' > "$report_dir/junit.xml"
exit "$VALIDATION_EXIT"
""")
        fake.chmod(0o755)
        return root / "examples/esnet_shell/build/au55c/validation"

    def test_collection_preserves_build_success_but_gate_checks_validation_exit(self):
        collect = self.resolve(".shell_image")["after_script"][0]
        gate = self.resolve(".validate_shell")["script"][0]
        for status in (0, 1, 2, 127):
            with self.subTest(status=status), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                reports = self.prepare_collection(root)
                result = self.run_ci_script(collect, root, VALIDATION_EXIT=str(status))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((reports / "ci-1234.exitcode").read_text(), f"{status}\n")
                self.assertIn("Build: success", result.stdout)
                result = self.run_ci_script(gate, root)
                self.assertEqual(result.returncode, 0 if status == 0 else 1, result.stderr)

    def test_final_summary_includes_routed_timing_or_explicitly_unavailable(self):
        collect = self.resolve(".shell_image")["after_script"][0]
        header = "WNS(ns) TNS(ns) TNS Failing Endpoints TNS Total Endpoints WHS(ns) THS(ns) THS Failing Endpoints THS Total Endpoints WPWS(ns) TPWS(ns) TPWS Failing Endpoints TPWS Total Endpoints"
        for values in ("0.125 0.000 0 1000 0.025 0.000 0 1000 0.100 0.000 0 500",
                       "-0.125 -2.000 16 1000 -0.025 -0.050 2 1000 0.100 0.000 0 500",
                       "incomplete", None):
            with self.subTest(values=values), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                reports = self.prepare_collection(root)
                reports.mkdir(parents=True)
                if values is not None:
                    (reports / "timing.rpt").write_text(f"{header}\n------\n{values}\n")
                result = self.run_ci_script(collect, root)
                self.assertEqual(result.returncode, 0, result.stderr)
                summary = result.stdout.split("Build summary", 1)[1]
                if values is None or values == "incomplete":
                    self.assertIn("Final routed timing: unavailable", summary)
                else:
                    verdict = "FAIL" if values.startswith("-") else "PASS"
                    self.assertIn(f"Final routed timing: {verdict}", summary)
                    self.assertIn(header, summary)
                    self.assertIn(values, summary)
                    self.assertNotIn("unavailable", summary)

    def test_gate_rejects_missing_stale_or_malformed_results(self):
        collect = self.resolve(".shell_image")["after_script"][0]
        gate = self.resolve(".validate_shell")["script"][0]
        for damage in ("missing_status", "stale_status", "malformed_status", "missing_summary", "missing_junit", "missing_job_id"):
            with self.subTest(damage=damage), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                reports = self.prepare_collection(root)
                self.assertEqual(self.run_ci_script(collect, root).returncode, 0)
                status = reports / "ci-1234.exitcode"
                variables = {}
                if damage == "missing_status":
                    status.unlink()
                elif damage == "stale_status":
                    status.rename(reports / "ci-1233.exitcode")
                elif damage == "malformed_status":
                    status.write_text("unknown\n")
                elif damage == "missing_summary":
                    (reports / "summary.json").unlink()
                elif damage == "missing_junit":
                    (reports / "junit.xml").unlink()
                else:
                    variables["SN_HW_BUILD_JOB_NUMBER"] = ""
                self.assertNotEqual(self.run_ci_script(gate, root, **variables).returncode, 0)

    def test_failed_and_canceled_images_skip_report_collection(self):
        collect = self.resolve(".shell_image")["after_script"][0]
        for status in ("failed", "canceled"):
            with self.subTest(status=status), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                reports = self.prepare_collection(root)
                result = self.run_ci_script(collect, root, CI_JOB_STATUS=status)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse((root / "calls").exists())
                self.assertFalse(reports.exists())
                self.assertIn(f"Build: {status}", result.stdout)
                self.assertIn("Final routed timing: unavailable (build did not succeed)", result.stdout)
                self.assertNotIn("Validation reports:", result.stdout)

    def test_packaging_and_downstream_jobs_are_not_gated_by_validation(self):
        for name, value in self.ci.items():
            if not isinstance(value, dict) or name == "variables":
                continue
            job = self.resolve(name)
            if job.get("stage") in ("package", "trigger_downstream"):
                for need in job.get("needs", []):
                    self.assertFalse((need if isinstance(need, str) else need["job"]).startswith("validate_"), name)
        self.assertEqual(self.ci["validate_p4_only_u280"]["extends"], ".validate")

    def test_automatic_native_builds_require_successful_prerequisites(self):
        for name in ("shell_ip_av80", "build_shell_av80", "build_p4_only_av80"):
            with self.subTest(job=name):
                job = self.resolve(name)
                self.assertEqual(job.get("when", "on_success"), "on_success")
                self.assertIs(job.get("allow_failure", False), False)
                self.assertNotIn("rules", job)
        for name in ("build_shell_av80", "build_p4_only_av80"):
            self.assertIn({"job": "shell_ip_av80", "artifacts": True}, self.resolve(name)["needs"])

    def test_manual_native_builds_remain_optional(self):
        for name in ("build_esnet_shell_au55c", "build_esnet_shell_au280",
                     "build_esnet_shell_au250", "build_esnet_shell_av80"):
            job = self.resolve(name)
            self.assertEqual(job["when"], "manual")
            self.assertTrue(job.get("allow_failure", True))
        rule = self.resolve("build_udplb_fec_av80")["rules"][0]
        self.assertEqual(rule["when"], "manual")
        self.assertTrue(rule["allow_failure"])

    def test_ip_job_transcripts_preserve_failure_from_nested_make(self):
        for template in (".shell_ip", ".shell_ip_versal"):
            with self.subTest(template=template), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / "bin").mkdir()
                fake = root / "bin/make"
                fake.write_text("#!/bin/sh\necho \"$*\" >> \"$CALLS\"\ncase \" $* \" in *' synth '*) echo 'CRITICAL WARNING: [TEST-1] Nested failure'; exit 17;; esac\n")
                fake.chmod(0o755)
                script = self.resolve(template)["script"][0].replace("esnet-fpga-library/scripts/run_logged.py", str(REPO / "esnet-fpga-library/scripts/run_logged.py"))
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
                if board.startswith("au"):
                    for n in (0, 1):
                        self.assertIn(f'--waiver-input "cmac_{n}={tmp}/build/out/smartnic/xilinx/cmac/ip/xilinx_cmac_{n}/xilinx_cmac_{n}.dcp"', result.stdout)
                    self.assertIn("cfg/validation/usplus.json", result.stdout)
                else:
                    self.assertNotIn("--waiver-input", result.stdout)
                    self.assertNotIn("cfg/validation/usplus.json", result.stdout)
                self.assertIn(("esnet_shell" if board.startswith("au") else "esnet_smartnic") + ".route_opt.dcp", result.stdout)
                self.assertNotIn("vivado -", result.stdout)
                self.assertNotIn("Configuring", result.stdout)
                self.assertFalse((Path(tmp) / "build").exists())


if __name__ == "__main__":
    unittest.main()
