
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best-practices |

Security and semantic-markup statuses rest on `process-markdown.ts`'s `rehype-sanitize` allowlist plus `remark-rehype`'s `allowDangerousHtml: false`, and on `MarkdownRenderer.tsx`'s `aria-busy`/`aria-live`/`role="alert"` markup together with real `<a>`/`<h1>`–`<h6>` elements; keyboard-navigable rests on those same native elements. Contrast is `partial` because the renderer applies palette/theme colors as supplied without independently verifying they meet WCAG AA. Unicode support is `passed` because neither the `AttributedString` parser nor the `unified`/`remark`/`rehype` pipeline restricts or transcodes the character set of the text they process. `separation-of-concerns` passes: the Apple `MarkdownRenderer` only walks parsed block/run structure into `NSAttributedString`, delegating syntax highlighting to an injected `CodeHighlighter`; the web pipeline's parsing (`remark-parse`/`remark-gfm`), sanitization (`rehype-sanitize`), and highlighting (Shiki) are separate composed stages in `process-markdown.ts`. `unit-test-coverage` passes: `MarkdownRendererTests.swift` (Apple) and `process-markdown.test.ts` (web) each exercise this component's rendering pipeline directly.

