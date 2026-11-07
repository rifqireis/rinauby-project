#!/usr/bin/env python3
import os
import sys
import json
import glob

def parse_desktop_file(path):
    try:
        name = ""
        exec_cmd = ""
        icon = ""
        no_display = False
        is_app = False
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            in_entry = False
            for line in f:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_entry = True
                    continue
                elif line.startswith("[") and in_entry:
                    break
                if not in_entry or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                k = k.strip()
                v = v.strip()
                if k == "Type" and v == "Application":
                    is_app = True
                elif k == "Name" and not name:
                    name = v
                elif k == "Exec" and not exec_cmd:
                    exec_cmd = v.split("%")[0].strip()
                elif k == "Icon" and not icon:
                    icon = v
                elif k == "NoDisplay" and v.lower() == "true":
                    no_display = True
        if is_app and not no_display and name and exec_cmd:
            return {"name": name, "exec": exec_cmd, "icon": icon}
    except Exception:
        pass
    return None

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--log":
        # Launch logging handled
        return

    dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/share/applications"
    ]
    seen = set()
    apps = []

    for d in dirs:
        if not os.path.isdir(d):
            continue
        for p in glob.glob(os.path.join(d, "*.desktop")):
            bname = os.path.basename(p)
            if bname in seen:
                continue
            seen.add(bname)
            app = parse_desktop_file(p)
            if app:
                apps.append(app)

    apps.sort(key=lambda a: a["name"].lower())
    print(json.dumps(apps))

if __name__ == "__main__":
    main()

