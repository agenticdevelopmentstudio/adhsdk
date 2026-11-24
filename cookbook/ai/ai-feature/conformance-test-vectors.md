
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-feature-001 | raw-values-equal-case-names | Read the raw value of `summarize` | "summarize" |
| ai-feature-002 | raw-values-equal-case-names | Read the raw value of `oversight` | "oversight" |
| ai-feature-003 | log-discriminator | Record a completion with feature `oversight` through the logged completion overload and read the stored log row (`AIInteractionLogTests`) | The row's `feature` is "oversight" |
| ai-feature-004 | log-discriminator | Record a completion with feature `summarize` through the logged completion overload and read the stored log row (`AIInteractionLogTests`) | The row's `feature` is "summarize" |
| ai-feature-005 | provider-settings-selection | Ask the daemon database for provider settings with feature `oversight` (no test in source asserts this) | The oversight-specific provider settings reader is returned |
| ai-feature-006 | provider-settings-selection | Ask the daemon database for provider settings with feature `summarize` (no test in source asserts this) | The general provider settings reader is returned |
| ai-feature-007 | no-error-domain | Construct the type from the string "unknown" using the raw-value initializer | The result is nothing; no error is thrown |
| ai-feature-008 | equality | Compare `summarize` with `summarize`, then `summarize` with `oversight` | Equal, then not equal |

