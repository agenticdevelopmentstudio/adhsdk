import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKDatabase

/// Pure parsing and routing of picker messages (recipe
/// workspace/browser/element-picker, vectors 001–004).
@MainActor
final class BrowserElementPickerTests: XCTestCase {

    private func body(thisItem: Any = "#a", allLikeIt: Any = "div.card",
                      count: Int = 3, page: Int = 100) -> [String: Any] {
        ["kind": "pick", "thisItem": thisItem, "allLikeIt": allLikeIt,
         "allLikeItCount": count, "pageElementCount": page,
         "label": "div \"Hi\"", "ref": NSNull()]
    }

    private func candidate(allLikeIt: String?, count: Int, page: Int) -> BrowserPickCandidate {
        BrowserPickCandidate(kind: .pick, thisItem: "#a", allLikeIt: allLikeIt, allLikeItCount: count,
                             pageElementCount: page, label: "div", ref: nil)
    }

    func test_candidateDecodes() throws {
        let json = ##"{"kind":"pick","thisItem":"#a","allLikeIt":"div.card","allLikeItCount":3,"##
            + ##""pageElementCount":100,"label":"div \"Hi\"","ref":null}"##
        let decoded = try JSONDecoder().decode(BrowserPickCandidate.self, from: Data(json.utf8))
        XCTAssertEqual(decoded, BrowserPickCandidate(kind: .pick, thisItem: "#a", allLikeIt: "div.card",
                                                     allLikeItCount: 3, pageElementCount: 100,
                                                     label: "div \"Hi\"", ref: nil))
        XCTAssertTrue(decoded.allLikeItAllowed)
    }

    func test_messageBodyDecodes() throws {
        let decoded = try XCTUnwrap(BrowserElementPicker.decode(body()))
        XCTAssertEqual(decoded.thisItem, "#a")
        XCTAssertEqual(decoded.allLikeIt, "div.card")
        XCTAssertNil(decoded.ref)
        XCTAssertNil(BrowserElementPicker.decode(["kind": "bogus"]))
    }

    func test_pickWithoutSelectorIsRefused() {
        var picks: [BrowserPickCandidate] = []
        var cancels = 0
        let picker = BrowserElementPicker(webView: WKWebView(frame: .zero), list: .user,
                                          onPick: { picks.append($0) }, onCancel: { cancels += 1 })
        picker.handle(body: body(thisItem: NSNull()))
        XCTAssertTrue(picks.isEmpty, "a pick with no This item selector never reaches onPick")
        XCTAssertEqual(cancels, 0)

        picker.handle(body: body())
        XCTAssertEqual(picks.count, 1, "the picker keeps taking picks after a refused one")
    }

    /// Blank space beside a layout hits `<body>`: This item for the page's
    /// root is refused like a missing one, for either list.
    func test_pickOfPageRootIsRefused() {
        for list in [BrowserHiddenItemList.user, .agent] {
            var picks: [BrowserPickCandidate] = []
            let picker = BrowserElementPicker(webView: WKWebView(frame: .zero), list: list,
                                              onPick: { picks.append($0) }, onCancel: {})
            for root in ["body", "html", "HTML > BODY", "html body", ":root", " body "] {
                picker.handle(body: body(thisItem: root))
            }
            XCTAssertTrue(picks.isEmpty, "\(list): no root pick reaches onPick")
            picker.handle(body: body(thisItem: "body > div.ad"))
            XCTAssertEqual(picks.map(\.thisItem), ["body > div.ad"], "an element inside body is fine")
        }
        XCTAssertTrue(BrowserPickCandidate.isPageRoot("html>body"))
        XCTAssertFalse(BrowserPickCandidate.isPageRoot("body.home"))
        XCTAssertFalse(BrowserPickCandidate.isPageRoot("#main"))
    }

    func test_cancelCallsOnCancel() {
        var cancels = 0
        let picker = BrowserElementPicker(webView: WKWebView(frame: .zero), list: .agent,
                                          onPick: { _ in XCTFail("no pick") }, onCancel: { cancels += 1 })
        picker.handle(body: ["kind": "cancel", "thisItem": NSNull(), "allLikeIt": NSNull(),
                             "allLikeItCount": 0, "pageElementCount": 0, "label": "", "ref": NSNull()])
        XCTAssertEqual(cancels, 1)
        XCTAssertEqual(picker.list, .agent)
    }

    func test_looseSelectorMatchingMostOfPageIsDisabled() {
        XCTAssertFalse(candidate(allLikeIt: "div.card", count: 80, page: 100).allLikeItAllowed)
    }

    func test_looseSelectorAtExactlyHalfIsAllowed() {
        XCTAssertTrue(candidate(allLikeIt: "div.card", count: 50, page: 100).allLikeItAllowed)
        XCTAssertFalse(candidate(allLikeIt: "div.card", count: 51, page: 100).allLikeItAllowed)
    }

    func test_noLooseSelectorIsDisabled() {
        XCTAssertFalse(candidate(allLikeIt: nil, count: 0, page: 100).allLikeItAllowed)
    }

    /// A bare tag, or the page's frame with a class, never hides "all items
    /// like it", however few elements it matches.
    func test_bareTagAndPageFrameAreNeverAllowed() {
        for selector in ["div", "span", "p", "body.home", "main.content", "HTML.x", "head.x"] {
            XCTAssertFalse(candidate(allLikeIt: selector, count: 2, page: 100).allLikeItAllowed, selector)
        }
        XCTAssertTrue(candidate(allLikeIt: "div.card", count: 2, page: 100).allLikeItAllowed)
    }

    func test_scriptsAreBundled() throws {
        XCTAssertTrue(try BrowserElementPicker.finderSource.contains("globalThis.__adkFinder = finder"))
        XCTAssertTrue(try BrowserElementPicker.finderSource.contains("MIT License"))
        XCTAssertTrue(try BrowserElementPicker.pickerSource.contains(BrowserElementPicker.messageHandlerName))
    }
}
