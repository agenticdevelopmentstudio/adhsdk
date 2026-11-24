---
id: 6F0C1E52-3B7A-4D59-9E21-8A4C2D7B5F13
title: "Semantic Search"
domain: adhsdk://ingredients/search/semantic-search
type: ingredient
version: 1.0.0
status: draft
language: en
created: 2026-11-08
modified: 2026-11-08
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "On-device embedding and search that makes vectors interchangeable with adh's server: same prefixes, token cap, truncation, stamp, source hash and fusion rule, plus a local keyword, semantic and combined store."
platforms:
  - ios
  - macos
  - swift
  - typescript
  - kotlin
  - windows
tags:
  - search
  - embeddings
  - semantic
  - adh
  - backend
depends-on: []
related:
  - adhsdk://ingredients/chat/persona-chat-coordinator
references:
  - https://github.com/google/embeddinggemma-2
---

# Semantic Search

## Overview

adh embeds documents on the server with one pinned model bundle,
`embeddinggemma-2`, and stores each passage's vector as `halfvec(256)` beside a
`semantic_stamp` naming the exact bundle that made it. This ingredient is the
client half: it embeds a query, or a document saved on the device, so that its
vector is interchangeable with the server's, and it searches a local copy of the
passages by keyword, by meaning, or both.

Interchangeable is the whole point. A device vector compared with a server
vector ranks correctly only when both sides put the same prefix in front of the
text, read the same tokens, cut the vector to the same length, and renormalise
it the same way. The stamp is how either side proves that: two vectors are
comparable exactly when their stamps are equal, so the stamp MUST be computed
identically everywhere.

The device never invents its own passages for keeps. A document saved on the
device is split and embedded at once so it is searchable immediately, but those
device passages are temporary: when the server's passages for the same text
sync down they replace them, and device passages are never pushed.

The SDK never downloads a model. An app ships the bundle (the
`symanticsearchmodel` repo, consumed as a submodule) and passes its directory.

Reference implementation (Apple):

| Piece | Where |
|---|---|
| Embedder protocol, prefixes, token cap, stamp, bundle verification, vector maths, half-float codec, chunker, source hash, fusion | `packages/apple/AgenticDeveloperHubSDK/SemanticSearch/` (framework `AgenticDeveloperHubSDKSemanticSearch`, Foundation only) |
| ONNX embedder, SQLite schema, vector index, FTS5 keyword index, store | `packages/apple/AgenticDeveloperHubSDK/SemanticSearchStore/` (framework `AgenticDeveloperHubSDKSemanticSearchStore`) |

Server references, in `adhbackend/src/adh/src/`:

| Concern | Server source |
|---|---|
| Prefixes, cap, truncation, stamp | `llm/local-embedder.ts` (`MAX_EMBED_TOKENS`, `stampFor`) |
| Chunking | `lib/markdown-chunks.ts` (`chunkMarkdown`) |
| Source hash | `lib/knowledge-chunks.ts` (`docSourceHash`) |
| Search modes and fusion | `lib/search-mode.ts` (`searchModeSchema`, `mergeRanked`) |
| Vector column | `db/schema/content.ts` (`semantic_embedding halfvec(256)`, `semantic_stamp varchar(96)`) |

## Terminology

| Term | Meaning |
|------|---------|
| **Bundle** | A directory holding `manifest.json` and the files it lists: `model.onnx`, `tokenizer.json`, `tokenizer.model`, `tokenizer_config.json`, `golden.json`. |
| **Task** | What a vector is for: a *query*, or a *document* passage with its document's title (possibly none). |
| **Prefix** | The text the model expects in front of the input for a task, taken from the manifest. |
| **Passage** | One chunk of a document, the unit that is embedded and searched. |
| **Stamp** | `name:model12:tok12:dims`, the provenance string stored beside every vector. |
| **Source hash** | The sha256 of the document text a passage was made from. |
| **Device passage** | A passage this device made; temporary and never pushed. |
| **Server passage** | A passage that synced down from adh. |
| **Pending** | A passage with no vector carrying the running embedder's stamp. |

