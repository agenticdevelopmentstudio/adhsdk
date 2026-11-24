import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

final class CardStackModelTests: XCTestCase {

    private let mainBottomRight = CardStackModel.StackKey(displayID: 1, position: .bottomRight)
    private let sideBottomRight = CardStackModel.StackKey(displayID: 2, position: .bottomRight)
    private let mainCenter = CardStackModel.StackKey(displayID: 1, position: .center)

    func testInsertPutsNewestFirstPerKey() {
        var model = CardStackModel()
        model.insert("a", in: mainBottomRight)
        model.insert("b", in: mainBottomRight)
        model.insert("c", in: mainCenter)
        XCTAssertEqual(model.ids(in: mainBottomRight), ["b", "a"])
        XCTAssertEqual(model.ids(in: mainCenter), ["c"])
    }

    func testInsertingAnIDTwiceInOneKeyMovesItToTheFront() {
        var model = CardStackModel()
        model.insert("a", in: mainBottomRight)
        model.insert("b", in: mainBottomRight)
        model.insert("a", in: mainBottomRight)
        XCTAssertEqual(model.ids(in: mainBottomRight), ["a", "b"])
    }

    func testRemoveReportsEveryKeyItLeftAndDropsEmptyKeys() {
        var model = CardStackModel()
        model.insert("a", in: mainBottomRight)
        model.insert("a", in: sideBottomRight)
        model.insert("b", in: sideBottomRight)
        XCTAssertEqual(model.remove("a"), [mainBottomRight, sideBottomRight])
        XCTAssertEqual(model.ids(in: sideBottomRight), ["b"])
        XCTAssertFalse(model.keys.contains(mainBottomRight))
        XCTAssertEqual(model.remove("missing"), [])
    }

    func testReplaceKeepsThePositionInEveryKey() {
        var model = CardStackModel()
        model.insert("a", in: mainBottomRight)
        model.insert("b", in: mainBottomRight)
        model.insert("a", in: sideBottomRight)
        XCTAssertEqual(model.replace("a", with: "z"), [mainBottomRight, sideBottomRight])
        XCTAssertEqual(model.ids(in: mainBottomRight), ["b", "z"])
        XCTAssertEqual(model.ids(in: sideBottomRight), ["z"])
    }

    func testReplaceWithAnIDAlreadyStackedLeavesOneCopy() {
        var model = CardStackModel()
        model.insert("a", in: mainBottomRight)
        model.insert("b", in: mainBottomRight)
        model.replace("a", with: "b")
        XCTAssertEqual(model.ids(in: mainBottomRight), ["b"])
    }

    func testKeysContainingAnID() {
        var model = CardStackModel()
        model.insert("a", in: mainBottomRight)
        model.insert("a", in: sideBottomRight)
        model.insert("b", in: mainCenter)
        XCTAssertEqual(Set(model.keys(containing: "a")), [mainBottomRight, sideBottomRight])
        XCTAssertEqual(model.keys(containing: "missing"), [])
    }

    func testSplitShowsTheNewestUpToTheLimitAndCountsTheRest() {
        var model = CardStackModel()
        for id in ["a", "b", "c", "d", "e", "f"] {
            model.insert(id, in: mainBottomRight)
        }
        let split = model.split(mainBottomRight, limit: 4)
        XCTAssertEqual(split.visible, ["f", "e", "d", "c"])
        XCTAssertEqual(split.hidden, ["b", "a"])
        XCTAssertEqual(split.pillCount, 2)

        let roomy = model.split(mainBottomRight, limit: 10)
        XCTAssertEqual(roomy.hidden, [])
        XCTAssertEqual(roomy.pillCount, 0)
    }

    func testSplitTreatsALimitBelowOneAsOne() {
        var model = CardStackModel()
        model.insert("a", in: mainBottomRight)
        model.insert("b", in: mainBottomRight)
        XCTAssertEqual(model.split(mainBottomRight, limit: 0).visible, ["b"])
        XCTAssertEqual(model.split(sideBottomRight, limit: 4).visible, [])
    }

    func testMoveRehomesAnIDKeepingItsRecency() {
        var model = CardStackModel()
        model.insert("old", in: sideBottomRight)
        model.insert("a", in: mainBottomRight)
        model.insert("new", in: sideBottomRight)
        model.move("old", from: sideBottomRight, to: mainBottomRight)
        XCTAssertEqual(model.ids(in: mainBottomRight), ["a", "old"])
        XCTAssertEqual(model.ids(in: sideBottomRight), ["new"])
    }

    func testMoveOntoAKeyThatAlreadyHoldsTheIDLeavesOneCopy() {
        var model = CardStackModel()
        model.insert("a", in: mainBottomRight)
        model.insert("a", in: sideBottomRight)
        model.move("a", from: sideBottomRight, to: mainBottomRight)
        XCTAssertEqual(model.ids(in: mainBottomRight), ["a"])
        XCTAssertEqual(model.keys(containing: "a"), [mainBottomRight])
    }

    func testRekeyingForAVanishedDisplay() {
        let key = CardStackModel.StackKey(displayID: 9, position: .bottomLeft)
        XCTAssertEqual(key.onDisplay(3), CardStackModel.StackKey(displayID: 3, position: .bottomLeft))
    }
}
