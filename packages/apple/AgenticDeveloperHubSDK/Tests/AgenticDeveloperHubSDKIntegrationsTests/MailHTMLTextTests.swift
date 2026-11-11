import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

struct MailHTMLTextTests {
    @Test func decodesNamedAndNumericEntities() {
        #expect(MailHTMLText.decodeEntities("I&#39;m &lt;here&gt; &amp; &quot;ok&quot;") == "I'm <here> & \"ok\"")
        #expect(MailHTMLText.decodeEntities("it&#x27;s &#X2014; &rsquo;&hellip;") == "it's — ’…")
        #expect(MailHTMLText.decodeEntities("a&nbsp;b") == "a\u{00A0}b")
    }

    @Test func decodesOnlyOnce() {
        #expect(MailHTMLText.decodeEntities("&amp;lt;") == "&lt;")
    }

    @Test func leavesUnknownAndMalformedReferencesAlone() {
        let text = "AT&T; R&D &bogus; &#; &#xZZ; &#0; &#+65; &#-65; &# 65; &#x+41; &#123456789; 5 & 6; tom&jerry"
        #expect(MailHTMLText.decodeEntities(text) == text)
    }

    @Test func readsTheC1RangeAsWindows1252() {
        #expect(MailHTMLText.decodeEntities("don&#146;t &#147;quoted&#148; &#128;5&#133;") == "don’t “quoted” €5…")
        #expect(MailHTMLText.decodeEntities("a&#x92;b") == "a’b")
    }

    @Test func dropsControlCharactersSoMailCantDriveTheTerminal() {
        #expect(MailHTMLText.decodeEntities("&#27;[2J&#27;]0;title&#7;done") == "[2J]0;titledone")
        #expect(MailHTMLText.decodeEntities("raw\u{1B}[31mred\u{7}\u{9B}") == "raw[31mred")
        #expect(MailHTMLText.decodeEntities("tab&#9;and&#10;line") == "tab\tand\nline")
        #expect(MailHTMLText.decodeEntities("&#129;&#157;x") == "x")
        #expect(MailHTMLText.plainText(fromHTML: "<p>&#27;[2Jhi</p>") == "[2Jhi")
    }

    @Test func dropsInvisiblePaddingCharacters() {
        #expect(MailHTMLText.decodeEntities("Hi&zwnj;&#847;&#8203; there\u{FEFF}") == "Hi there")
    }

    @Test func decodesAReferenceFollowedByACombiningMark() {
        #expect(MailHTMLText.decodeEntities("Preheader&nbsp;\u{034F}&nbsp;\u{034F}") == "Preheader\u{00A0}\u{00A0}")
        #expect(MailHTMLText.decodeEntities("&quot;\u{200C}Hi&quot;") == "\"\u{200C}Hi\"")
        #expect(MailHTMLText.plainText(fromHTML: "<p>Sale&nbsp;\u{034F}&nbsp;\u{034F}</p>") == "Sale")
    }

    @Test func keepsJoinersThatJoinVisibleCharacters() {
        let coder = "👨\u{200D}💻"
        #expect(MailHTMLText.decodeEntities(coder) == coder)
        #expect(MailHTMLText.decodeEntities("👨&zwj;💻") == coder)
        let persian = "می\u{200C}خواهم"
        #expect(MailHTMLText.decodeEntities(persian) == persian)
        #expect(MailHTMLText.decodeEntities("می&zwnj;خواهم") == persian)
        // Preview padding: joiners between spaces, or at either end, join nothing.
        #expect(MailHTMLText.decodeEntities("&zwnj; &zwnj;&nbsp;Sale\u{200C}") == " \u{00A0}Sale")
    }

    @Test func plainTextWithoutAmpersandIsUnchanged() {
        #expect(MailHTMLText.decodeEntities("plain words") == "plain words")
    }

    @Test func htmlDropsHeadStyleScriptAndComments() {
        let html = """
            <html><head><title>Ignored</title><style>p { color: red; }</style></head>
            <body><!-- a comment --><script type="text/javascript">alert("x")</script>
            <p>Visible</p></body></html>
            """
        #expect(MailHTMLText.plainText(fromHTML: html) == "Visible")
    }

    @Test func htmlKeepsParagraphsAndLineBreaks() {
        let html = """
            <p>Hi Mike,</p>
            <p>Thanks   for
               applying.<br>We&#39;ll be in touch.<br/>Soon.</p><div>The Team</div><div>Acme&nbsp;Inc.</div>
            """
        #expect(MailHTMLText.plainText(fromHTML: html) == """
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
        #expect(MailHTMLText.plainText(fromHTML: html) == "One\n\nTwo")
    }

    @Test func htmlTableCellsAndListItems() {
        let html = "<table><tr><td>Role</td><td>Engineer</td></tr><tr><th>Where</th><td>Remote</td></tr></table>"
            + "<ul><li>First</li><li>Second &amp; last</li></ul>"
        #expect(MailHTMLText.plainText(fromHTML: html) == "Role Engineer\nWhere Remote\n\n- First\n- Second & last")
    }

    @Test func htmlLinksKeepTheirTextAndEscapedTagsSurvive() {
        let html = #"<p>See <a href="https://example.com/x?a=1&amp;b=2">the posting</a> &lt;b&gt;now&lt;/b&gt;</p>"#
        #expect(MailHTMLText.plainText(fromHTML: html) == "See the posting <b>now</b>")
    }

    @Test func htmlTagsAreCaseInsensitiveAndSpanLines() {
        let html = "<HTML><HEAD><STYLE>\nx{}\n</STYLE></HEAD><BODY><P\nclass=\"a\">Up</P><BR>Down</BODY></HTML>"
        #expect(MailHTMLText.plainText(fromHTML: html) == "Up\n\nDown")
    }

    @Test func aBareLessThanIsTextAndAQuotedGreaterThanStaysInItsTag() {
        #expect(MailHTMLText.plainText(fromHTML: "<p>I <3 you</p><p><a href=x>link</a></p>") == "I <3 you\n\nlink")
        let html = #"<p>Hi Mike,</p><img alt="Shop now >" width="200"><p>Thanks</p>"#
        #expect(MailHTMLText.plainText(fromHTML: html) == "Hi Mike,\n\nThanks")
        #expect(MailHTMLText.plainText(fromHTML: "<p title='a > b'>x < y and y > z</p>") == "x < y and y > z")
        #expect(MailHTMLText.plainText(fromHTML: "a < b\u{1}\u{2} c") == "a < b c")
    }

    @Test func anUnclosedCommentTagOrHiddenElementRunsToTheEnd() {
        #expect(MailHTMLText.plainText(fromHTML: "<p>Shown</p><!-- never closed <p>gone</p>") == "Shown")
        #expect(MailHTMLText.plainText(fromHTML: "<p>Shown</p><style>p{} <p>gone</p>") == "Shown")
        #expect(MailHTMLText.plainText(fromHTML: "<p>Shown</p><img src=\"x") == "Shown")
        #expect(MailHTMLText.plainText(fromHTML: "<script>if (a</b) {}</script>Shown") == "Shown")
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
            for html in hostile { _ = MailHTMLText.plainText(fromHTML: html) }
        }
        #expect(elapsed < .seconds(5), "took \(elapsed)")
        #expect(MailHTMLText.plainText(fromHTML: hostile[1]) == "x")
    }

    @Test func emptyOrInvisibleHTMLIsEmpty() {
        #expect(MailHTMLText.plainText(fromHTML: "") == "")
        #expect(MailHTMLText.plainText(fromHTML: "<html><head><style>a{}</style></head><body> </body></html>") == "")
    }
}
