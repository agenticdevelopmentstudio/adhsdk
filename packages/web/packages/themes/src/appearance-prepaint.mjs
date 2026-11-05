// The pre-paint appearance script, and a Vite plugin that inlines it.
//
// Plain `.mjs`, deliberately, like materialize-fonts.mjs: a vite.config or next.config runs in
// plain Node before any bundler exists, so it can load this file but not the TypeScript beside
// it. appearance.ts imports the storage key, the pref lists and the script from here, so the
// browser code, the script and the config-time plugin share one definition.

export const APPEARANCE_STORAGE_KEY = "adh:appearance";

/**
 * The enum prefs and the value that means "leave the attribute off" (so the
 * matching `@media` query governs). Shared by applyAppearance and the pre-paint
 * script so the two can't drift. The dataset key (camelCase) maps to the kebab
 * `data-*` the CSS reads, e.g. `reduceMotion` → `data-reduce-motion`.
 */
export const ENUM_PREF_DEFAULTS = Object.freeze({
  reduceMotion: "auto",
  contrast: "default",
  textSize: "default",
  spacing: "compact",
});

/** Boolean prefs: present as `data-*="always"` when on, removed when off. */
export const BOOL_PREFS = Object.freeze(["focusOutlines", "underlineLinks"]);

// The enum/bool attribute statements for the pre-paint script, generated from
// the SAME lists applyAppearance uses — add a pref in one place and both follow.
const PREPAINT_ATTR_LINES = [
  ...Object.entries(ENUM_PREF_DEFAULTS).map(
    ([k, dflt]) => `s(${JSON.stringify(k)},p.${k}&&p.${k}!==${JSON.stringify(dflt)}?p.${k}:null);`,
  ),
  ...BOOL_PREFS.map((k) => `s(${JSON.stringify(k)},p.${k}?"always":null);`),
].join("");

/**
 * A self-contained IIFE (as a string) that reads the stored preferences and
 * applies them to <html> synchronously, before first paint, to avoid a flash of
 * unstyled / wrong-sized content. Inline it in <head> via
 * `<script dangerouslySetInnerHTML={{ __html: APPEARANCE_PREPAINT_SCRIPT }} />`,
 * or in a Vite app with `appearancePrepaint()`.
 *
 * The attribute statements are generated from ENUM_PREF_DEFAULTS / BOOL_PREFS,
 * the same lists applyAppearance iterates, so the two stay in lock-step.
 *
 * What it reads is a CACHE, not the truth: localStorage holds whatever this browser
 * last saw, so a returning signed-in user repaints in their own colour mode with no
 * flash. The truth arrives moments later from the server (AppearanceSync), which
 * corrects the document if they differ — and clears the cache on sign-out, so the
 * next visitor to this browser starts from the OS setting rather than inheriting a
 * stranger's theme. With no cache at all, `colorMode` is absent ⇒ `auto` ⇒ the OS.
 */
export const APPEARANCE_PREPAINT_SCRIPT = `(function(){try{
var el=document.documentElement;
var raw=localStorage.getItem(${JSON.stringify(APPEARANCE_STORAGE_KEY)});
var p=raw&&typeof JSON.parse(raw)==="object"?JSON.parse(raw):{};
var dark=p.colorMode==="light"?false:p.colorMode==="dark"?true:matchMedia("(prefers-color-scheme: dark)").matches;
el.classList.toggle("dark",dark);
el.dataset.colorMode=p.colorMode||"auto";
function s(k,v){if(v==null){delete el.dataset[k];}else{el.dataset[k]=v;}}
${PREPAINT_ATTR_LINES}
}catch(e){}})();`;

/**
 * A Vite plugin that inlines APPEARANCE_PREPAINT_SCRIPT into the page's <head>.
 *
 * It goes in at the end of <head> ("head"), not the start: prepended, it and the dev
 * server's own preamble push `<meta charset>` past the first 1024 bytes, where browsers
 * stop looking for the encoding. A script anywhere in <head> still runs before the body
 * paints.
 */
export function appearancePrepaint() {
  return {
    name: "adh-appearance-prepaint",
    transformIndexHtml: () => [
      { tag: "script", children: APPEARANCE_PREPAINT_SCRIPT, injectTo: "head" },
    ],
  };
}
