#!/usr/bin/env python3
"""Fetch, build and stage the Chromium Embedded Framework (CEF) the toolkit's
Chromium framework is built on.

The version is pinned in one place,
`packages/apple/AgenticDeveloperHubSDK/Chromium/CEF.json`; nothing else spells
it. Every step is idempotent and caches under
`~/Library/Caches/AgenticDeveloperHubSDK/CEF/<version>/<arch>/`, so the first
build downloads about 135 MB per architecture and compiles the wrapper once, and
every later build only checks stamps.

    cef.py fetch   --archs "arm64 x86_64"
        Download each architecture's minimal distribution, check its SHA-1,
        and unpack it.
    cef.py stage   --dest DIR --archs "$ARCHS"
        fetch, build `libcef_dll_wrapper.a` per architecture (CEF ships it as
        source and cmake is not assumed), and stage `DIR/include/...` and a
        `DIR/lib/libcef_dll_wrapper.a` holding every requested architecture.
        A target compiles against `DIR` (`#include "include/cef_app.h"`).
    cef.py embed   --frameworks DIR --state DIR --archs "$ARCHS"
                   --helper-name NAME --bundle-id ID [--sign IDENTITY]
        Copy `Chromium Embedded Framework.framework` into an app's
        Frameworks directory (one architecture copied, two merged with lipo),
        compile `Chromium/Helper/ChromiumHelperMain.mm` once per architecture,
        and build the five helper apps Chromium starts its subprocesses from
        beside it: `NAME.app` and `NAME (GPU|Renderer|Plugin|Alerts).app`,
        identified `ID.helper[.gpu|.renderer|.plugin|.alerts]`. Everything is
        signed, inside out, when an identity is given; a real identity also
        gets the hardened runtime and each helper the entitlements Chromium's
        process needs. Its stamps and work directories go in `--state`, never
        in the bundle: codesign refuses an app whose Frameworks directory holds
        anything that is not signed code. Give it a directory on the same
        volume as the bundle (`$DERIVED_FILE_DIR/CEF`), so a finished copy is
        moved into place in one rename.
    cef.py version
        Print the pinned version.

CEF is loaded at runtime (`CefScopedLibraryLoader`), never linked, so a build
without the framework still links; the Chrome pane reports the missing engine
instead of the app dying at launch.

Exits non-zero, with the reason on stderr, on any failure.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import filecmp
import hashlib
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path

TOOLKIT = Path(__file__).resolve().parents[2]
PIN = TOOLKIT / "packages/apple/AgenticDeveloperHubSDK/Chromium/CEF.json"
CACHE = Path(os.environ.get("ADH_CEF_CACHE", "~/Library/Caches/AgenticDeveloperHubSDK/CEF")).expanduser()
FRAMEWORK = "Chromium Embedded Framework.framework"
# Bumped when the wrapper's compile flags change, so a cached library built
# with the old flags is rebuilt rather than trusted.
WRAPPER_RECIPE = "1"
# CEF's own macOS flags (cmake/cef_variables.cmake), minus -Werror: a new
# compiler warning in CEF's sources must not fail the app's build.
WRAPPER_FLAGS = [
    "-DWRAPPING_CEF_SHARED", "-D__STDC_CONSTANT_MACROS", "-D__STDC_FORMAT_MACROS",
    "-DNDEBUG", "-DCEF_USE_SANDBOX", "-O3", "-mmacosx-version-min=13.0",
    "-fno-strict-aliasing", "-fstack-protector", "-funwind-tables", "-fvisibility=hidden",
    "-fno-exceptions", "-fno-rtti", "-fno-threadsafe-statics", "-fobjc-call-cxx-cdtors",
    "-fvisibility-inlines-hidden", "-std=c++20", "-Wno-narrowing", "-w",
]


def fail(message: str) -> None:
    raise SystemExit(f"error: cef.py: {message}")


def pin() -> dict:
    return json.loads(PIN.read_text())


def normalize_archs(text: str) -> list[str]:
    """Xcode's $ARCHS, deduplicated and ordered; anything but the two Mac
    architectures CEF ships is an error, not a silent skip."""
    archs = sorted(set(text.split()))
    if not archs:
        fail("no architectures given")
    for arch in archs:
        if arch not in ("arm64", "x86_64"):
            fail(f"CEF ships no macOS build for architecture {arch!r}")
    return archs


def arch_dir(version: str, arch: str) -> Path:
    return CACHE / version / arch


def sha1(path: Path) -> str:
    digest = hashlib.sha1()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def fetch_distribution(arch: str) -> Path:
    """The unpacked distribution's root for `arch`, downloading it once."""
    info = pin()
    version = info["version"]
    dist = info["distributions"][arch]
    root = arch_dir(version, arch)
    dist_root = root / "dist"
    stamp = root / "dist.complete"
    if stamp.exists() and stamp.read_text().strip() == dist["sha1"] and dist_root.is_dir():
        return dist_root
    root.mkdir(parents=True, exist_ok=True)
    archive = root / dist["file"]
    if not archive.exists() or sha1(archive) != dist["sha1"]:
        url = f"{info['url']}/{urllib.parse.quote(dist['file'])}"
        print(f"cef.py: downloading {dist['file']}", file=sys.stderr)
        partial = archive.with_suffix(".partial")
        with urllib.request.urlopen(url) as response, partial.open("wb") as out:
            shutil.copyfileobj(response, out, 1 << 20)
        got = sha1(partial)
        if got != dist["sha1"]:
            partial.unlink()
            fail(f"{dist['file']} has SHA-1 {got}, CEF.json pins {dist['sha1']}")
        partial.replace(archive)
    unpack = Path(tempfile.mkdtemp(dir=root, prefix="unpack."))
    try:
        with tarfile.open(archive) as tar:
            tar.extractall(unpack, filter="tar")
        tops = [p for p in unpack.iterdir() if p.is_dir()]
        if len(tops) != 1:
            fail(f"{dist['file']} does not hold one top-level directory")
        if dist_root.exists():
            shutil.rmtree(dist_root)
        tops[0].replace(dist_root)
    finally:
        shutil.rmtree(unpack, ignore_errors=True)
    if not (dist_root / "Release" / FRAMEWORK).is_dir():
        fail(f"{dist['file']} has no Release/{FRAMEWORK}")
    archive.unlink()
    stamp.write_text(dist["sha1"] + "\n")
    return dist_root


