#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// The model router's templates: the built-ins plus the user's copies, one JSON
/// file per copy in `directory`, and the preferred marks in one settings row.
/// Writes are planned whole against the state they would produce, so a refused
/// request changes nothing.
public struct ModelRouterTemplateStore: Sendable {
    static let preferredKey = "model_router_preferred_templates"
    static let directoryName = "model-router-templates"

    struct Loaded: Equatable, Sendable {
        let templates: [Sessions.ModelRouterTemplateDTO]
        let preferred: Set<String>
        let skipped: [String]
    }

    /// A validated request: what to write and what to remove.
    struct Plan: Sendable {
        fileprivate let save: Sessions.ModelRouterTemplateDTO?
        fileprivate let delete: String?
        fileprivate let preferred: Set<String>?
    }

    let directory: URL
    let database: DaemonDatabase

    /// Held from `plan` to `commit` so two writers can't race between validating and writing.
    static let writeLock = NSLock()

    /// A leading dot or dash would hide or misname the file, so the first character is a letter or digit.
    static func isValidId(_ id: String) -> Bool {
        id.range(of: "^[A-Za-z0-9][A-Za-z0-9._-]{0,127}\\z", options: .regularExpression) != nil
    }

    static func hasTemplateFields(_ prefs: Sessions.ModelRouterPreferencesDTO) -> Bool {
        prefs.saveTemplate != nil || prefs.deleteTemplate != nil
            || prefs.preferTemplate != nil || prefs.unpreferTemplate != nil
    }

    // MARK: - Reading

