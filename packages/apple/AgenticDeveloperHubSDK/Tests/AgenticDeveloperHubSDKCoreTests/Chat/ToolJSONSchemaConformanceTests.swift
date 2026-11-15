// Tests/AgenticDeveloperHubSDKCoreTests/Chat/ToolJSONSchemaConformanceTests.swift
import Testing
import Foundation
@testable import AgenticDeveloperHubSDKCore

@Suite("ToolJSONSchema conformance")
struct ToolJSONSchemaConformanceTests {
    private func text(_ data: Data) -> String { String(bytes: data, encoding: .utf8) ?? "" }

    private func decode(_ data: Data) throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("tool-json-schema-001: empty properties yields sorted-key object")
    func v001() throws {
        let data = ToolJSONSchema.object(properties: [:])
        #expect(text(data) == #"{"properties":{},"required":[],"type":"object"}"#)
        let json = try decode(data)
        #expect(json["type"] as? String == "object")
        #expect((json["properties"] as? [String: Any])?.isEmpty == true)
        #expect((json["required"] as? [String])?.isEmpty == true)
    }

    @Test("tool-json-schema-002: string property passes through")
    func v002() throws {
        let json = try decode(ToolJSONSchema.object(properties: ["x": ToolJSONSchema.string("x")]))
        let props = try #require(json["properties"] as? [String: Any])
        let prop = try #require(props["x"] as? [String: Any])
        #expect(prop["type"] as? String == "string")
        #expect(prop["description"] as? String == "x")
        #expect(prop.count == 2)
    }

    @Test("tool-json-schema-003: integer, number, boolean fragments")
    func v003() {
        let cases: [([String: Any], String)] = [
            (ToolJSONSchema.integer("n"), "integer"),
            (ToolJSONSchema.number("n"), "number"),
            (ToolJSONSchema.boolean("n"), "boolean")
        ]
        for (fragment, type) in cases {
            #expect(fragment.count == 2)
            #expect(fragment["type"] as? String == type)
            #expect(fragment["description"] as? String == "n")
        }
    }

    @Test("tool-json-schema-004: required order preserved, properties sorted")
    func v004() throws {
        let data = ToolJSONSchema.object(
            properties: ["b": ToolJSONSchema.string("b"), "a": ToolJSONSchema.string("a")],
            required: ["b", "a"])
        let json = try decode(data)
        #expect(json["required"] as? [String] == ["b", "a"])
        let serialized = text(data)
        let rangeA = try #require(serialized.range(of: "\"a\":{"))
        let rangeB = try #require(serialized.range(of: "\"b\":{"))
        #expect(rangeA.lowerBound < rangeB.lowerBound)
    }

    @Test("tool-json-schema-005: required not checked against properties")
    func v005() throws {
        let json = try decode(ToolJSONSchema.object(properties: [:], required: ["ghost"]))
        #expect(json["required"] as? [String] == ["ghost"])
    }

    @Test("tool-json-schema-006: identical input gives byte-equal output")
    func v006() {
        let props: [String: [String: Any]] = [
            "alpha": ToolJSONSchema.string("a"), "beta": ToolJSONSchema.integer("b"),
            "gamma": ToolJSONSchema.number("c"), "delta": ToolJSONSchema.boolean("d")
        ]
        let first = ToolJSONSchema.object(properties: props, required: ["alpha", "delta"])
        let second = ToolJSONSchema.object(properties: props, required: ["alpha", "delta"])
        #expect(first == second)
    }

    @Test("tool-json-schema-007: empty description kept")
    func v007() {
        let fragment = ToolJSONSchema.string("")
        #expect(fragment["description"] as? String == "")
        #expect(fragment.keys.contains("description"))
    }

    @Test("tool-json-schema-008: top-level keys are exactly properties, required, type")
    func v008() throws {
        let json = try decode(ToolJSONSchema.object(properties: ["u": ToolJSONSchema.string("a url")], required: ["u"]))
        #expect(Set(json.keys) == ["properties", "required", "type"])
        #expect(json["required"] as? [String] == ["u"])
    }
}
