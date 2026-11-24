"""Install a released app from its Sparkle zip, without sudo; check the installed copy.

`install` unpacks the zip beside the install, checks the unpacked bundle against
the layout, and only then quits the installed app (only the pids running from the
bundle in the apps directory, so a Debug build from a worktree survives), swaps it
in and opens it.

The old bundle is moved aside, not deleted, until the new one is in place; if the
second move fails the old one goes back. When the installed app belongs to another
user (the first-install .pkg makes it root's) this refuses, leaving the app
running, and prints the one-time `sudo chown` that hands the bundle back, for the
owner to run before installing again; it never runs sudo. (A second pkg install
would not do: its payload is root's too.)

`install_built_app` is the same swap for a bundle straight out of a local build
(an app's `./install`), with no zip, release.json or layout gate. `remove_installed_app` reverses it (an app's `./uninstall`). `swap_in` and
`destination_ok` are the pieces they share.

`installed_failures` proves the copy in the apps directory is this version and
build, signed Developer ID, layout-correct and running.
"""
from __future__ import annotations

import os
import plistlib
import shutil
import subprocess
import time
from pathlib import Path
from typing import Callable

from . import processes, versions
from .config import ReleaseConfig
from .shell import Runner

QUIT_TIMEOUT_S = 10.0
# How long a SIGKILLed pid may linger before the swap goes ahead anyway: a
# running copy keeps its old inode, so the rename is still safe.
REAP_TIMEOUT_S = 5.0


def run_command(argv: list[str]) -> "subprocess.CompletedProcess[str]":
    return subprocess.run(argv, capture_output=True, text=True)


def quit_app(app: Path, *, pids: Callable[[Path], list[int]],
             kill: Callable[[int, int], None], sleep: Callable[[float], None],
             monotonic: Callable[[], float]) -> list[int]:
    """SIGTERM this user's pids inside `app`, wait up to QUIT_TIMEOUT_S, then
    SIGKILL. Returns any that still have not exited."""
    return processes.quit_pids(lambda: pids(app), term_wait=QUIT_TIMEOUT_S,
                               kill_wait=REAP_TIMEOUT_S, kill=kill, sleep=sleep,
                               monotonic=monotonic)


FINDER_REFRESH_TIMEOUT_S = 10


def refresh_finder_icon(dest: Path, *, run: Runner = run_command,
                        say: Callable[[str], None] = print) -> bool:
    """Tell Finder to re-read the bundle that just landed at `dest`.

    Finder keeps its own per-item icon cache, and a bundle that arrives by rename
    can stay the generic app placeholder there for as long as Finder runs:
    `touch` and `lsregister -f` reach LaunchServices, not that cache. Finder's
    own `update` command does. Best-effort: a headless install has no Finder,
    and a terminal without Automation access to it gets a refusal; neither
    should fail an install whose bundle is already in place. True when Finder
    took it.
    """
    script = (f"with timeout of {FINDER_REFRESH_TIMEOUT_S} seconds\n"
              f'tell application "Finder" to update (POSIX file "{dest}" as alias)\n'
              "end timeout")
    try:
        result = run(["osascript", "-e", script])
    except OSError as exc:
        say(f"note: Finder did not refresh the icon ({exc}); it may show a generic "
            "icon until Finder relaunches")
        return False
    if result.returncode != 0:
        say(f"note: Finder did not refresh the icon ({(result.stderr or '').strip()}); "
            "it may show a generic icon until Finder relaunches")
        return False
    return True


def install(zip_path: Path, cfg: ReleaseConfig, *, apps_dir: Path | None = None,
            run: Runner = run_command,
            pids: Callable[[Path], list[int]] = processes.bundle_pids,
            kill: Callable[[int, int], None] = os.kill,
            sleep: Callable[[float], None] = time.sleep,
            monotonic: Callable[[], float] = time.monotonic,
            rename: Callable[[Path, Path], object] = os.rename,
            pid: int | None = None, uid: int | None = None,
            say: Callable[[str], None] = print) -> int:
    """Order: ownership check, extract, layout gate, quit, swap, Finder refresh,
    open. A bad zip
    leaves the running app untouched; the swap is two same-volume renames.
    Returns 0 on success, 1 on any refusal."""
    from . import layout

    apps_dir = cfg.apps_dir if apps_dir is None else apps_dir
    pid = os.getpid() if pid is None else pid
    uid = os.getuid() if uid is None else uid
    app_name = f"{cfg.app_name}.app"
    dest = apps_dir / app_name
    if not destination_ok(dest, uid=uid, say=say):
        return 1

    # Staged inside the apps dir so the swap renames within one volume.
    staging = apps_dir / f".{cfg.app_name}-install-{pid}"
    try:
        staging.mkdir(parents=True, exist_ok=True)
        unpacked = run(["ditto", "-x", "-k", str(zip_path), str(staging)])
        if unpacked.returncode != 0:
            say(f"error: ditto failed: {(unpacked.stderr or '').strip()}")
            return 1
        new = staging / app_name
        problems = layout.problems(new, cfg)
        if problems:
            say(f"error: {zip_path.name} does not match the bundle layout:")
            for problem in problems:
                say(f"  {problem}")
            return 1

        if not swap_in(new, dest, aside=apps_dir / f"{app_name}.old-{pid}", pids=pids,
                       kill=kill, sleep=sleep, monotonic=monotonic, rename=rename,
                       reopen=lambda d: run(["open", "-a", str(d)]), say=say):
            return 1
    finally:
        shutil.rmtree(staging, ignore_errors=True)

    if not open_installed(dest, run=run, say=say):
        return 1
    say(f"installed {dest} from {zip_path.name}")
    return 0


