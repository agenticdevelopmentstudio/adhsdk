
Every user-facing string is a hardcoded English literal with no localization lookup. The one locale-aware piece is the list in `removalProblem`, joined by the system list formatter for the current locale inside an English sentence. The template text forms (`claude:`, `provider:`), raw enum strings, tier and request ids and `unclassifiedId` are wire values and MUST NOT be localized. `ModelRouterTemplateDecodeError.newerFormat` names "Stenographer" in its reason.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; `ModelFamily.modelTitle`) | `Claude Haiku 5.5` / `Claude Sonnet 5.5` / `Claude Opus 5.5` / `Claude` | Title shown for a tier target naming a family |
| (none; `ModelRequestKindDTO.unclassifiedName`) | `Unclassified` | Display name of the kind that catches every unmatched request |
| (none; `defaultTiers`) | `Light` / `Standard` / `Heavy` | Default tier names |
| (none; `builtInCatalog`) | 44 request names, `Explore subagent` through `Command subagent` | Names of the built-in request kinds |
| (none; `builtIns`) | `Claude Code 2.1.296` | Name of the built-in template |
| (none; `ModelRouterTemplateDecodeError.reason`) | `not a template file` | File is not a template |
| (none; `reason`) | `made for a newer Stenographer (format N)` | File format above 3 |
| (none; `reason`) | `N of its request definitions can't be read, so the file was not imported` | Format-2 file with unreadable requests |
| (none; `reason`) | `its S can't be read, so the file was not imported` | Format-3 section unreadable |
| (none; `removalProblem`) | `<list> still go to <tier>. Choose another tier for them first.` / `<name> still goes to <tier>. Choose another tier for it first.` | A tier in use cannot be removed |
| `nameMissing` | `A template needs a name.` | Validation |
| `nameTaken` | `Another template already has that name.` | Validation |
| `nameTooLong` | `A template name can be at most 80 characters.` | Validation |
| `nameHasControls` | `A template name can't hold control characters, text-direction controls or line breaks.` | Validation |
| `badId` | `A template id is letters, digits, dots, dashes or underscores.` | Used by `ModelRouterTemplateStore` |
| `badVersion` | `A Claude Code version is whole numbers separated by dots, like 2.1.296.` | Validation |
| `backwardsRange` | `The first Claude Code version must not be after the last.` | Validation |
| `builtInReadOnly` | `Built-in templates can't be changed; duplicate one instead.` | Used by `ModelRouterTemplateStore` |
| `noSuchTemplate` | `That template no longer exists.` | Used by `ModelRouterTemplateStore` |
| `badRequestId` | `A request id is lowercase letters, digits and dashes, and can't be unclassified.` | Validation |
| `duplicateRequestId` | `Two requests have the same id.` | Validation |
| `requestNameMissing` | `Every request needs a name.` | Validation |
| `requestNameTaken` | `Two requests have the same name.` | Validation |
| `requestNameBad` | `A request name can be at most 80 characters, with no control characters or line breaks.` | Validation |
| `matchTextBad` | `The text a request is recognized by can be at most 400 characters, with no control characters.` | Validation |
| `noTiers` | `A template needs at least one tier.` | Validation |
| `badTierId` | `A tier id is lowercase letters, digits and dashes.` | Validation |
| `duplicateTierId` | `Two tiers have the same id.` | Validation |
| `tierNameMissing` | `Every tier needs a name.` | Validation |
| `tierNameTaken` | `Two tiers have the same name.` | Validation |
| `tierNameBad` | `A tier name can be at most 80 characters, with no control characters or line breaks.` | Validation |
| `requestTierMissing` | `Every request, and Unclassified, needs a tier.` | Validation |
| `requestTierUnknown` | `A request goes to a tier the template doesn't have.` | Validation |
| `requestTierStray` | `The request tiers name a request the template doesn't have.` | Validation |
| `tierTargetMissing` | `Every tier needs a model.` | Validation |
| `tierTargetBad` | `A tier's model must be a Claude model or an LLM Provider configuration.` | Validation |
| `tierTargetStray` | `The tier models name a tier the template doesn't have.` | Validation |

