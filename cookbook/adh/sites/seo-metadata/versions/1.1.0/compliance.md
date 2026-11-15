
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |

`separation-of-concerns` passes: `metadata.ts` contains zero DOM, fetch, or rendering
code — only `import type` reaches into `next`, and the one value that needs the live
request (the serving hostname) is passed IN by the caller rather than read here, per the
module's own top-of-file comment. `unit-test-coverage` is `partial`:
`registry-characterisation.test.ts` — whose own `describe` block is titled "seo helpers
(251 consumers, no other test)" — exercises `canonicalOnly`, `ogImageSize`, and only the
title/description/`openGraph`-truthy slice of `siteMetadata`; `siteRobots`,
`siteSitemap`, and the `NOINDEX_BUILD` robots-gate branch of `siteMetadata` have no test
at all. `explicit-error-handling` passes: the module has no `try`/`catch` and no thrown
or caught exception; its only optional-unwrapping (`site?.prodHost ?? …`) is a
deliberate, documented default for an unresolved `SiteId`, not a swallowed error.
`no-hardcoded-strings` is `partial`: `seo.title`/`seo.description` are caller-supplied,
not hardcoded, but `openGraph.locale` (`'en_US'`) and the `'Agentic Developer Hub'`
fallback brand are hardcoded English strings with no localization path, as detailed
under Localization above.

