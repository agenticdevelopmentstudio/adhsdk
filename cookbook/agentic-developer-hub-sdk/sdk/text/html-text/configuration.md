
Nothing is supplied by the caller or the environment: both operations take only their string, and there are no environment variables, settings keys or injected dependencies. The behavior is set by built-in constants, listed below. They are private and are not settings a caller can change.

**Built-in constants**

| Constant | Type | Default | Description |
|--------|------|---------|-------------|
| `hidden` | `Set<String>` | `style`, `script`, `title`, `noscript` | Elements whose content is dropped |
| `paragraphElements` | `Set<String>` | `p`, `h1`-`h6`, `blockquote`, `table`, `ul`, `ol`, `dl`, `pre`, `hr` | Elements that produce a blank-line break |
| `lineElements` | `Set<String>` | `div`, `tr`, `li`, `dt`, `dd`, `section`, `article`, `header`, `footer`, `nav`, `aside`, `main`, `address`, `figure`, `figcaption`, `center`, `form`, `fieldset` | Elements that produce a single line break |
| `named` | `[String: String]` | 77 entries (listed under Entity Tables in this section) | Named references that decode |
| `windows1252` | `[UInt32: Character]` | 27 entries (listed under Entity Tables in this section) | Characters shown for `&#128;` to `&#159;` |
| `invisible` | `Set<Unicode.Scalar>` | U+200B, U+2060, U+FEFF, U+00AD, U+034F | Scalars always dropped |
| `joiners` | `Set<Unicode.Scalar>` | U+200C, U+200D | Scalars kept only between two visible scalars |
| marker scalars | `Unicode.Scalar` | U+0001, U+0002, U+0003; U+E000, U+E001 | Internal soft-break, paragraph-break and bullet markers; stand-ins for preformatted space and tab |
| reference window | `Int` | 12 scalars after `&` | How far to look for the `;` |
| numeric digits | `ClosedRange<Int>` | 1 to 8 | Digits allowed in a numeric reference |

### Entity Tables

Both tables are built-in and complete: a reference not listed here is unknown and is left as written. Names are case-sensitive.

#### Named references (77)

| Name | Decodes to | Scalar |
|------|-----------|--------|
| `amp` | `&` | U+0026 |
| `lt` | `<` | U+003C |
| `gt` | `>` | U+003E |
| `quot` | `"` | U+0022 |
| `apos` | `'` | U+0027 |
| `nbsp` | (space or invisible) | U+00A0 |
| `ensp` | (space or invisible) | U+2002 |
| `emsp` | (space or invisible) | U+2003 |
| `thinsp` | (space or invisible) | U+2009 |
| `zwnj` | (space or invisible) | U+200C |
| `zwj` | (space or invisible) | U+200D |
| `shy` | (space or invisible) | U+00AD |
| `ndash` | – | U+2013 |
| `mdash` | — | U+2014 |
| `hellip` | … | U+2026 |
| `bull` | • | U+2022 |
| `middot` | · | U+00B7 |
| `lsquo` | ‘ | U+2018 |
| `rsquo` | ’ | U+2019 |
| `sbquo` | ‚ | U+201A |
| `ldquo` | “ | U+201C |
| `rdquo` | ” | U+201D |
| `bdquo` | „ | U+201E |
| `laquo` | « | U+00AB |
| `raquo` | » | U+00BB |
| `lsaquo` | ‹ | U+2039 |
| `rsaquo` | › | U+203A |
| `copy` | © | U+00A9 |
| `reg` | ® | U+00AE |
| `trade` | ™ | U+2122 |
| `deg` | ° | U+00B0 |
| `plusmn` | ± | U+00B1 |
| `times` | × | U+00D7 |
| `divide` | ÷ | U+00F7 |
| `euro` | € | U+20AC |
| `pound` | £ | U+00A3 |
| `cent` | ¢ | U+00A2 |
| `yen` | ¥ | U+00A5 |
| `sect` | § | U+00A7 |
| `para` | ¶ | U+00B6 |
| `dagger` | † | U+2020 |
| `Dagger` | ‡ | U+2021 |
| `prime` | ′ | U+2032 |
| `Prime` | ″ | U+2033 |
| `larr` | ← | U+2190 |
| `rarr` | → | U+2192 |
| `uarr` | ↑ | U+2191 |
| `darr` | ↓ | U+2193 |
| `frac12` | ½ | U+00BD |
| `frac14` | ¼ | U+00BC |
| `frac34` | ¾ | U+00BE |
| `iexcl` | ¡ | U+00A1 |
| `iquest` | ¿ | U+00BF |
| `aacute` | á | U+00E1 |
| `eacute` | é | U+00E9 |
| `iacute` | í | U+00ED |
| `oacute` | ó | U+00F3 |
| `uacute` | ú | U+00FA |
| `Aacute` | Á | U+00C1 |
| `Eacute` | É | U+00C9 |
| `Iacute` | Í | U+00CD |
| `Oacute` | Ó | U+00D3 |
| `Uacute` | Ú | U+00DA |
| `agrave` | à | U+00E0 |
| `egrave` | è | U+00E8 |
| `ograve` | ò | U+00F2 |
| `auml` | ä | U+00E4 |
| `euml` | ë | U+00EB |
| `ouml` | ö | U+00F6 |
| `uuml` | ü | U+00FC |
| `Auml` | Ä | U+00C4 |
| `Ouml` | Ö | U+00D6 |
| `Uuml` | Ü | U+00DC |
| `ntilde` | ñ | U+00F1 |
| `Ntilde` | Ñ | U+00D1 |
| `ccedil` | ç | U+00E7 |
| `szlig` | ß | U+00DF |

#### windows-1252 numeric references 128 to 159 (27)

The five codes 129, 141, 143, 144 and 157 are undefined and decode to nothing.

| Code | Decodes to | Scalar |
|------|-----------|--------|
| 128 (0x80) | € | U+20AC |
| 130 (0x82) | ‚ | U+201A |
| 131 (0x83) | ƒ | U+0192 |
| 132 (0x84) | „ | U+201E |
| 133 (0x85) | … | U+2026 |
| 134 (0x86) | † | U+2020 |
| 135 (0x87) | ‡ | U+2021 |
| 136 (0x88) | ˆ | U+02C6 |
| 137 (0x89) | ‰ | U+2030 |
| 138 (0x8A) | Š | U+0160 |
| 139 (0x8B) | ‹ | U+2039 |
| 140 (0x8C) | Œ | U+0152 |
| 142 (0x8E) | Ž | U+017D |
| 145 (0x91) | ‘ | U+2018 |
| 146 (0x92) | ’ | U+2019 |
| 147 (0x93) | “ | U+201C |
| 148 (0x94) | ” | U+201D |
| 149 (0x95) | • | U+2022 |
| 150 (0x96) | – | U+2013 |
| 151 (0x97) | — | U+2014 |
| 152 (0x98) | ˜ | U+02DC |
| 153 (0x99) | ™ | U+2122 |
| 154 (0x9A) | š | U+0161 |
| 155 (0x9B) | › | U+203A |
| 156 (0x9C) | œ | U+0153 |
| 158 (0x9E) | ž | U+017E |
| 159 (0x9F) | Ÿ | U+0178 |
