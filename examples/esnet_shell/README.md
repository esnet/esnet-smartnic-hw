# ESnet shell example

This example builds the ESnet shell with a replaceable application core.
`BOARD` selects the UltraScale+ or Versal build flow through
`scripts/Makefiles/shell_build.mk`.

| Board | Platform | Default programming output |
|---|---|---|
| `av80` (default) | Versal | PDI |
| `au55c` | UltraScale+ | Bitstream and binary |
| `au250` | UltraScale+ | Bitstream and binary |
| `au280` | UltraScale+ | Bitstream and binary |

Run from this directory, with the Vivado environment configured:

```sh
make BOARD=av80
make BOARD=au55c
```

Both builds use `core.stub.build` by default. Select another core with
`CORE_BUILD_REF`, for example `CORE_BUILD_REF=smartnic.core.build`.
Each core must expose the `shell_intf.core` boundary.

## Targets and outputs

```sh
make config BOARD=au55c
make info BOARD=au55c
make reg_package BOARD=au55c
make build BOARD=au55c
make image BOARD=au55c
make hwapi BOARD=au55c
make package BOARD=au55c
```

`config` creates the local project configuration. `info` shows the selected
shell, core, checkpoints, and outputs. `reg_package` generates the register
map for the selected platform and core. `hwapi` packages that map and the
programming artifacts after a successful build.

`package` runs `hwapi` and writes
`artifacts/artifacts.<board>.shell.0.zip`. The archive contains the
`esnet-smartnic-hwapi/<board>/` tree expected by the firmware repository, including
the compressed programming files, debug probes, register map, and optional
directories required by its importer. It uses the existing build outputs
without rerunning implementation.

Set `SHELL_PACKAGE_VERSION` to override the archive version (the default is
`BUILD_ID`, or `0` when unset), and `SHELL_PACKAGE_DIR` to select another
output directory. For example:

```sh
make package BOARD=au280 SHELL_PACKAGE_VERSION=123
make package BOARD=av80
```

Copy the ZIP into the firmware repository's `sn-hw/` directory and set
`SN_HW_BOARD`, `SN_HW_APP_NAME=shell`, and `SN_HW_VER` to match its name.
CI package jobs use `hwapi` directly and GitLab archives the same tree.

Outputs are isolated under `build/<board>/`. Final assembly artifacts are in
`build/<board>/out/esnet_smartnic/build/`:

- UltraScale+: `esnet_shell.bit`, `esnet_shell.bin`, and `esnet_shell.ltx`.
- Versal: `esnet_smartnic_app.pdi`, `esnet_smartnic_nofpt.pdi`, and
  `esnet_smartnic.ltx`, together with the hardware PDI and XSA.

The public targets are the same for every board. `build` implements the
design through routing and post-route optimization. `image` also exports
the platform's programming files: BIT/BIN/LTX on UltraScale+, or the
hardware and firmware PDIs, XSA, and LTX on Versal. Plain `make` defaults to
`image`; board selection and the native export steps happen internally.

`build_clean` removes assembly output, `clean` removes the selected board's
build directory, and `clean_all` removes all board builds. `restore` restores
the backup saved by the configuration flow when the build settings change.

CI jobs named `build_esnet_shell_<board>` and `hwapi_esnet_shell_<board>`
build and package this native example from `examples/esnet_shell`, using
`shell` as the firmware-facing application name. The V80 build runs
automatically; the UltraScale+ builds are manual. The existing
`build_shell_au55c` and `build_shell_au280` jobs continue to build the OpenNIC
`examples/shell` design. The single `hwapi_shell` bundle gathers those ONS
packages and `hwapi_esnet_shell_av80` for the bootstrap handoff. Native
UltraScale+ packages remain available individually.

The manual `shell_ip_<board>` jobs generate the UltraScale+ shell's IP into
this example's build output tree and cache it by board, tool version, and
library dependencies. Run the matching manual IP job before starting a
native UltraScale+ image build. Each image job requires that board's IP job
and downloads its output artifacts; it also reads the cache. The build
refreshes the IP configuration so changed configurations are regenerated
while unchanged output products are reused.

The automatic `shell_ip_av80` job uses the Versal tool environment to prepare
AVED's patched block design and the DCMAC, GTM, clocking, and debug IP.
All Versal image jobs require its output artifacts and read its cache.
Other examples link their Xilinx output tree to those prepared artifacts,
preserving the paths in generated Vivado projects.
Cache keys also include the producing job's Vivado version. AVED's block
design is explicitly refreshed before synthesis: its JTAG USERCODE contains
the pipeline build ID, so a new ID can require BD synthesis even when the
other IP remains reusable. Image jobs use the same pipeline build ID.

`make validate BOARD=<board>` checks the existing final routed checkpoint,
constraint coverage, critical warnings, and CDC findings, and writes reports,
JSON, and JUnit results under `build/<board>/validation/`. Native CI validation
reports are collected in the image jobs and checked by lightweight validation
jobs. These are advisory unless `SHELL_VALIDATION_REQUIRED=1`. See
[validation and waivers](../../cfg/validation/README.md) for logging
requirements, pass criteria, and waiver configuration.
