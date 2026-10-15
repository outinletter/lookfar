#!/usr/bin/env python3
"""Copy actual XCTest screen captures into App Store folders; no fabricated UI."""
import json
import re
import shutil
import subprocess
import struct
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1])
manifest = json.loads((source / "manifest.json").read_text())
found = []
for test in manifest:
    for attachment in test["attachments"]:
        name = attachment["suggestedHumanReadableName"]
        match = re.search(r"(\d{2}-[a-z]+-(ko|en))", name)
        if not match:
            continue
        language = "ko-KR" if match[2] == "ko" else "en-US"
        original = source / attachment["exportedFileName"]
        width, height = struct.unpack(">II", original.read_bytes()[16:24])
        raw_dir = root / "AppStore" / "Screenshots" / "Originals" / language
        raw_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(original, raw_dir / (match[1] + ".png"))
        target_dir = root / "AppStore" / "Screenshots" / language / "6.9-inch"
        target_dir.mkdir(parents=True, exist_ok=True)
        dest = target_dir / (match[1] + ".png")
        shutil.copy2(original, dest)
        if (width, height) != (1320, 2868):
            subprocess.run(["sips", "-z", "2868", "1320", str(dest)], check=True, capture_output=True)
        size = subprocess.check_output(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(dest)], text=True)
        if "1320" not in size or "2868" not in size:
            raise SystemExit("Unexpected screenshot dimensions: " + size)
        found.append(str(dest.relative_to(root)) + f" (original {width}x{height})")
print("\n".join(sorted(set(found))))
if not found:
    raise SystemExit("No named LookFar screenshots found")
