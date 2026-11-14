
- **Empty styles directory** (MUST): with no `.css` file the script writes the header, a blank line and a trailing newline only, and prints `build-theme-data: 0 themes → src/theme-data.ts`.
- **Empty stylesheet** (MUST): an empty `.css` file yields an export whose value is the empty string.
- **Non-CSS files in the directory** (MUST): a file without the `.css` extension is ignored.
- **Name collision** (not handled): two file names that convert to the same export name, such as `a-b.css` and `aB.css`, would produce a duplicate `export const`; the source does not detect it, and no shipped file collides.
- **Circular import chain** (MUST): a chain `a.css` to `b.css` to `a.css` throws the self-import error rather than recursing forever.
- **Import in a comment** (not handled): the import pattern is matched as text, so a relative `@import` inside a CSS comment is inlined too; `charcoalCss` and `fishlampCss` mention `@import` in comments without a relative path and are unaffected.
- **Import resolves outside the directory** (MUST): a `../` import is resolved against the importing file's directory, so it may read a file outside `src/styles`.
- **Wrong working directory** (MUST): run from another directory, the script resolves `src/styles` there, fails to read it, and writes nothing.
- **Missing file at runtime** (MUST): before the first install or build the file does not exist, so a source-path import of it fails; this is why the package runs the script on `postinstall`.
- **Concurrent runs**: not applicable beyond overwriting; two simultaneous runs write the same bytes to the same path, so the result is the same.
- **Network and offline**: not applicable to the generator, which only reads local files; the remote `@import url(...)` lines it keeps are fetched later by the browser, and a failed font fetch is the browser's concern.
- **Large strings** (MUST): the largest exports are `crtMonitorCss` (about 58,000 characters) and `handheldCommunicatorCss` (about 56,000); the whole file is held in memory and written in one call.

