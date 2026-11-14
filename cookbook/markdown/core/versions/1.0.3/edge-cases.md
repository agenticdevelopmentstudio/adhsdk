
- Fewer than 3 fence-marker characters MUST NOT be treated as a fence opener regardless of surrounding whitespace **(boundary value)** — fence-marker-recognition.
- A closing-fence line shorter than its opener, of the wrong marker, or carrying its own info string MUST be classified `.insideFence`, not treated as a closer **(malformed input)** — closing-fence-matching.
- An opening fence with no matching closer anywhere in the remaining input MUST run to end of file and yield no fenced block **(unterminated input)** — unterminated-fence-runs-to-eof.
- A frontmatter-looking `---` block not anchored at position 0 MUST NOT be recognized as frontmatter **(malformed input)** — frontmatter-block-detection.
- An unclosed `---` block MUST NOT be recognized as frontmatter **(malformed input)** — frontmatter-block-detection.
- Setting a frontmatter key to `nil` when it is the block's only key MUST remove the whole block, fences included, not leave an empty shell **(boundary value)** — setting-nil-removes-key.
- A title-cap cut that falls inside a UTF-16 surrogate pair MUST drop the whole pair rather than emit an invalid half **(boundary value, Unicode)** — title-character-cap.
- A frontmatter block extending past the 2000-Unicode-scalar excerpt source window MUST still be read in full for title derivation **(boundary value)** — unicode-scalar-excerpt-source-window.
- A fetch aborted for the timeout reason that nonetheless resolves afterward MUST be shown as a success with that data — a timeout-reason abort does not, by itself, drop the result the way an unmount/id-change abort does; only a fetch that instead rejects after a timeout abort produces the timeout error message **(concurrent access)** — stale-response-suppression.
- A `problem+json` error body MUST be read as text exactly once; a second read (e.g. also as JSON) would throw a "body already used" error **(error state)** — default-fetcher-error-messages.
- A malformed or non-mapping frontmatter block on the write path MUST leave `content` completely unchanged rather than attempting a partial patch **(error state)** — write-path-refuses-unparseable-yaml.
- A syntactically malformed frontmatter block (e.g. `foo: [unclosed`) does NOT make `frontmatterOf`/`deriveDocumentTitle` return `null` or fall back to the body — `parseYaml`'s silent log level recovers a partial document, so the read path still derives a title from it, while `setFrontmatterTitle`'s write path independently refuses to touch the same block because `parseDocument` reports an error **(read/write asymmetry)** — real-yaml-parser-for-frontmatter, write-path-refuses-unparseable-yaml.
- Raw HTML embedded in source markdown MUST be dropped by `remark-rehype`'s default `allowDangerousHtml: false`, never passed to the sanitizer as trusted markup **(security boundary)** — pipeline-stage-order.

