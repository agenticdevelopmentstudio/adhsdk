//
//  ToolDefinition.swift
//  AgenticDeveloperHubSDK
//
//  Created by Mike Fullerton on 4/30/26.
//

import Foundation

/// A tool that the model can call. Backends translate this into the
/// provider-specific shape (Anthropic `tools`, OpenAI `functions`, etc.)
/// before sending the request.
public struct ToolDefinition: Sendable, Hashable {
    public let name: String
    public let description: String
    public let parametersJSONSchema: Data
    /// JSON Schema for what the tool returns, when it declares one. A daemon's
    /// tool model publishes it so a client (or a CLI) can type the result.
    public let resultJSONSchema: Data?
    /// One example invocation, as text, for help output and model prompts.
    public let example: String?

    public init(
        name: String,
        description: String,
        parametersJSONSchema: Data,
        resultJSONSchema: Data? = nil,
        example: String? = nil
    ) {
        self.name = name
        self.description = description
        self.parametersJSONSchema = parametersJSONSchema
        self.resultJSONSchema = resultJSONSchema
        self.example = example
    }
}
