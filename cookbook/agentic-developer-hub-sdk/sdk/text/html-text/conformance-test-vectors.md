
Tests are in `HTMLTextTests` (`packages/apple/AgenticDeveloperHubSDK/SDK/Tests/AgenticDeveloperHubSDKTests/HTMLTextTests.swift`); the named test is the source of each vector's assertion.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| html-text-001 | plain-text-entry, empty-input | `plainText` of `""`; of a document with only a `style` in `head` and a space in `body` (test `emptyOrInvisibleHTMLIsEmpty`) | `""` in both cases |
| html-text-002 | decode-entities-entry, entity-named, entity-numeric | `decodeEntities` of `I&#39;m &lt;here&gt; &amp; &quot;ok&quot;`; of `it&#x27;s &#X2014; &rsquo;&hellip;`; of `a&nbsp;b` (test `decodesNamedAndNumericEntities`) | `I'm <here> & "ok"`; `it's — ’…`; `a` U+00A0 `b` |
| html-text-003 | plain-text-no-ampersand | `decodeEntities("plain words")` (test `plainTextWithoutAmpersandIsUnchanged`) | `plain words` |
| html-text-004 | entity-single-pass | `decodeEntities("&amp;lt;")` (test `decodesOnlyOnce`) | `&lt;` |
| html-text-005 | entity-unknown, entity-numeric-digits, entity-invalid-scalar, entity-lookahead | `decodeEntities` of `AT&T; R&D &bogus; &#; &#xZZ; &#0; &#+65; &#-65; &# 65; &#x+41; &#123456789; 5 & 6; tom&jerry` (test `leavesUnknownAndMalformedReferencesAlone`) | Output equals the input, character for character |
| html-text-006 | entity-windows-1252 | `decodeEntities` of `don&#146;t &#147;quoted&#148; &#128;5&#133;`; of `a&#x92;b` (test `readsTheC1RangeAsWindows1252`) | `don’t “quoted” €5…`; `a’b` |
| html-text-007 | entity-windows-1252 | `decodeEntities("&#129;&#157;x")` (test `dropsControlCharactersSoMailCantDriveTheTerminal`) | `x` |
| html-text-008 | control-dropped | `decodeEntities` of `&#27;[2J&#27;]0;title&#7;done`; of raw ESC `[31mred` BEL and U+009B; of `tab&#9;and&#10;line` (test `dropsControlCharactersSoMailCantDriveTheTerminal`) | `[2J]0;titledone`; `raw[31mred`; `tab` TAB `and` LF `line` |
| html-text-009 | control-dropped, entity-before-whitespace | `plainText("<p>&#27;[2Jhi</p>")` (same test) | `[2Jhi` |
| html-text-010 | invisible-dropped | `decodeEntities("Hi&zwnj;&#847;&#8203; there\u{FEFF}")` (test `dropsInvisiblePaddingCharacters`) | `Hi there` |
| html-text-011 | entity-scalar-based, nbsp-plain | `decodeEntities` of `Preheader&nbsp;` U+034F `&nbsp;` U+034F; `plainText("<p>Sale&nbsp;" U+034F "&nbsp;" U+034F "</p>")` (test `decodesAReferenceFollowedByACombiningMark`) | `Preheader` U+00A0 U+00A0; `Sale` |
| html-text-012 | joiner-between-visible | `decodeEntities` of man-ZWJ-laptop, `👨&zwj;💻`, a Persian word with ZWNJ and `&zwnj;` form (test `keepsJoinersThatJoinVisibleCharacters`) | Joiner kept; the decoded and raw forms are equal to the raw joined sequence |
| html-text-013 | joiner-between-visible | `decodeEntities("&zwnj; &zwnj;&nbsp;Sale\u{200C}")` (same test) | U+0020 U+00A0 `Sale`: every joiner dropped |
| html-text-014 | hidden-elements, comment, hidden-open-space | A document with `title`, `style`, a comment and a `script` around `<p>Visible</p>` (test `htmlDropsHeadStyleScriptAndComments`) | `Visible` |
| html-text-015 | paragraph-elements, line-elements, br-break, whitespace-collapse, entity-numeric | `<p>Hi Mike,</p>`, then `<p>Thanks   for` newline `   applying.<br>We&#39;ll be in touch.<br/>Soon.</p>`, `<div>The Team</div>`, `<div>Acme&nbsp;Inc.</div>` (test `htmlKeepsParagraphsAndLineBreaks`) | `Hi Mike,` blank line `Thanks for applying.` newline `We'll be in touch.` newline `Soon.` blank line `The Team` newline `Acme Inc.` |
| html-text-016 | blank-line-collapse, break-edges, soft-break-merge, line-trim | `<div><div><p>&nbsp;</p><p>One</p></div></div><br><br><br><br><table><tr><td>Two</td></tr></table>` (test `htmlCollapsesBlankLinesAndTrimsLines`) | `One\n\nTwo` |
| html-text-017 | table-cells, list-bullet, line-elements | A two-row table (`td`, `td`; `th`, `td`) then `<ul><li>First</li><li>Second &amp; last</li></ul>` (test `htmlTableCellsAndListItems`) | `Role Engineer\nWhere Remote\n\n- First\n- Second & last` |
| html-text-018 | list-bullet | `<ul><li><p>First</p></li><li><p>Second</p></li></ul>`; `<ol><li><div>One</div></li><li> Two</li></ol>` (test `listItemsWithBlockChildrenKeepTheirBullets`) | `- First\n\n- Second`; `- One\n- Two` |
| html-text-019 | br-break, soft-break-merge | `Line one</br>Line two`; `Line<br> <div>Next</div>`; `Line<br>\n  <p>Para</p>` (test `closingBrIsABreakAndASpaceAfterBrAddsNoBlankLine`) | `Line one\nLine two`; `Line\nNext`; `Line\n\nPara` |
| html-text-020 | other-tags-removed, entity-not-reparsed, entity-attributes-ignored, quoted-attribute-value | `<p>See <a href="https://example.com/x?a=1&amp;b=2">the posting</a> &lt;b&gt;now&lt;/b&gt;</p>` (test `htmlLinksKeepTheirTextAndEscapedTagsSurvive`) | `See the posting <b>now</b>` |
| html-text-021 | tag-name, tag-attributes, hidden-close-match | `<HTML><HEAD><STYLE>` newline `x{}` newline `</STYLE></HEAD><BODY><P` newline `class="a">Up</P><BR>Down</BODY></HTML>` (test `htmlTagsAreCaseInsensitiveAndSpanLines`) | `Up\n\nDown` |
| html-text-022 | tag-start | `<p>I <3 you</p><p><a href=x>link</a></p>` (test `aBareLessThanIsTextAndAQuotedGreaterThanStaysInItsTag`) | `I <3 you\n\nlink` |
| html-text-023 | quoted-attribute-value | `<p>Hi Mike,</p><img alt="Shop now >" width="200"><p>Thanks</p>`; `<p title='a > b'>x < y and y > z</p>` (same test) | `Hi Mike,\n\nThanks`; `x < y and y > z` |
| html-text-024 | control-no-marker-forgery | `plainText("a < b" U+0001 U+0002 " c")` (same test) | `a < b c` |
| html-text-025 | unterminated-markup, hidden-unclosed | `<p>Shown</p><!-- never closed <p>gone</p>`; `<p>Shown</p><style>p{} <p>gone</p>`; `<p>Shown</p><img src="x` (test `anUnclosedCommentTagOrHiddenElementRunsToTheEnd`) | `Shown` for each |
| html-text-026 | hidden-raw-content, hidden-elements | `<script>if (a</b) {}</script>Shown` (same test) | `Shown` |
| html-text-027 | linear-time | Five hostile inputs: 50,000 `<!--`; a `style` plus 50,000 `a{} `; 100,000 `< ` then `<p>end</p>`; 50,000 `<a `; 50,000 `</` (test `hostileHTMLConvertsInLinearTime`) | All five convert in under 5 seconds total; the second yields `x` |
| html-text-028 | pre-preserve, pre-whitespace | `<pre>step 1 ok\nstep 2 FAILED</pre>` (test `preKeepsItsLineBreaksAndIndentation`) | `step 1 ok\nstep 2 FAILED` |
| html-text-029 | pre-first-newline, pre-line-endings, pre-trailing-trim, pre-decoded-breaks | `<pre>\n  indented\r\n\tTab  \nx&#10;y</pre>` (same test) | `  indented\n\tTab\nx\ny` |
| html-text-030 | pre-preserve, whitespace-collapse, pre-depth | `<p>a   b</p><PRE>x  <b>y</b></PRE><p>c\n d</p>` (same test) | `a b\n\nx  y\n\nc d` |
| html-text-031 | entity-before-whitespace, pre-decoded-breaks | `<p>Thank you for applying.&#13;\nWe will review it&#13;\nand reply.</p>`; `a&#10;&#9;b` (test `encodedLineBreaksAreCollapsibleWhitespace`) | `Thank you for applying. We will review it and reply.`; `a b` |
| html-text-032 | declaration, bogus-close | `<p>A</p><!DOCTYPE html><?xml version="1.0"?></ x><p>B</p>` (derived from `tag(in:at:)`; no test) | `A\n\nB` |
| html-text-033 | pre-depth | `<pre>a</pre></pre><p>b</p>` and `<pre>a  b` (derived from `TextWriter.write(tag:)`; no test) | `a\n\nb`; `a  b` |
| html-text-034 | pre-private-use | `plainText("a" U+E000 "b")` (derived from `TextWriter.write(text:)`; no test) | `ab` |
| html-text-035 | stateless, no-feedback, stage-order | Two concurrent calls on different strings (derived from the type declaration; no test) | Each returns the result it returns alone |

