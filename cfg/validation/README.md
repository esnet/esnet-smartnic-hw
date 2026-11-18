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

Seven native CI validation jobs use the matching tool environments and
publish results even on failure. They use `allow_failure: true` and do not
gate packaging or downstream triggers. Existing ONS validation remains
separate.

## Design and per-build waivers

No waivers are enabled by default. Waiver data stays in the design
repository, rather than in the common library.

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

Review findings before adding exceptions. Do not lower timing thresholds,
suppress entire message severities, or waive CDC checks globally.

## Tests

```sh
python3 -B -m unittest discover -s scripts/Makefiles/tests
python3 -B -m unittest discover -s esnet-fpga-library/scripts/tests
```
