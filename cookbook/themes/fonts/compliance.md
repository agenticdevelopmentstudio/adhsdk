
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.performance.startup-impact](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/41f11fb7-abed-5c62-ae13-456da5874bb0) | passed | performance |
| [adc.check.performance.lazy-loading](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/93049d53-e8e2-5ea3-8a3a-9eb07e60d0e2) | passed | performance |

Separation of concerns passes: the module does one thing, listing preload hrefs, and leaves rule emission to the css build and file placement to `materializeThemeFonts`, with the manifest as the single shared fact. Unit-test coverage is partial: no test sits beside `fonts.ts`; the contract is asserted by the adh package's `landingTypeScale.test.ts`, and the generator's preload flags are tested in `subset-fonts_test.py` for the site cuts only. Startup impact and lazy loading pass because only the three CORE cuts are preloaded and the EXT cuts are left to `unicode-range`.

