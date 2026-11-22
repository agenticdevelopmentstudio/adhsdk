#!/usr/bin/env python3
"""Build adhd from the adh-daemon submodule and embed it in the app bundle.

    embed_adhd.py embed --repo <checkout> --app <name>     (an Xcode build phase: `Embed adhd`)

`--repo` is the app's checkout, the directory that holds `external/adh-daemon`
(an Xcode phase passes it relative to `$SRCROOT`: `"$SRCROOT/.."` for the
Kitchen, `"$SRCROOT/../.."` for Stenographer). `--app` names the app in adhd's
DerivedData, `ADHDaemon-<app>-<worktree>`: `adkitchen`, `stenographer`.

The Hub daemon ships inside every suite app at
`<App>.app/Contents/Library/adhd/adhd`, with the frameworks it loads in
`Contents/Library/adhd/Frameworks/`. `ADHDBootstrap.connect` (adh-daemon's
ADHDClient) hands that path to `DaemonInstaller`, which copies the daemon and
its framework closure into the daemon's support directory and registers it.

adhd is a built artifact, not a target of this project. Its project links
adh-daemon's OWN adhsdk pin, so referencing ADHDaemon.xcodeproj from here
would put two projects producing `AgenticDeveloperHubSDKSync.framework` (and
its siblings) in one build. Instead this phase builds adh-daemon's `adhd`
scheme in a DerivedData of its own and copies the result outside
`Contents/Frameworks`, so the daemon's toolkit copies never shadow the app's.

Steps, driven by the build settings Xcode exports to a script phase
(`CONFIGURATION`, `TARGET_BUILD_DIR`, `WRAPPER_NAME`, `SRCROOT`,
`EXPANDED_CODE_SIGN_IDENTITY`):

1. Generate adh-daemon's (untracked) Xcode project with XcodeGen and build the
   `adhd` scheme with the app's configuration, so a Debug app carries the dev
   daemon. Skipped when the stamp beside the products (in adhd's own
   DerivedData, so it describes whatever was last built THERE, whichever
   target or checkout built it) matches the submodule's HEAD, a hash of its
   uncommitted changes (nested submodules included) and the configuration.
   xcodegen is `$XCODEGEN` when set, else the first on the user's login-shell
   PATH, else `/opt/homebrew/bin` or `/usr/local/bin`.
2. Copy `adhd` to `Contents/Library/adhd/adhd` and hand that directory to
   `embed_transitive_frameworks.py` beside this script, which copies every `@rpath`
   framework adhd loads, transitively, into `Contents/Library/adhd/Frameworks`
   and signs each with the app's identity. That directory has exactly the flat
   layout the toolkit script reads (`<dir>/<dir name>` beside
   `<dir>/Frameworks`), and adhd's `@executable_path/Frameworks` rpath is
   where dyld and `MachODependencies` look.
3. Re-sign `adhd` with the app's identity.
4. Exit non-zero, naming it, if a dependency cannot be found (the toolkit
   script's own report).

Steps 1-3 run under an exclusive `flock` on a lock file in adhd's
DerivedData: an app's targets can share that folder (the Kitchen's App and
ADNotes both carry this phase, and one `xcodebuild` of its `AppMacOSAll`
aggregate runs the two at once), and so can two builds of one checkout.
"""

from __future__ import annotations

import contextlib
import fcntl
import hashlib
import os
import pwd
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterator, Mapping, Sequence

SUBMODULE = Path("external/adh-daemon")
PROJECT_DIR = SUBMODULE / "apple/ADHDaemon"
WORKSPACE = SUBMODULE / "apple/ADHDaemon.xcworkspace"
TRANSITIVE_EMBEDDER = Path(__file__).resolve().parent / "embed_transitive_frameworks.py"
SCHEME = "adhd"
DAEMON_NAME = "adhd"
BUNDLE_SUBPATH = Path("Contents/Library/adhd")
STAMP_SUFFIX = ".embed_adhd-stamp"
LOCK_NAME = ".embed_adhd.lock"
AD_HOC_IDENTITY = "-"

# What a nested xcodebuild may inherit. Everything else an Xcode script phase
# exports (SDKROOT, ARCHS, TARGET_BUILD_DIR, CONFIGURATION_BUILD_DIR, ...) would
# be read by the inner build as overrides and aim it at the app's build.
PASSED_ENVIRONMENT = ("HOME", "USER", "LOGNAME", "TMPDIR", "LANG", "DEVELOPER_DIR", "SSH_AUTH_SOCK")
TOOL_PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# Where xcodegen is looked for last, after `$XCODEGEN` and the login shell's PATH.
XCODEGEN_FALLBACK_DIRECTORIES = ("/opt/homebrew/bin", "/usr/local/bin")
LOGIN_SHELL_TIMEOUT = 15

