"""Zip the patcher for release: <work>/build/debug_console/Debug_Console_<version>.zip with debug_console_patcher.py, the payload and README.

Run build.py first so flash/patcher/debug_console_payload.json is current.
Usage: python package.py [--work DIR]
"""
import argparse
import json
import os
import zipfile

FLASH = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
FILES = ["debug_console_patcher.py", "debug_console_payload.json", "README.txt"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", default=os.environ.get("DEBUG_CONSOLE_WORK") or os.environ.get("EID_FLASH_WORK") or os.path.expanduser("~/flash-isaac-decomp"))
    a = ap.parse_args()
    patcher = os.path.join(FLASH, "patcher")
    version = json.load(open(os.path.join(patcher, "debug_console_payload.json"), encoding="utf-8"))["version"]
    if version.endswith("-debug"):
        raise SystemExit("payload is a debug build; run build.py without --debug first")
    out = os.path.join(a.work, "build", "debug_console", f"Debug_Console_{version}.zip")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in FILES:
            z.write(os.path.join(patcher, f), os.path.join("Debug_Console", f))
    print("wrote", out, os.path.getsize(out), "bytes")


if __name__ == "__main__":
    main()