def wrapper_sources(dist_root: Path) -> list[Path]:
    """The wrapper's sources, as libcef_dll/CMakeLists.txt lists them, less the
    Windows and Linux ones."""
    text = (dist_root / "libcef_dll/CMakeLists.txt").read_text()
    names = re.findall(r"^\s+([A-Za-z0-9_/]+\.(?:cc|mm))\s*$", text, re.MULTILINE)
    names = [n for n in names if not re.search(r"_(win|linux)\.", n)]
    if not names:
        fail("found no wrapper sources in libcef_dll/CMakeLists.txt")
    return [dist_root / "libcef_dll" / n for n in sorted(set(names))]


def sdk_path() -> str:
    return subprocess.run(["xcrun", "--sdk", "macosx", "--show-sdk-path"],
                          check=True, capture_output=True, text=True).stdout.strip()


def build_wrapper(arch: str) -> Path:
    """`libcef_dll_wrapper.a` for `arch`, compiled once per pinned version."""
    version = pin()["version"]
    dist_root = fetch_distribution(arch)
    out = arch_dir(version, arch) / "wrapper"
    library = out / "libcef_dll_wrapper.a"
    stamp = out / "wrapper.complete"
    if library.exists() and stamp.exists() and stamp.read_text().strip() == WRAPPER_RECIPE:
        return library
    objects_dir = out / "obj"
    if objects_dir.exists():
        shutil.rmtree(objects_dir)
    objects_dir.mkdir(parents=True)
    sdk = sdk_path()
    sources = wrapper_sources(dist_root)

    def compile_one(index_source: tuple[int, Path]) -> Path:
        index, source = index_source
        obj = objects_dir / f"{index:03d}_{source.stem}.o"
        command = ["xcrun", "clang++", "-c", "-arch", arch, "-isysroot", sdk,
                   "-I", str(dist_root), *WRAPPER_FLAGS, str(source), "-o", str(obj)]
        done = subprocess.run(command, capture_output=True, text=True)
        if done.returncode != 0:
            raise RuntimeError(f"{source.relative_to(dist_root)}:\n{done.stderr}")
        return obj

    print(f"cef.py: compiling libcef_dll_wrapper ({arch}, {len(sources)} files)", file=sys.stderr)
    with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
        try:
            objects = list(pool.map(compile_one, enumerate(sources)))
        except RuntimeError as error:
            fail(f"wrapper compile failed: {error}")
    if library.exists():
        library.unlink()
    subprocess.run(["xcrun", "libtool", "-static", "-no_warning_for_no_symbols",
                    "-o", str(library), *map(str, objects)], check=True)
    shutil.rmtree(objects_dir)
    stamp.write_text(WRAPPER_RECIPE + "\n")
    return library


