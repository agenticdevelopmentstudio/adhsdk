
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |

`separation-of-concerns` passes because `AIPluginDescriptor.swift` performs no file I/O, network access, or persistence of its own — bundle discovery lives in `AIPluginManager`, and credential/setting storage lives in `PluginConfigStore`/`AIProviderConfigStore`; this file is only the decoded shape and its pure resolution helpers. `no-hardcoded-strings` fails: `resolvedConfigType` returns the literal, non-localized English strings `"API Key"` and `"Local"`, which the provider picker's Config Type column displays directly (see Localization). `data-integrity` is `partial`: `identifier`, `Field.key`, and `ProviderTemplate.id` carry no uniqueness or non-empty validation in this type — duplicates decode and construct successfully, and `AIPluginManager.template(pluginIdentifier:templateId:)` silently resolves to the first match on a colliding `id` (see Edge Cases). `secure-storage` is `partial`: `Field.Kind.secret` correctly signals which values downstream consumers MUST route to the Keychain (confirmed in `PluginConfigStore.swift`/`AIProviderConfigStore.swift`), but this type performs no storage or enforcement of its own — a consumer that ignored `isSecret` would not be caught by anything in this file.

`unit-test-coverage` passes because `AIPluginDescriptorTests.swift` covers decoding identity, models and typed fields, `resolvedDefaultModel` falling back to the first model, explicit version-3 templates, the implicit template when none is declared, and a template overriding the descriptor's fields, with `DescriptorCatalogTests.swift` covering the shipped descriptors.

