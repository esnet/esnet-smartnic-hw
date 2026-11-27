"""Check the firmware probe names and preserve the physical debug mapping.

Run with: python3 -m unittest discover -s scripts/usplus/tests
"""

import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPTS = Path(__file__).resolve().parents[1]
RUNNER = SCRIPTS.parents[1] / "esnet-fpga-library/scripts/vivado/build_non_proj.tcl"
SPEC = importlib.util.spec_from_file_location(
    "rename_pcie_reset_probes", SCRIPTS / "rename_pcie_reset_probes.py"
)
PROBES = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBES)


def fixture():
    pins = []
    for number, (name, (direction, index, _)) in enumerate(PROBES.PROBES.items()):
        pins.append({
            "name": name, "id": number, "type": "DATA",
            "direction": direction, "portIndex": index,
            "isVector": False, "leftIndex": 0, "rightIndex": 0,
            "nets": [{"name": f"shell/reset/status_sync_{number}",
                      "isBus": True, "subnets": [{"name": f"status[{number}]"}]}],
        })
    core = {
        "name": "shell/" + PROBES.RESET_CORE,
        "type": "VIO_V2", "ipName": "vio", "uuid": "reset-core-uuid",
        "core_location": {"user_chain": 1, "slave_index": 0}, "pins": pins,
    }
    return {"ltx_root": {"version": 4, "minor": 0, "ltx_data": [{
        "name": "", "active": True,
        "debug_cores": [{"name": "ila", "type": "ILA_V3", "pins": []}, core],
    }]}}


def reset_core(data):
    return data["ltx_root"]["ltx_data"][0]["debug_cores"][1]


class ResetProbeNamesTest(unittest.TestCase):
    def test_only_signal_labels_change(self):
        expected_names = {
            "probe_in0": "__pcie_rstn_int",
            "probe_in1": "pcie_rstn_int",
            "probe_in2": "pcie_init_ready",
            "probe_out0": "jtag_rst",
        }
        original = fixture()
        renamed = PROBES.rename_reset_probes(copy.deepcopy(original))
        self.assertEqual(len(reset_core(renamed)["pins"]), len(expected_names))
        for old, new in zip(reset_core(original)["pins"], reset_core(renamed)["pins"]):
            expected = expected_names[new["name"]]
            self.assertEqual(new["nets"], [{"name": expected, "isBus": False}])
            new["nets"] = old["nets"]
        self.assertEqual(renamed, original)

    def test_export_is_idempotent(self):
        renamed = PROBES.rename_reset_probes(fixture())
        self.assertEqual(PROBES.rename_reset_probes(copy.deepcopy(renamed)), renamed)

    def test_rejects_incompatible_layouts(self):
        cases = []
        data = fixture()
        reset_core(data)["name"] = "other_vio"
        cases.append(data)
        data = fixture()
        cores = data["ltx_root"]["ltx_data"][0]["debug_cores"]
        cores.append(copy.deepcopy(reset_core(data)))
        cases.append(data)
        data = fixture()
        data["ltx_root"]["ltx_data"][0]["debug_cores"].append({"type": "VIO_V2", "name": "other_vio"})
        cases.append(data)
        for change in ({"direction": "OUT"}, {"portIndex": 3}, {"rightIndex": 1}, {"nets": []}):
            data = fixture()
            reset_core(data)["pins"][0].update(change)
            cases.append(data)
        data = fixture()
        reset_core(data)["pins"].pop()
        cases.append(data)
        for data in cases:
            with self.subTest(data=data), self.assertRaises(ValueError):
                PROBES.rename_reset_probes(data)

    def test_invalid_input_does_not_replace_output(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, output = root / "raw.ltx", root / "firmware.ltx"
            source.write_text("{}")
            output.write_text("previous valid probes")
            result = subprocess.run(
                ["python3", str(SCRIPTS / "rename_pcie_reset_probes.py"), str(source), str(output)],
                capture_output=True, text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Invalid PCIe reset probes", result.stderr)
            self.assertEqual(output.read_text(), "previous valid probes")

    def test_shared_bitstream_hook_exports_raw_and_firmware_probes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "fixture.ltx"
            source.write_text(json.dumps(fixture()))
            driver = root / "driver.tcl"
            driver.write_text("\n".join([
                f"set argv [list bitstream shell -out_dir {{{root}}} -userid 0 -usr_access 0 "
                f"-hook_tcl {{{SCRIPTS / 'write_bitstream.post.tcl'}}}]",
                "set argc [llength $argv]",
                "proc open_checkpoint {args} {}",
                "proc set_property {args} {}",
                "proc current_design {} {return design}",
                "proc write_bitstream {args} {}",
                "proc write_debug_probes {args} {",
                f"    file copy -force {{{source}}} [lindex $args end]",
                "}",
                f"source {{{RUNNER}}}",
            ]) + "\n")
            subprocess.run(["tclsh", str(driver)], check=True, capture_output=True, text=True)
            self.assertEqual((root / "shell.raw.ltx").read_bytes(), source.read_bytes())
            self.assertEqual(
                json.loads((root / "shell.ltx").read_text()),
                PROBES.rename_reset_probes(fixture()),
            )


if __name__ == "__main__":
    unittest.main()
