
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| json-renderer-001 | pretty-print-document | `{"a":1,"b":[true]}` (from `pretty-json.test.ts`, "indents a JSON document") | Body is `{`, `  "a": 1,`, `  "b": [`, `    true`, `  ]`, `}` on separate lines, fenced as json, no note. |
| json-renderer-002 | pretty-print-lines, skip-blank-lines | `{"a":1}`, a blank line, `{"b":2}`, trailing newline (from "indents each record of JSON Lines") | Body is `{` / `  "a": 1` / `}` / `{` / `  "b": 2` / `}`, joined by a single newline, no blank line between records. |
| json-renderer-003 | invalid-shown-as-written, invalid-note, fence-language | `not json` (from "returns null for text that is neither") | Note "Not valid JSON — shown as written." then `not json` in a fence with no language. |
| json-renderer-004 | invalid-shown-as-written | `{"a":1}` newline `nope` (from "returns null for text that is neither") | One bad line makes the whole text invalid; shown unchanged with the note. |
| json-renderer-005 | invalid-shown-as-written | `   ` (whitespace only, from the same test) | Treated as invalid: the note, then the whitespace unmodified. |
| json-renderer-006 | fence-longer-than-body | JSON string value that contains a run of four backticks (derived from `pretty-json.test.ts`, "fences with more backticks than the body holds") | Fence is five backticks; block does not close early. |
| json-renderer-007 | single-line-not-lines, valid-no-note | A single line `{"a":1` (unterminated) | Invalid: the note and the text as written. |
| json-renderer-008 | limit-boundary | Valid JSON whose pretty-printed body is exactly 524288 characters | Rendered through `MarkdownRenderer`, with colours. |
| json-renderer-009 | highlight-limit, plain-path-markup, plain-path-no-processing | Valid JSON whose pretty-printed body is 524289 characters | A `div.adh-mv-prose` containing `pre.shiki > code` with the body; no Markdown pipeline call; no note. |
| json-renderer-010 | plain-path-note | Invalid text of 524289 characters | `p.adh-mv-json-note` with the note, then `pre.shiki > code` with the text unmodified. |
| json-renderer-011 | limit-measures-body | Compact JSON of 400000 characters that pretty-prints to more than 524288 | Takes the plain path, because the displayed text exceeds the limit. |
| json-renderer-012 | forward-wrap, plain-path-wrap | `wrap` true, once with a small and once with an oversized body | Small: `wrap` is passed to `MarkdownRenderer`. Oversized: root class includes `adh-mv-prose--wrap`. |
| json-renderer-013 | accept-wrap, default-measure | `wrap` omitted, oversized body | Root class is `adh-mv-prose` only: no wrap modifier and no fill modifier. |
| json-renderer-014 | inherit-markdown-errors | Small valid body while the Markdown pipeline rejects | `MarkdownRenderer`'s "Failed to render document" alert pane is shown; the component adds nothing. |

Test coverage note: `packages/web/packages/markdown/src/__tests__/jsonRenderer.test.tsx` renders `JsonRenderer` for all 14 vectors; `pretty-json.test.ts` and `prose-class.test.ts` cover the helpers. The one SHOULD requirement, `memoise-pretty`, has no vector because it is a performance property with no observable output.

