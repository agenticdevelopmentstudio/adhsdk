
Two files in `Core/Sessions/Wire` hold the value types the model router's daemon and its clients exchange, all nested in the `Sessions` namespace. The model router sends a Claude Code request down a template's ranked list of tiers to a smaller Claude model or to an LLM Provider configuration; these types are the vocabulary of that exchange and the pure logic over templates, not the routing itself.

`ModelRouterDTOs.swift` defines:

- `ModelThreadKind`: which kind of Claude Code conversation a request belongs to (`main`, `subagent`, `side`, `other`).
- `ModelFamily`: the model family a Claude model id names (`haiku`, `sonnet`, `opus`, `other`), with its routable ranking (`routable`, `size`) and a display title (`modelTitle`).
- `ModelTierDTO`: one tier a template defines (`id`, `name`).
- `ModelTierTarget`: what serves a tier, with a text form `claude:<haiku|sonnet|opus>` or `provider:<uuid>[/<model>]`, a failable parser and a printer.
- `ModelRouteConditionsDTO`: the conditions a request definition matches on (`thread`, `commands`, `system`, `message`).
- `ModelRequestKindDTO`: one kind of request a template recognizes (`id`, `name`, `when`), the reserved `unclassified` id, and the id rule `isValidId`.
- `LossyDecoded`: an internal wrapper that decodes one array element or yields nil, so one bad element is dropped instead of the whole array.
- `ModelRouterPreferencesDTO`: a partial write of the router's settings.
- `ModelRouterProviderDTO`: one configured AI provider a `provider:` target can name, without secrets.
- `ModelRouterStatusDTO`: the router's status as the daemon reports it.
- `ModelUsageRowDTO`: one usage-report line per (requested model, served model, provider).

`ModelRouterTemplates.swift` defines:

- `ClaudeCodeVersion`: a parsed, comparable Claude Code version (1 to 4 dot-separated whole numbers), with extraction from a `claude-cli/<version>` user agent.
- `ModelRouterTemplateDecodeError`: why a template file was refused, each with a one-sentence `reason`.
- `ModelRouterTemplateDTO`: one request template in four parts (tiers, requests, request-to-tier map, tier-to-target map) covering a range of Claude Code versions; its decoder reads formats 1, 2 and 3; readers over the four parts; the file codec `decodeFile` / `encodedFile`; and the defaults, including the built-in catalog of 44 request kinds and the one built-in template.
- `ModelRouterTemplateValidation`: the user-facing refusal sentences, the name-scalar denylist `isRefusedInName`, and `problem(_:others:)`, which returns the first problem with a template or nil.
- `ModelRouterTemplateSelector`: picks the template for a Claude Code version (`select`) and tells whether two templates' version ranges overlap (`overlaps`).

Everything here is a plain value or a pure function: no I/O, no logging, no shared mutable state. Reading and writing template files on disk and applying a preferences write is `ModelRouterTemplateStore` in the Database tier (it calls `decodeFile`, `encodedFile`, `problem`, `overlaps` and the `badId`, `builtInReadOnly` and `noSuchTemplate` sentences); building a status is `AccountRouterServer.modelStatus`; matching conditions against a live request is the routing policy (`ModelRoutingPolicy`, `ModelRequestFacts`).

