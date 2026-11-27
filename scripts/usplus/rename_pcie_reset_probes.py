"""Export scalar PCIe reset probe names consumed by firmware deployment tools."""

import argparse
import json
from pathlib import Path


RESET_CORE = "i_xilinx_jtag_reset_ctrl/i_xilinx_jtag_reset_vio"
PROBES = {
    "probe_in0": ("IN", 0, "__pcie_rstn_int"),
    "probe_in1": ("IN", 1, "pcie_rstn_int"),
    "probe_in2": ("IN", 2, "pcie_init_ready"),
    "probe_out0": ("OUT", 0, "jtag_rst"),
}


def rename_reset_probes(data):
    all_cores = [
        core for entry in data["ltx_root"]["ltx_data"]
        for core in entry["debug_cores"]
    ]
    cores = [
        core for core in all_cores
        if core.get("name", "").endswith(RESET_CORE)
    ]
    if len(cores) != 1:
        raise ValueError(f"Expected one PCIe reset VIO, found {len(cores)}")
    core = cores[0]
    if core.get("type") != "VIO_V2" or core.get("ipName") != "vio":
        raise ValueError("Expected an UltraScale+ VIO reset core")
    if sum(core.get("type") == "VIO_V2" for core in all_cores) != 1:
        raise ValueError("Firmware reset flow requires a single VIO core")
    pins = core["pins"]
    if len(pins) != len(PROBES) or {pin["name"] for pin in pins} != PROBES.keys():
        raise ValueError("Unexpected PCIe reset VIO probe layout")
    for pin in pins:
        direction, index, name = PROBES[pin["name"]]
        if (pin["direction"] != direction or pin["portIndex"] != index
                or pin["leftIndex"] != pin["rightIndex"]
                or len(pin["nets"]) != 1):
            raise ValueError(f"Unexpected scalar probe mapping: {pin['name']}")
        # UUID, core location, and physical port/bit mapping remain unchanged.
        pin["nets"] = [{"name": name, "isBus": False}]
    return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="Vivado-generated LTX file")
    parser.add_argument("output", type=Path, help="Firmware-facing LTX file")
    args = parser.parse_args()
    try:
        data = rename_reset_probes(json.loads(args.input.read_text()))
    except (KeyError, TypeError, ValueError) as error:
        parser.exit(1, f"Invalid PCIe reset probes in {args.input}: {error}\n")
    args.output.write_text(json.dumps(data, indent=2) + "\n")


if __name__ == "__main__":
    main()
