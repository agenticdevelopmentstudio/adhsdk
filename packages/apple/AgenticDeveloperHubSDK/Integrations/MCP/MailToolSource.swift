import AgenticDeveloperHubSDKCore
import Foundation

/// The mail tools an MCP host offers, over a `MailClient`. Results are pretty-printed JSON with
/// sorted keys; a bad argument or a service failure comes back as an error result.
public struct MailToolSource: ChatToolSource {
    private let client: MailClient

    public init(client: MailClient) {
        self.client = client
    }

    public func toolDefinitions() async -> [ToolDefinition] {
        let account = ToolJSONSchema.string("The account's connection id or email address.")
        func strings(_ description: String) -> [String: Any] {
            ["type": "array", "items": ["type": "string"], "description": description]
        }
        return [
            ToolDefinition(
                name: "mail_list_accounts", description: "Lists the connected mail accounts.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [:])),
            ToolDefinition(
                name: "mail_list_labels", description: "Lists an account's labels.",
                parametersJSONSchema: ToolJSONSchema.object(
                    properties: ["account": account], required: ["account"])),
            ToolDefinition(
                name: "mail_list_messages",
                description: "Lists an account's synced messages, newest first, one page at a time.",
                parametersJSONSchema: ToolJSONSchema.object(
                    properties: [
                        "account": account,
                        "since": ToolJSONSchema.string("Earliest date: YYYY-MM-DD or an ISO-8601 timestamp."),
                        "until": ToolJSONSchema.string("Latest date: YYYY-MM-DD or an ISO-8601 timestamp."),
                        "labels": strings("Label ids or names; a message must carry all of them."),
                        "limit": ToolJSONSchema.integer("Page size, 1 to 500. Defaults to 50."),
                        "cursor": ToolJSONSchema.string("The nextCursor of the previous page."),
                        "include_bodies": ToolJSONSchema.boolean("Include message bodies.")
                    ], required: ["account"])),
            ToolDefinition(
                name: "mail_get_message", description: "Gets one message, with its body.",
                parametersJSONSchema: ToolJSONSchema.object(
                    properties: ["account": account, "id": ToolJSONSchema.string("The message id.")],
                    required: ["account", "id"])),
            ToolDefinition(
                name: "mail_modify_labels",
                description: "Adds and removes labels on messages, in Gmail. Give at least one of add or remove.",
                parametersJSONSchema: ToolJSONSchema.object(
                    properties: [
                        "account": account,
                        "message_ids": strings("The messages to change."),
                        "add": strings("Label ids or names to add."),
                        "remove": strings("Label ids or names to remove.")
                    ], required: ["account", "message_ids"]))
        ]
    }

    public func callTool(name: String, argumentsJSON: Data) async -> (content: String, isError: Bool) {
        let arguments = (try? JSONSerialization.jsonObject(with: argumentsJSON)) as? [String: Any] ?? [:]
        do {
            return (try await run(name, arguments), false)
        } catch let error as ArgumentError {
            return (error.message, true)
        } catch {
            return (error.localizedDescription, true)
        }
    }

    // MARK: - Tools

    private func run(_ name: String, _ arguments: [String: Any]) async throws -> String {
        switch name {
        case "mail_list_accounts":
            return try MailJSON.encode(try await client.accounts())
        case "mail_list_labels":
            return try MailJSON.encode(try await client.labels(account: try string("account", arguments)))
        case "mail_list_messages":
            return try MailJSON.encode(try await client.messages(try filter(arguments)))
        case "mail_get_message":
            let message = try await client.message(
                account: try string("account", arguments), id: try string("id", arguments))
            return try MailJSON.encode(message)
        case "mail_modify_labels":
            return try MailJSON.encode(try await modify(arguments))
        default:
            throw ArgumentError(message: "unknown tool \(name)")
        }
    }

    private func filter(_ arguments: [String: Any]) throws -> MailMessageFilter {
        var filter = MailMessageFilter(account: try string("account", arguments))
        filter.since = try bound("since", arguments, edge: .start)
        filter.until = try bound("until", arguments, edge: .end)
        filter.labels = try strings("labels", arguments)
        if let limit = arguments["limit"] {
            guard let value = Self.integer(limit), value > 0 else {
                throw ArgumentError(message: "limit must be a positive integer")
            }
            filter.limit = value
        }
        filter.cursor = try optionalString("cursor", arguments)
        if let bodies = arguments["include_bodies"] {
            guard let value = Self.boolean(bodies) else {
                throw ArgumentError(message: "include_bodies must be a boolean")
            }
            filter.includeBodies = value
        }
        return filter
    }

    private func modify(_ arguments: [String: Any]) async throws -> [MailMessage] {
        let account = try string("account", arguments)
        let ids = try strings("message_ids", arguments)
        let add = try strings("add", arguments)
        let remove = try strings("remove", arguments)
        guard !ids.isEmpty else { throw ArgumentError(message: "message_ids must not be empty") }
        guard !add.isEmpty || !remove.isEmpty else {
            throw ArgumentError(message: "give at least one label in add or remove")
        }
        return try await client.modifyLabels(account: account, messageIds: ids, add: add, remove: remove)
    }

    // MARK: - Arguments

    private struct ArgumentError: Error { let message: String }

    private func string(_ key: String, _ arguments: [String: Any]) throws -> String {
        guard let value = try optionalString(key, arguments), !value.isEmpty else {
            throw ArgumentError(message: "missing required argument: \(key)")
        }
        return value
    }

    /// `nil` when absent; an error when present but not a string.
    private func optionalString(_ key: String, _ arguments: [String: Any]) throws -> String? {
        guard let raw = arguments[key] else { return nil }
        guard let value = raw as? String else { throw ArgumentError(message: "\(key) must be a string") }
        return value
    }

    /// JSON booleans and numbers both bridge to `NSNumber`; only a real boolean is one here.
    private static func boolean(_ raw: Any) -> Bool? {
        guard let number = raw as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
        return number.boolValue
    }

    /// A JSON number with no fractional part; never a boolean.
    private static func integer(_ raw: Any) -> Int? {
        guard let number = raw as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return Int(exactly: number.doubleValue)
    }

    private func strings(_ key: String, _ arguments: [String: Any]) throws -> [String] {
        guard let raw = arguments[key] else { return [] }
        guard let values = raw as? [String] else {
            throw ArgumentError(message: "\(key) must be an array of strings")
        }
        return values
    }

    private func bound(_ key: String, _ arguments: [String: Any], edge: MailDateBound.Edge) throws -> String? {
        guard let text = try optionalString(key, arguments) else { return nil }
        guard let value = MailDateBound.normalize(text, edge: edge) else {
            throw ArgumentError(message: "\(key) must be YYYY-MM-DD or an ISO-8601 timestamp")
        }
        return value
    }
}