Runner = Callable[..., subprocess.CompletedProcess]


class EmbedError(Exception):
    """A failure the build log should show as one line."""


# MARK: - Where things are

@dataclass(frozen=True)
class Checkout:
    """An app's checkout (`repo`, the directory holding `external/adh-daemon`)
    and the app's name in adhd's DerivedData (`app`)."""
    repo: Path
    app: str

    @property
    def submodule(self) -> Path:
        return self.repo / SUBMODULE


def worktree_token(repo: Path) -> str:
    """The checkout's name for adhd's build folder: the worktree's directory,
    or `managed-<hash>` in a main checkout. dev.py's `workspace_token` says
    plain `managed`, which is every non-worktree clone's name at once; two
    clones at different adh-daemon pins sharing one adhd folder would embed
    each other's daemon, so the main checkout's token carries a short hash of
    its absolute path."""
    if (repo / ".git").is_file():
        return repo.name
    digest = hashlib.sha256(str(repo.resolve()).encode()).hexdigest()[:8]
    return f"managed-{digest}"


def adhd_derived_data(checkout: Checkout) -> Path:
    """adhd's DerivedData for THIS checkout's submodule. The app is in the
    name because adh-daemon's own worktree of the same name already owns
    `ADHDaemon-<worktree>`, and the Kitchen's and Stenographer's worktrees of
    a phase share a name; sharing a folder would let two source trees
    overwrite each other's products."""
    return (Path.home() / "Library/Developer/Xcode/DerivedData"
            / f"ADHDaemon-{checkout.app}-{worktree_token(checkout.repo)}")


def products_directory(checkout: Checkout, configuration: str) -> Path:
    return adhd_derived_data(checkout) / "Build/Products" / configuration


def stamp_path(checkout: Checkout, configuration: str) -> Path:
    """The stamp for one configuration's products, beside them in adhd's
    DerivedData rather than in a target's `$DERIVED_FILE_DIR`: the products
    are shared by every target (and run) that builds into that folder, so
    only a stamp kept with them can say what they were built from."""
    return adhd_derived_data(checkout) / f"{configuration}{STAMP_SUFFIX}"


# MARK: - The stamp

def run_git(submodule: Path, arguments: Sequence[str], runner: Runner = subprocess.run) -> str:
    done = runner(["/usr/bin/git", "-C", str(submodule), *arguments], capture_output=True, text=True)
    if done.returncode != 0:
        raise EmbedError(f"git {' '.join(arguments)} in {submodule} failed: {done.stderr.strip()}")
    return done.stdout


def repositories(submodule: Path, runner: Runner = subprocess.run) -> list[Path]:
    """The submodule and every submodule nested in it, recursively."""
    nested = run_git(submodule, ["submodule", "foreach", "--recursive", "--quiet", "pwd"], runner=runner)
    return [submodule, *(Path(line) for line in nested.splitlines() if line.strip())]


def hash_untracked(repository: Path, top: Path, digest, runner: Runner = subprocess.run) -> None:
    """Feeds `digest` the name and contents of every untracked, not-ignored
    file in `repository` (porcelain status names them but never reads them,
    so an edit to a file not yet added would change nothing). A symlink is
    hashed by its target, never followed."""
    listed = run_git(repository, ["ls-files", "--others", "--exclude-standard", "-z"], runner=runner)
    for name in sorted(entry for entry in listed.split("\0") if entry):
        path = repository / name
        try:
            label = path.relative_to(top)
        except ValueError:
            label = path
        digest.update(f"untracked {label}\0".encode())
        if path.is_symlink():
            digest.update(f"-> {os.readlink(path)}\0".encode())
        elif path.is_file():
            with path.open("rb") as handle:
                for chunk in iter(lambda: handle.read(1 << 20), b""):
                    digest.update(chunk)
            digest.update(b"\0")


def source_stamp(submodule: Path, configuration: str, runner: Runner = subprocess.run) -> str:
    """HEAD, a hash of every uncommitted change (tracked diffs and the
    contents of untracked files, in the submodule and, recursively, in every
    submodule nested in it) and the configuration: what decides whether the
    last build still stands."""
    head = run_git(submodule, ["rev-parse", "HEAD"], runner=runner).strip()
    dirty = hashlib.sha256()
    for arguments in (["status", "--porcelain=v1", "--ignore-submodules=none"],
                      ["diff", "HEAD"],
                      ["submodule", "foreach", "--recursive", "git rev-parse HEAD && git diff HEAD"]):
        dirty.update(run_git(submodule, arguments, runner=runner).encode())
    for repository in repositories(submodule, runner=runner):
        hash_untracked(repository, submodule, dirty, runner=runner)
    return f"{head} {dirty.hexdigest()} {configuration}\n"


