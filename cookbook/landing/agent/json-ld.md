---
id: 3df8fdde-339e-472f-b6e5-c52aa8738262
title: "JSON-LD"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: "JsonLd script element for a page's schema.org data, and withWebSite, which merges a site's WebSite entity into a single schema.org graph."
platforms:
  - typescript
  - web
tags:
  - landing
  - agent
  - structured-data
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# JSON-LD

## Overview

JSON-LD is a pair of helpers that publish a page's structured data for search engines and answer engines. `JsonLd` renders one `<script type="application/ld+json">` element holding a schema.org document, and escapes `<` so no string in the data can close the element. `withWebSite` builds that document: it takes a site's name, URL and description plus any entities the page already has, and returns one `{ "@context", "@graph" }` document with a `WebSite` entity added unless one is already present. The data type, `JsonLdValue`, is a plain record of string keys to unknown values.

## Behavioral Requirements

- **render-script-element**: `JsonLd` MUST render exactly one `<script>` element with `type="application/ld+json"`.
- **serialize-data**: `JsonLd` MUST write the `data` prop into the script element as the result of JSON serialization of that value.
- **escape-less-than**: `JsonLd` MUST replace every `<` character in the serialized data with the six characters `\u003c`, so no string in the data can close the script element.
- **no-other-escaping**: `JsonLd` MUST NOT escape any character other than `<`; `>` and `&` pass through unchanged.
- **graph-context**: `withWebSite` MUST return an object whose `@context` is `https://schema.org`.
- **graph-array**: `withWebSite` MUST return the entities under an `@graph` array.
- **add-website**: `withWebSite` MUST place a `WebSite` entity first in `@graph`, ahead of the entities taken from `extra`, when none of those entities has an `@type` equal to `WebSite`.
- **website-id**: The added `WebSite` entity MUST carry an `@id` made of `site.url` with all trailing `/` characters removed, followed by `/#website`.
- **website-fields**: The added `WebSite` entity MUST carry the `name`, `url` and `description` of `site`, with `url` unchanged by the trailing-slash trimming applied to `@id`. The source spreads `site` last, so any extra enumerable key on a `site` object (for example its own `@id`) also lands on the entity and overrides the defaults.
- **keep-own-website**: `withWebSite` MUST NOT add a `WebSite` entity when an entity from `extra` already has an `@type` equal to the string `WebSite`, and MUST return that entity unchanged apart from the removal of its `@context`.
- **extra-optional**: `withWebSite` MUST accept an omitted or null `extra` and return a graph holding only the added `WebSite`.
- **extra-forms**: `withWebSite` MUST accept `extra` as a single entity, as a list of entities or documents, or as a `{ "@context", "@graph" }` document.
- **flatten-nested**: `withWebSite` MUST flatten nested lists and nested `@graph` arrays into one flat list of entities.
- **preserve-order**: `withWebSite` MUST keep the entities of `extra` in the order given, after the added `WebSite`.
- **strip-context**: `withWebSite` MUST remove the `@context` key from each entity it takes from `extra`, so that the document carries a single `@context`.
- **no-mutation**: `withWebSite` MUST NOT modify the objects passed in `extra`; each entity is a shallow copy.
- **website-type-exact**: `withWebSite` MUST detect an existing website only by an `@type` that is strictly the string `WebSite`.
- **pure-functions**: `withWebSite` MUST be a pure function with no I/O, and `JsonLd` MUST hold no state.

## Appearance

Not applicable: `JsonLd` renders a `<script>` element of type `application/ld+json`, which a browser does not display, and `withWebSite` returns data. The source applies no class, style or layout.

- **Corner radius**: Not applicable; nothing is drawn.
- **Padding**: Not applicable; nothing is drawn.
- **Font**: Not applicable; nothing is drawn.
- **Background**: Not applicable; nothing is drawn.
- **Foreground/Text**: Not applicable; the script text is data read by crawlers.
- **Border**: Not applicable; nothing is drawn.
- **Shadow**: Not applicable; nothing is drawn.
- **Min/Max size**: Not applicable; the source sets no size limit on the serialized data.

## States

Not applicable: neither export holds state or reacts to input, as the source has no hooks, handlers or props beyond `data`, `site` and `extra`.

| State | Appearance change |
|-------|------------------|
| Default | The script element holds the serialized data; nothing is visible. |
| Pressed | Not applicable; the element is not interactive. |
| Disabled | Not applicable; there is no disabled prop. |
| Focused | Not applicable; a script element cannot take focus. |
| Loading | Not applicable; the data is serialized synchronously during render. |

## Accessibility

Not applicable: the `<script type="application/ld+json">` element is not rendered to the user and is not exposed to assistive technology, so it has no role, label, focus or tap target.

- **Role/trait**: Not applicable; a script element has no accessibility role.
- **Label requirements**: Not applicable; nothing is announced.
- **Announce state changes**: Not applicable; the component has no state.
- **Minimum tap target**: Not applicable; the component is not interactive.

## Conformance Test Vectors

