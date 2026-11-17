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
make BOARD=au55c
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

Explicit `bitstream` (UltraScale+) and `pdi` (Versal) targets select the same
programming outputs as the default target. `build` runs the platform hardware
assembly; on Versal, use `pdi` to also generate the firmware PDI variants.

`build_clean` removes assembly output, `clean` removes the selected board's
build directory, and `clean_all` removes all board builds. `restore` restores
the backup saved by the configuration flow when the build settings change.