def sync_tree(source: Path, dest: Path) -> None:
    """Make `dest` a copy of `source`, touching only files that differ, so a
    rerun leaves header mtimes alone and nothing recompiles."""
    dest.mkdir(parents=True, exist_ok=True)
    wanted = set()
    for path in source.rglob("*"):
        rel = path.relative_to(source)
        wanted.add(rel)
        target = dest / rel
        if path.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        elif not target.exists() or not filecmp.cmp(path, target, shallow=False):
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
    for path in sorted(dest.rglob("*"), reverse=True):
        if path.relative_to(dest) not in wanted:
            if path.is_dir() and not path.is_symlink():
                shutil.rmtree(path)
            else:
                path.unlink()


def stage(dest: Path, archs: list[str]) -> None:
    libraries = [build_wrapper(arch) for arch in archs]
    sync_tree(fetch_distribution(archs[0]) / "include", dest / "include")
    lib_dir = dest / "lib"
    lib_dir.mkdir(parents=True, exist_ok=True)
    staged = lib_dir / "libcef_dll_wrapper.a"
    merged = lib_dir / "libcef_dll_wrapper.a.new"
    if len(libraries) == 1:
        shutil.copy2(libraries[0], merged)
    else:
        subprocess.run(["xcrun", "lipo", "-create", *map(str, libraries), "-output", str(merged)], check=True)
    if staged.exists() and filecmp.cmp(staged, merged, shallow=False):
        merged.unlink()
    else:
        merged.replace(staged)
    # Not "VERSION": `dest` is on the header search path, and on a
    # case-insensitive disk that file is what `#include <version>` finds.
    (dest / "cef-version.txt").write_text(pin()["version"] + "\n")


def is_macho(path: Path) -> bool:
    if path.is_symlink() or not path.is_file():
        return False
    with path.open("rb") as handle:
        magic = handle.read(4)
    return magic in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xca\xfe\xba\xbe")


def merge_frameworks(sources: list[Path], dest: Path) -> None:
    """One framework at `dest` holding every architecture of `sources`: Mach-O
    files merged with lipo, every other file copied from the first source. A
    non-Mach-O file present in more than one source must be identical, or the
    merge would silently pick one architecture's data; a file only one
    architecture has (a per-architecture V8 snapshot, say) is copied as is."""
    first = sources[0]
    for path in sorted(first.rglob("*")):
        rel = path.relative_to(first)
        target = dest / rel
        if path.is_symlink():
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(os.readlink(path))
        elif path.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        elif is_macho(path):
            others = [s / rel for s in sources[1:]]
            missing = [o for o in others if not o.exists()]
            if missing:
                fail(f"{rel} is in one architecture's framework but not {missing[0]}")
            subprocess.run(["xcrun", "lipo", "-create", str(path), *map(str, others),
                            "-output", str(target)], check=True)
        else:
            for other in sources[1:]:
                if (other / rel).exists() and not filecmp.cmp(path, other / rel, shallow=False):
                    fail(f"{rel} differs between architectures; it cannot be merged")
            shutil.copy2(path, target)
    for other in sources[1:]:
        for path in sorted(other.rglob("*")):
            rel = path.relative_to(other)
            target = dest / rel
            if target.exists() or target.is_symlink():
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            if path.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                shutil.copy2(path, target)


