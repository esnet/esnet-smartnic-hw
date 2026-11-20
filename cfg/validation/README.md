# Shell build validation

Run `make validate BOARD=<board>` from a native shell/core example using
the Vivado version that produced the build. Validation reads the final
routed checkpoint and writes reports, JSON, and JUnit results to
`build/<board>/validation/`. It never rebuilds the design.

The implementation and Make interface belong to the common FPGA library:
[generic Vivado validation](../../esnet-fpga-library/scripts/vivado/validation/README.md).
That document describes checks, log requirements, waiver syntax, and the
standalone command-line interface.

## Shell configuration

The shell adapter in `shell_proj_config.mk` supplies the checkpoint, input
checkpoints for freshness checks, logs, output directory, and build label.
The default label is `<board>.<example-directory>`, for example
`au55c.esnet_shell` or `av80.p4_only_av80`. Override `VALIDATION_NAME` for a
separate build configuration.

Image, register-package, and driver targets retain command transcripts in
`build/<board>/validation-inputs/`. The IP-preparation job retains
its transcript at
`examples/esnet_shell/build/<board>/out/validation-inputs/ip.log`, alongside
cached output products. The adapter supplies these required transcripts
and both the example's and the shared IP output trees to validation.
Missing transcripts from older builds cause an integrity failure; those
builds cannot establish warning completeness without rerunning the logged
preparation/build steps.

Native image jobs run validation in `after_script`, using the same tool
environment as the build. Validation findings do not fail an otherwise
successful image job. The build artifacts include the reports and a
completion status tied to the producing job ID. The validator prints its
per-category summary during collection. The library's `build_summary.py`
then prints the build status and final routed timing table, including setup,
hold, and pulse-width slack and endpoint counts. Missing or incomplete timing
reports are shown as unavailable. Failed image jobs skip validation and
report timing as unavailable. The job reserves up to one hour for validation
after the existing ten-hour build allowance, plus fifteen minutes for
artifact upload; runner timeout limits must accommodate this allowance.

The seven validation jobs run on `ht-misc`. They use the validator's
`--summary-only` mode to print the saved validation summary and return its
status without invoking Vivado. A required collection status file ties the
results to the producing build job. Missing, incomplete, or failed results
fail the validation job. Reports and JUnit results are published even when
the gate fails.

By default, these jobs are advisory (`allow_failure: true`). Set the pipeline
variable `SHELL_VALIDATION_REQUIRED=1` to make failed validation fail the
pipeline. HWAPI packaging and firmware/card-testing triggers retain their
direct build dependencies, so they can use an image even if validation
fails. A release or promotion job that requires validated artifacts must
explicitly `need` its corresponding validation job and use the required
policy. Existing ONS validation remains separate.

## Design and per-build waivers

Design and per-build waiver data stays in the design repository. Component
waivers live with their owning modules. The common JSON waiver set is empty.

The adapter supplies two search directories:

- This directory: `cfg/validation/`.
- The example's local `validation/` directory.

The library searches each directory for JSON and XDC files named after
these scopes, in order:

1. `common`
2. Architecture: `usplus` or `versal`
3. Board: for example `au55c`
4. Full build name: for example `au55c.esnet_shell`

For example, `examples/p4_only_av80/validation/av80.p4_only_av80.xdc` holds
native CDC/DRC/methodology waivers specific to that build. A corresponding
JSON file can hold narrowly scoped message or constraint exceptions.
Explicit `VALIDATION_WAIVERS` and `VALIDATION_WAIVER_TCL` lists override
automatic selection. Optional JSON `builds` lists use `VALIDATION_NAME`,
not board-specific fields.

Module- or IP-owned waiver files can be registered with
`VALIDATION_WAIVER_REFS` as `REF=PATH` mappings. The library applies each
file relative to every matching instance using `read_xdc -ref`.

UltraScale+ builds select `usplus.json` for the guarded CMAC AN/LT license
exception. Its configuration checks and rationale are documented in the
[UltraScale+ README](../../src/xilinx/alveo/usplus/README.md#cmac-license-validation).
The shell adapter supplies the generated CMAC checkpoints through
`VALIDATION_WAIVER_INPUTS`; a missing or changed configuration fails validation.

Native UltraScale+ and Versal builds register the library's `fifo_core`,
`sync_ctr`, and `sync_bus` waivers. Their scopes and protocol requirements
are documented in the [FIFO README](../../esnet-fpga-library/src/fifo/README.md#xilinx-fifo-payload-cdc-waiver)
and [synchronizer README](../../esnet-fpga-library/src/sync/README.md).

Review findings before adding exceptions. Do not lower timing thresholds,
suppress entire message severities, or waive CDC checks globally.

## Tests

```sh
python3 -B -m unittest discover -s scripts/Makefiles/tests
python3 -B -m unittest discover -s esnet-fpga-library/scripts/tests
```
