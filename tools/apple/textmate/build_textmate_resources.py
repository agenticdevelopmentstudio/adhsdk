#!/usr/bin/env python3
"""Build the TextMate resources the syntax highlighter loads.

    python3 build_textmate_resources.py --out <dir>          # write the tree
    python3 build_textmate_resources.py --out <dir> --check  # exit 1 if <dir> is stale

Every input comes from the npm packages pinned in package.json and
package-lock.json beside this file: `npm ci` installs them, esbuild bundles
entry.js (vscode-textmate + vscode-oniguruma) into highlighter.js, and the
grammars, themes, language table, licences and a manifest are written next to
it. The output is a pure function of the lock file, so --check rebuilds into a
temporary directory and compares byte for byte.

Grammars and themes are shipped only when their licence (tm-grammars /
tm-themes metadata, cross-checked against the package's NOTICE) is one of
ALLOWED_LICENSES. Each shipped grammar and theme gets its own licence file
under LICENSES/, holding the licence text the package's NOTICE carries for it.
"""
import argparse
import filecmp
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
MODULES = os.path.join(HERE, "node_modules")
ALLOWED_LICENSES = ("MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "ISC", "Unlicense")
ESBUILD_ARGS = ["--bundle", "--format=iife", "--platform=neutral", "--target=safari17", "--main-fields=module,main"]
PACKAGES = ("esbuild", "linguist-languages", "tm-grammars", "tm-themes", "vscode-oniguruma", "vscode-textmate")
# Licence files of the packages whose code or data ships, as LICENSES/package-<key>.txt.
PACKAGE_LICENSES = {
    "esbuild": "esbuild/LICENSE.md",
    "linguist-languages": "linguist-languages/LICENSE",
    "linguist-languages-notices": "linguist-languages/ThirdPartyNoticeText.txt",
    "tm-grammars": "tm-grammars/LICENSE",
    "tm-themes": "tm-themes/LICENSE",
    "vscode-oniguruma": "vscode-oniguruma/LICENSE.txt",
    "vscode-oniguruma-notices": "vscode-oniguruma/NOTICES.txt",
    "vscode-textmate": "vscode-textmate/LICENSE.md",
}

# Prints the packages' metadata as one JSON object; tm-grammars, tm-themes and
# linguist-languages publish it only as ES modules.
METADATA_JS = """
import { grammars } from "tm-grammars";
import { themes } from "tm-themes";
import * as linguist from "linguist-languages";
const languages = Object.values(linguist).map((l) => ({
  name: l.name, tmScope: l.tmScope ?? null, extensions: l.extensions ?? [], filenames: l.filenames ?? [],
}));
process.stdout.write(JSON.stringify({ grammars, themes, languages }));
"""


def run_tool(argv):
    result = subprocess.run(argv, cwd=HERE, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"{' '.join(argv)} failed ({result.returncode}):\n{result.stdout}{result.stderr}")
    return result.stdout


def json_text(value):
    return json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def write_text(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def module_text(relpath):
    with open(os.path.join(MODULES, relpath), encoding="utf-8") as f:
        return f.read()


def parse_notice(relpath):
    """file name -> {"spdx", "url", "text"} from a tm-grammars / tm-themes NOTICE."""
    sections = re.split(r"^={50,}\n(?=Files:)", module_text(relpath), flags=re.M)[1:]
    entries = {}
    for section in sections:
        rule = re.search(r"^-{50,}\n", section, flags=re.M)
        head, body = section[: rule.start()], section[rule.end():]
        fields = dict(re.findall(r"^(\w+):\s+(.*)$", head, flags=re.M))
        entry = {"spdx": fields["SPDX"], "url": fields["License"], "text": body.strip() + "\n"}
        for name in re.split(r",\s*", fields["Files"].strip()):
            entries[name] = entry
    return entries


def licence_text(subject, source, entry):
    lines = [subject]
    if source:
        lines.append(f"Source: {source}")
    lines += [f"License: {entry['url']}", f"SPDX: {entry['spdx']}", "", entry["text"]]
    return "\n".join(lines)


def build_tree(out):
    """Write the whole resource tree into the empty directory `out`; return a summary."""
    run_tool(["npm", "ci", "--ignore-scripts", "--no-audit", "--no-fund"])
    versions = {name: json.loads(module_text(f"{name}/package.json"))["version"] for name in PACKAGES}
    meta = json.loads(run_tool(["node", "--input-type=module", "-e", METADATA_JS]))

    run_tool([os.path.join(MODULES, ".bin", "esbuild"), "entry.js", *ESBUILD_ARGS,
              "--outfile=" + os.path.join(out, "highlighter.js"), "--log-level=warning"])
    shutil.copyfile(os.path.join(MODULES, "vscode-oniguruma/release/onig.wasm"), os.path.join(out, "onig.wasm"))
    for key, relpath in PACKAGE_LICENSES.items():
        write_text(os.path.join(out, "LICENSES", f"package-{key}.txt"), module_text(relpath))

    # Grammars: every file in tm-grammars/grammars, including the ones that exist
    # only to be embedded (they have a NOTICE entry but no metadata row).
    notice = parse_notice("tm-grammars/NOTICE")
    rows = {g["name"] + ".json": g for g in meta["grammars"]}
    grammar_dir = os.path.join(MODULES, "tm-grammars/grammars")
    kept, dropped = [], []
    for file in sorted(os.listdir(grammar_dir)):
        name = file[: -len(".json")]
        row, entry = rows.get(file), notice.get(file)
        licence = row.get("license") if row else (entry["spdx"] if entry else None)
        if row and entry and row.get("license") != entry["spdx"]:
            sys.exit(f"{file}: metadata licence {row.get('license')} != NOTICE {entry['spdx']}")
        if licence not in ALLOWED_LICENSES:
            dropped.append({"name": name, "license": licence or "none"})
            continue
        if not entry:
            sys.exit(f"{file}: licence {licence} but no licence text in tm-grammars/NOTICE")
        text = module_text(f"tm-grammars/grammars/{file}")
        write_text(os.path.join(out, "grammars", file), text)
        write_text(os.path.join(out, "LICENSES", f"grammar-{name}.txt"),
                   licence_text(f"grammars/{file} (tm-grammars {versions['tm-grammars']})",
                                row and row.get("source"), entry))
        kept.append({"name": name, "scopeName": json.loads(text)["scopeName"], "license": licence,
                     "row": row})

    # Languages: the kept grammars tm-grammars lists, joined to linguist by scope name.
    languages = []
    for g in kept:
        if not g["row"]:
            continue
        matches = [lang for lang in meta["languages"] if lang["tmScope"] == g["scopeName"]]
        languages.append({
            "id": g["name"], "scopeName": g["scopeName"], "aliases": g["row"].get("aliases", []),
            "extensions": sorted({e for lang in matches for e in lang["extensions"]}),
            "filenames": sorted({n for lang in matches for n in lang["filenames"]}),
        })
    write_text(os.path.join(out, "languages.json"), json_text(languages))

    # Themes, under the same licence rule.
    theme_notice = parse_notice("tm-themes/NOTICE")
    themes, dropped_themes = [], []
    for row in sorted(meta["themes"], key=lambda t: t["name"]):
        file = row["name"] + ".json"
        if row.get("license") not in ALLOWED_LICENSES:
            dropped_themes.append({"name": row["name"], "license": row.get("license") or "none"})
            continue
        entry = theme_notice.get(file)
        if not entry or entry["spdx"] != row["license"]:
            sys.exit(f"theme {file}: no matching licence text in tm-themes/NOTICE")
        write_text(os.path.join(out, "themes", file), module_text(f"tm-themes/themes/{file}"))
        write_text(os.path.join(out, "LICENSES", f"theme-{row['name']}.txt"),
                   licence_text(f"themes/{file} (tm-themes {versions['tm-themes']})", row.get("source"), entry))
        themes.append({"name": row["name"], "displayName": row["displayName"], "type": row.get("type"),
                       "license": row["license"]})

    files = {}
    for path in tree_paths(out):
        with open(os.path.join(out, path), "rb") as f:
            files[path] = hashlib.sha256(f.read()).hexdigest()
    manifest = {
        "versions": versions,
        "esbuild": ESBUILD_ARGS,
        "allowedLicenses": list(ALLOWED_LICENSES),
        "grammars": [{k: g[k] for k in ("name", "scopeName", "license")} for g in kept],
        "themes": themes,
        "dropped": {"grammars": dropped, "themes": dropped_themes},
        "files": files,
    }
    write_text(os.path.join(out, "manifest.json"), json_text(manifest))
    size = sum(os.path.getsize(os.path.join(out, p)) for p in tree_paths(out))
    return {"grammars": len(kept), "languages": len(languages), "dropped": dropped,
            "themes": len(themes), "droppedThemes": dropped_themes, "files": len(files) + 1, "bytes": size}


def tree_paths(root):
    return sorted(os.path.relpath(os.path.join(r, n), root) for r, _, ns in os.walk(root) for n in ns)


def stale_paths(fresh, existing):
    if not os.path.isdir(existing):
        return [f"{existing} does not exist"]
    a, b = set(tree_paths(fresh)), set(tree_paths(existing))
    lines = [f"missing: {p}" for p in sorted(a - b)]
    lines += [f"unexpected: {p}" for p in sorted(b - a)]
    lines += [f"differs: {p}" for p in sorted(a & b)
              if not filecmp.cmp(os.path.join(fresh, p), os.path.join(existing, p), shallow=False)]
    return lines


def print_summary(summary):
    print(f"grammars: {summary['grammars']} kept ({summary['languages']} languages), "
          f"{len(summary['dropped'])} dropped by licence")
    for d in summary["dropped"]:
        print(f"  dropped grammar {d['name']} ({d['license']})")
    print(f"themes: {summary['themes']} kept, {len(summary['droppedThemes'])} dropped by licence")
    for d in summary["droppedThemes"]:
        print(f"  dropped theme {d['name']} ({d['license']})")
    print(f"files: {summary['files']}, total {summary['bytes']:,} bytes ({summary['bytes'] / 1e6:.1f} MB)")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", required=True, help="the resource directory (S/Resources/TextMate)")
    parser.add_argument("--check", action="store_true", help="rebuild into a temp dir; exit 1 if --out differs")
    args = parser.parse_args()
    out = os.path.abspath(args.out)

    with tempfile.TemporaryDirectory(prefix="textmate-") as scratch:
        fresh = os.path.join(scratch, "TextMate")
        os.makedirs(fresh)
        summary = build_tree(fresh)
        print_summary(summary)
        if args.check:
            lines = stale_paths(fresh, out)
            for line in lines:
                print(line)
            print(f"{out}: " + (f"stale, {len(lines)} differences" if lines else "up to date"))
            sys.exit(1 if lines else 0)
        if os.path.isdir(out) and os.listdir(out) and not os.path.isfile(os.path.join(out, "manifest.json")):
            sys.exit(f"{out} is not empty and has no manifest.json; refusing to replace it")
        shutil.rmtree(out, ignore_errors=True)
        shutil.copytree(fresh, out)
        print(f"wrote {out}")


if __name__ == "__main__":
    main()
