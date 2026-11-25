
**Decision**: the plugin configuration stores configuration as a flat
string-keyed dictionary of strings with three convenience accessors
(`apiKey`, `baseURL`, `model`), rather than a strongly-typed shape with one
field per plugin-declared value.
**Rationale**: (Swift implementation) a plugin's settings schema (its
`descriptor.json`, described alongside `AIPlugin.swift`) is host-resolved
data, not compile-time-known fields — a stringly-typed bag is the only
shape that can carry an arbitrary, plugin-declared field set without this
contract knowing every plugin's schema in advance. Callers SHOULD use the
literal keys `apiKey`, `baseURL`, and `model` for those conventional
fields, since the plugin configuration performs no key aliasing or
normalization — a caller that stores an API key under a different key name
will find `apiKey` returns nothing.
**Approved**: pending

**Decision**: the chat context's `maxTokens` defaults to `4096` with no
enforced minimum or maximum.
**Rationale**: this contract treats `maxTokens` as an opaque budget number
to forward to whichever provider the plugin targets. Each provider sets its
own limits, and they differ by model, so only the plugin that knows the
provider can clamp it; this contract does not. `4096` is a convenience
default rather than a validated floor. Per the Edge Cases entry above, the
one adjustment any plugin makes today is the Anthropic API plugin raising
it above `thinkingBudgetTokens`.
**Approved**: pending

**Decision**: the chat context carries an optional `thinkingBudgetTokens`,
and its absence means no reasoning is requested.
**Rationale**: reasoning costs tokens and time, so a caller has to ask for
it; absence as the default keeps every existing caller's requests
unchanged. The value is a budget in tokens rather than an on/off flag
because the providers that take a budget need a number, and a provider
that reasons adaptively can treat any budget as "on". This contract does
not validate it, for the same reason it does not validate `maxTokens`: the
legal range is the provider's. It sits after `tools` and before `config`
in the initializer so that every existing call, which passes `config`
last, keeps compiling.
**Approved**: pending

