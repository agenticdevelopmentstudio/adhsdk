
Vectors 001 to 011 derive from `__tests__/ThemeStyle.test.tsx` and `__tests__/buildScopedCss.test.ts` beside the source; the rest derive from the source. The component tests mock the manifest with a stub theme whose CSS is `:root:not(.dark) { --a: 1; } :root.dark { --a: 2; }`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-style-001 | global-id, inline-style-element, unscoped-passthrough | `ThemeStyle.test.tsx` "renders an unscoped theme inline": `<ThemeStyle theme="stub" />` | a `style` in the render container with id `adh-sdk-theme`, none in `document.head`, body contains `--a: 1` |
| theme-style-002 | scoped-id-prefix, scoped-id-slug | "gives two differently-scoped renders two different ids": scopes `.host-a` and `.host-b` rendered on one page | both ids non-empty and different from each other |
| theme-style-003 | theme-color-mode-type, legacy-root-dark, legacy-root-not-dark | "resolves colorMode dark and light to different CSS": scope `.host`, `colorMode` `dark` then `light` | the two style bodies differ |
| theme-style-004 | system-mode-default | "defaults colorMode to system": scope `.host`, no `colorMode` | body contains `html.dark :scope` and `html:not(.dark) :scope` |
| theme-style-005 | unknown-theme-renders-nothing | "renders nothing for an unknown theme key": `theme="not-a-real-theme"` | render does not throw and no `style` element exists |
| theme-style-006 | html-root-bare, scope-wrapper | `buildScopedCss.test.ts` "rewrites a full-palette theme's dark anchor": input `html:root {` with a custom property, scope `.host` | output contains `:scope {` and `@scope (.host)` |
| theme-style-007 | html-root-light-anchor | "keeps the light block conditional on data-color-mode": input `html:root[data-color-mode]:not(.dark) {...}` | output contains `html[data-color-mode]:not(.dark) :scope {` and no line is a bare `:scope {` |
| theme-style-008 | legacy-root-bare, legacy-root-dark | "still resolves the legacy :root / :root.dark pair": `:root {` and `:root.dark {` blocks | output contains `:scope {` and `html.dark :scope {` |
| theme-style-009 | import-hoisting | "hoists @import above the @scope block": an `@import url('https://fonts.example/x.css');` line then `html:root {` | the `@import` appears before `@scope` in the output |
| theme-style-010 | forced-mode-keeps-dark-block, light-anchor-not-in-lists | "light/dark against dracula" and "leaves charcoal.css byte-identical": dracula with `light`, then `dark`; charcoal with all three modes | dracula `light`: at least two bare `:scope {` rules and no `html[data-color-mode]`; dracula `dark`: contains `:scope.pc-colormode-off {`; charcoal output identical for `system`, `light` and `dark` |
| theme-style-011 | no-anchor-left-behind | "leaves no unrewritten root anchor in any shipped theme": every key in `themeIds`, scope `.host` | no output matches a line-start or comma-preceded `:root` or `html:root` |
| theme-style-012 | html-root-qualified | input `html:root[data-contrast='high'] {` with scope `.host` | output contains `html[data-contrast='high'] :scope {` |
| theme-style-013 | anchors-at-line-start, horizontal-whitespace-only | input with `  html:root {` indented inside a media block, preceded by a blank line | the rule becomes `  :scope {` and the blank line is kept |
| theme-style-014 | body-anchor | input `body {` and `body.dark {` | each becomes `:scope {` and `:scope.dark {` |
| theme-style-015 | scoped-id-slug | scope `Host B > .x` | id is `adh-sdk-theme-scoped-host-b-x-g3a3in` (the run space, `>`, space, `.` collapses to one `-`; the scope is not its own slug, so the FNV-1a hash is appended) |
| theme-style-016 | color-mode-scoped-only | `<ThemeStyle theme="stub" colorMode="dark" />` with no `scope` | body equals the stub CSS exactly |
| theme-style-017 | distinct-scope-ids, scoped-id-prefix | "keeps scopes that differ only in punctuation or case on different ids": scopes `.host-a`, `#host-a`, `.Host-A`, `host-a` | four distinct ids; `host-a` gives `adh-sdk-theme-scoped-host-a`; `.host-a` gives `adh-sdk-theme-scoped-host-a-5l1jl5`; `#host-a` gives `adh-sdk-theme-scoped-host-a-lcrp5y` |
