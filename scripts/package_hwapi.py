"""Archive an installed HW API tree for the firmware repository's Meson importer."""

import argparse
import os
from pathlib import Path
import tempfile
import zipfile


def package(hwapi_dir, output, board, tests=None):
    hwapi_dir = hwapi_dir.resolve()
    output = output.resolve()
    if output.is_relative_to(hwapi_dir):
        raise ValueError("Archive output must be outside the HW API tree")
    for name in (
        "firmware/esnet-smartnic.bin.zst",
        "firmware/esnet-smartnic.ltx",
        "regmap/esnet-smartnic-top-ir.yaml",
    ):
        if not (hwapi_dir / name).is_file():
            raise ValueError(f"Missing HW API input: {hwapi_dir / name}")
    if not any((hwapi_dir / f"firmware/esnet-smartnic.{ext}.zst").is_file()
               for ext in ("bit", "pdi")):
        raise ValueError("Missing BIT or PDI programming artifact")
    for name in ("regmap/spec", "wireshark", "libvitisnetp4drv"):
        if not (hwapi_dir / name).is_dir():
            raise ValueError(f"Missing firmware importer directory: {name}")
    if tests is not None and not tests.is_file():
        raise ValueError(f"Missing hardware test archive: {tests}")

    archive_root = Path("esnet-smartnic-hwapi") / board
    output.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=output.parent, suffix=".zip")
    os.close(fd)
    try:
        with zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED) as archive:
            if tests is not None:
                archive.write(tests, "robot-framework-test.tar.bz2")
            archive.write(hwapi_dir, str(archive_root) + "/")
            for path in sorted(hwapi_dir.rglob("*")):
                archive.write(path, str(archive_root / path.relative_to(hwapi_dir)))
        os.replace(temporary, output)
    finally:
        Path(temporary).unlink(missing_ok=True)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hwapi-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--board", required=True, choices=("au55c", "au280", "au250", "av80", "av90", "av96"))
    parser.add_argument("--tests", type=Path, help="Hardware test tarball for the firmware importer")
    args = parser.parse_args()
    try:
        print(package(args.hwapi_dir, args.output, args.board, args.tests))
    except (ValueError, OSError) as error:
        parser.exit(1, f"HW API packaging failed: {error}\n")


if __name__ == "__main__":
    main()