## Behavioral Requirements

### Bundle and model delivery

- **ss-no-download**: The SDK MUST NOT download, fetch or update a model. It
  MUST take a bundle directory supplied by the app.
- **ss-verify-hashes**: Before loading, the embedder MUST verify every file the
  manifest lists: present, not a git LFS pointer, and its sha256 equal to the
  manifest's. Any failure MUST be an error naming the file; a mismatched file
  MUST NOT be loaded.
- **ss-lfs-pointer**: A file that begins with
  `version https://git-lfs.github.com/spec/v1` MUST be reported as an LFS
  pointer, not as a hash mismatch, so the fix (`git lfs pull`) is obvious.
- **ss-no-bundle-truncation**: A manifest whose `max_tokens` is not null MUST be
  refused. The cap belongs to the embedder (`ss-token-cap`), and a bundle that
  truncates on its own would read different tokens from the server.
- **ss-pinned-tokenizer**: Tokenisation MUST use the bundle's own
  `tokenizer.json`, never a tokenizer fetched or bundled elsewhere. The token ids
  for every golden case MUST equal the golden set's `input_ids` exactly.

### Embedding

- **ss-task-prefixes**: The input MUST be the manifest prefix for the task
  followed by the text. A query uses `prefixes.query`. A document passage with a
  non-empty title uses `prefixes.document` with its FIRST `{title}` replaced by
  the title, inserted literally. A passage whose title is absent or empty uses
  `prefixes.document_untitled`. An empty title and no title MUST embed
  identically, because the server passes `title || null`.
- **ss-token-cap**: An input longer than 1024 tokens (`<bos>` and `<eos>`
  included) MUST be cut to its first 1023 tokens followed by its LAST token.
  The server does exactly this, so both sides read the same tokens of any input.
- **ss-one-at-a-time**: The embedder MUST run one input per model invocation, and
  one invocation at a time. Batching pads inputs and changes mean pooling; the
  parity results were measured unbatched.
- **ss-truncate-renormalise**: The model's `sentence_embedding` output MUST be
  cut to its first `truncate_dims` (256) values and renormalised to unit length.
  A zero vector MUST be left as zeros, not divided by zero.
- **ss-float32-compute**: Inference MUST run in float32. The manifest's
  `forbid_float16` is true; half precision is a storage format only
  (`ss-halfvec-layout`).

### Stamp

- **ss-stamp-format**: The stamp MUST be
  `<manifest.name>:<first 12 hex chars of files["model.onnx"].sha256>:<first 12
  hex chars of files["tokenizer.json"].sha256>:<manifest.truncate_dims>`, taken
  from the manifest exactly as written (no case change). It MUST be computed
  from the manifest, not by re-hashing the files; verification
  (`ss-verify-hashes`) is what ties the two together.
- **ss-stamp-length**: A stamp longer than 96 UTF-16 code units MUST be refused.
  This matches the server's `stamp.length > 96` check and the `varchar(96)`
  column, so both sides refuse exactly the same bundle names.
- **ss-stamp-compare**: A vector MUST be compared only with vectors whose stamp
  equals the running embedder's stamp. A vector carrying any other stamp is
  stale: it MUST NOT be scored, and its passage is pending.

### Chunking

- **ss-chunk-rules**: A device MUST split a document with the server's
  `chunkMarkdown` rules:
  1. CRLF is read as LF.
  2. Blocks are runs of lines between lines that are empty or only whitespace;
     each block is trimmed and empty blocks are dropped.
  3. A block that starts with `#` or `##` followed by whitespace starts a new
     passage, unless the current passage is empty.
  4. A block longer than 4000 characters is cut into pieces of at most 4000:
     each cut falls at the last whitespace in the window (never at its first
     position), or at the limit when the window holds none. Pieces are trimmed.
  5. Pieces are packed into a passage, joined by a blank line, while the passage
     stays within 1500 characters counting the 2-character join. A piece is
     never refused by an empty passage, so a single piece longer than 1500
     still lands.
  6. A passage that does not fit the token budget is halved at the space nearest
     its middle (the space at or before the middle wins a tie with the one
     after; with no space it is cut at the middle), and each half is halved
     again until every piece fits.
  7. Passages are trimmed, empty ones dropped, and numbered from 0.
