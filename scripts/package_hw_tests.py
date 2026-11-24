"""Package hardware test libraries and suites for the firmware importer."""

import argparse
import os
from pathlib import Path
import tarfile
import tempfile


def package(test_root, output, app):
    sources = [test_root / "library", test_root / "suites/smartnic"]
    for source in sources:
        if not source.is_dir():
            raise ValueError(f"Missing hardware test input: {source}")
    if not app or Path(app).name != app or app in (".", ".."):
        raise ValueError(f"Invalid application suite name: {app}")
    suite = test_root / "suites" / app
    if suite.is_dir() and suite not in sources:
        sources.append(suite)

    def exclude_generated(info):
        path = Path(info.name)
        return None if "__pycache__" in path.parts or path.suffix in (".pyc", ".pyo") else info

    output.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=output.parent, suffix=".tar.bz2")
    os.close(fd)
    try:
        with tarfile.open(temporary, "w:bz2") as archive:
            for source in sources:
                archive.add(source, arcname=str(source.relative_to(test_root)), filter=exclude_generated)
        os.replace(temporary, output)
    finally:
        Path(temporary).unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--test-root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--app", required=True)
    args = parser.parse_args()
    try:
        package(args.test_root, args.output, args.app)
    except (ValueError, OSError, tarfile.TarError) as error:
        parser.exit(1, f"Hardware test packaging failed: {error}\n")


if __name__ == "__main__":
    main()
