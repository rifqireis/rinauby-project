import os
import glob
from collections import defaultdict

WORKFLOW_CATEGORIES = {
    "development": {
        "title": "Pengembangan & Kode",
        "icon": "applications-development-symbolic",
        "keywords": ["Development", "IDE", "TextEditor", "Debugger", "Programming", "ComputerScience", "Database"]
    },
    "internet": {
        "title": "Internet & Komunikasi",
        "icon": "applications-internet-symbolic",
        "keywords": ["Network", "WebBrowser", "Email", "InstantMessaging", "Chat", "Feed", "IRCClient", "Telephony"]
    },
    "productivity": {
        "title": "Produktivitas & Dokumen",
        "icon": "x-office-document-symbolic",
        "keywords": ["Office", "WordProcessor", "Spreadsheet", "Presentation", "Publishing", "Finance", "Education", "Documentation", "Viewer"]
    },
    "multimedia": {
        "title": "Multimedia & Grafis",
        "icon": "applications-multimedia-symbolic",
        "keywords": ["AudioVideo", "Audio", "Video", "Player", "Recorder", "Music", "Graphics", "2DGraphics", "RasterGraphics", "Photography", "AudioVideoEditing"]
    },
    "system": {
        "title": "Sistem & Utilitas",
        "icon": "applications-system-symbolic",
        "keywords": ["System", "Utility", "FileManager", "TerminalEmulator", "Archiving", "Core", "Monitor", "Settings", "DesktopSettings", "HardwareSettings", "PackageManager"]
    },
    "gaming": {
        "title": "Game & Hiburan",
        "icon": "applications-games-symbolic",
        "keywords": ["Game", "ActionGame", "AdventureGame", "ArcadeGame", "BoardGame", "BlocksGame", "CardGame", "KidsGame", "LogicGame", "RolePlaying", "Shooter", "Simulation", "SportsGame", "StrategyGame", "Emulator", "X-WayDroid-App"]
    },
    "custom": {
        "title": "Aturan Kustom",
        "icon": "preferences-other-symbolic",
        "keywords": []
    }
}

class AppDetector:
    _cached_apps = None
    _cached_mtimes = {}

    DESKTOP_DIRS = [
        "/usr/share/applications",
        "/usr/local/share/applications",
        os.path.expanduser("~/.local/share/applications"),
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications")
    ]

    @classmethod
    def _get_current_mtimes(cls):
        mtimes = {}
        for d in cls.DESKTOP_DIRS:
            if os.path.exists(d):
                mtimes[d] = os.path.getmtime(d)
        return mtimes

    @classmethod
    def _classify_categories(cls, cats):
        cat_set = set(cats)
        scores = defaultdict(int)
        for wf_key, meta in WORKFLOW_CATEGORIES.items():
            if wf_key == "custom":
                continue
            for kw in meta["keywords"]:
                if kw in cat_set:
                    scores[wf_key] += 1
        if not scores:
            return "system"
        return max(scores.items(), key=lambda x: x[1])[0]

    @classmethod
    def get_all_apps(cls, force_reload=False):
        if not force_reload and cls._cached_apps is not None:
            return cls._cached_apps

        apps = []
        seen_ids = set()

        for directory in cls.DESKTOP_DIRS:
            if not os.path.exists(directory):
                continue
            for filepath in glob.glob(os.path.join(directory, "**/*.desktop"), recursive=True):
                filename = os.path.basename(filepath)
                app_id = filename[:-8] if filename.endswith(".desktop") else filename
                if app_id in seen_ids:
                    continue

                try:
                    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                        name = ""
                        icon = ""
                        exec_cmd = ""
                        wm_class = ""
                        categories = []
                        nodisplay = False
                        is_desktop_entry = False

                        for line in f:
                            line = line.strip()
                            if line == "[Desktop Entry]":
                                is_desktop_entry = True
                                continue
                            elif line.startswith("[") and line.endswith("]"):
                                if is_desktop_entry:
                                    break
                                continue

                            if not is_desktop_entry:
                                continue

                            if line.startswith("Name=") and not name:
                                name = line.split("=", 1)[1].strip()
                            elif line.startswith("Icon=") and not icon:
                                icon = line.split("=", 1)[1].strip()
                            elif line.startswith("Exec=") and not exec_cmd:
                                exec_cmd = line.split("=", 1)[1].strip()
                            elif line.startswith("StartupWMClass=") and not wm_class:
                                wm_class = line.split("=", 1)[1].strip()
                            elif line.startswith("Categories="):
                                cat_str = line.split("=", 1)[1].strip()
                                categories = [c.strip() for c in cat_str.split(";") if c.strip()]
                            elif line == "NoDisplay=true":
                                nodisplay = True

                        if nodisplay or not name:
                            continue

                        bin_part = ""
                        if exec_cmd:
                            first_part = exec_cmd.split()[0].strip('"').strip("'")
                            bin_part = os.path.basename(first_part)

                        candidates = []
                        if wm_class and wm_class not in candidates:
                            candidates.append(wm_class)
                        if "." in app_id and app_id not in candidates:
                            candidates.append(app_id)
                        generic_launchers = {"flatpak", "python", "python3", "bash", "sh", "env", "waydroid", "gtk-launch"}
                        if bin_part and bin_part.lower() not in generic_launchers:
                            if bin_part not in candidates:
                                candidates.append(bin_part)
                        if not candidates:
                            candidates.append(app_id)

                        detected_class = "|".join(candidates)
                        wf_cat = cls._classify_categories(categories)

                        apps.append({
                            "id": app_id,
                            "name": name,
                            "icon": icon if icon else "application-x-executable",
                            "exec": exec_cmd,
                            "detected_class": detected_class,
                            "categories": categories,
                            "workflow_category": wf_cat,
                            "path": filepath
                        })
                        seen_ids.add(app_id)
                except Exception:
                    pass

        apps.sort(key=lambda x: x["name"].lower())
        cls._cached_apps = apps
        return apps

    @classmethod
    def get_apps_by_workflow(cls):
        apps = cls.get_all_apps()
        categorized = defaultdict(list)
        for a in apps:
            categorized[a["workflow_category"]].append(a)
        return categorized

    @classmethod
    def find_app_by_class(cls, class_pattern):
        if not class_pattern:
            return None
        apps = cls.get_all_apps()
        clean = class_pattern.strip("^$").lower()
        parts = [p.strip("()") for p in clean.split("|")]
        for app in apps:
            app_id_lower = app["id"].lower()
            detected_lower = app.get("detected_class", "").lower()
            for part in parts:
                if part and (part in app_id_lower or part in detected_lower):
                    return app
        return None

    @classmethod
    def sync_registry(cls, force_reload=True):
        apps = cls.get_all_apps(force_reload=force_reload)
        cache_dir = os.path.expanduser("~/.cache/illogical-impulse")
        os.makedirs(cache_dir, exist_ok=True)
        cache_file = os.path.join(cache_dir, "app_registry.json")
        try:
            import json
            with open(cache_file, "w", encoding="utf-8") as f:
                json.dump({"apps": apps}, f, indent=2)
        except Exception:
            pass
        return apps