- **ss-token-budget**: A passage fits when its token count under its document
  task, prefix, `<bos>` and `<eos>` included, is at most 1024. A passage the
  tokenizer cannot measure MUST be treated as not fitting.
- **ss-chunk-deterministic**: Chunking MUST be deterministic — no clock and no
  randomness — so one text and one budget always give the same passages.

Device passages need not match the server's byte for byte: they are replaced
when the server's arrive (`ss-server-replaces-device`). They follow the same
rules so a device result looks like the server result it stands in for.

### Source hash

- **ss-source-hash**: A passage's source hash MUST be the lowercase hex sha256 of
  the UTF-8 bytes of `title + "\n\n" + content`, an absent title counting as the
  empty string. The text MUST be hashed exactly as held: no line-ending change
  and no Unicode normalisation, because the server hashes its stored text the
  same way.

### Storage

- **ss-halfvec-layout**: A vector MUST be stored as `dims` IEEE 754 binary16
  values, little-endian, two bytes each, round to nearest even — the byte layout
  of pgvector's `halfvec(256)` element array. A blob whose length is not
  `2 × dims` MUST be refused, not padded or truncated.
- **ss-device-flag**: Every passage MUST record whether this device made it.
- **ss-passage-hash**: Every passage MUST record the source hash of the text it
  was made from.
- **ss-device-never-pushed**: Device passages and their vectors MUST NOT be sent
  to the server by any path. They are not registered with sync.

### Device and server passages

- **ss-device-index**: Indexing a document on the device records its source
  hash. If server passages with that hash are already present, it MUST keep them,
  drop any other passages of the document, and embed nothing. Otherwise it MUST
  replace every passage of the document with freshly chunked device passages and
  embed them when an embedder is present.
- **ss-server-replaces-device**: Server passages for a document whose recorded
  source hash equals theirs MUST replace every passage of that document, device
  and server alike. A server vector carrying the running embedder's stamp MUST
  be stored as is; one with any other stamp, or none, leaves its passage pending.
- **ss-stale-server-ignored**: Server passages whose source hash differs from the
  document's recorded hash describe other text, and MUST be ignored, leaving the
  current passages in place. A document with no recorded hash takes them.
- **ss-pending-embed**: Pending passages MUST be embeddable later, in bounded
  batches, so a model that arrives after the passages, or a new bundle, catches
  up without re-chunking.

### Search

- **ss-modes**: The store MUST offer the server's three modes by the server's
  names: `keyword`, `semantic` and `combined`.
- **ss-keyword**: Keyword search MUST match every query word against passage
  content and title, folding case and diacritics, and rank by bm25. Query words
  MUST be taken literally: an FTS operator typed by a user is a word, never
  syntax. A query with no letters or numbers returns nothing.
- **ss-semantic**: Semantic search MUST embed the query under the query task,
  score each comparable passage by dot product (both vectors are unit length, so
  this is cosine), and rank best first.
- **ss-one-per-document**: Both keyword and semantic results MUST keep only the
  best passage of each document.
- **ss-combined-order**: Combined search MUST list every semantic hit first in
  its order, then each keyword hit whose document is not already listed, capped
  at the limit. Scores MUST NOT be normalised or mixed: bm25 is unbounded and
  corpus-dependent, cosine is not.
- **ss-rrf-long-only**: Reciprocal Rank Fusion MAY be offered as an alternative
  combined order, but only for a limit greater than 10. Each document scores the
  sum of `1 / (60 + rank)` over the lists it appears in, rank from 1, counted
  once per list at its best rank; ties keep first-appearance order, semantic
  list first. A limit of 10 or less MUST be refused, because at that length the
  server rule gives the same practical order for less.
- **ss-no-embedder**: Without an embedder, `semantic` MUST fail with a clear
  error and `combined` MUST return the keyword results alone. A blank query
  returns nothing in every mode.

