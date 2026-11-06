import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

final class CardStackModelTests: XCTestCase {

    private let mainTopRight = CardStackModel.StackKey(displayID: 1, position: .topRight)
    private let sideTopRight = CardStackModel.StackKey(displayID: 2, position: .topRight)
    private let mainCenter = CardStackModel.StackKey(displayID: 1, position: .center)

    func testInsertPutsNewestFirstPerKey() {
        var model = CardStackModel()
        model.insert("a", in: mainTopRight)
        model.insert("b", in: mainTopRight)
        model.insert("c", in: mainCenter)
        XCTAssertEqual(model.ids(in: mainTopRight), ["b", "a"])
        XCTAssertEqual(model.ids(in: mainCenter), ["c"])
    }

    func testInsertingAnIDTwiceInOneKeyMovesItToTheFront() {
        var model = CardStackModel()
        model.insert("a", in: mainTopRight)
        model.insert("b", in: mainTopRight)
        model.insert("a", in: mainTopRight)
        XCTAssertEqual(model.ids(in: mainTopRight), ["a", "b"])
    }

    func testRemoveReportsEveryKeyItLeftAndDropsEmptyKeys() {
        var model = CardStackModel()
        model.insert("a", in: mainTopRight)
        model.insert("a", in: sideTopRight)
        model.insert("b", in: sideTopRight)
        XCTAssertEqual(model.remove("a"), [mainTopRight, sideTopRight])
        XCTAssertEqual(model.ids(in: sideTopRight), ["b"])
        XCTAssertFalse(model.keys.contains(mainTopRight))
        XCTAssertEqual(model.remove("missing"), [])
    }

    func testReplaceKeepsThePositionInEveryKey() {
        var model = CardStackModel()
        model.insert("a", in: mainTopRight)
        model.insert("b", in: mainTopRight)
        model.insert("a", in: sideTopRight)
        XCTAssertEqual(model.replace("a", with: "z"), [mainTopRight, sideTopRight])
        XCTAssertEqual(model.ids(in: mainTopRight), ["b", "z"])
        XCTAssertEqual(model.ids(in: sideTopRight), ["z"])
    }

    func testReplaceWithAnIDAlreadyStackedLeavesOneCopy() {
        var model = CardStackModel()
        model.insert("a", in: mainTopRight)
        model.insert("b", in: mainTopRight)
        model.replace("a", with: "b")
        XCTAssertEqual(model.ids(in: mainTopRight), ["b"])
    }

    func testKeysContainingAnID() {
        var model = CardStackModel()
        model.insert("a", in: mainTopRight)
        model.insert("a", in: sideTopRight)
        model.insert("b", in: mainCenter)
        XCTAssertEqual(Set(model.keys(containing: "a")), [mainTopRight, sideTopRight])
        XCTAssertEqual(model.keys(containing: "missing"), [])
    }

    func testSplitShowsTheNewestUpToTheLimitAndCountsTheRest() {
        var model = CardStackModel()
        for id in ["a", "b", "c", "d", "e", "f"] {
            model.insert(id, in: mainTopRight)
        }
        let split = model.split(mainTopRight, limit: 4)
        XCTAssertEqual(split.visible, ["f", "e", "d", "c"])
        XCTAssertEqual(split.hidden, ["b", "a"])
        XCTAssertEqual(split.pillCount, 2)

        let roomy = model.split(mainTopRight, limit: 10)
        XCTAssertEqual(roomy.hidden, [])
        XCTAssertEqual(roomy.pillCount, 0)
    }

    func testSplitTreatsALimitBelowOneAsOne() {
        var model = CardStackModel()
        model.insert("a", in: mainTopRight)
        model.insert("b", in: mainTopRight)
        XCTAssertEqual(model.split(mainTopRight, limit: 0).visible, ["b"])
        XCTAssertEqual(model.split(sideTopRight, limit: 4).visible, [])
    }

    func testMoveRehomesAnIDKeepingItsRecency() {
        var model = CardStackModel()
        model.insert("old", in: sideTopRight)
        model.insert("a", in: mainTopRight)
        model.insert("new", in: sideTopRight)
        model.move("old", from: sideTopRight, to: mainTopRight)
        XCTAssertEqual(model.ids(in: mainTopRight), ["a", "old"])
        XCTAssertEqual(model.ids(in: sideTopRight), ["new"])
    }

    func testMoveOntoAKeyThatAlreadyHoldsTheIDLeavesOneCopy() {
        var model = CardStackModel()
        model.insert("a", in: mainTopRight)
        model.insert("a", in: sideTopRight)
        model.move("a", from: sideTopRight, to: mainTopRight)
        XCTAssertEqual(model.ids(in: mainTopRight), ["a"])
        XCTAssertEqual(model.keys(containing: "a"), [mainTopRight])
    }

    func testRekeyingForAVanishedDisplay() {
        let key = CardStackModel.StackKey(displayID: 9, position: .bottomLeft)
        XCTAssertEqual(key.onDisplay(3), CardStackModel.StackKey(displayID: 3, position: .bottomLeft))
    }
}