def destination_ok(dest: Path, *, uid: int, say: Callable[[str], None] = print,
                   removing: bool = False) -> bool:
    """Whether `dest` may be replaced (or, `removing`, deleted) without root. Says
    why not, and how to fix it, when it may not: a symlink is refused, and so is a
    bundle another user owns."""
    if dest.is_symlink():
        how = "remove it by hand" if removing else "remove it or install by hand"
        say(f"error: {dest} is a symlink; {how}.")
        return False
    if dest.exists() and dest.lstat().st_uid != uid:
        if removing:
            say(f"error: {dest} is not owned by you, so it cannot be removed without "
                "root. Remove it with:")
            say(f"  sudo rm -rf {dest}")
            return False
        # Installing the pkg again would not help: pkgbuild's payload is root's, so
        # it leaves the bundle root-owned and the next release refuses the same way.
        # Handing the bundle back once is what makes every later install sudo-free.
        say(f"error: {dest} is not owned by you (the installer package made it), so it "
            "cannot be replaced without root.")
        say("Hand it back to yourself once, then run install again; this and every "
            "later release then swap in without sudo:")
        say(f'  sudo chown -R "$(id -un)" {dest}')
        return False
    return True


def swap_in(new: Path, dest: Path, *, aside: Path,
            pids: Callable[[Path], list[int]] = processes.bundle_pids,
            kill: Callable[[int, int], None] = os.kill,
            sleep: Callable[[float], None] = time.sleep,
            monotonic: Callable[[], float] = time.monotonic,
            rename: Callable[[Path, Path], object] = os.rename,
            reopen: Callable[[Path], object] | None = None,
            say: Callable[[str], None] = print) -> bool:
    """Quit what runs from `dest`, then put the bundle at `new` in its place.

    `new` and `aside` must be on `dest`'s volume, so both moves are renames. The
    old bundle is moved to `aside` and deleted only once the new one is in place;
    if the second move fails, the old one goes back and, when it was running
    before the quit, `reopen(dest)` starts it again. True when `new` is installed.
    """
    was_running = bool(pids(dest))
    quit_app(dest, pids=pids, kill=kill, sleep=sleep, monotonic=monotonic)

    had_old = dest.exists()
    try:
        if had_old:
            rename(dest, aside)
    except OSError as exc:
        say(f"error: could not move {dest} aside: {exc}")
        return False
    try:
        rename(new, dest)
    except OSError as exc:
        say(f"error: could not move the new app into place: {exc}")
        if had_old:
            shutil.rmtree(dest, ignore_errors=True)  # any partial new copy
            try:
                rename(aside, dest)
            except OSError as back:
                say(f"error: could not put the old app back either ({back}); it is at "
                    f"{aside}. Restore it with:")
                say(f'  mv "{aside}" "{dest}"')
                return False
            if was_running and reopen is not None:
                say(f"put the old {dest.name} back; reopening it.")
                reopen(dest)
        return False
    if had_old:
        shutil.rmtree(aside, ignore_errors=True)
    return True


def open_installed(dest: Path, *, run: Runner = run_command,
                   say: Callable[[str], None] = print) -> bool:
    """Refresh Finder's icon for `dest` (best-effort) and open it. False when it
    would not open."""
    refresh_finder_icon(dest, run=run, say=say)
    opened = run(["open", "-a", str(dest)])
    if opened.returncode != 0:
        say(f"error: installed {dest} but could not open it: {(opened.stderr or '').strip()}")
        return False
    return True


