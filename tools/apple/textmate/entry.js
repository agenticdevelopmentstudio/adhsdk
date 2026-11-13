// The TextMate highlighter that runs inside a bare JavaScriptCore context
// (no Node, no DOM): VS Code's own vscode-textmate engine over VS Code's WASM
// Oniguruma. build_textmate_resources.py bundles this file with esbuild into
// highlighter.js, an IIFE that defines globalThis.ADKHighlighter.
//
// The host supplies one global before calling create:
//   ADKHost.grammarText(scopeName) -> string | null   (a .tmLanguage.json text)
//
// API (every call after create needs create to have resolved):
//   ADKHighlighter.create(wasmBytes: ArrayBuffer) -> Promise<void>
//   ADKHighlighter.setTheme(themeJSON: string)
//   ADKHighlighter.highlight(text: string, scopeName: string) -> Promise<string>
//     resolves to JSON {"lines": [[[start, length, color, fontStyle], ...], ...]}
//     color is uppercase "#RRGGBB" or, when the theme gives an alpha,
//     "#RRGGBBAA" (a theme's "#RGB" and "#RGBA" are expanded to those);
//     start and length in UTF-16 code units within the line; fontStyle the
//     bits italic 1, bold 2, underline 4, strikethrough 8. Lines are split on
//     "\r\n", "\r" and "\n", each one break: "a\rb" and "a\r\nb" are both two
//     lines.
import * as tm from "vscode-textmate";
import * as onig from "vscode-oniguruma";

let registry = null;
const grammars = new Map();

// A VS Code theme -> a vscode-textmate raw theme. The first, scope-less rule
// carries the editor's own foreground and background, as VS Code does; the
// theme's tokenColors follow. A theme whose tokenColors is missing or is not
// an array (a path, in an extension's theme file) contributes no token rules;
// a TextMate-style theme's "settings" array is read in its place.
function rawTheme(theme) {
  const colors = theme.colors || {};
  const rules = Array.isArray(theme.tokenColors)
    ? theme.tokenColors
    : Array.isArray(theme.settings)
      ? theme.settings
      : [];
  return {
    name: theme.name,
    settings: [
      { settings: { foreground: colors["editor.foreground"], background: colors["editor.background"] } },
      ...rules,
    ],
  };
}

// A theme colour as uppercase #RRGGBB or #RRGGBBAA. vscode-textmate admits
// only #RGB, #RGBA, #RRGGBB and #RRGGBBAA into its colour map, so anything else
// is a broken invariant, not a theme to tolerate.
function normalizedColor(color) {
  const hex = /^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.exec(color || "");
  if (!hex) throw new Error("unexpected theme colour " + color);
  const digits = hex[1].length <= 4 ? [...hex[1]].map((d) => d + d).join("") : hex[1];
  return "#" + digits.toUpperCase();
}

function requireRegistry() {
  if (!registry) throw new Error("ADKHighlighter.create has not completed");
  return registry;
}

async function create(wasmBytes) {
  await onig.loadWASM({ instantiator: (imports) => WebAssembly.instantiate(wasmBytes, imports) });
  registry = new tm.Registry({
    onigLib: Promise.resolve({
      createOnigScanner: (patterns) => new onig.OnigScanner(patterns),
      createOnigString: (s) => new onig.OnigString(s),
    }),
    loadGrammar: async (scopeName) => {
      const text = ADKHost.grammarText(scopeName);
      return text ? tm.parseRawGrammar(text, scopeName + ".json") : null;
    },
  });
  grammars.clear();
}

function setTheme(themeJSON) {
  requireRegistry().setTheme(rawTheme(JSON.parse(themeJSON)));
}

async function grammar(scopeName) {
  if (!grammars.has(scopeName)) grammars.set(scopeName, await requireRegistry().loadGrammar(scopeName));
  return grammars.get(scopeName);
}

async function highlight(text, scopeName) {
  const g = await grammar(scopeName);
  if (!g) throw new Error("no grammar for " + scopeName);
  const colorMap = requireRegistry().getColorMap();
  const colors = [];
  const color = (id) => colors[id] ?? (colors[id] = normalizedColor(colorMap[id]));
  let state = tm.INITIAL;
  const lines = [];
  for (const line of text.split(/\r\n|\r|\n/)) {
    const result = g.tokenizeLine2(line, state);
    const tokens = result.tokens;
    const count = tokens.length / 2;
    const runs = [];
    for (let i = 0; i < count; i++) {
      const start = tokens[2 * i];
      const end = i + 1 < count ? tokens[2 * i + 2] : line.length;
      if (end <= start) continue;
      const meta = tokens[2 * i + 1];
      runs.push([start, end - start, color((meta >>> 15) & 0x1ff), (meta >>> 11) & 0xf]);
    }
    lines.push(runs);
    state = result.ruleStack;
  }
  return JSON.stringify({ lines });
}

globalThis.ADKHighlighter = { create, setTheme, highlight };
