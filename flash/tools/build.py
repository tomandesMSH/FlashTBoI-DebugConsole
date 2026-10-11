"""Developer build of Debug Console: makes the payload and applies it with the same patcher users run.

Usage: python flash/tools/build.py [--work DIR] [--swf FILE]

The work directory (default: $DEBUG_CONSOLE_WORK, $EID_FLASH_WORK or ~/flash-isaac-decomp; the same one EID Flash uses)
holds everything derived from the game, which must never be committed: isaac.swf (dumped with swfdump.py or the
patcher), decompiled scripts and build output. Tools are looked up in <work>/tools (portable JRE + JPEXS FFDec)
unless $JAVA / $FFDEC_JAR are set.

Output: <work>/build/debug_console/isaac_console.swf. Also refreshes flash/patcher/debug_console_payload.json,
which is what gets distributed.
--swf patches another SWF instead of <work>/isaac.swf, e.g. EID Flash's build to test both mods together.
"""
import argparse
import glob
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FLASH = os.path.normpath(os.path.join(HERE, ".."))
sys.dont_write_bytecode = True  # keep __pycache__ out of flash/patcher (it is distributed as-is)
sys.path.insert(0, HERE)


def find_tools(work):
    exe = "java.exe" if os.name == "nt" else "java"
    java = os.environ.get("JAVA") or next(iter(glob.glob(os.path.join(work, "tools", "jre", "*", "bin", exe))), "java")
    jar = os.environ.get("FFDEC_JAR") or os.path.join(work, "tools", "ffdec", "ffdec-cli.jar")
    if not os.path.exists(jar):
        sys.exit(f"FFDec not found at {jar} (set FFDEC_JAR)")
    return [java, "-Xmx4g", "-jar", jar]


def main():
    import make_payload
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", default=make_payload.default_work())
    ap.add_argument("--swf", help="SWF to patch (default: <work>/isaac.swf)")
    a = ap.parse_args()

    swf = a.swf or os.path.join(a.work, "isaac.swf")
    if not os.path.exists(swf):
        sys.exit(f"{swf} missing: dump it from the running game first (flash/tools/swfdump.py)")
    payload = make_payload.make(a.work, os.path.join(FLASH, "patcher", "debug_console_payload.json"))
    name = "isaac_console.swf"
    r = subprocess.run([sys.executable, os.path.join(FLASH, "patcher", "debug_console_patcher.py"), "--swf", swf,
                        "--payload", payload, "--out", os.path.join(a.work, "build", "debug_console"), "--name", name,
                        "--no-projector"])
    sys.exit(r.returncode)


if __name__ == "__main__":
    main()
