#!/usr/bin/env python3
"""Generate VPD build constants for a native shell top level."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess

PREFIX = "// Build identity: "


def generate(output, repo, environ):
    def git(*args):
        return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()

    build_id = int(environ.get("SHELL_VPD_BUILD_ID") or "0", 0)
    if not 0 <= build_id <= 0xFFFFFFFF:
        raise ValueError("SHELL_VPD_BUILD_ID must fit in 32 bits")
    identity = {
        "PRODUCT_ID": environ.get("SHELL_VPD_PRODUCT_ID") or "ESnet SmartNIC",
        "APPLICATION_ID": environ.get("SHELL_VPD_APPLICATION_ID") or "shell",
        "BUILD_ID": build_id,
        "BUILD_GIT_REPO": environ.get("SHELL_VPD_BUILD_GIT_REPO") or repo.name,
        "BUILD_GIT_HASH": environ.get("SHELL_VPD_BUILD_GIT_HASH") or git("rev-parse", "--short=8", "HEAD"),
        "TIMESTAMP_OVERRIDE": environ.get("SHELL_VPD_BUILD_TIMESTAMP") or "",
    }
    old = output.read_text() if output.exists() else ""
    cached = None
    if old.startswith(PREFIX):
        try:
            cached = json.loads(old.splitlines()[0][len(PREFIX):])
        except (ValueError, IndexError):
            pass
    if cached and cached.get("identity") == identity:
        timestamp = cached["timestamp"]
    else:
        timestamp = int(identity["TIMESTAMP_OVERRIDE"]) if identity["TIMESTAMP_OVERRIDE"] else int(datetime.now(timezone.utc).timestamp())
    if not 0 <= timestamp <= 0xFFFFFFFF:
        raise ValueError("build timestamp must fit in 32 bits")
    values = {k: v for k, v in identity.items() if k != "TIMESTAMP_OVERRIDE"}
    values["BUILD_TIMESTAMP"] = timestamp
    values["BUILD_TIMESTAMP_STR"] = datetime.fromtimestamp(timestamp, timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    lines = [PREFIX + json.dumps({"identity": identity, "timestamp": timestamp}, sort_keys=True)]
    for name, value in values.items():
        if isinstance(value, int):
            lines.append(f"localparam logic [31:0] VPD_{name} = 32'h{value:08x};")
        else:
            if any(ord(c) < 32 or ord(c) > 126 for c in value):
                raise ValueError(f"{name} must contain printable ASCII characters")
            lines.append(f"localparam VPD_{name} = {json.dumps(value)};")
    text = "\n".join(lines) + "\n"
    if old != text:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--repo", type=Path, required=True)
    args = parser.parse_args()
    generate(args.output, args.repo, os.environ)


if __name__ == "__main__":
    main()