def embed(frameworks_dir: Path, state_dir: Path, archs: list[str], identity: str | None,
          helper_name: str, bundle_id: str) -> None:
    state_dir.mkdir(parents=True, exist_ok=True)
    embed_framework(frameworks_dir, state_dir, archs, identity)
    embed_helpers(frameworks_dir, state_dir, archs, identity, helper_name, bundle_id)


def embed_framework(frameworks_dir: Path, state_dir: Path, archs: list[str],
                    identity: str | None) -> None:
    sources = [fetch_distribution(arch) / "Release" / FRAMEWORK for arch in archs]
    version = pin()["version"]
    target = frameworks_dir / FRAMEWORK
    stamp = state_dir / f"{FRAMEWORK}.stamp"
    wanted = json.dumps({"version": version, "archs": archs, "identity": identity or "",
                         "target": str(target), "layout": "versioned"})
    if target.is_dir() and stamp.exists() and stamp.read_text() == wanted:
        return
    frameworks_dir.mkdir(parents=True, exist_ok=True)
    stamp.unlink(missing_ok=True)
    building = state_dir / f"{FRAMEWORK}.building"
    if building.exists():
        shutil.rmtree(building)
    if len(sources) == 1:
        shutil.copytree(sources[0], building, symlinks=True)
    else:
        building.mkdir()
        merge_frameworks(sources, building)
    make_versioned(building)
    if identity:
        # Inside out: the bundled dylibs first, then the framework itself.
        for dylib in sorted((building / "Versions" / "A" / "Libraries").glob("*.dylib")):
            codesign(dylib, identity)
        codesign(building, identity)
    if target.exists():
        shutil.rmtree(target)
    building.replace(target)
    stamp.write_text(wanted)


def make_versioned(framework: Path) -> None:
    """Turn CEF's flat framework (binary, `Libraries/` and `Resources/` at the
    top, `Info.plist` in `Resources/`) into the versioned layout every macOS
    framework has: everything in `Versions/A`, and symlinks at the top through
    `Versions/Current`. Xcode's product validation refuses the flat shape,
    since a shallow bundle keeps its Info.plist at the top, and codesign seals
    a versioned one properly. Electron ships Chromium's framework the same way.
    Nothing loads it by anything but the top-level path, which the symlinks
    keep: `cef_load_library` and the helper's `CefScopedLibraryLoader` both
    open `<framework>/Chromium Embedded Framework`."""
    stale_signature = framework / "_CodeSignature"
    if stale_signature.exists():
        shutil.rmtree(stale_signature)
    version = framework / "Versions" / "A"
    entries = sorted(entry.name for entry in framework.iterdir() if entry.name != "Versions")
    version.mkdir(parents=True)
    for name in entries:
        (framework / name).rename(version / name)
    (framework / "Versions" / "Current").symlink_to("A")
    for name in entries:
        (framework / name).symlink_to(f"Versions/Current/{name}")


