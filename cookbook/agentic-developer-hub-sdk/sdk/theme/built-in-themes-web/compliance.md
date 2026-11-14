
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-platform-notes](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90c2d8c2-cf79-5465-bffd-54f9fb1453bc) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f5b5cbe6-22e8-5954-a18d-0362ee387941) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1888cb38-9583-5657-a76f-c9685d296d6c) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-change-history](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/14bf2d1d-875b-5e58-b43d-be492c9f941a) | passed | artifact-formatting |

`separation-of-concerns` passes: the file is pure data, with native-only changes kept in `BuiltInThemes+Native.swift` and role resolution in `SemanticPalette`. `unit-test-coverage` is `partial`: `PortedThemeTests` asserts the catalogue, palette validity, chat-role presence, flatness, typography, size scales and the settled-colour rule, but no test asserts the individual hex values, the ids or the ANSI slot rules. `explicit-error-handling` is `partial`: every colour is built with a force-unwrapped `RGBAColor(hexString:)`, so a malformed generated literal traps rather than returning an error. `no-hardcoded-strings` is `partial`: theme names are English proper nouns held as literals, with no string catalogue. `graceful-degradation` passes: absent optional roles derive, and the doc comments state that a missing font family falls back to the system face. The formatting checks pass for this recipe.

