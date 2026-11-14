
Nothing is supplied by the caller or the environment: both operations take only their string, and there are no environment variables, settings keys or injected dependencies. The behavior is set by built-in constants.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hidden` | `Set<String>` | `style`, `script`, `title`, `noscript` | Elements whose content is dropped |
| `paragraphElements` | `Set<String>` | `p`, `h1`-`h6`, `blockquote`, `table`, `ul`, `ol`, `dl`, `pre`, `hr` | Elements that produce a blank-line break |
| `lineElements` | `Set<String>` | `div`, `tr`, `li`, `dt`, `dd`, `section`, `article`, `header`, `footer`, `nav`, `aside`, `main`, `address`, `figure`, `figcaption`, `center`, `form`, `fieldset` | Elements that produce a single line break |
| `named` | `[String: String]` | 77 entries | Named references that decode |
| `windows1252` | `[UInt32: Character]` | 27 entries | Characters shown for `&#128;` to `&#159;` |
| `invisible` | `Set<Unicode.Scalar>` | U+200B, U+2060, U+FEFF, U+00AD, U+034F | Scalars always dropped |
| `joiners` | `Set<Unicode.Scalar>` | U+200C, U+200D | Scalars kept only between two visible scalars |
| marker scalars | `Unicode.Scalar` | U+0001, U+0002, U+0003; U+E000, U+E001 | Internal soft-break, paragraph-break and bullet markers; stand-ins for preformatted space and tab |
| reference window | `Int` | 12 scalars after `&` | How far to look for the `;` |
| numeric digits | `ClosedRange<Int>` | 1 to 8 | Digits allowed in a numeric reference |

