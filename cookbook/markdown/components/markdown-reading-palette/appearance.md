
MarkdownReadingPalette does not define its own visual dimensions, spacing, or colors. It always applies the same static `adh-mv-content` class — that class name never changes — plus the selected theme's `--mdv-*` custom properties as inline `style`. Only those custom-property values vary by theme; see `packages/web/packages/markdown/src/themes/palettes.ts` for the four built-in palettes (dark, light, sepia, github).

