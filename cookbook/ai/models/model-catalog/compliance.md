
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

Notes: graceful-degradation passes because `load(from:)`/`shared` always
resolve to a usable catalog (see `shared-catalog-never-fails-to-exist`).
explicit-error-handling is partial because every decode/load failure is
swallowed via `try?` with no diagnostic signal, unlike the sibling
`AIPluginManager` warning log for an incompatible plugin. data-integrity is
partial because `id`/alias collisions across `Model` entries silently
overwrite in the index with no validation (see
`alias-collision-last-writer-wins`). no-hardcoded-strings fails because
`Model.description` and curated `ModelDetail.goodFor` ship as English-only
prose with no localization mechanism (see Localization).

`separation-of-concerns` passes because `AIModelCatalog` is a decodable data model with lookup, offering and canonical-id resolution only; facet and capability derivation live in `ModelUseFacet` and `ModelCapability`, and loading of plugin bundles belongs to the plugin manager. `unit-test-coverage` is partial: `AIModelCatalogTests.swift` covers canonical-id suffixes, resolution by id, alias and unseen spellings, per-gateway terms, curated details winning, absent fields decoding to empty, the shipped catalog loading and a missing resource yielding an empty catalog, but no test asserts the id and alias collision behavior (last writer wins) or a corrupt catalog being swallowed.