HELPER_SOURCE = TOOLKIT / "packages/apple/AgenticDeveloperHubSDK/Chromium/Helper/ChromiumHelperMain.mm"
# Bumped when the helper's compile or link flags change.
HELPER_RECIPE = "1"
HELPER_COMPILE_FLAGS = [
    "-x", "objective-c++", "-D__STDC_CONSTANT_MACROS", "-D__STDC_FORMAT_MACROS",
    "-DNDEBUG", "-DCEF_USE_SANDBOX", "-O2", "-mmacosx-version-min=13.0",
    "-fno-strict-aliasing", "-fstack-protector", "-funwind-tables", "-fvisibility=hidden",
    "-fno-exceptions", "-fno-rtti", "-fno-threadsafe-statics", "-fobjc-call-cxx-cdtors",
    "-fvisibility-inlines-hidden", "-std=c++20",
]
# CEF_STANDARD_LIBS in cmake/cef_variables.cmake.
HELPER_LINK_FLAGS = ["-lpthread", "-framework", "AppKit", "-framework", "Cocoa", "-framework", "IOSurface"]
# (bundle name suffix, bundle identifier suffix), as CEF_HELPER_APP_SUFFIXES
# lists them. Chromium finds each variant by appending the name suffix to the
# base helper's name, so these strings are a contract with Chromium.
HELPER_VARIANTS = [
    ("", ""),
    (" (Alerts)", ".alerts"),
    (" (GPU)", ".gpu"),
    (" (Plugin)", ".plugin"),
    (" (Renderer)", ".renderer"),
]
# What each helper needs under the hardened runtime: V8 JITs in every process,
# and the GPU and plugin processes load code Chromium did not sign.
HELPER_ENTITLEMENTS = {
    "": ["com.apple.security.cs.allow-jit"],
    ".alerts": ["com.apple.security.cs.allow-jit"],
    ".renderer": ["com.apple.security.cs.allow-jit"],
    ".gpu": ["com.apple.security.cs.allow-jit",
             "com.apple.security.cs.allow-unsigned-executable-memory",
             "com.apple.security.cs.disable-library-validation"],
    ".plugin": ["com.apple.security.cs.allow-jit",
                "com.apple.security.cs.allow-unsigned-executable-memory",
                "com.apple.security.cs.disable-library-validation"],
}


def build_helper_executable(arch: str) -> Path:
    """The helper executable for `arch`, compiled once per pinned version,
    recipe and source."""
    version = pin()["version"]
    dist_root = fetch_distribution(arch)
    wrapper = build_wrapper(arch)
    out = arch_dir(version, arch) / "helper"
    executable = out / "ChromiumHelper"
    stamp = out / "helper.complete"
    wanted = f"{HELPER_RECIPE} {sha1(HELPER_SOURCE)}"
    if executable.exists() and stamp.exists() and stamp.read_text().strip() == wanted:
        return executable
    out.mkdir(parents=True, exist_ok=True)
    print(f"cef.py: compiling the Chromium helper ({arch})", file=sys.stderr)
    command = ["xcrun", "clang++", "-arch", arch, "-isysroot", sdk_path(), "-I", str(dist_root),
               *HELPER_COMPILE_FLAGS, str(HELPER_SOURCE),
               # `-x` applies to every later input; the library is not source.
               "-x", "none", str(wrapper), *HELPER_LINK_FLAGS,
               "-o", str(executable)]
    done = subprocess.run(command, capture_output=True, text=True)
    if done.returncode != 0:
        fail(f"helper compile failed:\n{done.stderr}")
    stamp.write_text(wanted + "\n")
    return executable


def helper_info(executable_name: str, identifier: str) -> dict:
    return {
        "CFBundleDevelopmentRegion": "en",
        "CFBundleDisplayName": executable_name,
        "CFBundleExecutable": executable_name,
        "CFBundleIdentifier": identifier,
        "CFBundleInfoDictionaryVersion": "6.0",
        "CFBundleName": executable_name,
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": pin()["version"].split("+")[0],
        "CFBundleVersion": pin()["version"].split("+")[0],
        "LSEnvironment": {"MallocNanoZone": "0"},
        "LSFileQuarantineEnabled": True,
        "LSMinimumSystemVersion": "13.0",
        "LSUIElement": "1",
        "NSSupportsAutomaticGraphicsSwitching": True,
    }


