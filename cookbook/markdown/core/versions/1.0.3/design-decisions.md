
- **Decision**: Keep `FenceScanner` (CommonMark-correct, used for rendering) and `MarkdownText.titleSearchBody` (adh's lazy-paired-fence regex, used only for title/excerpt derivation) as two deliberately separate scanners rather than unifying them.
  **Rationale**: The two answer different questions — a renderer must reject false-positive fences the way CommonMark requires, while adh's own title/excerpt derivation is pinned byte-for-byte to a lazy-regex quirk (see MarkdownTextTests "a fenced code block is not a title"). Unifying them would either break renderer correctness or silently move the title column on the next sync with adh's backend.
  **Approved**: pending
- **Decision**: Do not adopt a full YAML parser in the Apple `Frontmatter`/`YAMLScalar` implementation; keep the hand-rolled scalar reader/writer and accept its documented divergences from adh's real parser (block sequences flatten to `null`, flow mappings/block scalars/aliases pass through as literal text, a malformed block still yields readable keys instead of nulling entirely).
  **Rationale**: `FenceScanner`/`Frontmatter` compile into all five platform frameworks from one Foundation-only source; a real YAML parser is a foundation-tier commitment the toolkit has not made. The three MarkdownAdhParityTests DIVERGENCE cases pin the resulting behavior as tested fact rather than leaving it as a silent surprise.
  **Approved**: pending
- **Decision**: Track three separate unit systems across `MarkdownText` — UTF-16 code units for title truncation and JS `.slice()` parity, Unicode scalars for the excerpt source window and Postgres `left()` parity, and grapheme clusters (`Character.isNewline`) for `FenceScanner`'s line splitting — rather than one unit throughout.
  **Rationale**: Each unit mirrors a specific counterpart the Apple port must stay identical with (JavaScript, PostgreSQL, and CommonMark line semantics, respectively); collapsing to one unit would silently break parity with whichever counterpart that unit doesn't match.
  **Approved**: pending
- **Decision**: Rewrite the web `document-title.ts` from a line-regex approach to the real `yaml` package (`parseYaml`/`parseDocument`/`Document`), rather than mirroring the Apple side's hand-rolled scalar approach.
  **Rationale**: A prior line-regex implementation corrupted a folded (`>-`) title scalar on save, and because the backend fails the whole `frontmatter` jsonb column to null on any unparseable YAML, that one bad write silently destroyed `adh_source` and `summary` alongside it. The web package already runs on the Node.js runtime the real `yaml` package targets, so there is no five-platform-portability cost to paying for a real parser there.
  **Approved**: pending
- **Decision**: Run shiki syntax highlighting before `rehype-sanitize` in `process-markdown.ts`'s pipeline, and scope the `style` attribute allowlist to `pre`/`code`/`span` only (leaving `className` allowed globally).
  **Rationale**: Highlighting must run first because it produces real hast element nodes for the sanitizer to filter — sanitizing first would strip the highlighter's own token markup. Scoping `style` to those three tags, rather than allowing it globally, lets shiki's dual-theme CSS variables through while closing the inline-style XSS vector everywhere else; `className` stays allowed globally so structural classes such as `remark-adh-alerts`'s `adh-mv-alert` markup survive sanitization.
  **Approved**: pending
- **Decision**: Look up a viewer theme by `id` in `getThemeById`, falling back to the theme whose id equals `DEFAULT_THEME_ID`, rather than falling back to `VIEWER_THEMES[0]`.
  **Rationale**: A separate no-flash bootstrap script outside these sources also falls back by `DEFAULT_THEME_ID`; a position-based fallback here would diverge from it the moment `VIEWER_THEMES` is reordered, producing a theme flash on reload for an unknown id.
  **Approved**: pending
- **Decision**: Confine every concrete color literal to `palettes.ts` (the "STANDING palette exception"), and keep shiki's own code-block colors out of it entirely.
  **Rationale**: Centralizing color literals in one module lets every other module in the package, and consumers of `registry.ts`, style purely from `--mdv-*` custom properties, with no per-theme branch anywhere else in the render path; shiki's colors are excluded because they come from its own theme files, not this palette.
  **Approved**: pending

