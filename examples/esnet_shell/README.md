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
`artifacts/artifacts.<board>.esnet_shell.0.zip`. The archive contains the
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
`SN_HW_BOARD`, `SN_HW_APP_NAME=esnet_shell`, and `SN_HW_VER` to match its name.
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
build and package this native example. `hwapi_esnet_shell` gathers all four
boards into one deliverable. The existing `build_shell_au55c` and
`build_shell_au280` jobs continue to build the OpenNIC `examples/shell`
design; their `hwapi_shell` gather and bootstrap trigger retain the upstream
handoff. The V80 shell job uses this native example under the handoff name
`shell`.

The manual `shell_ip_<board>` jobs generate the UltraScale+ shell's IP into
this example's build output tree and cache it by board, tool version, and
library dependencies. Run the matching manual IP job before starting a
native UltraScale+ image build. Each image job requires that board's IP job
and downloads its output artifacts; it also reads the cache. The build
refreshes the IP configuration so changed configurations are regenerated
while unchanged output products are reused.