## Appearance

Not applicable — no visual representation. A results list is the consuming
surface's concern.

## States

| State | Entered when | Exited when |
|-------|--------------|-------------|
| `keyword-only` | Store opened without an embedder | Reopened with one |
| `ready` | Store opened with a verified embedder | Closed |
| passage `pending` | Passage stored without a vector of the running stamp | Embedded, or replaced |
| passage `embedded` | Vector of the running stamp stored | Passage replaced, or the bundle changes |

## Accessibility

Not applicable — no user-facing surface.

## Conformance Test Vectors

Each vector MUST be observed failing for its stated reason before it is trusted.
A vector that has never failed has proved nothing.

### Stamp

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ss-001 | ss-stamp-format | The `embeddinggemma-2` bundle manifest | `embeddinggemma-2:0137f60d95fc:4d777ef5bdc1:256` (46 units) |
| ss-002 | ss-stamp-length | Name of 66 `n`, 64-char hashes, dims 256 | Stamp of exactly 96 units, accepted |
| ss-003 | ss-stamp-length | Name of 67 `n` | Refused |
| ss-004 | ss-stamp-length | Name of 65 `n` + U+1F600 | Refused (97 UTF-16 units, though 96 characters) |

### Bundle

The pinned bundle's file hashes, as its manifest lists them:

| File | sha256 |
|------|--------|
| `model.onnx` | `0137f60d95fc8d0712d2afee6fd259203e1124559bdc3ec0cc853fb0f89170ac` |
| `tokenizer.json` | `4d777ef5bdc1aa36227abdfb77c3e49e7b9c892d16e1b6bda41c393504828be4` |
| `tokenizer.model` | `e594c8a90eb08d8bda498ff4747977dc827ae0c3c56b5c0d41a605a22d02ef03` |
| `tokenizer_config.json` | `17bd5d6e9364ca49a534e1502076593317c298d4a663623091ed45388f004874` |
| `golden.json` | `fb15edb6ad169e688f60f83cc02ac2b3cfad737f701e8a4bbce919f6463441cc` |

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ss-010 | ss-verify-hashes | A listed file missing | `fileNotFound` naming it |
| ss-011 | ss-verify-hashes | A listed file with changed bytes | `hashMismatch` naming it, with both hashes |
| ss-012 | ss-lfs-pointer | A listed file holding an LFS pointer | `lfsPointer` naming it |
| ss-013 | ss-no-bundle-truncation | `max_tokens: 512` | Refused |
| ss-014 | ss-no-download | No bundle directory | The embedder cannot be made; no network I/O |

### Prefixes and cap

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ss-020 | ss-task-prefixes | Query `"x"` | `"task: search result \| query: x"` |
| ss-021 | ss-task-prefixes | Passage `"x"`, title `"T"` | `"title: T \| text: x"` |
| ss-022 | ss-task-prefixes | Passage `"x"`, title nil or `""` | `"title: none \| text: x"` |
| ss-023 | ss-task-prefixes | Template `"{title} / {title}: "`, title `"$1 & {title}"`, passage `"x"` | `"$1 & {title} / {title}: x"` — first only, literal |
| ss-024 | ss-token-cap | `[2]`, 2000 × `7`, `[1]` (2002 ids) | 1024 ids: the first 1023, then `1` |
| ss-025 | ss-token-cap | 1024 ids | Unchanged |

### Golden set

`golden.json` in the bundle: 25 cases, `dims` 256, `min_cosine` 0.999. Each case
holds `text`, `title`, `prefixed`, `input_ids` and the reference `vector`. Query
cases' ids begin `[2, 8071, 236787, 3927]`, document cases' `[2, 3250, 236787]`,
and every case ends with id 1 (`<eos>`).

