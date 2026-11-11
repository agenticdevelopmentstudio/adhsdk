import Foundation

/// The `mail …` command line: parses the arguments after `mail`, asks a `MailClient`, prints.
public enum MailCommandLine {
    /// The usage text. `program` is how the host's users type the command, such as `temporal mail`.
    public static func usage(program: String = "mail") -> String {
        """
        usage: \(program) <command> [--json]
          \(program) accounts
          \(program) labels <account>
          \(program) list <account> [--since D] [--until D] [--label L]... [--any-label L]... [--limit N]
              [--cursor C] [--bodies]
          \(program) get <account> <id>
          \(program) label add <account> <label> <id>...
          \(program) label remove <account> <label> <id>...
          \(program) move <account> <id>... --to <label> [--from <label>]...
        D is YYYY-MM-DD or an ISO-8601 timestamp. L is a label id or exact name. An id is our
        message id or Gmail's.
        list: a message must carry every --label (AND) and, if any are given, at least one
          --any-label (OR); the two combine.
        move: adds the --to label and removes every --from label, in one Gmail write. With no
          --from it removes INBOX (nothing for --to INBOX).
        exit status: 0 success, 1 failure, \(notFoundStatus) a message id matches nothing, 64 usage error.
        """
    }

    /// The exit status when a message id matches nothing (`get`, `label`, `move`).
    public static let notFoundStatus: Int32 = 3

    /// 0 on success or when help was asked for (printed to stdout), 64 for a usage error (the
    /// usage goes to stderr), `notFoundStatus` when a message id matches nothing, 1 for any
    /// other failure.
    public static func run(
        _ args: [String], program: String = "mail", client: MailClient,
        stdout: @Sendable (String) -> Void, stderr: @Sendable (String) -> Void
    ) async -> Int32 {
        // `help` as the command, or `--help`/`-h` anywhere (`mail list --help`).
        if args.first == "help" || args.contains(where: ["--help", "-h"].contains) {
            stdout(usage(program: program))
            return 0
        }
        guard let parsed = parse(args) else {
            stderr(usage(program: program))
            return 64
        }
        do {
            let output = try await execute(parsed.command, json: parsed.json, client: client)
            if !output.isEmpty { stdout(output) }
            return 0
        } catch MailClientError.notFound(let message) {
            stderr("Error: \(message)")
            return notFoundStatus
        } catch {
            stderr("Error: \(error.localizedDescription)")
            return 1
        }
    }

    // MARK: - Parsing

    private enum Command {
        case accounts
        case labels(account: String)
        case list(MailMessageFilter)
        case get(account: String, id: String)
        case modify(account: String, ids: [String], add: [String], remove: [String])
        case move(account: String, ids: [String], destination: String, from: [String]?)
    }

    private typealias Parsed = (command: Command, json: Bool)

    private struct Options {
        var json = false
        var positionals: [String] = []
        var values: [String: [String]] = [:]
        var flags: Set<String> = []
    }

    /// Splits `args` into positionals and options. `nil` for an unknown option or a missing value.
    private static func split(_ args: [String], valued: Set<String> = [], boolean: Set<String> = []) -> Options? {
        var options = Options()
        var index = 0
        while index < args.count {
            let arg = args[index]
            index += 1
            if arg == "--json" {
                options.json = true
            } else if boolean.contains(arg) {
                options.flags.insert(arg)
            } else if valued.contains(arg) {
                guard index < args.count else { return nil }
                options.values[arg, default: []].append(args[index])
                index += 1
            } else if arg.hasPrefix("--") {
                return nil
            } else {
                options.positionals.append(arg)
            }
        }
        return options
    }

    private static func parse(_ args: [String]) -> Parsed? {
        guard let name = args.first else { return nil }
        let rest = Array(args.dropFirst())
        switch name {
        case "accounts": return plain(rest, count: 0) { _ in .accounts }
        case "labels": return plain(rest, count: 1) { .labels(account: $0[0]) }
        case "get": return plain(rest, count: 2) { .get(account: $0[0], id: $0[1]) }
        case "list": return parseList(rest)
        case "label": return parseLabel(rest)
        case "move": return parseMove(rest)
        default: return nil
        }
    }

    private static func plain(_ args: [String], count: Int, build: ([String]) -> Command) -> Parsed? {
        guard let options = split(args), options.positionals.count == count else { return nil }
        return (build(options.positionals), options.json)
    }

