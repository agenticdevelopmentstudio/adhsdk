import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("CodableIgnored conformance")
struct CodableIgnoredConformanceTests {

    private struct Model: Codable {
        var first: Int
        @CodableIgnored var second: Int?

        enum CodingKeys: String, CodingKey {
            case first = "a"
            case second = "b"
        }
    }

    @Test("fc-001: decoding discards the wrapped key's value")
    func fc001_decodeSkipsKey() throws {
        let data = Data(#"{"a": 1, "b": 2}"#.utf8)
        let model = try JSONDecoder().decode(Model.self, from: data)
        #expect(model.first == 1)
        #expect(model.second == nil)
    }

    @Test("fc-002: encoding omits the key and the round trip loses the value")
    func fc002_encodeSkipsKey() throws {
        var model = Model(first: 1)
        model.second = 42
        let data = try JSONEncoder().encode(model)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["b"] == nil)
        #expect(object["a"] as? Int == 1)

        let decoded = try JSONDecoder().decode(Model.self, from: data)
        #expect(decoded.second == nil)
    }
}
