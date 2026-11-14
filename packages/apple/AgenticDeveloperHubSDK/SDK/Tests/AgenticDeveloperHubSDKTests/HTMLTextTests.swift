import Foundation
import Testing
@testable import AgenticDeveloperHubSDK

struct HTMLTextTests {
    @Test func decodesNamedAndNumericEntities() {
        #expect(HTMLText.decodeEntities("I&#39;m &lt;here&gt; &amp; &quot;ok&quot;") == "I'm <here> & \"ok\"")
        #expect(HTMLText.decodeEntities("it&#x27;s &#X2014; &rsquo;&hellip;") == "it's — ’…")
        #expect(HTMLText.decodeEntities("a&nbsp;b") == "a\u{00A0}b")
    }

    @Test func decodesOnlyOnce() {
        #expect(HTMLText.decodeEntities("&amp;lt;") == "&lt;")
    }

    @Test func leavesUnknownAndMalformedReferencesAlone() {
        let text = "AT&T; R&D &bogus; &#; &#xZZ; &#0; &#+65; &#-65; &# 65; &#x+41; &#123456789; 5 & 6; tom&jerry"
        #expect(HTMLText.decodeEntities(text) == text)
    }

    @Test func readsTheC1RangeAsWindows1252() {
        #expect(HTMLText.decodeEntities("don&#146;t &#147;quoted&#148; &#128;5&#133;") == "don’t “quoted” €5…")
        #expect(HTMLText.decodeEntities("a&#x92;b") == "a’b")
    }

    @Test func dropsControlCharactersSoMailCantDriveTheTerminal() {
        #expect(HTMLText.decodeEntities("&#27;[2J&#27;]0;title&#7;done") == "[2J]0;titledone")
        #expect(HTMLText.decodeEntities("raw\u{1B}[31mred\u{7}\u{9B}") == "raw[31mred")
        #expect(HTMLText.decodeEntities("tab&#9;and&#10;line") == "tab\tand\nline")
        #expect(HTMLText.decodeEntities("&#129;&#157;x") == "x")
        #expect(HTMLText.plainText(fromHTML: "<p>&#27;[2Jhi</p>") == "[2Jhi")
    }

    @Test func dropsInvisiblePaddingCharacters() {
        #expect(HTMLText.decodeEntities("Hi&zwnj;&#847;&#8203; there\u{FEFF}") == "Hi there")
    }

    @Test func decodesAReferenceFollowedByACombiningMark() {
        #expect(HTMLText.decodeEntities("Preheader&nbsp;\u{034F}&nbsp;\u{034F}") == "Preheader\u{00A0}\u{00A0}")
        #expect(HTMLText.decodeEntities("&quot;\u{200C}Hi&quot;") == "\"\u{200C}Hi\"")
        #expect(HTMLText.plainText(fromHTML: "<p>Sale&nbsp;\u{034F}&nbsp;\u{034F}</p>") == "Sale")
    }

    @Test func keepsJoinersThatJoinVisibleCharacters() {
        let coder = "👨\u{200D}💻"
        #expect(HTMLText.decodeEntities(coder) == coder)
        #expect(HTMLText.decodeEntities("👨&zwj;💻") == coder)
        let persian = "می\u{200C}خواهم"
        #expect(HTMLText.decodeEntities(persian) == persian)
        #expect(HTMLText.decodeEntities("می&zwnj;خواهم") == persian)
        // Preview padding: joiners between spaces, or at either end, join nothing.
        #expect(HTMLText.decodeEntities("&zwnj; &zwnj;&nbsp;Sale\u{200C}") == " \u{00A0}Sale")
    }

    @Test func plainTextWithoutAmpersandIsUnchanged() {
        #expect(HTMLText.decodeEntities("plain words") == "plain words")
    }

    @Test func htmlDropsHeadStyleScriptAndComments() {
        let html = """
            <html><head><title>Ignored</title><style>p { color: red; }</style></head>
            <body><!-- a comment --><script type="text/javascript">alert("x")</script>
            <p>Visible</p></body></html>
            """
        #expect(HTMLText.plainText(fromHTML: html) == "Visible")
    }