| ID | Case | Tokens | ID | Case | Tokens |
|----|------|-------:|----|------|-------:|
| ss-030 | query-plain | 15 | ss-043 | query-mixed-case | 15 |
| ss-031 | query-empty | 10 | ss-044 | document-plain | 23 |
| ss-032 | query-nfc | 12 | ss-045 | document-empty | 9 |
| ss-033 | query-nfd | 13 | ss-046 | document-titled | 19 |
| ss-034 | query-ligature | 15 | ss-047 | document-title-pipe | 17 |
| ss-035 | query-fullwidth | 17 | ss-048 | document-whitespace | 25 |
| ss-036 | query-japanese | 12 | ss-049 | document-code | 22 |
| ss-037 | query-chinese | 15 | ss-050 | document-markdown | 25 |
| ss-038 | query-korean | 11 | ss-051 | document-url | 33 |
| ss-039 | query-arabic | 12 | ss-052 | document-numbers | 45 |
| ss-040 | query-hindi | 11 | ss-053 | document-symbols | 25 |
| ss-041 | query-emoji-zwj | 19 | ss-054 | document-long | 4108 |
| ss-042 | query-astral | 30 | | | |

For every case (requirements ss-pinned-tokenizer, ss-task-prefixes,
ss-truncate-renormalise):

1. The prefixed input MUST equal the case's `prefixed`.
2. The uncapped token ids MUST equal `input_ids` exactly, and the token count
   MUST equal their length.
3. For a case within the cap, the cosine between the embedder's vector and the
   reference `vector` MUST be at least `min_cosine`.
4. `document-long` (ss-054) is past the cap: its embedded ids MUST be the first
   1023 of `input_ids` then id 1 (ss-token-cap), and its vector MUST be unit
   length with 256 values. Its reference vector was made uncapped and is not
   compared — the server's own test makes the same exception.

A further check, ss-055 (ss-halfvec-layout): every in-cap golden vector,
encoded to half floats and decoded, MUST still meet `min_cosine` against its
reference.

A runner without the bundle, or with LFS pointers in it, MUST skip these vectors
and say why, rather than fail.

### Half floats

| ID | Requirements | Input | Expected bytes |
|----|-------------|-------|----------------|
| ss-060 | ss-halfvec-layout | 1.0 | `00 3c` |
| ss-061 | ss-halfvec-layout | 0.5 | `00 38` |
| ss-062 | ss-halfvec-layout | -2.0 | `00 c0` |
| ss-063 | ss-halfvec-layout | 0.1 | `66 2e` |
| ss-064 | ss-halfvec-layout | 0.0 | `00 00` |
| ss-065 | ss-halfvec-layout | -0.0 | `00 80` |
| ss-066 | ss-halfvec-layout | 65504 | `ff 7b` |
| ss-067 | ss-halfvec-layout | 0.333333 | `55 35` |
| ss-068 | ss-halfvec-layout | 6 bytes decoded as 4 dims | Refused |

### Source hash

| ID | Requirements | Title, content | Expected |
|----|-------------|-------|----------|
| ss-070 | ss-source-hash | `"Notes"`, `"Hello"` | `240940d96ae57f5f7d8803b87cdd38180d2665d5420088488264957d06d4378e` |
| ss-071 | ss-source-hash | nil, `"Hello"` | `b9662bd8128a983445b3eef232acfb6fee5b9927c4e4672b71c1b60659652813` |
| ss-072 | ss-source-hash | `""`, `"Hello"` | Same as ss-071 |
| ss-073 | ss-source-hash | `"Café"`, `"naïve\r\ntext"` | `6419bfd95317913d875de8ded8a47de0e89e3d2f16adf999b80eb4cd480b49f3` |

### Chunking

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ss-080 | ss-chunk-rules | `""`, or only whitespace | No passages |
| ss-081 | ss-chunk-rules | `"a\r\n\r\nb"` | `["a\n\nb"]` |
| ss-082 | ss-chunk-rules | `"# Title\n\ntext"` | `["# Title\n\ntext"]` |
| ss-083 | ss-chunk-rules | `"#tag"`, `"### deep"` | Not headings |
| ss-084 | ss-chunk-rules | `"aaaa\n\nbbbb\n\ncccc"`, target 10 | `["aaaa\n\nbbbb", "cccc"]` |
| ss-085 | ss-chunk-rules | `"alpha beta gamma delta"`, max 12 | `["alpha beta", "gamma delta"]` |
| ss-086 | ss-chunk-rules | `"alpha beta gamma"`, max 10 | `["alpha", "beta", "gamma"]` |
| ss-087 | ss-chunk-rules | `"abcdefghij"`, max 4 | `["abcd", "efgh", "ij"]` |
| ss-088 | ss-chunk-rules, ss-token-budget | `"one two three four five six"`, fits ≤ 13 chars | `["one two three", "four five six"]` |
| ss-089 | ss-token-budget | Unmeasurable passage | Does not fit |

