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
        let text = "AT&T; R&D &bogus; &#; &#xZZ; &#0; 5 & 6; tom&jerry"
        #expect(MailHTMLText.decodeEntities(text) == text)
    }

    @Test func dropsInvisiblePaddingCharacters() {
        #expect(MailHTMLText.decodeEntities("Hi&zwnj;&#847;&#8203; there\u{FEFF}") == "Hi there")
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

    @Test func emptyOrInvisibleHTMLIsEmpty() {
        #expect(MailHTMLText.plainText(fromHTML: "") == "")
        #expect(MailHTMLText.plainText(fromHTML: "<html><head><style>a{}</style></head><body> </body></html>") == "")
    }
}