def embed_helpers(frameworks_dir: Path, state_dir: Path, archs: list[str], identity: str | None,
                  helper_name: str, bundle_id: str) -> None:
    executables = [build_helper_executable(arch) for arch in archs]
    stamp = state_dir / "Chromium Helpers.stamp"
    wanted = json.dumps({
        "recipe": HELPER_RECIPE, "version": pin()["version"], "archs": archs,
        "identity": identity or "", "name": helper_name, "bundle_id": bundle_id,
        "executables": [sha1(e) for e in executables], "target": str(frameworks_dir),
    })
    bundles = [frameworks_dir / f"{helper_name}{suffix}.app" for suffix, _ in HELPER_VARIANTS]
    if stamp.exists() and stamp.read_text() == wanted and all(b.is_dir() for b in bundles):
        return
    frameworks_dir.mkdir(parents=True, exist_ok=True)
    stamp.unlink(missing_ok=True)
    work = Path(tempfile.mkdtemp(dir=state_dir, prefix="helpers."))
    try:
        merged = work / "ChromiumHelper"
        if len(executables) == 1:
            shutil.copy2(executables[0], merged)
        else:
            subprocess.run(["xcrun", "lipo", "-create", *map(str, executables), "-output", str(merged)],
                           check=True)
        for (suffix, id_suffix), bundle in zip(HELPER_VARIANTS, bundles):
            name = f"{helper_name}{suffix}"
            building = work / f"{name}.app"
            macos = building / "Contents" / "MacOS"
            macos.mkdir(parents=True)
            shutil.copy2(merged, macos / name)
            with (building / "Contents" / "Info.plist").open("wb") as handle:
                plistlib.dump(helper_info(name, f"{bundle_id}.helper{id_suffix}"), handle)
            if identity:
                entitlements = work / f"entitlements{id_suffix or '.base'}.plist"
                with entitlements.open("wb") as handle:
                    plistlib.dump({key: True for key in HELPER_ENTITLEMENTS[id_suffix]}, handle)
                codesign(building, identity, entitlements)
            if bundle.exists():
                shutil.rmtree(bundle)
            building.replace(bundle)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    stamp.write_text(wanted)


def codesign(path: Path, identity: str, entitlements: Path | None = None) -> None:
    """Ad hoc (`-`) signs plainly, as Xcode signs a Debug build; a real
    identity adds the hardened runtime, which notarization requires."""
    command = ["codesign", "--force", "--sign", identity]
    if identity != "-":
        command += ["--options", "runtime", "--timestamp=none"]
    if entitlements is not None:
        command += ["--entitlements", str(entitlements)]
    done = subprocess.run([*command, str(path)], capture_output=True, text=True)
    if done.returncode != 0:
        fail(f"codesign {path.name} failed: {done.stderr.strip()}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    commands = parser.add_subparsers(dest="command", required=True)
    fetch_parser = commands.add_parser("fetch")
    fetch_parser.add_argument("--archs", default="arm64")
    stage_parser = commands.add_parser("stage")
    stage_parser.add_argument("--dest", required=True, type=Path)
    stage_parser.add_argument("--archs", required=True)
    embed_parser = commands.add_parser("embed")
    embed_parser.add_argument("--frameworks", required=True, type=Path)
    embed_parser.add_argument("--state", required=True, type=Path)
    embed_parser.add_argument("--archs", required=True)
    embed_parser.add_argument("--sign")
    embed_parser.add_argument("--helper-name", required=True)
    embed_parser.add_argument("--bundle-id", required=True)
    commands.add_parser("version")
    args = parser.parse_args(argv)
    if args.command == "version":
        print(pin()["version"])
    elif args.command == "fetch":
        for arch in normalize_archs(args.archs):
            print(fetch_distribution(arch))
    elif args.command == "stage":
        stage(args.dest, normalize_archs(args.archs))
    elif args.command == "embed":
        embed(args.frameworks, args.state, normalize_archs(args.archs), args.sign or None,
              args.helper_name, args.bundle_id)
    return 0


if __name__ == "__main__":
    sys.exit(main())
