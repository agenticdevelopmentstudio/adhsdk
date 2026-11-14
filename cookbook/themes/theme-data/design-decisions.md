
**Decision**: Emit each stylesheet as a string constant in a generated module rather than import the CSS file.
**Rationale**: The comment in `build-theme-data.mjs` says the strings are for `ThemeStyle`'s raw injection, which needs the text at runtime in code that runs without a CSS bundler.
**Approved**: pending

**Decision**: Inline relative `@import` statements and leave remote ones alone.
**Rationale**: The comment in `inline-imports.mjs` says a sheet that shares another's roles holds only its own declarations, so anything that reads it as a whole theme must inline the import; a remote font request is not a file the script can read, so the browser keeps resolving it.
**Approved**: pending

**Decision**: Regenerate the file on install and keep it out of version control.
**Rationale**: The package comments say `postinstall` runs the script so any workspace that links the package gets the file, and the ignore file lists it, which also explains why tests that do not need it stub the module.
**Approved**: pending

**Decision**: Export every `.css` file, including sheets that are not themes.
**Rationale**: Inferred from the script, which has no filter; it keeps the generator trivial, at the cost that sheets such as `accessibilityCss` and `colorModeLightCss` sit beside the theme strings and are not registered in the manifest.
**Approved**: pending

**Decision**: Sort file names before generating.
**Rationale**: Inferred from the script's explicit sort; it makes the output order independent of the directory listing order of the file system.
**Approved**: pending