    private static func parseList(_ args: [String]) -> Parsed? {
        guard let options = split(
            args, valued: ["--since", "--until", "--label", "--any-label", "--limit", "--cursor"],
            boolean: ["--bodies"]),
            options.positionals.count == 1 else { return nil }
        var filter = MailMessageFilter(account: options.positionals[0])
        if let since = options.values["--since"]?.last {
            guard let value = MailDateBound.normalize(since, edge: .start) else { return nil }
            filter.since = value
        }
        if let until = options.values["--until"]?.last {
            guard let value = MailDateBound.normalize(until, edge: .end) else { return nil }
            filter.until = value
        }
        if let limit = options.values["--limit"]?.last {
            guard let value = Int(limit), value > 0 else { return nil }
            filter.limit = value
        }
        filter.labels = options.values["--label"] ?? []
        filter.anyLabels = options.values["--any-label"] ?? []
        filter.cursor = options.values["--cursor"]?.last
        filter.includeBodies = options.flags.contains("--bodies")
        return (.list(filter), options.json)
    }

    private static func parseLabel(_ args: [String]) -> Parsed? {
        guard let verb = args.first, verb == "add" || verb == "remove",
              let options = split(Array(args.dropFirst())),
              options.positionals.count >= 3 else { return nil }
        let label = options.positionals[1]
        let command = Command.modify(
            account: options.positionals[0], ids: Array(options.positionals.dropFirst(2)),
            add: verb == "add" ? [label] : [], remove: verb == "remove" ? [label] : [])
        return (command, options.json)
    }

    /// `move <account> <id>... --to <label> [--from <label>]...`: exactly one `--to`.
    private static func parseMove(_ args: [String]) -> Parsed? {
        guard let options = split(args, valued: ["--to", "--from"]), options.positionals.count >= 2,
              let destinations = options.values["--to"], destinations.count == 1 else { return nil }
        let command = Command.move(
            account: options.positionals[0], ids: Array(options.positionals.dropFirst()),
            destination: destinations[0], from: options.values["--from"])
        return (command, options.json)
    }

    // MARK: - Running

    private static func execute(_ command: Command, json: Bool, client: MailClient) async throws -> String {
        switch command {
        case .accounts:
            let accounts = try await client.accounts()
            return try json ? MailJSON.encode(accounts) : accounts.map(accountLine).joined(separator: "\n")
        case .labels(let account):
            let labels = try await client.labels(account: account)
            return try json ? MailJSON.encode(labels) : labels.map(labelLine).joined(separator: "\n")
        case .list(let filter):
            let page = try await client.messages(filter)
            if json { return try MailJSON.encode(page) }
            var lines = page.messages.map(messageLine)
            if let cursor = page.nextCursor { lines.append("next cursor: \(cursor)") }
            return lines.joined(separator: "\n")
        case .get(let account, let id):
            let message = try await client.message(account: account, id: id)
            return try json ? MailJSON.encode(message) : detail(message)
        case .modify(let account, let ids, let add, let remove):
            let messages = try await client.modifyLabels(account: account, messageIds: ids, add: add, remove: remove)
            return try json ? MailJSON.encode(messages) : messages.map(messageLine).joined(separator: "\n")
        case .move(let account, let ids, let destination, let from):
            let results = try await client.moveMessages(
                account: account, messageIds: ids, destination: destination, from: from)
            return try json ? MailJSON.encode(results) : results.map(moveLine).joined(separator: "\n")
        }
    }

    private static func accountLine(_ account: MailAccount) -> String {
        "\(account.email)  \(account.status.rawValue)  \(account.lastSyncAt ?? "never")"
    }

    private static func labelLine(_ label: MailLabel) -> String {
        "\(label.name)  \(label.id)  \(label.type)"
    }

    private static func messageLine(_ message: MailMessage) -> String {
        let labels = message.labelNames.joined(separator: ", ")
        return "\(message.date)  \(message.id)  \(message.from)  \(message.subject)  [\(labels)]"
    }

    /// The message line, then what changed: `+Added -Removed`, or `(no change)`.
    private static func moveLine(_ result: MailMoveResult) -> String {
        let changes = result.added.map { "+\($0)" } + result.removed.map { "-\($0)" }
        let summary = changes.isEmpty ? "(no change)" : changes.joined(separator: " ")
        return "\(messageLine(result.message))  \(summary)"
    }

    private static func detail(_ message: MailMessage) -> String {
        [
            "From: \(message.from)", "To: \(message.to.joined(separator: ", "))",
            "Date: \(message.date)", "Subject: \(message.subject)",
            "Labels: \(message.labelNames.joined(separator: ", "))", "",
            // The service fills `bodyText` from the HTML itself; converting here as well keeps
            // HTML-only mail readable from a service that predates that.
            message.bodyText ?? message.bodyHtml.map(MailHTMLText.plainText(fromHTML:)) ?? message.snippet
        ].joined(separator: "\n")
    }
}
