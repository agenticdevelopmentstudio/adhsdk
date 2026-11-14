
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| registry-mark-001 | render-link | `profileUrl="https://registry.example.com/user/alice"` | Link href is `https://registry.example.com/user/alice`, target is `_blank`, rel includes `noopener noreferrer` |
| registry-mark-002 | accessible-name | `label="Visit Alice's profile"` | Link's `aria-label` attribute equals `"Visit Alice's profile"` |
| registry-mark-003 | render-at-glyph | Default render | The `<path class="pc-rm-glyph">` inside the SVG has `d` equal to the `AT_GLYPH` constant in `RegistryMark.tsx` (the JetBrains Mono weight-400 "@" outline) |
| registry-mark-004 | render-star | Default render | The `<path class="pc-rm-gold">` has `d` equal to the `STAR` constant in `RegistryMark.tsx` and `fill="#c4a35a"` |
| registry-mark-005 | tint-glyph-with-currentcolor | Ancestor has `style="color: #ff0000"` | `.pc-rm-glyph` path has `fill="currentColor"`, renders red |
| registry-mark-006 | preserve-anchor-geometry | Default render | The root `<span class="pc-registry-mark">` carries inline style `--pc-rm-anchor-x: 50%; --pc-rm-anchor-y: -50%` and computed `transform: translate(50%, -50%)`; combined with the artwork's own center (viewBox point 12,12), this places the @ glyph's center exactly on the top-right corner of the span's border box |
| registry-mark-007 | render-optional-popover | `tip="Bio text here"` | Span with class `pc-rm-tip` containing the tip content is in DOM |
| registry-mark-008 | render-optional-popover | `tip={undefined}` | No `pc-rm-tip` span in DOM |
| registry-mark-009 | hide-svg-from-accessibility-tree | Default render | SVG has `aria-hidden="true"` |
| registry-mark-010 | support-classname | `className="custom-class"` | Root span has both `pc-registry-mark` and `custom-class` classes |
| registry-mark-011 | memoize-rendering | Parent re-renders with referentially-identical props (including a stable `tip`) | A render-count spy (e.g. a ref incremented inside a thin non-memoized wrapper around `RegistryMark`) shows no additional render |
| registry-mark-012 | popover-visible-on-focus-or-hover | Tab moves focus onto a link rendered inside `tip` | `.pc-rm-tip` computed style shows `visibility: visible` and `opacity: 1` (via the companion CSS `:has(:focus-visible)` rule) |
| registry-mark-013 | stable-tip-reference | Host guidance: parent re-renders passing the same `tip` object reference, then a fresh inline JSX `tip` | No additional render with the stable reference; a render with the inline `tip` (this checks the host contract, not component behavior, and extends vector 011 with a `tip` present) |
| registry-mark-014 | clip-safe-placement | Mark rendered as a sibling of the chat frame inside a `position: relative` ancestor, with no intervening `overflow: hidden` | The mark's `getBoundingClientRect()` extends outside the sibling chat frame's border box at the top-right corner, unclipped |
| registry-mark-015 | tip-sibling-of-link | `tip=<a href="https://example.com">more</a>` | The `pc-rm-tip` span is a child of the root `pc-registry-mark` span and a sibling of `a.pc-rm-link`; no `pc-rm-tip` element is inside the `a.pc-rm-link` |
