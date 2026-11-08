"""Build Install-SuperSpeed.bat from installer-template.ps1 and the mod's init.lua.

Run from anywhere:  python3 cyberpunk-super-speed/tools/build_installer.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "tools" / "installer-template.ps1"
INIT_LUA = ROOT / "bin" / "x64" / "plugins" / "cyber_engine_tweaks" / "mods" / "SuperSpeed" / "init.lua"
OUTPUT = ROOT / "Install-SuperSpeed.bat"

template = TEMPLATE.read_text(encoding="ascii")
lua = INIT_LUA.read_text(encoding="ascii").rstrip("\n")

# The Lua goes inside a PowerShell single-quoted here-string, which ends at a
# line starting with '@ and does no other interpretation.
if any(line.startswith("'@") for line in lua.splitlines()):
    raise SystemExit("init.lua has a line starting with '@, which would end the here-string early")
if template.count("__INIT_LUA__") != 1:
    raise SystemExit("template must contain exactly one __INIT_LUA__ marker")

text = template.replace("__INIT_LUA__", lua)
# cmd.exe needs Windows line endings to run the batch part reliably.
text = text.replace("\r\n", "\n").replace("\n", "\r\n")
OUTPUT.write_bytes(text.encode("ascii"))
print(f"wrote {OUTPUT}")
