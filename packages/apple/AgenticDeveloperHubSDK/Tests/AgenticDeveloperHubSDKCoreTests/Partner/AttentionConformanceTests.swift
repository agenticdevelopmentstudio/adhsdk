import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Attention conformance") struct AttentionConformanceTests {

    private let firstDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let secondDate = Date(timeIntervalSince1970: 1_700_000_100)
    private let thirdDate = Date(timeIntervalSince1970: 1_700_000_200)

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func jsonObject<Value: Encodable>(_ value: Value) throws -> [String: Any] {
        let data = try makeEncoder().encode(value)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func itemJSON(removing key: String? = nil, state: String = "open") throws -> Data {
        var object: [String: Any] = [
            "id": "a", "kind": "question", "text": "t", "reference": [String: String](),
            "state": state, "createdBy": "p",
            "createdAt": "2023-11-14T22:13:20Z", "updatedAt": "2023-11-14T22:13:20Z"
        ]
        if let key { object.removeValue(forKey: key) }
        return try JSONSerialization.data(withJSONObject: object)
    }

    private func actionJSON(removing key: String? = nil) throws -> Data {
        var object: [String: Any] = [
            "id": "x", "itemID": "a", "action": "confirm", "at": "2023-11-14T22:13:20Z"
        ]
        if let key { object.removeValue(forKey: key) }
        return try JSONSerialization.data(withJSONObject: object)
    }

    @Test("partner-attention-001: item defaults")
    func testV1_itemDefaults() {
        let item = AttentionItem(kind: .question, text: "Ship it?", createdBy: "partner")
        #expect(item.state == .open)
        #expect(item.reference == [:])
        #expect(item.completedAt == nil)
        #expect(UUID(uuidString: item.id) != nil)
        #expect(!item.id.isEmpty)
    }

    @Test("partner-attention-002: each item gets a fresh id")
    func testV2_freshIDs() {
        let first = AttentionItem(kind: .question, text: "t", createdBy: "p")
        let second = AttentionItem(kind: .question, text: "t", createdBy: "p")
        #expect(first.id != second.id)
        #expect(first != second)
    }

    @Test("partner-attention-003: default dates are now")
    func testV3_defaultDates() {
        let before = Date()
        let item = AttentionItem(kind: .notification, text: "t", createdBy: "p")
        #expect(abs(item.createdAt.timeIntervalSince(before)) < 1)
        #expect(abs(item.updatedAt.timeIntervalSince(before)) < 1)
    }

    @Test("partner-attention-004: explicit initializer values are stored as passed")
    func testV4_explicitValues() {
        let item = AttentionItem(
            id: "a", kind: .blocked, text: "t", reference: ["file": "x"], state: .discussing,
            createdBy: "p", createdAt: firstDate, updatedAt: secondDate, completedAt: thirdDate)
        #expect(item.id == "a")
        #expect(item.kind == .blocked)
        #expect(item.text == "t")
        #expect(item.reference == ["file": "x"])
        #expect(item.state == .discussing)
        #expect(item.createdBy == "p")
        #expect(item.createdAt == firstDate)
        #expect(item.updatedAt == secondDate)
        #expect(item.completedAt == thirdDate)
    }

    @Test("partner-attention-005: kind raw values")
    func testV5_kindValues() {
        #expect(AttentionKind.allCases.map(\.rawValue) == ["question", "blocked", "notification"])
    }

    @Test("partner-attention-006: state raw values")
    func testV6_stateValues() {
        #expect(AttentionState.open.rawValue == "open")
        #expect(AttentionState.discussing.rawValue == "discussing")
        #expect(AttentionState.sent.rawValue == "sent")
        #expect(AttentionState.done.rawValue == "done")
    }

    @Test("partner-attention-007: action kind raw values")
    func testV7_actionKindValues() {
        #expect(AttentionActionKind.discuss.rawValue == "discuss")
        #expect(AttentionActionKind.resolved.rawValue == "resolved")
        #expect(AttentionActionKind.confirm.rawValue == "confirm")
        #expect(AttentionActionKind.reopen.rawValue == "reopen")
    }

    @Test("partner-attention-008: item wire keys and enum strings")
    func testV8_itemWireKeys() throws {
        let item = AttentionItem(kind: .notification, text: "t", state: .sent, createdBy: "p")
        let object = try jsonObject(item)
        #expect(object["kind"] as? String == "notification")
        #expect(object["state"] as? String == "sent")
        for key in ["createdBy", "createdAt", "updatedAt"] {
            #expect(object[key] != nil, "missing key \(key)")
        }
    }

    @Test("partner-attention-009: an item round-trips")
    func testV9_itemRoundTrip() throws {
        let item = AttentionItem(
            id: "a", kind: .question, text: "t", reference: ["k": "v"], state: .open,
            createdBy: "p", createdAt: firstDate, updatedAt: secondDate)
        let data = try makeEncoder().encode(item)
        let decoded = try makeDecoder().decode(AttentionItem.self, from: data)
        #expect(decoded == item)
        #expect(decoded.completedAt == nil)
    }

    @Test("partner-attention-010: an item missing a required field fails to decode")
    func testV10_itemMissingText() throws {
        let data = try itemJSON(removing: "text")
        #expect(throws: DecodingError.self) {
            _ = try makeDecoder().decode(AttentionItem.self, from: data)
        }
    }

    @Test("partner-attention-011: an unknown state fails to decode")
    func testV11_unknownState() throws {
        let data = try itemJSON(state: "archived")
        #expect(throws: DecodingError.self) {
            _ = try makeDecoder().decode(AttentionItem.self, from: data)
        }
    }

    @Test("partner-attention-012: action defaults")
    func testV12_actionDefaults() {
        let before = Date()
        let action = AttentionAction(itemID: "a", action: .confirm)
        #expect(action.messageID == nil)
        #expect(abs(action.at.timeIntervalSince(before)) < 1)
        #expect(UUID(uuidString: action.id) != nil)
    }

    @Test("partner-attention-013: action wire keys")
    func testV13_actionWireKeys() throws {
        let action = AttentionAction(itemID: "a", action: .resolved, messageID: "m1")
        let object = try jsonObject(action)
        for key in ["id", "itemID", "action", "at", "messageID"] {
            #expect(object[key] != nil, "missing key \(key)")
        }
        #expect(object["action"] as? String == "resolved")
    }

    @Test("partner-attention-014: an action without messageID decodes")
    func testV14_actionOptionalMessageID() throws {
        let decoded = try makeDecoder().decode(AttentionAction.self, from: try actionJSON())
        #expect(decoded.messageID == nil)
    }

    @Test("partner-attention-015: item fields are mutable in place")
    func testV15_itemMutable() {
        var item = AttentionItem(
            id: "a", kind: .question, text: "t", createdBy: "p", createdAt: firstDate, updatedAt: secondDate)
        item.state = .done
        item.completedAt = thirdDate
        #expect(item.state == .done)
        #expect(item.completedAt == thirdDate)
        #expect(item.updatedAt == secondDate)
    }

    @Test("partner-attention-016: an action round-trips")
    func testV16_actionRoundTrip() throws {
        let action = AttentionAction(id: "x", itemID: "a", action: .confirm, at: firstDate, messageID: "m1")
        let data = try makeEncoder().encode(action)
        let decoded = try makeDecoder().decode(AttentionAction.self, from: data)
        #expect(decoded == action)
    }

    @Test("partner-attention-017: an action missing a required field fails to decode")
    func testV17_actionMissingRequired() throws {
        for key in ["itemID", "action", "at"] {
            let data = try actionJSON(removing: key)
            #expect(throws: DecodingError.self, "decoding without \(key)") {
                _ = try makeDecoder().decode(AttentionAction.self, from: data)
            }
        }
    }
}
