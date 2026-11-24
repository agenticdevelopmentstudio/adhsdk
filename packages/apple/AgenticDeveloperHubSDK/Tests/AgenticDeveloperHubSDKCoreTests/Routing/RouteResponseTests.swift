import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("RouteResponse")
struct RouteResponseTests {

    private struct Sample: Encodable {
        let fooBar: Int
        // swiftlint:disable:next identifier_name
        let at: Date
    }

    private struct Unencodable: Encodable {
        struct Failure: Error {}
        func encode(to encoder: Encoder) throws { throw Failure() }
    }

    /// 2026-01-31T00:00:00Z.
    private let fixedDate = Date(timeIntervalSince1970: 1_769_817_600)

    @Test func jsonUsesSnakeCaseIsoDatesPrettyPrintingAndSortedKeys() {
        let response = RouteResponse.json(Sample(fooBar: 1, at: fixedDate))

        let expected = "{\n  \"at\" : \"2026-01-31T00:00:00Z\",\n  \"foo_bar\" : 1\n}"
        #expect(String(data: response.body, encoding: .utf8) == expected)
        #expect(response.status == 200)
        #expect(response.contentType == "application/json")
    }

    @Test func jsonCarriesTheRequestedStatus() {
        #expect(RouteResponse.json(Sample(fooBar: 1, at: fixedDate), status: 201).status == 201)
    }

    @Test func aValueThatFailsToEncodeYieldsAnEmptyObject() {
        let response = RouteResponse.json(Unencodable())

        #expect(String(data: response.body, encoding: .utf8) == "{}")
    }

    @Test func errorBodyIsValidJSONThatDecodesBackToTheMessage() throws {
        let message = "a \"quoted\" msg\nwith a newline and a \\ backslash"

        let response = RouteResponse.error(message, status: 400)

        #expect(response.status == 400)
        let object = try #require(JSONSerialization.jsonObject(with: response.body) as? [String: String])
        #expect(object["error"] == message)
    }

    @Test func notFoundIs404() {
        let response = RouteResponse.notFound()

        #expect(response.status == 404)
        #expect(String(data: response.body, encoding: .utf8)?.contains("Not found") == true)
    }

    private struct PathValue: Encodable {
        let path: String
    }

    @Test("V7: notFound with a custom message decodes back to it")
    func v7_notFoundCarriesACustomMessage() throws {
        let response = RouteResponse.notFound("gone")

        #expect(response.status == 404)
        let object = try #require(JSONSerialization.jsonObject(with: response.body) as? [String: String])
        #expect(object["error"] == "gone")
        let defaultObject = try #require(
            JSONSerialization.jsonObject(with: RouteResponse.notFound().body) as? [String: String])
        #expect(defaultObject["error"] == "Not found")
    }

    @Test("V8: the initializer defaults the content type and headers")
    func v8_initializerDefaults() {
        let response = RouteResponse(status: 200, body: Data())

        #expect(response.contentType == "application/json")
        #expect(response.headers.isEmpty)
    }

    @Test("V9: each makeJSONEncoder call returns a distinct encoder with the wire format")
    func v9_encoderIsFreshPerCall() {
        let first = RouteResponse.makeJSONEncoder()
        let second = RouteResponse.makeJSONEncoder()

        #expect(first !== second)
        for encoder in [first, second] {
            #expect(encoder.outputFormatting == [.prettyPrinted, .sortedKeys])
            let data = try? encoder.encode(Sample(fooBar: 1, at: fixedDate))
            #expect(data.flatMap { String(data: $0, encoding: .utf8) }?.contains("\"foo_bar\"") == true)
        }
    }

    @Test("V10: the status is stored without validation")
    func v10_statusIsUnchecked() {
        #expect(RouteResponse(status: 999, body: Data()).status == 999)
    }

    @Test("V11: a slash in a string value is escaped")
    func v11_slashIsEscaped() {
        let response = RouteResponse.json(PathValue(path: "a/b"))

        #expect(String(data: response.body, encoding: .utf8) == "{\n  \"path\" : \"a\\/b\"\n}")
    }

    @Test("V12: every builder returns empty headers")
    func v12_buildersHaveEmptyHeaders() {
        #expect(RouteResponse.json(Sample(fooBar: 1, at: fixedDate)).headers.isEmpty)
        #expect(RouteResponse.error("x", status: 400).headers.isEmpty)
        #expect(RouteResponse.notFound().headers.isEmpty)
        #expect(RouteResponse.noContent.headers.isEmpty)
    }

    @Test func noContentIs204WithAnEmptyBody() {
        #expect(RouteResponse.noContent.status == 204)
        #expect(RouteResponse.noContent.body.isEmpty)
        #expect(RouteResponse.noContent.contentType == "application/json")
    }
}