    @Test func htmlKeepsParagraphsAndLineBreaks() {
        let html = """
            <p>Hi Mike,</p>
            <p>Thanks   for
               applying.<br>We&#39;ll be in touch.<br/>Soon.</p><div>The Team</div><div>Acme&nbsp;Inc.</div>
            """
        #expect(HTMLText.plainText(fromHTML: html) == """
            Hi Mike,

            Thanks for applying.
            We'll be in touch.
            Soon.

            The Team
            Acme Inc.
            """)
    }

    @Test func htmlCollapsesBlankLinesAndTrimsLines() {
        let html = "<div><div><p>&nbsp;</p><p>One</p></div></div><br><br><br><br><table><tr><td>Two</td></tr></table>"
        #expect(HTMLText.plainText(fromHTML: html) == "One\n\nTwo")
    }

    @Test func htmlTableCellsAndListItems() {
        let html = "<table><tr><td>Role</td><td>Engineer</td></tr><tr><th>Where</th><td>Remote</td></tr></table>"
            + "<ul><li>First</li><li>Second &amp; last</li></ul>"
        #expect(HTMLText.plainText(fromHTML: html) == "Role Engineer\nWhere Remote\n\n- First\n- Second & last")
    }

    @Test func listItemsWithBlockChildrenKeepTheirBullets() {
        let html = "<ul><li><p>First</p></li><li><p>Second</p></li></ul>"
        #expect(HTMLText.plainText(fromHTML: html) == "- First\n\n- Second")
        #expect(HTMLText.plainText(fromHTML: "<ol><li><div>One</div></li><li> Two</li></ol>") == "- One\n- Two")
    }

    @Test func closingBrIsABreakAndASpaceAfterBrAddsNoBlankLine() {
        #expect(HTMLText.plainText(fromHTML: "Line one</br>Line two") == "Line one\nLine two")
        #expect(HTMLText.plainText(fromHTML: "Line<br> <div>Next</div>") == "Line\nNext")
        #expect(HTMLText.plainText(fromHTML: "Line<br>\n  <p>Para</p>") == "Line\n\nPara")
    }

    @Test func htmlLinksKeepTheirTextAndEscapedTagsSurvive() {
        let html = #"<p>See <a href="https://example.com/x?a=1&amp;b=2">the posting</a> &lt;b&gt;now&lt;/b&gt;</p>"#
        #expect(HTMLText.plainText(fromHTML: html) == "See the posting <b>now</b>")
    }

    @Test func htmlTagsAreCaseInsensitiveAndSpanLines() {
        let html = "<HTML><HEAD><STYLE>\nx{}\n</STYLE></HEAD><BODY><P\nclass=\"a\">Up</P><BR>Down</BODY></HTML>"
        #expect(HTMLText.plainText(fromHTML: html) == "Up\n\nDown")
    }

    @Test func aBareLessThanIsTextAndAQuotedGreaterThanStaysInItsTag() {
        #expect(HTMLText.plainText(fromHTML: "<p>I <3 you</p><p><a href=x>link</a></p>") == "I <3 you\n\nlink")
        let html = #"<p>Hi Mike,</p><img alt="Shop now >" width="200"><p>Thanks</p>"#
        #expect(HTMLText.plainText(fromHTML: html) == "Hi Mike,\n\nThanks")
        #expect(HTMLText.plainText(fromHTML: "<p title='a > b'>x < y and y > z</p>") == "x < y and y > z")
        #expect(HTMLText.plainText(fromHTML: "a < b\u{1}\u{2} c") == "a < b c")
    }

    @Test func anUnclosedCommentTagOrHiddenElementRunsToTheEnd() {
        #expect(HTMLText.plainText(fromHTML: "<p>Shown</p><!-- never closed <p>gone</p>") == "Shown")
        #expect(HTMLText.plainText(fromHTML: "<p>Shown</p><style>p{} <p>gone</p>") == "Shown")
        #expect(HTMLText.plainText(fromHTML: "<p>Shown</p><img src=\"x") == "Shown")
        #expect(HTMLText.plainText(fromHTML: "<script>if (a</b) {}</script>Shown") == "Shown")
    }

    @Test(.timeLimit(.minutes(1)))
    func hostileHTMLConvertsInLinearTime() {
        let hostile = [
            String(repeating: "<!--", count: 50_000),
            "<p>x</p><style>" + String(repeating: "a{} ", count: 50_000),
            String(repeating: "< ", count: 100_000) + "<p>end</p>",
            String(repeating: "<a ", count: 50_000),
            String(repeating: "</", count: 50_000)
        ]
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for html in hostile { _ = HTMLText.plainText(fromHTML: html) }
        }
        #expect(elapsed < .seconds(5), "took \(elapsed)")
        #expect(HTMLText.plainText(fromHTML: hostile[1]) == "x")
    }

    @Test func preKeepsItsLineBreaksAndIndentation() {
        #expect(HTMLText.plainText(fromHTML: "<pre>step 1 ok\nstep 2 FAILED</pre>") == "step 1 ok\nstep 2 FAILED")
        #expect(HTMLText.plainText(fromHTML: "<pre>\n  indented\r\n\tTab  \nx&#10;y</pre>")
            == "  indented\n\tTab\nx\ny")
        let mixed = "<p>a   b</p><PRE>x  <b>y</b></PRE><p>c\n d</p>"
        #expect(HTMLText.plainText(fromHTML: mixed) == "a b\n\nx  y\n\nc d")
    }

    @Test func encodedLineBreaksAreCollapsibleWhitespace() {
        let html = "<p>Thank you for applying.&#13;\nWe will review it&#13;\nand reply.</p>"
        #expect(HTMLText.plainText(fromHTML: html) == "Thank you for applying. We will review it and reply.")
        #expect(HTMLText.plainText(fromHTML: "a&#10;&#9;b") == "a b")
    }

    @Test func emptyOrInvisibleHTMLIsEmpty() {
        #expect(HTMLText.plainText(fromHTML: "") == "")
        #expect(HTMLText.plainText(fromHTML: "<html><head><style>a{}</style></head><body> </body></html>") == "")
    }
}
