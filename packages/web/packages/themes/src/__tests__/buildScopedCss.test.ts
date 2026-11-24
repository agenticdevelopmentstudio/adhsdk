import { describe, expect, it } from 'vitest'
import { buildScopedCss } from '../ThemeStyle'
import { themes, themeIds } from '../manifest'

describe('buildScopedCss', () => {
  it('theme-style-006 rewrites a full-palette theme’s dark anchor to :scope', () => {
    const out = buildScopedCss('html:root {\n  --color-surface: #000;\n}\n', '.host')
    expect(out).toContain(':scope {')
    expect(out).toContain('@scope (.host)')
  })

  it('theme-style-007 keeps the light block conditional on data-color-mode', () => {
    const out = buildScopedCss(
      'html:root[data-color-mode]:not(.dark) {\n  --color-surface: #fff;\n}\n',
      '.host',
    )
    expect(out).toContain('html[data-color-mode]:not(.dark) :scope {')
    // The light block must NOT collapse to an unconditional `:scope`, which would make it
    // win in dark mode too (it is the later rule).
    expect(out).not.toMatch(/^:scope \{/m)
  })

  // Contract regression test: no theme in src/styles/ exercises this path today — the
  // :root / :root.dark pair was converted away from before this repo went public — but
  // buildScopedCss is a public export, and an external consumer's stylesheet may still
  // be in this shape. Keep resolving it even though nothing shipped here still does.
  it('theme-style-008 still resolves the legacy :root / :root.dark anchor pair for external consumers', () => {
    const out = buildScopedCss(':root {\n  --a: 1;\n}\n:root.dark {\n  --a: 2;\n}\n', '.host')
    expect(out).toContain(':scope {')
    expect(out).toContain('html.dark :scope {')
  })

  it('theme-style-009 hoists @import above the @scope block', () => {
    const css = "@import url('https://fonts.example/x.css');\nhtml:root {\n  --a: 1;\n}\n"
    const out = buildScopedCss(css, '.host')
    expect(out.indexOf('@import')).toBeLessThan(out.indexOf('@scope'))
  })

  // The guard that matters: a root anchor this function does not know about survives into
  // the output, matches nothing inside the scope, and drops that theme's entire palette
  // with no error. Assert on the REAL stylesheets so a newly-authored anchor form fails
  // here instead of silently un-theming a scoped surface.
  it('theme-style-011 leaves no unrewritten root anchor in any shipped theme', () => {
    for (const key of themeIds) {
      const scoped = buildScopedCss(themes[key].css, '.host')
      expect(scoped, key).not.toMatch(/(^|,\s*)(html)?:root\b/m)
    }
  })

  // colorMode's own coverage, against the real corpus rather than a stub: 27 of the 41
  // shipped stylesheets pair a bare `html:root` dark block with an `html:root[data-color-
  // mode]:not(.dark)` light block as two separate rules (dracula.css is typical — a
  // 91-declaration dark block followed by an 85-declaration light one). Before the
  // HTML_ROOT_LIGHT_ANCHOR_RE fix, colorMode had no effect on any of them: the light
  // block's discriminator was left standing regardless of the forced mode, so only the
  // document's real `data-color-mode` attribute — never the `colorMode` prop — decided
  // which block actually applied.
  describe('colorMode, against a real paired html:root theme (dracula)', () => {
    it('theme-style-010a "system" leaves the light block conditional on data-color-mode (no regression)', () => {
      const out = buildScopedCss(themes.dracula.css, '.host', 'system')
      expect(out).toContain(':scope {')
      expect(out).toContain('html[data-color-mode]:not(.dark) :scope {')
    })

    it('theme-style-010b "light" collapses the light block to :scope too, so it wins by source order', () => {
      const out = buildScopedCss(themes.dracula.css, '.host', 'light')
      // Neither block was dropped — the dark block from HTML_ROOT_RE is untouched by
      // colorMode by design, and the light block's discriminator is gone, not the block
      // itself. Both are now the same bare selector; the light block, later in source,
      // is what the cascade actually renders. (dracula.css also has a `body { }` rule,
      // rewritten to a third `:scope {` unrelated to color mode — count at least 2, not
      // exactly 2.)
      const bareScopeBlocks = out.match(/(^|\n):scope \{/g) ?? []
      expect(bareScopeBlocks.length).toBeGreaterThanOrEqual(2)
      // The literal rewritten selector, not the substring "data-color-mode" alone — the
      // file's own header comment discusses the discriminator in prose and would give a
      // false failure otherwise.
      expect(out).not.toContain('html[data-color-mode]')
    })

    it('theme-style-010c "dark" drops the light block with a never-matching selector', () => {
      const out = buildScopedCss(themes.dracula.css, '.host', 'dark')
      expect(out).toContain(':scope.pc-colormode-off {')
      expect(out).not.toContain('html[data-color-mode]')
    })
  })

  // charcoal.css and fishlamp.css are "dark-always" — one combined selector list
  // (`html:root, html:root[data-color-mode]:not(.dark), …[data-contrast=…] { }`) with no
  // separate light palette. HTML_ROOT_LIGHT_ANCHOR_RE must not fire inside that list: its
  // qualified members are either not the sole selector of their rule (comma-joined to
  // siblings) or carry a contrast qualifier alongside the discriminator, and either
  // property alone keeps this anchor out. Assert charcoal's real stylesheet is genuinely
  // byte-identical across all three modes — forcing its light selector to win, when it has
  // no light palette, is the regression this corpus shape exists to catch.
  it('theme-style-010d leaves charcoal.css (dark-always, no light palette) byte-identical across colorModes', () => {
    const system = buildScopedCss(themes.charcoal.css, '.host', 'system')
    const light = buildScopedCss(themes.charcoal.css, '.host', 'light')
    const dark = buildScopedCss(themes.charcoal.css, '.host', 'dark')
    expect(light).toBe(system)
    expect(dark).toBe(system)
  })

  it('theme-style-012 a qualified html:root anchor moves its qualifiers onto an html ancestor', () => {
    const out = buildScopedCss("html:root[data-contrast='high'] {\n  --a: 1;\n}\n", '.host')
    expect(out).toContain("html[data-contrast='high'] :scope {")
  })

  it('theme-style-013 an indented anchor is rewritten and a preceding blank line is kept', () => {
    const out = buildScopedCss('@media (x) {\n\n  html:root {\n    --a: 1;\n  }\n}\n', '.host')
    expect(out).toContain('{\n\n  :scope {\n')
  })

  it('theme-style-014 body selectors become :scope', () => {
    const out = buildScopedCss('body {\n  --a: 1;\n}\nbody.dark {\n  --a: 2;\n}\n', '.host')
    expect(out).toContain(':scope {')
    expect(out).toContain(':scope.dark {')
    expect(out).not.toMatch(/^body/m)
  })

  it('theme-style-018 only the unquoted url() import form is hoisted', () => {
    expect(buildScopedCss("@import 'a.css';\nhtml:root { --a: 1; }", '.host')).toBe(
      "\n@scope (.host) {\n@import 'a.css';\n:scope { --a: 1; }\n}",
    )
  })

  it('theme-style-019 the scope is inserted as given, with no escaping', () => {
    expect(buildScopedCss('body {}', '.a > .b')).toBe('\n@scope (.a > .b) {\n:scope {}\n}')
  })

  it('theme-style-020 :root:not(.dark) follows colorMode, and an empty stylesheet still wraps', () => {
    expect(buildScopedCss(':root:not(.dark) {}', '.host', 'system')).toBe(
      '\n@scope (.host) {\nhtml:not(.dark) :scope {}\n}',
    )
    expect(buildScopedCss(':root:not(.dark) {}', '.host', 'light')).toBe('\n@scope (.host) {\n:scope {}\n}')
    expect(buildScopedCss(':root:not(.dark) {}', '.host', 'dark')).toBe(
      '\n@scope (.host) {\n:scope.pc-colormode-off {}\n}',
    )
    expect(buildScopedCss('', '.host')).toBe('\n@scope (.host) {\n\n}')
  })

  it('theme-style-021 known limitation: the discriminator last in a comma list gets the colorMode rewrite', () => {
    expect(buildScopedCss('html:root, html:root[data-color-mode]:not(.dark) {}', '.host')).toBe(
      '\n@scope (.host) {\n:scope, html[data-color-mode]:not(.dark) :scope {}\n}',
    )
  })
})
