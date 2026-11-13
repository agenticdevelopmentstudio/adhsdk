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
# Extensions linguist gives to more than one shipped grammar with equal standing
# (see join_languages), and the grammar each goes to.
CLAIM_OVERRIDES = {
    ".cake": "csharp", ".cgi": "perl", ".ddl": "sql", ".es": "javascript", ".fcgi": "perl", ".h": "c",
    ".hh": "cpp", ".inc": "php", ".pl": "perl", ".pluginspec": "ruby", ".pm": "perl", ".prc": "sql",
    ".pro": "prolog", ".sch": "scheme", ".spec": "python", ".t": "perl", ".v": "verilog",
}
# Lookups the build refuses to ship wrong: (kind, item) -> the one language id that must own it.
CANARIES = {
    ("extensions", ".md"): "markdown", ("extensions", ".cpp"): "cpp", ("extensions", ".php"): "php",
    ("extensions", ".ts"): "typescript", ("extensions", ".rs"): "rust", ("filenames", "Makefile"): "make",
    ("extensions", ".swift"): "swift", ("extensions", ".py"): "python", ("extensions", ".json"): "json",
    ("extensions", ".h"): "c",
}

# Prints the packages' metadata as one JSON object; tm-grammars, tm-themes and
# linguist-languages publish it only as ES modules.
METADATA_JS = """
import { grammars } from "tm-grammars";
import { themes } from "tm-themes";
import * as linguist from "linguist-languages";
const languages = Object.values(linguist).map((l) => ({
  name: l.name, aliases: l.aliases ?? [], tmScope: l.tmScope ?? null,
  extensions: l.extensions ?? [], filenames: l.filenames ?? [],
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


def linguist_key(name):
    """A linguist name or alias in tm-grammars' spelling: "C++" -> "cpp", "C#" -> "csharp"."""
    return name.lower().replace(" ", "-").replace("++", "pp").replace("#", "sharp")


def join_languages(grammars, linguist):
    """languages.json: each listed grammar with the extensions and filenames linguist gives it.

    A linguist language feeds a grammar when its name or an alias (linguist_key)
    is the grammar's name or an alias, or when its tmScope is the grammar's scope
    name. An extension or filename more than one grammar is fed goes to the
    strongest claim: a linguist language whose name is the grammar's name beats
    an alias match, which beats a scope match; then an item that is the linguist
    language's first (primary) entry beats one that is not. What still ties is
    settled by CLAIM_OVERRIDES, and the build fails on anything left, on a stale
    override, and on any CANARIES entry that does not come out as stated.
    """
    claims = {}  # (kind, item) -> {grammar name: strength}
    for g in grammars:
        names = {g["name"], *g["row"].get("aliases", [])}
        for lang in linguist:
            named = bool({linguist_key(n) for n in (lang["name"], *lang["aliases"])} & names)
            if not named and lang["tmScope"] != g["scopeName"]:
                continue
            match = 2 if linguist_key(lang["name"]) == g["name"] else 1 if named else 0
            for kind in ("extensions", "filenames"):
                for index, item in enumerate(lang[kind]):
                    strength = (match, 1 if index == 0 else 0)
                    claimants = claims.setdefault((kind, item), {})
                    claimants[g["name"]] = max(claimants.get(g["name"], strength), strength)

    owners, ties = {}, []
    for key, claimants in sorted(claims.items()):
        top = max(claimants.values())
        best = sorted(name for name, strength in claimants.items() if strength == top)
        override = CLAIM_OVERRIDES.get(key[1])
        if override and len(claimants) > 1 and override in claimants:
            owners[key] = override
        elif len(best) == 1:
            owners[key] = best[0]
        else:
            ties.append(f"{key[1]}: {', '.join(best)}")
    contested = {key[1] for key, claimants in claims.items() if len(claimants) > 1}
    stale = [f"{item} -> {name}" for item, name in sorted(CLAIM_OVERRIDES.items())
             if item not in contested or not any(owners.get((k, item)) == name for k in ("extensions", "filenames"))]
    if ties or stale:
        sys.exit("languages.json: unresolved claims (add to CLAIM_OVERRIDES):\n  " + "\n  ".join(ties)
                 + ("\nstale CLAIM_OVERRIDES entries:\n  " + "\n  ".join(stale) if stale else ""))

    languages = []
    for g in grammars:
        mine = {kind: sorted(item for (k, item), name in owners.items() if k == kind and name == g["name"])
                for kind in ("extensions", "filenames")}
        languages.append({"id": g["name"], "scopeName": g["scopeName"], "aliases": g["row"].get("aliases", []),
                          **mine})

    counts = {}
    for lang in languages:
        for kind in ("extensions", "filenames"):
            for item in lang[kind]:
                counts.setdefault((kind, item), []).append(lang["id"])
    doubled = [f"{item}: {', '.join(ids)}" for (_, item), ids in sorted(counts.items()) if len(ids) != 1]
    wrong = [f"{item} -> {counts.get((kind, item), ['nothing'])} (want {want})"
             for (kind, item), want in CANARIES.items() if counts.get((kind, item)) != [want]]
    if doubled or wrong:
        sys.exit("languages.json: canaries or uniqueness failed:\n  " + "\n  ".join(doubled + wrong))
    return languages


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

    languages = join_languages([g for g in kept if g["row"]], meta["languages"])
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
    unclaimed = sum(1 for lang in languages if not lang["extensions"] and not lang["filenames"])
    return {"grammars": len(kept), "languages": len(languages), "unclaimed": unclaimed, "dropped": dropped,
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
    print(f"grammars: {summary['grammars']} kept ({summary['languages']} languages, "
          f"{summary['unclaimed']} with no extension or filename), {len(summary['dropped'])} dropped by licence")
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
