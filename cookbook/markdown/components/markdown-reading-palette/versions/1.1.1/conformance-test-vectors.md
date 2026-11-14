
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| palette-001 | render-children | `<MarkdownReadingPalette><div>Hello</div></MarkdownReadingPalette>` | Rendered output includes `<div>Hello</div>` unchanged |
| palette-002 | theme-data-attributes | `themeId="dark"` (registry theme `dark`, `shikiVariant: "dark"`) | Rendered div has `data-mdv-theme="dark"` and `data-mdv-shiki-variant="dark"` |
| palette-003 | theme-palette-style | `themeId="dark"` (registry theme `dark`'s palette) | Rendered div `style` prop includes `"--mdv-bg": "#0c0c0f"` and `"--mdv-text": "#e8e6e3"` |
| palette-004 | content-class | No className prop supplied | Rendered div has class `adh-mv-content` |
| palette-005 | classname-merge | `className="border rounded"` | Rendered div class attribute includes both `adh-mv-content` and `border rounded` |
| palette-006 | theme-id-prop, data-slot-forwarding | `themeId="light"`, `data-slot="markdown-preview"` | Rendered div has `data-mdv-theme="light"` and `data-slot="markdown-preview"` |
| palette-007 | theme-id-prop | No `themeId` prop supplied | Rendered div uses the `DEFAULT_THEME_ID` (`"dark"`) theme |
| palette-008 | server-safe | Component rendered via `renderToString` inside an async server component | `renderToString` succeeds without throwing, and the component's source file contains no `"use client"` directive and no React hook imports |
| palette-009 | render-children | `<MarkdownReadingPalette>{null}</MarkdownReadingPalette>` | Wrapper div renders with the theme applied and no child content |
| palette-010 | theme-data-attributes, theme-palette-style | `themeId="not-a-real-theme"` | `getThemeById` does not throw; rendered div has `data-mdv-theme="dark"` (the `DEFAULT_THEME_ID` fallback theme) and that theme's palette applied |
| palette-011 | classname-merge | `className="   "` (whitespace only) | Rendered div `class` attribute is exactly `adh-mv-content` |

