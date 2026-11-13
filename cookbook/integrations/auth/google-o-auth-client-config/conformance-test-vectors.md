
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gocc-001 | parse-success, parse-extra-keys-ignored | `{"installed":{"client_id":"abc","client_secret":"xyz","auth_uri":"u"}}` (test `parsesInstalledClientJSON`) | Returns a config equal to `clientId` "abc", `clientSecret` "xyz" |
| gocc-002 | parse-web-client-rejected, parse-error-type | `{"web":{"client_id":"abc","client_secret":"xyz"}}` (test `rejectsWebClientJSON`) | Throws `IntegrationError.invalidSettings` with the Web application client message |
| gocc-003 | parse-installed-keys-required | `{"installed":{"client_id":"abc"}}` (test `rejectsMissingKeys`) | Throws `IntegrationError.invalidSettings` with the missing-keys message |
| gocc-004 | parse-json-object-required | `not json`, `[]` and empty data | Each throws `IntegrationError.invalidSettings("the OAuth client file is not valid JSON")` |
| gocc-005 | parse-empty-values-rejected | `{"installed":{"client_id":"","client_secret":"xyz"}}` | Throws the missing-keys message |
| gocc-006 | parse-installed-keys-required | `{"installed":{"client_id":"abc","client_secret":7}}` and `{"installed":"x"}` and `{}` | Each throws the missing-keys message |
| gocc-007 | parse-installed-wins | `{"installed":{"client_id":"a","client_secret":"b"},"web":{}}` | Returns a config with id "a" and secret "b" |
| gocc-008 | parse-no-trimming | `{"installed":{"client_id":" a ","client_secret":"b"}}` | Returns `clientId` " a " with its spaces |
| gocc-009 | installed-json-shape, installed-json-key-order | `GoogleOAuthClientConfig(clientId: "id", clientSecret: "secret").installedJSON()` | The bytes `{"installed":{"client_id":"id","client_secret":"secret"}}` |
| gocc-010 | installed-json-round-trip | `installedJSON()` of a config with id "id-1.apps.googleusercontent.com" and secret "GOCSPX-secret", fed to `parse(json:)` (test `savingTheClientFormSendsItAsInstalledJSONAndClearsTheFields`) | Returns a config equal to the original |
| gocc-011 | installed-json-no-validation | `GoogleOAuthClientConfig(clientId: "", clientSecret: "s").installedJSON()` then `parse(json:)` | `installedJSON()` returns data; `parse(json:)` throws the missing-keys message |
| gocc-012 | memberwise-init, value-semantics | Two configs built with the same two strings, one with a different secret | The first two compare equal; the third does not |
| gocc-013 | secret-not-in-errors | Any rejected input containing the client secret "GOCSPX-abc" | The thrown reason text does not contain "GOCSPX-abc" |

Test traceability: gocc-001 to gocc-003 are the assertions of `GoogleOAuthTests` (target `AgenticDeveloperHubSDKIntegrationsTests`). gocc-010 is derived from `GmailSettingsModelTests` and the use of `installedJSON()` in `MailIntegrationServiceTests`. gocc-004 to gocc-009 and gocc-011 to gocc-013 follow from the source and have no test beside it.