Vectors 001 to 004 come from `agent.test.tsx` in `packages/web/packages/landing/src/__tests__/`; the rest follow from the source. `site` is a name, a URL and a description, with the URL `https://x.example` in the tests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| json-ld-001 | add-website, website-id, website-fields, graph-context, graph-array, preserve-order (test: adds a WebSite ahead of the site's own entities) | `withWebSite(site, { "@context": "https://schema.org", "@graph": [{ "@type": "Organization", name: "O" }] })` | `{ "@context": "https://schema.org", "@graph": [ { "@type": "WebSite", "@id": "https://x.example/#website", ...site }, { "@type": "Organization", name: "O" } ] }` |
| json-ld-002 | keep-own-website, strip-context (test: keeps a WebSite the site already declares) | `withWebSite(site, { "@context": "https://schema.org", "@type": "WebSite", name: "Mine" })` | `@graph` equals `[ { "@type": "WebSite", name: "Mine" } ]`; no entity is added |
| json-ld-003 | escape-less-than, render-script-element, serialize-data (test: escapes `<` so the data cannot close its script) | `JsonLd` rendered with `data={{ name: "</script><b>" }}` | The markup is `<script type="application/ld+json">{"name":"\u003c/script>\u003cb>"}</script>` |
| json-ld-004 | no-other-escaping (test: the same assertion) | The `data` of json-ld-003 | The `>` characters appear unescaped in the output |
| json-ld-005 | extra-optional | `withWebSite(site)` and `withWebSite(site, null)` | `@graph` holds one entity, the added `WebSite` |
| json-ld-006 | website-id, website-fields | `site.url` of `https://x.example///` | `@id` is `https://x.example/#website` and `url` is still `https://x.example///` |
| json-ld-007 | extra-forms, preserve-order | `extra` is a single entity `A` | `@graph` is the `WebSite`, then `A` |
| json-ld-008 | flatten-nested, preserve-order | `extra` is `[A, { "@graph": [B, [C]] }, D]` | `@graph` is the `WebSite`, `A`, `B`, `C`, `D` in that order |
| json-ld-009 | strip-context | `extra` is an entity carrying its own `@context` | The entity in `@graph` has no `@context` key |
| json-ld-010 | no-mutation | `extra` is an entity carrying an `@context` | After the call the original object still has its `@context` |
| json-ld-011 | website-type-exact | `extra` is an entity whose `@type` is `["WebSite", "Thing"]` | A `WebSite` is still added first, because the array is not equal to the string |
| json-ld-012 | extra-optional, flatten-nested | `extra` is `{ "@graph": [] }` | `@graph` holds only the added `WebSite` |
| json-ld-013 | pure-functions | `withWebSite` called twice with equal arguments | Both results are deeply equal and no call has an observable side effect |

## Edge Cases

- **Null or omitted extra**: `withWebSite` MUST return a graph of the added `WebSite` alone. See json-ld-005.
- **Empty graph in extra**: A `@graph` of zero entities MUST contribute nothing. See json-ld-012.
- **Trailing slashes on the URL**: All trailing `/` characters MUST be trimmed from the `@id` base and from nothing else. See json-ld-006.
- **WebSite declared with an array type**: The check is a strict equality, so an `@type` list is not recognized and a second `WebSite` is added; hosts SHOULD declare their own with the plain string type. See json-ld-011.
- **Document with sibling keys**: When `extra` is a `{ "@context", "@graph" }` document, only its `@graph` entities are kept; any other top-level key on that document is discarded. A `@graph` that is not an array makes the object an ordinary entity.
- **Non-object extra**: A string, number or boolean `extra` is not rejected; it is spread into an entity (a number or boolean yields an empty entity, a string yields an entity keyed by character index), so the host SHOULD pass objects, arrays, null or undefined only.
- **Strings containing the script terminator**: `<` is escaped, so `</script>` inside any string value MUST NOT close the element. See json-ld-003.
- **Data JSON cannot serialize**: `JsonLd` calls `JSON.stringify` with no guard, so a circular structure or a BigInt value throws during render and the source has no error state. The host MUST pass JSON-safe data.
- **Boundary values**: Not applicable; the source constrains no length, count or range, and an empty `data` object serializes to an empty object.
- **Concurrent access**: Not applicable; both functions are pure and keep no shared state, so calls cannot interfere.
- **Offline or disconnected state**: Not applicable; neither function makes a network request.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data` | `JsonLdValue` | required | The schema.org entity or `{ "@context", "@graph" }` document `JsonLd` serializes. |
| `site.name` | string | required | The name placed on the added `WebSite`. |
| `site.url` | string | required | The origin placed on the added `WebSite`; trailing slashes are trimmed for the `@id` only. |
| `site.description` | string | required | The description placed on the added `WebSite`. |
| `extra` | unknown | omitted | A document, an entity or a list of them, whose entities follow the `WebSite`. |

## Deep Linking

Not applicable: the component renders no link and defines no route; the `@id` it builds is an identifier fragment, not a navigation target.

## Localization

Not applicable: the component contains no user-facing strings; `name`, `description` and the entities are supplied by the host and written as given.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; nothing animates. |
| Increase Contrast | Not applicable; nothing is drawn. |
| Differentiate Without Color | Not applicable; nothing is drawn. |

## Feature Flags

Not applicable: the source reads no flag; a host decides whether to render `JsonLd`.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: None; the component collects nothing.
- **Storage**: None; nothing is stored.
- **Transmission**: The serialized data is written into the page HTML, so whatever the host passes is public to every reader of the page.
- **Retention**: Not applicable; the component keeps nothing.

## Logging

Not applicable: the source has no logging calls.

## Platform Notes

- **SwiftUI**: Not a view concern, since the source is web only. On an Apple platform that serves web pages, build the same document with `Codable` structures or a dictionary and `JSONSerialization`, then replace `<` with the six-character sequence `\u003c` before inserting it into the HTML. A native app has no crawler to serve; use `NSUserActivity` and `CSSearchableItem` for Spotlight indexing instead.
- **Compose**: Not a UI concern. In a Kotlin web back end, build the graph with a JSON library such as `kotlinx.serialization` `JsonObject`, apply the same flatten, strip-context and add-website rules, and escape `<` before writing the `<script>`. Compose itself has no equivalent of the script element.
- **React/Web**: Source is `packages/web/packages/landing/src/agent/json-ld.tsx`, exported from the landing package index as `JsonLd`, `withWebSite` and the `JsonLdValue` type. `JsonLd` uses `dangerouslySetInnerHTML` on a `<script>`, because React would otherwise escape the JSON text as HTML; the escape of `<` is what makes that safe. The element works in server rendering (`renderToStaticMarkup` in the test) and can sit in the head or body.
- **AppKit / UIKit**: Not a UI concern. Spotlight and `NSUserActivity` metadata are the native counterparts for search discoverability; a macOS or iOS server component that emits web pages follows the SwiftUI note above.
- **WinUI 3**: Not a XAML control, since the output is HTML read by crawlers. In a C# web project (an ASP.NET Core Razor page or a Blazor component) emit a `script` tag with `type="application/ld+json"` and the content from `System.Text.Json` `JsonSerializer.Serialize`, then call `Replace("<", "\\u003c")` on the string and write it with `Html.Raw` or a `MarkupString` so the framework does not HTML-encode the quotes. Port `withWebSite` as a static method over `JsonNode` or `Dictionary<string, object>` with a recursive flatten, and use `TrimEnd('/')` for the `@id`. A packaged WinUI 3 app has no equivalent surface; its search surface is Windows Search with an app's own indexer, which this recipe does not cover.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/agent/json-ld.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `<` is escaped as `\u003c` and no other character is.
**Rationale**: A `</script>` inside any string would end the element and let the rest of the data run as markup. Escaping `<` alone closes that hole, and `\u003c` is read back as `<` by any JSON parser, so the data is unchanged for crawlers.
**Approved**: pending

**Decision**: `JsonLd` writes the text through `dangerouslySetInnerHTML` instead of as a React child.
**Rationale**: React escapes text children as HTML, which would turn quotes into entities and break the JSON. The `<` escape stands in for that protection.
**Approved**: pending

**Decision**: `withWebSite` adds a `WebSite` for every site unless the page declares one.
**Rationale**: The source comment says the entry tells an answer engine that the name, the description and the origin belong together, "which every site can say without writing anything new".
**Approved**: pending

**Decision**: The `WebSite` `@id` is the origin with trailing slashes trimmed plus `/#website`.
**Rationale**: A stable identifier lets other entities in the graph refer to the site; trimming keeps `https://x.example/` and `https://x.example` from producing different identifiers.
**Approved**: pending

**Decision**: `@context` is stripped from every incoming entity and one is set on the result.
**Rationale**: A graph carries one context. Hosts can pass whole documents, single entities or lists without caring which form a helper returned.
**Approved**: pending

**Decision**: An existing website is recognized only by `@type` equal to the string `WebSite`.
**Rationale**: This is the source's check, and it is technical debt that affects behavior: a `WebSite` declared with an array type is not detected and is duplicated. A host that declares its own SHOULD use the string form.
**Approved**: pending

**Decision**: There is no guard around serialization.
**Rationale**: The data is authored by the host and static in practice. Throwing at render time makes a bad value visible during development, and the source adds no fallback.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`separation-of-concerns` passes because rendering (`JsonLd`), graph assembly (`withWebSite`) and normalizing (`graphOf`, private) are three small functions with no I/O. `unit-test-coverage` passes: `json-ld.test.tsx` has one test for each of vectors 001 to 013, and `agent.test.tsx` also covers the added WebSite, the kept WebSite and the `<` escape. `input-sanitization` passes because the one input that can end the element, `<`, is escaped and tested. `explicit-error-handling` is partial because serialization failures surface as an uncaught exception at render time with no handling.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (json-ld.test.tsx, 13 of 13 vectors); unit-test-coverage now passed. |
