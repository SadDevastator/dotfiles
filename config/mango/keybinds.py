#!/usr/bin/env python3
"""Print mango's keybinds: plain lines by default, or `--json` for the noctalia
keybinds panel plugin (~/noctalia-plugins/keybinds).

Source of truth is ~/.config/mango/config.toml: a comment right after a blank
line or table header starts a section (text before " (" or ":" is the title),
and a bind's trailing `# label` is its row label. Text parse, not tomllib,
because the labels live in comments.
"""
import json
import pathlib
import re
import sys

CONFIG = pathlib.Path.home() / ".config/mango/config.toml"
BIND_TABLE = re.compile(r"^\[(bind|mousebind|axisbind|gesturebind)\.")
BIND = re.compile(r'^"([^"]+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*(?:#\s*(.*))?$')
PRETTY = {
    "F23": "Copilot", "Prior": "PgUp", "Next": "PgDn", "space": "Space", "minus": "-",
    "equal": "=", "backslash": "\\", "Escape": "Esc", "Delete": "Del", "Print": "PrtSc",
    "btn_left": "Left click", "btn_right": "Right click", "UP": "Scroll up", "DOWN": "Scroll down",
    "XF86AudioRaiseVolume": "Vol+", "XF86AudioLowerVolume": "Vol-", "XF86AudioMute": "Mute",
    "XF86AudioMicMute": "Mic mute", "XF86AudioPlay": "Play", "XF86AudioNext": "Next",
    "XF86AudioPrev": "Prev", "XF86MonBrightnessUp": "Bright+", "XF86MonBrightnessDown": "Bright-",
}


def pretty(key: str) -> str:
    parts = key.split("+")
    if parts[0].lower() == "none" and len(parts) == 3:  # gesture: none+left+4
        return f"{parts[2]}-finger swipe {parts[1]}"
    out = [PRETTY.get(p, p.upper() if len(p) == 1 else p) for p in parts]
    return " + ".join(out)


def parse(text: str) -> list:
    sections, current, in_binds, prev_blank = [], None, False, True
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("["):
            in_binds = bool(BIND_TABLE.match(line)) and not line.startswith("[[")
            prev_blank = True  # a comment right under a table header is a title
            continue
        if not in_binds:
            continue
        if not line:
            prev_blank = True
            continue
        if line.startswith("#"):
            if prev_blank:
                title = re.split(r" \(|:", line.lstrip("# "), maxsplit=1)[0].strip()
                current = {"title": title, "rows": []}
                sections.append(current)
            prev_blank = False
            continue
        prev_blank = False
        m = BIND.match(line)
        if not m or not m.group(3):
            continue  # unlabelled binds stay off the sheet
        if current is None:
            current = {"title": "Other", "rows": []}
            sections.append(current)
        key, label = m.group(1), m.group(3).strip()
        rows = current["rows"]
        # Fold digit runs (SUPER+1..9 with the same label) into one "SUPER + 1-9" row
        d = re.fullmatch(r"(.*\+)(\d)", key)
        last = rows[-1] if rows else None
        if d and last and last["label"] == label and last.get("_base") == d.group(1):
            last["_hi"] = d.group(2)
            last["keys"] = [pretty(d.group(1) + "X").replace("X", f"{last['_lo']}-{last['_hi']}")]
            continue
        # Same label elsewhere in the section (SUPER+minus / SUPER+ALT+Left): one row, alt keys in note
        twin = next((r for r in rows if r["label"] == label and "_base" not in r), None)
        if twin and not d:
            twin["note"] = (twin["note"] + ", " if twin["note"] else "also ") + pretty(key)
            continue
        row = {"label": label, "note": None, "keys": [pretty(key)]}
        if d:
            row.update(_base=d.group(1), _lo=d.group(2), _hi=d.group(2))
        rows.append(row)
    for s in sections:
        for r in s["rows"]:
            for k in ("_base", "_lo", "_hi"):
                r.pop(k, None)
    return [s for s in sections if s["rows"]]


def selftest() -> None:
    sample = (
        '[bind.default]\n# Tags (x)\n"SUPER+1" = "view,1,0"  # Go to tag\n'
        '"SUPER+2" = "view,2,0"  # Go to tag\n"SUPER+minus" = "a"  # Narrower\n'
        '"SUPER+n" = "b"  # Next layout\n"SUPER+ALT+Left" = "a"  # Narrower\n"SUPER+q" = "killclient,"\n'
        '[gesturebind.default]\n# Touchpad\n"none+up+4" = "enteroverview"  # Overview\n'
        '[[rule.layer_rule]]\n# Not a section\n"x" = "y"  # nope\n'
    )
    got = parse(sample)
    assert [s["title"] for s in got] == ["Tags", "Touchpad"], got
    rows = got[0]["rows"]
    assert rows[0] == {"label": "Go to tag", "note": None, "keys": ["SUPER + 1-2"]}, rows[0]
    assert rows[1]["keys"] == ["SUPER + -"] and rows[1]["note"] == "also SUPER + ALT + Left", rows[1]
    assert len(rows) == 3, rows  # non-adjacent Narrower merged; unlabelled SUPER+q skipped
    assert got[1]["rows"][0]["keys"] == ["4-finger swipe up"]


if __name__ == "__main__":
    if sys.argv[1:] == ["--test"]:
        selftest()
        print("ok")
    elif sys.argv[1:] == ["--json"]:
        print(json.dumps({"sections": parse(CONFIG.read_text())}))
    else:
        for s in parse(CONFIG.read_text()):
            for r in s["rows"]:
                note = f"  ({r['note']})" if r["note"] else ""
                print(f"{r['keys'][0]}  —  {r['label']}{note}   · {s['title']}")
