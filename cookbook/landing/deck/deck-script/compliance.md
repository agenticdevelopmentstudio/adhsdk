
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`armSmooth` only toggles the `data-smooth` attribute; whether `scroll-behavior: smooth` is actually cancelled under `@media (prefers-reduced-motion: reduce)` depends on the `base.css` rule this source file does not contain, so the status is `partial` rather than `passed` (see #requirements/css-contract). `separation-of-concerns` is passed because all four behaviors are built as plain strings by the pure `deckScript()` function, with `DeckScript` itself only a thin wrapper that injects that string into a literal `<script>` tag; `unit-test-coverage` is `passed`: `deck.test.tsx` covers every vector (deck-script-001 to 026). It asserts the string output of `deckScript()` for each option, server-renders `DeckScript` (014), and executes the script in jsdom with stubbed user agents and a viewport meta (016, 017, 021, 022, 024, 026).