def remove_installed_app(dest: Path, *,
                         pids: Callable[[Path], list[int]] = processes.bundle_pids,
                         kill: Callable[[int, int], None] = os.kill,
                         sleep: Callable[[float], None] = time.sleep,
                         monotonic: Callable[[], float] = time.monotonic,
                         uid: int | None = None,
                         say: Callable[[str], None] = print) -> int:
    """Quit what runs from `dest` and delete the bundle: the reverse of
    `install_built_app`. Nothing installed is a success. Only the bundle goes;
    whatever the app itself wrote (preferences, Keychain items) is left alone.
    Returns 0 on success, 1 on any refusal."""
    uid = os.getuid() if uid is None else uid
    if not dest.exists() and not dest.is_symlink():
        say(f"{dest} is not installed; nothing to remove.")
        return 0
    if not destination_ok(dest, uid=uid, say=say, removing=True):
        return 1
    left = quit_app(dest, pids=pids, kill=kill, sleep=sleep, monotonic=monotonic)
    if left:
        say(f"error: {dest} is still running (pids {', '.join(map(str, left))}); not removed.")
        return 1
    shutil.rmtree(dest)
    say(f"removed {dest}")
    return 0


def install_built_app(app: Path, apps_dir: Path, *, run: Runner = run_command,
                      pids: Callable[[Path], list[int]] = processes.bundle_pids,
                      kill: Callable[[int, int], None] = os.kill,
                      sleep: Callable[[float], None] = time.sleep,
                      monotonic: Callable[[], float] = time.monotonic,
                      rename: Callable[[Path, Path], object] = os.rename,
                      pid: int | None = None, uid: int | None = None,
                      say: Callable[[str], None] = print) -> int:
    """Install a locally built `app` bundle (a build's products directory, say)
    into `apps_dir` under its own name, with no release.json, zip or notarization.

    The same order and guarantees as `install`: ownership check, copy beside the
    install, quit, swap, Finder refresh, open. A failed copy leaves the installed
    app running and untouched. Returns 0 on success, 1 on any refusal.
    """
    pid = os.getpid() if pid is None else pid
    uid = os.getuid() if uid is None else uid
    if not (app / "Contents" / "Info.plist").is_file():
        say(f"error: {app} is not an app bundle (no Contents/Info.plist).")
        return 1
    dest = apps_dir / app.name
    if not destination_ok(dest, uid=uid, say=say):
        return 1

    staging = apps_dir / f".{app.stem}-install-{pid}"
    try:
        staging.mkdir(parents=True, exist_ok=True)
        new = staging / app.name
        copied = run(["ditto", str(app), str(new)])
        if copied.returncode != 0 or not new.is_dir():
            say(f"error: ditto failed: {(copied.stderr or '').strip()}")
            return 1
        if not swap_in(new, dest, aside=apps_dir / f"{app.name}.old-{pid}", pids=pids,
                       kill=kill, sleep=sleep, monotonic=monotonic, rename=rename,
                       reopen=lambda d: run(["open", "-a", str(d)]), say=say):
            return 1
    finally:
        shutil.rmtree(staging, ignore_errors=True)

    if not open_installed(dest, run=run, say=say):
        return 1
    say(f"installed {dest} from {app}")
    return 0


def installed_failures(cfg: ReleaseConfig, *, apps_dir: Path | None = None,
                       run: Runner = run_command,
                       pids: Callable[[Path], list[int]] = processes.bundle_pids) -> list[str]:
    """What is wrong with the installed copy; empty means healthy."""
    from . import layout

    app = (cfg.apps_dir if apps_dir is None else apps_dir) / f"{cfg.app_name}.app"
    plist = app / "Contents/Info.plist"
    if not plist.exists():
        return [f"{app} is not installed ({plist} is missing)"]
    failures: list[str] = []
    version, build = versions.read_versions(cfg)
    info = plistlib.loads(plist.read_bytes())
    got = (info.get("CFBundleShortVersionString"), info.get("CFBundleVersion"))
    if got != (version, str(build)):
        failures.append(f"installed app is {got[0]} ({got[1]}), not {version} ({build})")
    shown = run(["codesign", "-dv", "--verbose=2", str(app)])
    authorities = [line.split("=", 1)[1] for line in
                   ((shown.stderr or "") + (shown.stdout or "")).splitlines()
                   if line.startswith("Authority=")]
    if shown.returncode != 0 or not authorities or not authorities[0].startswith(
            cfg.app_identity):
        failures.append(f"installed app is not signed {cfg.app_identity} "
                        f"(authority: {authorities[0] if authorities else 'none'})")
    failures += [f"layout: {p}" for p in layout.problems(app, cfg)]
    if not pids(app):
        failures.append(f"{cfg.app_name} is not running from {app}")
    return failures