### Fusion

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ss-090 | ss-combined-order | semantic `[a, b]`, keyword `[c, a, d]`, limit 10 | `[a, b, c, d]` |
| ss-091 | ss-combined-order | semantic `[a]`, keyword `[a]` | `[a]`, the semantic hit kept |
| ss-092 | ss-combined-order | semantic `[a, b, c]`, keyword `[d, e]`, limit 4 | `[a, b, c, d]` |
| ss-093 | ss-rrf-long-only | Any lists, limit 10 | Refused |
| ss-094 | ss-rrf-long-only | `[a, b, c]` and `[c, d]`, limit 20 | `[c, a, b, d]` |
| ss-095 | ss-rrf-long-only | `[a, b, a]` and `[b]`, limit 11 | `[b, a]` |

### Store

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ss-100 | ss-device-index, ss-device-flag, ss-passage-hash | Index a document on the device | Device passages carrying its source hash, embedded |
| ss-101 | ss-server-replaces-device | Then server passages with that hash | Only server passages remain |
| ss-102 | ss-stale-server-ignored | Server passages with another hash | Ignored; result names the current hash |
| ss-103 | ss-device-index | Re-index text the server already split | Server passages kept, nothing embedded |
| ss-104 | ss-stamp-compare, ss-pending-embed | Server vector with another stamp | Passage pending, then embedded locally |
| ss-105 | ss-keyword | Passage `"near or not"`; queries `NEAR OR`, `"unbalanced * ^col: (`, `- ...` | First matches `d1`; the others return nothing and never raise an FTS syntax error |
| ss-106 | ss-one-per-document | Two matching passages in one document | One hit, the better |
| ss-107 | ss-no-embedder | `combined` with no embedder | Keyword hits only |

## Edge Cases

- **Empty query or empty document.** A blank query returns nothing. An empty
  document indexes to no passages; its source hash is still recorded, so stale
  server passages for older text stay ignored.
- **A bundle changes.** The new stamp differs, so every stored vector becomes
  pending. Nothing is compared across models while they catch up; keyword search
  keeps working throughout.
- **Text past the cap.** A passage is split to fit before embedding, so the cap
  cuts only a query, or a document the chunker could not split (a single run with
  no spaces longer than the budget).
- **Text the tokenizer cannot measure.** Treated as too long and halved, rather
  than embedded whole and silently capped.
- **Chinese and Japanese keywords.** `unicode61` does not segment them, so the
  keyword side matches only whole runs; the semantic side still covers them.
- **The server's passages for the same text differ from the device's.** Expected:
  the device follows the rules without promising identical output. The server's
  win as soon as they arrive.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `bundleDirectory` | URL | — (required for an embedder) | The bundle the app ships. |
| `verify` | Bool | `true` | Verify file hashes before loading. Only a test that already verified may pass `false`. |
| `embedder` | injected | `nil` | Any `TextEmbedder`; `nil` gives a keyword-only store. |
| `targetCharacters` | Int | 1500 | Passage packing target. |
| `maxCharacters` | Int | 4000 | Hard block cut. |
| `limit` | Int | 10 | Results returned. |
| `fusion` | enum | `serverOrder` | `reciprocalRank` only for `limit > 10`. |

The embedder is **injected, never constructed by the store**, so a test supplies
a fake and a new bundle needs no store change.

## Deep Linking

Not applicable.

## Localization

No user-facing prose. Error descriptions are developer-facing and not localized.

