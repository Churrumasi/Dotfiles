#!/usr/bin/env python3
"""rofi / desktop shortcuts helper for Steam Flatpak

Watches the Flatpak Steam applications folder and exports .desktop files
and icons to the user ~/.local/share directories so your DE/launcher
(Rofi, Gnome Shell, etc.) can see them.

Features added:
- pathlib for robust path handling
- argparse to override paths and behaviour
- logging instead of silent except/pass
- initial scan (sync existing files)
- handles both created and modified events
- safer Exec= rewriting preserving args (e.g. %U)
- copies icons only if present and avoids clobbering unnecessary files
- optional skip existing mode or force overwrite
- updates desktop database and icon cache when possible
- graceful shutdown on SIGINT/SIGTERM
"""

from __future__ import annotations

import argparse
import logging
import re
import shutil
import signal
import subprocess
import sys
from pathlib import Path
from typing import Optional

from watchdog.events import FileSystemEventHandler, FileCreatedEvent, FileModifiedEvent
from watchdog.observers import Observer


logger = logging.getLogger("steam-shortcuts")


def rewrite_exec_line(exec_line: str) -> str:
    """Rewrite the Exec= line so the command uses flatpak run com.valvesoftware.Steam
    while preserving argument tokens such as %U, %u, %F, etc.

    Example:
        Exec=steam %U -> Exec=flatpak run com.valvesoftware.Steam %U
        Exec=/usr/bin/steam -applaunch 12345 -> Exec=flatpak run com.valvesoftware.Steam -applaunch 12345
    """
    prefix = "Exec="
    assert exec_line.startswith(prefix)
    content = exec_line[len(prefix) :].strip()

    # split into command + rest; preserve quoted args as-is
    parts = content.split()
    if not parts:
        return exec_line

    cmd = Path(parts[0]).name.lower()
    rest = parts[1:]

    if "steam" in cmd:
        new_cmd = "flatpak run com.valvesoftware.Steam"
        new = prefix + "{}".format(new_cmd)
        if rest:
            new += " " + " ".join(rest)
        return new + "\n"

    # If it doesn't look like steam, return original
    return exec_line


class DesktopExporter(FileSystemEventHandler):
    def __init__(self, flatpak_apps: Path, local_apps: Path, force: bool = False) -> None:
        self.flatpak_apps = flatpak_apps
        self.local_apps = local_apps
        self.force = force

    def _process_file(self, src: Path) -> None:
        if not src.exists() or src.suffix != ".desktop":
            return

        logger.info("Processing: %s", src)

        try:
            dst = self.local_apps / src.name
            # read and rewrite Exec line
            text = src.read_text(encoding="utf-8", errors="ignore")

            # skip Steam/Proton launcher lines if desired
            if src.name.startswith("Steam") or src.name.startswith("Proton"):
                logger.debug("Skipping launcher-like desktop: %s", src.name)
                return

            lines = text.splitlines(keepends=True)
            out_lines = []
            modified = False
            for line in lines:
                if line.startswith("Exec="):
                    new = rewrite_exec_line(line)
                    if new != line:
                        modified = True
                        logger.debug("Rewrote Exec: %s -> %s", line.strip(), new.strip())
                    out_lines.append(new)
                else:
                    out_lines.append(line)

            final_text = "".join(out_lines)

            if dst.exists() and not self.force:
                logger.info("Destination exists and force is False, skipping: %s", dst)
            else:
                # ensure local directory exists
                self.local_apps.mkdir(parents=True, exist_ok=True)
                dst.write_text(final_text, encoding="utf-8")
                dst.chmod(0o644)
                logger.info("Wrote desktop file: %s", dst)

            # try copying icons if present
            self._copy_icons_if_any(src.parent)

            # update desktop database and icon cache (best-effort)
            self._update_system_cache()

        except Exception as e:
            logger.exception("Failed to process %s: %s", src, e)

    def _copy_icons_if_any(self, src_app_dir: Path) -> None:
        """Look for typical icon/theme locations inside the flatpak app dir and copy them
        into ~/.local/share/icons/ if found.
        """
        # Common places where apps ship icons in Flatpak runtimes
        candidates = [
            src_app_dir.parent / "icons",
            src_app_dir / "icons",
            src_app_dir.parent / "share" / "icons",
            src_app_dir / "share" / "icons",
        ]

        for c in candidates:
            if c.exists() and c.is_dir():
                dest = Path.home() / ".local" / "share" / "icons"
                try:
                    logger.info("Copying icons from %s to %s", c, dest)
                    shutil.copytree(c, dest, dirs_exist_ok=True)
                except Exception:
                    logger.exception("Failed copying icons from %s", c)

    def _update_system_cache(self) -> None:
        # update desktop database
        try:
            subprocess.run(["update-desktop-database", str(self.local_apps)], check=False)
            logger.debug("Ran update-desktop-database")
        except FileNotFoundError:
            logger.debug("update-desktop-database not found on system")

        # update icon cache for hicolor if present (best-effort)
        try:
            icon_dir = Path.home() / ".local" / "share" / "icons" / "hicolor"
            if icon_dir.exists():
                subprocess.run(["gtk-update-icon-cache", "-t", "-f", str(icon_dir)], check=False)
                logger.debug("Ran gtk-update-icon-cache on %s", icon_dir)
        except FileNotFoundError:
            logger.debug("gtk-update-icon-cache not found on system")

    # Watchdog events
    def on_created(self, event: FileCreatedEvent) -> None:
        if event.is_directory:
            return
        self._process_file(Path(event.src_path))

    def on_modified(self, event: FileModifiedEvent) -> None:
        if event.is_directory:
            return
        self._process_file(Path(event.src_path))


def initial_sync(exporter: DesktopExporter) -> None:
    """Scan existing .desktop files in the flatpak dir and export them."""
    if not exporter.flatpak_apps.exists():
        logger.warning("Flatpak applications dir does not exist: %s", exporter.flatpak_apps)
        return

    for p in exporter.flatpak_apps.iterdir():
        if p.is_file() and p.suffix == ".desktop":
            exporter._process_file(p)


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Export Steam Flatpak desktop files for Rofi/DE")
    parser.add_argument("--flatpak", default=str(Path.home() / ".var" / "app" / "com.valvesoftware.Steam" / ".local" / "share" / "applications"),
                        help="Flatpak Steam applications dir to watch")
    parser.add_argument("--local", default=str(Path.home() / ".local" / "share" / "applications"),
                        help="Local applications dir to write to")
    parser.add_argument("--force", action="store_true", help="Overwrite existing .desktop files")
    parser.add_argument("--verbose", "-v", action="count", default=0)
    args = parser.parse_args(argv)

    level = logging.WARNING
    if args.verbose == 1:
        level = logging.INFO
    elif args.verbose >= 2:
        level = logging.DEBUG
    logging.basicConfig(level=level, format="%(asctime)s %(levelname)s: %(message)s")

    flatpak_apps = Path(args.flatpak)
    local_apps = Path(args.local)

    exporter = DesktopExporter(flatpak_apps, local_apps, force=args.force)

    # initial sync
    initial_sync(exporter)

    # start watchdog
    observer = Observer()
    observer.schedule(exporter, path=str(flatpak_apps), recursive=False)
    observer.start()

    # graceful shutdown
    def _stop(signum, frame):
        logger.info("Shutting down (signal %s)", signum)
        observer.stop()

    signal.signal(signal.SIGINT, _stop)
    signal.signal(signal.SIGTERM, _stop)

    try:
        while observer.is_alive():
            observer.join(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
