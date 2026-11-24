
The source has no unit test beside it. Vectors 001 to 013 are derived from the source; vectors 014 to 016 come from assertions in `packages/web/packages/adh/src/__tests__/landingFlow.test.tsx` and `landingDeck.test.tsx` (index rows) and `packages/web/packages/landing/src/__tests__/page.test.tsx` (the `heroSlots` pending-label test, which goes through `renderBlock`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| blocks-001 | prose-paragraphs, prose-keys | `prose(['a', 'b'])` | Two `<p>` elements containing `a` then `b`, keyed 0 and 1 |
| blocks-002 | prose-empty | `prose([])` | An empty list |
| blocks-003 | render-block-kind-dispatch, render-code | `renderBlock({ kind: 'Code', text: 'a b' }, 0)` | A Code element with `text` equal to `a b` |
| blocks-004 | render-block-key | `renderBlock({ kind: 'Lede', children: 'x' }, 7)` | An element whose key is `7` |
| blocks-005 | render-cards-icon, render-cards-card | A `Cards` block with one card whose `icon` is `shield` | Card receives the icon `/icons/shield.svg` |
| blocks-006 | render-cards-icon | A `Cards` block with one card that has no `icon` | Card receives no icon |
| blocks-007 | render-cards-body, prose-paragraphs | A card with `body` of two strings | The card contains two `<p>` children |
| blocks-008 | render-shot-media | `Shot` with `src` `main-window` and `caption` `The main window` | Shot receives an `<img>` with source `/screenshots/main-window.png` and `alt` `The main window` |
| blocks-009 | render-shot-placeholder, render-shot-default-label, render-shot-pending-label | `Shot` with no `src`, called with no label | Shot receives no `media`, and its `pendingLabel` is `Screenshot coming soon` |
| blocks-010 | render-roadmap, render-roadmap-pending-label, render-roadmap-keys | A `Roadmap` whose child is a `Shot` with no `src`, called with `pendingLabel` `Soon` | The nested Shot shows the pending label `Soon`; the child is keyed 0 |
| blocks-011 | render-faq-entries, render-faq-answer | A `Faq` entry with `open: true` and an `answer` of one string | Faq entry keeps `open` true and its answer is one `<p>` |
| blocks-012 | render-cta-buttons | A `Cta` with buttons `{ href: '/start', label: 'Get started' }` and one with `variant: 'ghost'` | Two Btn elements; the first has `href` `/start` and passes no variant (Btn then uses its `primary` default), the second has variant `ghost` |
| blocks-013 | render-unknown-kind | A value cast to `LandingBlock` whose `kind` is `Nope` | The same value returned, not an element |
| blocks-014 | index-rows-shape, index-rows-href, index-rows-label | A page with sections `{ id: 'what-it-is', eyebrow: 'What it is' }`, `{ id: 'what-it-does', eyebrow: 'What it does' }`, `{ id: 'the-shape', eyebrow: 'The shape' }` | Rows `#what-it-is` / `What it is`, `#what-it-does` / `What it does`, `#the-shape` / `The shape` (landingFlow test: gives every band a row in the index) |
| blocks-015 | index-rows-no-hero | A page with a hero and three sections | Exactly three rows; none for the hero |
| blocks-016 | render-shot-pending-label | A hero `Shot` with no image, rendered with a host label (page.test: words a pending hero Shot as its host asks) | The placeholder reads the host's label, not the default |

