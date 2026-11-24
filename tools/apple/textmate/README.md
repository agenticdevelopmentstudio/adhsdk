# TextMate resources

`build_textmate_resources.py` builds
`packages/apple/AgenticDeveloperHubSDK/Resources/TextMate/`, the files the
toolkit's syntax highlighter loads: VS Code's `vscode-textmate` engine with its
WASM Oniguruma (`highlighter.js`, `onig.wasm`), the `tm-grammars` grammars and
`tm-themes` themes whose licences allow shipping, `languages.json`, one licence
file per grammar, theme and package under `LICENSES/`, and `manifest.json`
(versions, what was dropped and why, sha256 of every file). The directory
belongs to no framework target; the app copies it into
`Contents/Resources/TextMate/`. Recipe:
`cookbook/foundation/language/textmate-resources`.

```sh
# from the adhsdk repo root
python3 tools/apple/textmate/build_textmate_resources.py --out packages/apple/AgenticDeveloperHubSDK/Resources/TextMate
python3 tools/apple/textmate/build_textmate_resources.py --out packages/apple/AgenticDeveloperHubSDK/Resources/TextMate --check
```

The first writes the tree and prints the counts, the dropped grammars and
themes with their licences, and the total size. The second rebuilds into a
temporary directory and exits 1, listing each path, if the committed tree is
stale. The output depends only on `package-lock.json`.

## Updating a version

Edit the exact version in `package.json`, run `npm install --ignore-scripts`
here to refresh `package-lock.json`, rebuild, and commit `package.json`,
`package-lock.json` and the whole resource tree together. Pick versions
published at least two weeks earlier.

Only grammars and themes licensed MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause,
ISC or Unlicense ship; the licence comes from the package metadata, checked
against the package's NOTICE, which also supplies the licence text.

## The bundle

`entry.js` is bundled by esbuild into an IIFE (`--platform=neutral
--target=safari17`) for a bare JavaScriptCore context. The host defines
`ADKHost.grammarText(scopeName)` returning a grammar's JSON text or `null`,
then calls:

- `ADKHighlighter.create(wasmBytes: ArrayBuffer) -> Promise<void>`
- `ADKHighlighter.setTheme(themeJSON: string)` — a VS Code theme (`colors`,
  `tokenColors`)
- `ADKHighlighter.highlight(text, scopeName) -> Promise<string>` — JSON
  `{"lines": [[[start, length, color, fontStyle], ...], ...]}`, UTF-16
  offsets within each line, font style bits italic 1, bold 2, underline 4,
  strikethrough 8.
  - **Colours** are always uppercase `#RRGGBB`, or `#RRGGBBAA` when the
    theme gives an alpha (the ayu themes, andromeeda and others do). A
    theme's short `#RGB` and `#RGBA` (laserwave, synthwave-84, slack-ochin,
    vesper) come out expanded to those two forms, and nothing else is ever
    emitted.
  - **Lines** are split on `\r\n`, `\r` and `\n`, each counting as one
    break: `"a\rb"`, `"a\nb"` and `"a\r\nb"` are all two lines. A caller
    that maps runs back onto its own text must split the same way.

## The language table

`languages.json` lists each grammar tm-grammars describes (`id` is its
tm-grammars name, so Makefiles are `make`, with alias `makefile`), with the
extensions and filenames linguist gives it. A linguist language feeds a
grammar when its name or an alias matches the grammar's name or an alias
(`C++` reads as `cpp`, `C#` as `csharp`) or when its `tmScope` is the
grammar's scope name. Every extension and filename belongs to exactly one
language: a contested one goes to the linguist language whose name is the
grammar's name, then to the one it is the primary (first) entry of, then to
`CLAIM_OVERRIDES` in the build script (`.h` → `c`). The build fails on a tie
with no override, on a stale override, and when any `CANARIES` lookup (`.md`,
`.cpp`, `.php`, `.ts`, `.rs`, `Makefile`, `.swift`, `.py`, `.json`, `.h`)
comes out wrong.

## Smoke test

From the adhsdk repo root, after a build:

```sh
node -e '
const fs = require("fs"), vm = require("vm");
const dir = "packages/apple/AgenticDeveloperHubSDK/Resources/TextMate";
const manifest = JSON.parse(fs.readFileSync(dir + "/manifest.json", "utf8"));
const byScope = Object.fromEntries(manifest.grammars.map(g => [g.scopeName, dir + "/grammars/" + g.name + ".json"]));
globalThis.ADKHost = { grammarText: s => byScope[s] ? fs.readFileSync(byScope[s], "utf8") : null };
vm.runInThisContext(fs.readFileSync(dir + "/highlighter.js", "utf8"));
const wasm = fs.readFileSync(dir + "/onig.wasm");
(async () => {
  await ADKHighlighter.create(wasm.buffer.slice(wasm.byteOffset, wasm.byteOffset + wasm.byteLength));
  ADKHighlighter.setTheme(fs.readFileSync(dir + "/themes/dark-plus.json", "utf8"));
  const out = JSON.parse(await ADKHighlighter.highlight("let x = 1\n/* a\n comment */\nfunc f() {}", "source.swift"));
  out.lines.forEach((l, i) => console.log(i + 1, JSON.stringify(l)));
})();
'
```

Every line prints non-empty runs; line 1 starts `[0,3,"#569CD6",0]` (`let`
in Dark+'s keyword blue), and line 3 stays comment-coloured because the rule
stack carries over from line 2.
