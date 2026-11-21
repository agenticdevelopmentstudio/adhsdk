import Testing
import Foundation
@testable import AgenticDeveloperHubSDKCore

@Suite("ToolDefinition result schema and example")
struct ToolDefinitionResultSchemaTests {

    @Test("both default to nil, so existing call sites are unchanged")
    func defaultsAreNil() {
        let tool = ToolDefinition(name: "t", description: "d", parametersJSONSchema: Data("{}".utf8))
        #expect(tool.resultJSONSchema == nil)
        #expect(tool.example == nil)
    }

    @Test("a declared result schema and example are kept")
    func keepsBoth() {
        let schema = Data(#"{"type":"object"}"#.utf8)
        let tool = ToolDefinition(
            name: "notes.list", description: "List notes", parametersJSONSchema: Data("{}".utf8),
            resultJSONSchema: schema, example: "adh notes list")
        #expect(tool.resultJSONSchema == schema)
        #expect(tool.example == "adh notes list")
    }
}