## Accessibility Options

Not applicable.

## Feature Flags

None. Semantic search is available exactly when the app passes a bundle.

## Analytics

None.

## Privacy

Embedding runs entirely on the device; text never leaves it for embedding.
Device passages and vectors MUST NOT be uploaded (`ss-device-never-pushed`).
Implementations MUST NOT log passage text, query text or vectors.

## Logging

None required. An implementation that logs MUST limit itself to counts, the
stamp and timings.

## Platform Notes

- **Swift (iOS / macOS)** — Two frameworks. `AgenticDeveloperHubSDKSemanticSearch`
  depends on system frameworks only (Foundation, CryptoKit, Accelerate) and holds everything that is pure: the
  `TextEmbedder` protocol, prefixes, `TokenLimit`, `SemanticStamp`,
  `EmbeddingBundle`, `VectorMath` (vDSP dot products),
  `HalfVectorCodec` (vImage float/half conversion), `PassageChunker`, `PassageSourceHash` and
  `SearchFusion`. `AgenticDeveloperHubSDKSemanticSearchStore` adds the
  `ONNXEmbedder` (onnxruntime-swift-package-manager 1.24.2, swift-transformers
  1.3.5 `Tokenizers` loading the bundle's `tokenizer.json`), and the GRDB store:
  `semantic_documents`, `semantic_passages`, `semantic_vectors` (half-float
  BLOB) and an external-content FTS5 table `semantic_passages_fts` with
  `unicode61 remove_diacritics 2`, kept in step by triggers. Inference runs on a
  private serial queue, one input at a time. The golden test reads
  `EMBEDDING_BUNDLE`; under `xcodebuild` it is passed as
  `TEST_RUNNER_EMBEDDING_BUNDLE`.

- **TypeScript (server)** — The reference for every vector above; see the server
  sources in the Overview. A web client searches through the server's API and
  does not embed.

- **Kotlin (Android)** — Planned. ONNX Runtime for Android runs the same
  `model.onnx`; the tokenizer MUST be loaded from the bundle's `tokenizer.json`
  (for example with the HuggingFace tokenizers bindings), never a tokenizer
  bundled in a library. Store vectors as half-float BLOBs in SQLite and use FTS5
  with the same tokenizer options. The golden set is the gate: a port is done
  when ss-030 to ss-055 pass.

- **Windows** — Planned. `Microsoft.ML.OnnxRuntime` and a tokenizer loaded from
  `tokenizer.json`; `System.Half` for the codec. Same gate.

## Design Decisions

**Decision**: The stamp is computed from the manifest, not by re-hashing files.
**Rationale**: It is what the server does, so it is the only way to be equal by
construction. Verification is a separate step that proves the files match the
manifest the stamp came from.
**Approved**: yes

**Decision**: Device passages are temporary and replaced wholesale by the
server's for the same source hash.
**Rationale**: The server is the authority on passages. Keeping device passages
only until then makes a new document searchable at once without a merge rule,
and the source hash says unambiguously which text a set of passages describes.
**Approved**: yes

**Decision**: Combined search uses the server's `mergeRanked`; RRF is offered
only past 10 results.
**Rationale**: Matching the server keeps a device result and a server result in
the same order. RRF only differs meaningfully over long lists.
**Approved**: yes

**Decision**: The cap keeps the last token.
**Rationale**: The tokenizer ends every input with `<eos>` and the server cuts
the same way, so both read the same tokens.
**Approved**: yes

**Decision**: The SDK takes a bundle directory and never downloads.
**Rationale**: A 300 MB model is an app's distribution decision, and a pinned
bundle is what makes the stamp mean anything.
**Approved**: yes

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| if-frontmatter-complete | passed | Artifact Formatting |
| if-type-field | passed | Artifact Formatting |
| if-title-heading | passed | Artifact Formatting |
| if-section-order | passed | Artifact Formatting |
| if-platform-notes | passed | Artifact Formatting |
| if-change-history | passed | Artifact Formatting |

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-08 | Mike Fullerton | Initial creation, with the Apple reference implementation. |
