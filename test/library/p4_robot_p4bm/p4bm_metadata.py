#!/usr/bin/env python3

"""Utility to parse and format P4 metadata files.

The module provides functions to:

* Parse a ``*.meta`` file where each line consists of space‑separated
  ``key=value`` pairs.  Keys containing ``.`` are turned into nested dictionaries,
  and leaf values are converted from hexadecimal strings to decimal integers.
* Format a nested dictionary (or a list of them) back into the original line
  format, converting leaf integers into hexadecimal strings without the ``0x``
  prefix and separating the pairs with spaces.  A trailing semicolon is added
  to each line.

Typical usage::

    from p4bm_metadata import parse_metadata_file, format_dict_line, write_metadata_file

    data = parse_metadata_file('packets_out.meta')
    # ... manipulate ``data`` ...
    write_metadata_file(data, 'new_packets.meta')
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List, Tuple

# --------------------------------------------------------------------------- #
# Parsing utilities
# --------------------------------------------------------------------------- #


def _hex_to_int(value: str) -> Any:
    """
    Convert a hex string to an integer after stripping leading ``0`` padding.

    The function first removes any leading ``0`` characters (but preserves a
    single ``0`` if the entire string consists of zeros). It then attempts to
    interpret the cleaned string as a base‑16 integer. If conversion fails
    (e.g., the string contains non‑hex characters), the original value is
    returned unchanged.

    Parameters
    ----------
    value : str
        Hexadecimal string, possibly with leading ``0`` padding.

    Returns
    -------
    int or str
        Decimal integer if conversion succeeds, otherwise the original string.
    """
    # Remove leading '0' characters; keep at least one character to avoid
    # converting an empty string.
    stripped = value.lstrip('0') or '0'
    try:
        # ``int(..., 16)`` handles arbitrarily large values without truncation.
        return int(stripped, 16)
    except ValueError:
        # If the string is not a valid hexadecimal representation, return it as is.
        return value


def _parse_line(line: str) -> Dict[str, Any]:
    """
    Parse a single line of ``key=value`` pairs, creating nested dictionaries
    for keys that share a common ``.`` prefix. Leaf values are converted from
    hexadecimal strings to decimal integers where possible.

    Parameters
    ----------
    line: str
        A line from the metadata file.

    Returns
    -------
    dict
        Mapping from keys to values, where keys containing ``.`` are
        represented as nested dictionaries and leaf values are integers.
    """
    line = line.strip()
    if line.endswith(';'):
        line = line[:-1]  # remove trailing semicolon

    kv_pairs: Dict[str, Any] = {}
    for token in line.split():
        if '=' not in token:
            continue  # ignore malformed tokens
        full_key, raw_value = token.split('=', 1)

        # Convert the raw hex string to an integer after stripping leading zeros
        value = _hex_to_int(raw_value)

        # Split the key into its hierarchical parts
        parts = full_key.split('.')
        current_level = kv_pairs

        # Walk/create intermediate dictionaries
        for part in parts[:-1]:
            if part not in current_level or not isinstance(current_level[part], dict):
                current_level[part] = {}
            current_level = current_level[part]  # type: ignore

        # Assign the leaf value
        leaf_key = parts[-1]
        current_level[leaf_key] = value

    return kv_pairs


def parse_metadata_file(file_path: str | Path) -> List[Dict[str, Any]]:
    """
    Open and parse a metadata file where each line consists of space‑separated
    ``key=value`` entries.

    Parameters
    ----------
    file_path : str or pathlib.Path
        Path to the ``*.meta`` file.

    Returns
    -------
    list of dict
        A list where each element is a dictionary representing one line of the
        file. Nested dictionaries are used for keys that share a common prefix,
        and leaf values are decimal integers when the original values were hex.
    """
    path = Path(file_path)
    result: List[Dict[str, Any]] = []

    with path.open('r') as f:
        for line in f:
            if not line.strip():
                continue  # skip empty lines
            result.append(_parse_line(line))

    return result


# --------------------------------------------------------------------------- #
# Formatting utilities
# --------------------------------------------------------------------------- #


def _int_to_hex(value: int) -> str:
    """
    Convert an integer to a hexadecimal string without the ``0x`` prefix.
    The result uses lower‑case letters and contains no leading ``0x``.  Zero
    is represented as ``0``.

    Parameters
    ----------
    value : int
        Integer to convert.

    Returns
    -------
    str
        Hexadecimal representation.
    """
    return format(value, 'x')


def _flatten_dict(
    data: Dict[str, Any], parent_key: str = ""
) -> List[Tuple[str, Any]]:
    """
    Flatten a nested dictionary into a list of ``(key, value)`` pairs where
    ``key`` is the dot‑joined path.

    Parameters
    ----------
    data : dict
        Nested dictionary to flatten.
    parent_key : str, optional
        Prefix for the current recursion level (used internally).

    Returns
    -------
    list of (str, Any)
        Flattened ``key`` / ``value`` pairs.
    """
    items: List[Tuple[str, Any]] = []
    for k, v in data.items():
        new_key = f"{parent_key}.{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(_flatten_dict(v, new_key))
        else:
            items.append((new_key, v))
    return items


def format_dict_line(data: Dict[str, Any]) -> str:
    """
    Convert a nested dictionary into a single line that matches the format
    used in ``packets_out.meta``.  All leaf values are turned into hexadecimal
    strings, keys are flattened using ``.`` as a separator, the pairs are
    separated by a single space, and a trailing semicolon is appended.

    Parameters
    ----------
    data : dict
        Nested dictionary to format.

    Returns
    -------
    str
        Formatted line suitable for writing to a ``*.meta`` file.
    """
    flat_items = _flatten_dict(data)

    # Sort by key for deterministic output (optional but handy for tests)
    flat_items.sort(key=lambda item: item[0])

    parts = []
    for key, value in flat_items:
        if isinstance(value, int):
            hex_val = _int_to_hex(value)
        else:
            # If the leaf is not an int we keep its string representation.
            # This mirrors the behaviour of the original parser that left
            # non‑hex strings untouched.
            hex_val = str(value)
        parts.append(f"{key}={hex_val}")

    return " ".join(parts) + " ;"


def write_metadata_file(
    data: List[Dict[str, Any]], file_path: str | Path
) -> None:
    """
    Write a list of nested dictionaries to a metadata file using the
    ``format_dict_line`` representation.

    Parameters
    ----------
    data : list of dict
        Each dictionary corresponds to one line in the output file.
    file_path : str or pathlib.Path
        Destination file path.
    """
    path = Path(file_path)
    with path.open("w") as f:
        for entry in data:
            line = format_dict_line(entry)
            f.write(line + "\n")


# --------------------------------------------------------------------------- #
# Simple command‑line demo
# --------------------------------------------------------------------------- #


if __name__ == "__main__":
    # Demo: read a file, pretty‑print the parsed structure, then write it back.
    import sys
    import json

    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <metadata-file>")
        sys.exit(1)

    input_path = sys.argv[1]
    parsed = parse_metadata_file(input_path)

    print("Parsed representation (JSON pretty‑print):")
    print(json.dumps(parsed, indent=2))

    # Write the parsed data back to a temporary file to demonstrate formatting.
    tmp_out = Path("tmp_formatted.meta")
    write_metadata_file(parsed, tmp_out)
    print(f"\nFormatted output written to {tmp_out}")