# MARK: - One build at a time

@contextlib.contextmanager
def exclusive_lock(path: Path) -> Iterator[None]:
    """Holds an exclusive `flock` on `path` for the body. Two Embed adhd
    phases of one checkout build into one DerivedData and may run in parallel;
    the second waits here instead of racing the first's xcodebuild (one of
    them failing on a locked build database) or reading half-written
    products. The kernel drops the lock if the process dies."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print(f"embed_adhd: waiting for another Embed adhd phase ({path})", flush=True)
            fcntl.flock(handle, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def lock_path(checkout: Checkout) -> Path:
    return adhd_derived_data(checkout) / LOCK_NAME


# MARK: - The build

def build_environment(environ: Mapping[str, str]) -> dict[str, str]:
    environment = {key: environ[key] for key in PASSED_ENVIRONMENT if key in environ}
    environment["PATH"] = TOOL_PATH
    return environment


def login_shell_path(environ: Mapping[str, str], runner: Runner = subprocess.run) -> str:
    """The user's login-shell PATH, or "" when the shell cannot say. An Xcode
    build phase inherits launchd's PATH, not the one the user's shell sets
    up, so a tool on a mint, nix or `~/.local/bin` PATH is invisible to it."""
    shell = environ.get("SHELL") or pwd.getpwuid(os.getuid()).pw_shell or "/bin/zsh"
    environment = {key: environ[key] for key in ("HOME", "USER", "LOGNAME", "TMPDIR") if key in environ}
    try:
        done = runner([shell, "-l", "-c", 'printf "\\n%s" "$PATH"'], capture_output=True, text=True,
                      env=environment, timeout=LOGIN_SHELL_TIMEOUT)
    except (OSError, subprocess.SubprocessError):
        return ""
    if done.returncode != 0 or not (done.stdout or "").strip():
        return ""
    # The last line: a login shell may print a banner before it.
    return done.stdout.rstrip("\n").splitlines()[-1].strip()


def resolve_xcodegen(environ: Mapping[str, str], runner: Runner = subprocess.run) -> str:
    """xcodegen's path: `$XCODEGEN` when set, else the first on the login
    shell's PATH, else the first in `XCODEGEN_FALLBACK_DIRECTORIES`. Raises
    naming the tool and every place looked when none has it."""
    override = environ.get("XCODEGEN", "")
    if override:
        if os.path.isfile(override) and os.access(override, os.X_OK):
            return override
        raise EmbedError(f"XCODEGEN={override} is not an executable file")
    shell_path = login_shell_path(environ, runner=runner)
    if shell_path:
        found = shutil.which("xcodegen", path=shell_path)
        if found:
            return found
    found = shutil.which("xcodegen", path=os.pathsep.join(XCODEGEN_FALLBACK_DIRECTORIES))
    if found:
        return found
    raise EmbedError(
        "xcodegen not found (adh-daemon's Xcode project is generated with it). Looked in $XCODEGEN "
        f"(unset), the login shell's PATH ({shell_path or 'unavailable'}) and "
        f"{', '.join(XCODEGEN_FALLBACK_DIRECTORIES)}. Install it (brew install xcodegen) "
        "or set XCODEGEN to its path.")


def build_commands(checkout: Checkout, configuration: str,
                   xcodegen: str = "xcodegen") -> list[tuple[list[str], Path]]:
    """XcodeGen (adh-daemon's .xcodeproj is untracked) and then xcodebuild
    through adh-daemon's own workspace, each with the directory it runs in."""
    return [
        ([xcodegen, "generate"], checkout.repo / PROJECT_DIR),
        (["/usr/bin/xcodebuild",
          "-workspace", str(checkout.repo / WORKSPACE),
          "-scheme", SCHEME,
          "-configuration", configuration,
          "-destination", "platform=macOS",
          "-derivedDataPath", str(adhd_derived_data(checkout)),
          "-skipPackagePluginValidation", "-skipMacroValidation",
          "build"], checkout.repo),
    ]


def failure_detail(done: subprocess.CompletedProcess) -> str:
    log = (done.stdout or "") + (done.stderr or "")
    errors = sorted({line.strip() for line in log.splitlines() if "error:" in line})
    return "\n".join(errors[:30]) or "\n".join(log.splitlines()[-40:])


def build_adhd(checkout: Checkout, configuration: str, environ: Mapping[str, str],
               runner: Runner = subprocess.run) -> Path:
    """Build adhd unless the stamp says the products already match the
    sources, and return the products directory it is in."""
    products = products_directory(checkout, configuration)
    stamp_file = stamp_path(checkout, configuration)
    stamp = source_stamp(checkout.submodule, configuration, runner=runner)
    if (products / DAEMON_NAME).exists() and stamp_file.exists() and stamp_file.read_text() == stamp:
        print(f"embed_adhd: adhd ({configuration}) is current, not rebuilding")
        return products
    xcodegen = resolve_xcodegen(environ, runner=runner)
    # The products are about to change: a build that fails or is cut short
    # must not leave the old stamp vouching for them.
    stamp_file.unlink(missing_ok=True)
    environment = build_environment(environ)
    for command, directory in build_commands(checkout, configuration, xcodegen=xcodegen):
        print(f"embed_adhd: {' '.join(command)}", flush=True)
        done = runner(command, cwd=str(directory), env=environment, capture_output=True, text=True)
        if done.returncode != 0:
            raise EmbedError(f"{Path(command[0]).name} failed for adhd ({configuration}):\n{failure_detail(done)}")
    if not (products / DAEMON_NAME).exists():
        raise EmbedError(f"the adhd build succeeded but left no {products / DAEMON_NAME}")
    stamp_file.parent.mkdir(parents=True, exist_ok=True)
    stamp_file.write_text(stamp)
    return products


# MARK: - Copy and sign

def copy_daemon(products: Path, destination: Path, identity: str,
                runner: Runner = subprocess.run) -> None:
    """Replace `destination` with adhd and its framework closure, signed."""
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)
    shutil.copy2(products / DAEMON_NAME, destination / DAEMON_NAME)
    done = runner([sys.executable, str(TRANSITIVE_EMBEDDER), str(destination), str(products)],
                  env={**os.environ, "EXPANDED_CODE_SIGN_IDENTITY": identity},
                  capture_output=True, text=True)
    if done.returncode != 0:
        raise EmbedError(f"adhd's frameworks could not all be embedded:\n{failure_detail(done)}")
    # The toolkit script signs only copies that do not verify, and adhd's own
    # build signed every one with ITS identity. Re-sign them all, then the
    # daemon, with the app's, so a Developer ID app carries no other signer.
    for item in [*sorted((destination / "Frameworks").glob("*.framework")), destination / DAEMON_NAME]:
        done = runner(["/usr/bin/codesign", "--force", "--sign", identity,
                       "--preserve-metadata=identifier,entitlements,flags", "--timestamp=none",
                       str(item)], capture_output=True, text=True)
        if done.returncode != 0:
            raise EmbedError(f"codesign {item.name} failed: {done.stderr.strip()}")


