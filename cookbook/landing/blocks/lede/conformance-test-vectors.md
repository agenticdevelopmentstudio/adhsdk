
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| lede-001 | render-as-paragraph | `<Lede>Text</Lede>` | Element is rendered as `<p>` in the DOM |
| lede-002 | render-children | `<Lede>Hello World</Lede>` | Text content "Hello World" appears in paragraph |
| lede-003 | apply-lede-class | `<Lede>Text</Lede>` | Rendered element includes `lp-lede` class |
| lede-004 | accept-additional-class | `<Lede className="extra">Text</Lede>` | Rendered element includes both `lp-lede` and `extra` classes |
| lede-005 | clean-class-attribute | `<Lede className={undefined}>Text</Lede>` | Rendered element class is `lp-lede` only (undefined filtered out) |
| lede-006 | clean-class-attribute | `<Lede className="">Text</Lede>` | Rendered element class is `lp-lede` only (empty string filtered out) |
| lede-007 | Edge Case: whitespace-only className | `<Lede className=" ">Text</Lede>` | Rendered element class attribute is `lp-lede  ` (two spaces): a whitespace-only value is truthy, so it is not filtered and leaves a stray blank token. This documents current behavior and is not a requirement; **clean-class-attribute** covers only `undefined`, `null` and `""`. |
| lede-008 | constrain-paragraph-measure | `<Lede>Text</Lede>` | The `.lp-lede` rule in `blocks.css` declares `max-width: 72ch` (jsdom applies no stylesheets and `getComputedStyle` reports pixels, so assert the rule text, or use a Playwright check of the rendered width) |
| lede-009 | Edge Case: empty children | `<Lede></Lede>` | Component renders `<p class="lp-lede"></p>` with no children guard |
| lede-010 | accept-additional-class | `<Lede className="a b">Text</Lede>` | Rendered element class is `lp-lede a b` |
| lede-011 | meet-contrast-ratio | Rendered paragraph with `--lp-ink-dim` unset (fallback `#a0a0a0`) on the host's page background | The contrast ratio between `#a0a0a0` and the background is at least 4.5:1 |
