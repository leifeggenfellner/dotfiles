"""Fail on Hyprland IPC calls that still use pre-Lua syntax (#89).

Hyprland runs a Lua config (D-038): `hyprctl dispatch <x>` evaluates <x> as
Lua, and the `keyword` request is gone. Any line that talks to Hyprland
(hyprctl, Quickshell's Hyprland.dispatch, waybar's socket call) must dispatch
`hl.*` Lua (or a shell variable holding it) and must not use `keyword`.

Usage: python3 _hyprland-lua-syntax.py <source root>
"""

import pathlib
import re
import sys

IPC = re.compile(r"hyprctl|Hyprland\.dispatch|getSocket1Reply")
KEYWORD = re.compile(r"hyprctl\b[^|;&#]*\s(keyword|--batch)\b|\"keyword\"")
# Token after `dispatch`, skipping quotes/commas/parens and an f-string prefix.
DISPATCH = re.compile(r"dispatch\b[\s\"',(]*(?:f(?=['\"]))?['\"]*([^\s\"',()]+)")
SUFFIXES = {".nix", ".qml", ".py", ".sh", ".yuck", ".lua", ".js"}
# This file (the Nix check runs a hash-prefixed store copy, so not __file__).
SELF = "_hyprland-lua-syntax.py"


def offences(root):
    for path in sorted(root.rglob("*")):
        if path.suffix not in SUFFIXES or not path.is_file() or path.name == SELF:
            continue
        for number, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
            if not IPC.search(line):
                continue
            match = DISPATCH.search(line)
            old_dispatch = match is not None and not match.group(1).startswith(("hl.", "$"))
            if KEYWORD.search(line) or old_dispatch:
                yield f"{path.relative_to(root)}:{number}: {line.strip()}"


def main():
    root = pathlib.Path(sys.argv[1])
    bad = list(offences(root))
    if bad:
        print("pre-Lua Hyprland IPC syntax (see #89):", *bad, sep="\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