def required(environ: Mapping[str, str], name: str) -> str:
    value = environ.get(name, "")
    if not value:
        raise EmbedError(f"{name} is not set (run this as an Xcode build phase)")
    return value


def embed_adhd(environ: Mapping[str, str], checkout: Checkout, runner: Runner = subprocess.run) -> Path:
    """The `embed` subcommand; returns the embedded daemon's path."""
    configuration = required(environ, "CONFIGURATION")
    bundle = Path(required(environ, "TARGET_BUILD_DIR")) / required(environ, "WRAPPER_NAME")
    identity = environ.get("EXPANDED_CODE_SIGN_IDENTITY") or AD_HOC_IDENTITY
    if not (checkout.repo / PROJECT_DIR / "project.yml").exists():
        raise EmbedError(f"{checkout.submodule} is not checked out: git submodule update --init --recursive")
    destination = bundle / BUNDLE_SUBPATH
    with exclusive_lock(lock_path(checkout)):
        products = build_adhd(checkout, configuration, environ, runner=runner)
        copy_daemon(products, destination, identity, runner=runner)
    frameworks = sorted(path.name for path in (destination / "Frameworks").glob("*.framework"))
    print(f"embed_adhd: {BUNDLE_SUBPATH / DAEMON_NAME} with {len(frameworks)} frameworks: {', '.join(frameworks)}")
    return destination / DAEMON_NAME


USAGE = "usage: embed_adhd.py embed --repo <checkout> --app <name>"


def parse_checkout(argv: Sequence[str]) -> Checkout | None:
    """`embed --repo <checkout> --app <name>`, in either order, or None."""
    arguments = list(argv)
    if not arguments or arguments[0] != "embed" or len(arguments) != 5:
        return None
    options = dict(zip(arguments[1::2], arguments[2::2]))
    if set(options) != {"--repo", "--app"} or not all(options.values()):
        return None
    return Checkout(repo=Path(options["--repo"]).resolve(), app=options["--app"])


def main(argv: Sequence[str]) -> int:
    checkout = parse_checkout(argv)
    if checkout is None:
        print(USAGE, file=sys.stderr)
        return 2
    try:
        embed_adhd(os.environ, checkout)
    except EmbedError as error:
        print(f"error: embed_adhd: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