    func load() -> Loaded {
        var templates = Sessions.ModelRouterTemplateDTO.builtIns
        var skipped: [String] = []
        var copies: [Sessions.ModelRouterTemplateDTO] = []
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        for file in jsonFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let name = file.lastPathComponent
            guard let data = try? Data(contentsOf: file) else {
                skipped.append("\(name): could not be read")
                continue
            }
            switch Sessions.ModelRouterTemplateDTO.decodeFile(data) {
            case .failure(let error):
                skipped.append("\(name): \(error.reason)")
            case .success(let template):
                if template.isBuiltIn {
                    skipped.append("\(name): the id is reserved for built-in templates")
                } else if file.deletingPathExtension().lastPathComponent != template.id
                            || !Self.isValidId(template.id) {
                    skipped.append("\(name): the file name is not the template's id")
                } else if let problem = Sessions.ModelRouterTemplateValidation.problem(template, others: []) {
                    // A hand-placed file gets the same checks as a save.
                    skipped.append("\(name): \(problem)")
                } else {
                    copies.append(template)
                }
            }
        }
        copies.sort {
            let order = $0.name.caseInsensitiveCompare($1.name)
            return order == .orderedSame ? $0.id < $1.id : order == .orderedAscending
        }
        for copy in copies {
            if templates.contains(where: { Self.sameName($0.name, copy.name) }) {
                skipped.append("\(copy.id).json: another template already has the name \"\(copy.name)\"")
            } else {
                templates.append(copy)
            }
        }
        let ids = Set(templates.map(\.id))
        return Loaded(templates: templates, preferred: storedPreferred().intersection(ids), skipped: skipped)
    }

    private static func sameName(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(rhs.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }

    private func storedPreferred() -> Set<String> {
        guard let text = (try? database.setting(for: Self.preferredKey)) ?? nil,
              let ids = try? JSONDecoder().decode([String].self, from: Data(text.utf8))
        else { return [] }
        return Set(ids)
    }

    // MARK: - Writing

    func apply(_ prefs: Sessions.ModelRouterPreferencesDTO) throws {
        Self.writeLock.lock()
        defer { Self.writeLock.unlock() }
        try commit(try plan(prefs), rows: [])
    }

    /// Validates the whole request against the state each step would produce
    /// (save, delete, prefer, unprefer), or throws one sentence. Writes nothing.
    func plan(_ prefs: Sessions.ModelRouterPreferencesDTO) throws -> Plan {
        let loaded = load()
        var templates = loaded.templates
        var preferred = loaded.preferred
        if let template = prefs.saveTemplate {
            if template.isBuiltIn
                || Sessions.ModelRouterTemplateDTO.builtIns.contains(where: { $0.id == template.id }) {
                throw refusal(Sessions.ModelRouterTemplateValidation.builtInReadOnly)
            }
            guard Self.isValidId(template.id) else { throw refusal(Sessions.ModelRouterTemplateValidation.badId) }
            if let problem = Sessions.ModelRouterTemplateValidation.problem(template, others: templates) {
                throw refusal(problem)
            }
            // Case-insensitive file systems would make "MINE" overwrite "mine".
            if templates.contains(where: { $0.id != template.id && $0.id.lowercased() == template.id.lowercased() }) {
                throw refusal(Sessions.ModelRouterTemplateValidation.badId)
            }
            if let index = templates.firstIndex(where: { $0.id == template.id }) {
                templates[index] = template
            } else {
                templates.append(template)
            }
            if preferred.contains(template.id) {
                // A changed range may now overlap another preferred template.
                for other in templates where other.id != template.id && preferred.contains(other.id)
                    && Sessions.ModelRouterTemplateSelector.overlaps(template, other) {
                    preferred.remove(other.id)
                }
            }
        }
        if let id = prefs.deleteTemplate {
            guard let target = templates.first(where: { $0.id == id }) else {
                throw refusal(Sessions.ModelRouterTemplateValidation.noSuchTemplate)
            }
            if target.isBuiltIn { throw refusal(Sessions.ModelRouterTemplateValidation.builtInReadOnly) }
            templates.removeAll { $0.id == id }
            preferred.remove(id)
        }
        if let id = prefs.preferTemplate {
            guard let target = templates.first(where: { $0.id == id }) else {
                throw refusal(Sessions.ModelRouterTemplateValidation.noSuchTemplate)
            }
            for other in templates where other.id != id && preferred.contains(other.id)
                && Sessions.ModelRouterTemplateSelector.overlaps(target, other) {
                preferred.remove(other.id)
            }
            preferred.insert(id)
        }
        if let id = prefs.unpreferTemplate {
            guard templates.contains(where: { $0.id == id }) else {
                throw refusal(Sessions.ModelRouterTemplateValidation.noSuchTemplate)
            }
            preferred.remove(id)
        }
        return Plan(save: prefs.saveTemplate, delete: prefs.deleteTemplate,
                    preferred: preferred == loaded.preferred ? nil : preferred)
    }

    /// One settings row a request writes.
    struct Row: Sendable, Equatable {
        let key: String
        let value: String
    }

    /// Commits a request whole, as the caller sees it. `rows` (the caller's
    /// other settings) and the plan's preferred row are written in one
    /// settings transaction first; the files are written and deleted after it
    /// commits. If a file step fails, every row goes back to what it was and
    /// any file already written is undone, so nothing half-applies, and the
    /// error is thrown.
    func commit(_ plan: Plan?, rows: [Row]) throws {
        var writes = rows
        if let preferred = plan?.preferred {
            let data = try JSONEncoder().encode(preferred.sorted())
            writes.append(Row(key: Self.preferredKey, value: String(bytes: data, encoding: .utf8) ?? "[]"))
        }
        let previous: [(key: String, value: String?)] = try database.transaction {
            let before = try writes.map { (key: $0.key, value: try database.setting(for: $0.key)) }
            for row in writes { try database.setSetting(row.key, row.value) }
            return before
        }
        guard let plan else { return }
        do {
            try writeFiles(plan)
        } catch {
            do {
                try database.transaction {
                    for row in previous.reversed() {
                        if let value = row.value {
                            try database.setSetting(row.key, value)
                        } else {
                            try database.deleteSetting(row.key)
                        }
                    }
                }
            } catch let restore {
                let why = AccountRouterLog.scrub(restore.localizedDescription)
                AccountRouterLog.logger.error(
                    "model router: could not restore settings after a failed template write: \(why, privacy: .public)")
            }
            throw error
        }
    }

    /// The plan's file steps: the save, then the delete. A failed delete puts
    /// the saved file back the way it was.
    private func writeFiles(_ plan: Plan) throws {
        let manager = FileManager.default
        var undoSave: (() -> Void)?
        if let template = plan.save {
            let url = file(template.id)
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            let old = try? Data(contentsOf: url)
            try template.encodedFile().write(to: url, options: .atomic)
            undoSave = {
                if let old {
                    try? old.write(to: url, options: .atomic)
                } else {
                    try? manager.removeItem(at: url)
                }
            }
        }
        if let id = plan.delete {
            let url = file(id)
            do {
                if manager.fileExists(atPath: url.path) { try manager.removeItem(at: url) }
            } catch {
                undoSave?()
                throw error
            }
        }
    }

    private func file(_ id: String) -> URL {
        directory.appendingPathComponent("\(id).json", isDirectory: false)
    }

    private func refusal(_ sentence: String) -> AccountRouterPreferenceError {
        AccountRouterPreferenceError(errorDescription: sentence)
    }
}
#endif
