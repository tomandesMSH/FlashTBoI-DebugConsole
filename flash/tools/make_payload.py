"""Build the patcher payload (flash/patcher/debug_console_payload.json) from this repository.

The payload holds only the Debug Console's own content, never game code:
  - doaction: a complete DoAction tag with the compiled code (as2/dcon_host.as + generated dcon_data.as + as2/dcon_console.as)
  - bitmaps:  the font/icon atlas as a DefineBitsLossless2 body without its character id
  - launcher: "Debug Console.exe", compiled from flash/launcher/DebugConsoleLauncher.cs
The patcher inserts both into frame 1 of the user's own game SWF (see patcher/debug_console_patcher.py).

Same method as EID Flash: our AS2 is compiled on its own. A minimal one-frame SWF with an empty DoAction is
generated, FFDec replaces that script with ours, and the resulting DoAction tag is taken out again.
Needs Pillow and FFDec (see build.py).

Usage: python make_payload.py [--work DIR] [--out FILE]
"""
import argparse
import base64
import json
import os
import re
import struct
import subprocess
import sys
import zlib

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
FLASH = os.path.normpath(os.path.join(HERE, ".."))
sys.dont_write_bytecode = True  # keep __pycache__ out of flash/patcher (it is distributed as-is)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(FLASH, "patcher"))
import dcon_assets  # noqa: E402
import debug_console_patcher as patcher  # noqa: E402

# SHA-256 of the decrypted game SWF this release was tested with (Steam, Wrath of the Lamb / Eternal Edition v1.666)
TESTED_GAME_SHA256 = ["ef03b6ce5ae72a8b8ed3859f29ce4efa24e3abf21357ad658b7de3a66b6dc725"]


def default_work():
    return os.environ.get("DEBUG_CONSOLE_WORK") or os.environ.get("EID_FLASH_WORK") or os.path.expanduser("~/flash-isaac-decomp")


def minimal_swf():
    """SWF 8, 800x600, one frame: FileAttributes, SetBackgroundColor, empty DoAction, ShowFrame, End."""
    nbits = 15
    bits = f"{nbits:05b}" + "".join(f"{v:0{nbits}b}" for v in (0, 16000, 0, 12000))
    bits += "0" * (-len(bits) % 8)
    rect = int(bits, 2).to_bytes(len(bits) // 8, "big")
    tags = (patcher.tag_header(69, 4) + struct.pack("<I", 0)
            + patcher.tag_header(9, 3) + b"\0\0\0"
            + patcher.tag_header(12, 1) + b"\0"
            + patcher.tag_header(1, 0)
            + patcher.tag_header(0, 0))
    body = rect + struct.pack("<HH", 30 << 8, 1) + tags
    return b"FWS" + bytes([8]) + struct.pack("<I", 8 + len(body)) + body


def compile_as2(script_path, work, tmp_dir):
    import build
    src, out = os.path.join(tmp_dir, "empty.swf"), os.path.join(tmp_dir, "compiled.swf")
    open(src, "wb").write(minimal_swf())
    if os.path.exists(out):
        os.remove(out)
    r = subprocess.run(build.find_tools(work) + ["-replace", src, out, "\\frame_1\\DoAction", script_path],
                       capture_output=True, text=True)
    log = r.stdout + r.stderr
    if r.returncode != 0 or not os.path.exists(out) or re.search(r"\berror\b", log, re.I):
        sys.exit("AS2 compile failed:\n" + log[-3000:])
    d = patcher.decompress(open(out, "rb").read())
    for code, start, body, length in patcher.walk_tags(d, patcher.first_tag_offset(d), len(d)):
        if code == 12:
            return d[start:body + length]
    sys.exit("compiled SWF has no DoAction")


def lossless2_body(png):
    """DefineBitsLossless2 body without the leading character id: format 5 (32-bit), premultiplied ARGB."""
    img = Image.open(png).convert("RGBA")
    raw = bytearray()
    for r, g, b, a in img.getdata():
        raw += bytes((a, r * a // 255, g * a // 255, b * a // 255))
    return struct.pack("<BHH", 5, img.width, img.height) + zlib.compress(bytes(raw), 9)


def version():
    return open(os.path.join(FLASH, "VERSION"), encoding="utf-8").read().strip()


def compile_launcher(tmp):
    """Compile flash/launcher/DebugConsoleLauncher.cs ("Debug Console.exe") with the .NET Framework compiler in Windows."""
    windir = os.environ.get("WINDIR", r"C:\Windows")
    csc = next((p for p in (os.path.join(windir, "Microsoft.NET", fw, "v4.0.30319", "csc.exe")
                            for fw in ("Framework64", "Framework")) if os.path.exists(p)), None)
    if not csc:
        sys.exit("csc.exe (.NET Framework 4) not found; it is needed to build the launcher")
    out = os.path.join(tmp, "Debug Console.exe")
    r = subprocess.run([csc, "-nologo", "-target:winexe", "-optimize", "-out:" + out,
                        os.path.join(FLASH, "launcher", "DebugConsoleLauncher.cs")], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("launcher compile failed:\n" + r.stdout + r.stderr)
    return open(out, "rb").read()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", default=default_work())
    ap.add_argument("--out", default=os.path.join(FLASH, "patcher", "debug_console_payload.json"))
    a = ap.parse_args()
    make(a.work, a.out)


def make(work, out):
    tmp = os.path.join(work, "build", "debug_console", "payload")
    os.makedirs(tmp, exist_ok=True)
    dcon_assets.build(tmp)
    parts = [open(os.path.join(FLASH, "as2", "dcon_host.as"), encoding="utf-8").read(),
             open(os.path.join(tmp, "dcon_data.as"), encoding="utf-8").read(),
             open(os.path.join(FLASH, "as2", "dcon_console.as"), encoding="utf-8").read()]
    script = os.path.join(tmp, "dcon_script.as")
    with open(script, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(parts))
    payload = {
        "version": version(),
        "game_sha256": TESTED_GAME_SHA256,
        "doaction": base64.b64encode(compile_as2(script, work, tmp)).decode(),
        "bitmaps": [{"name": "dcon_atlas", "lossless2": base64.b64encode(lossless2_body(os.path.join(tmp, "dcon_atlas.png"))).decode()}],
        # "Debug Console.exe": starts the projector with the modded game; usable as a Steam launch option
        "launcher": base64.b64encode(compile_launcher(tmp)).decode(),
    }
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        json.dump(payload, f, indent=1)
        f.write("\n")
    print(f"payload {out}: {os.path.getsize(out)} bytes")
    return out


if __name__ == "__main__":
    main()
