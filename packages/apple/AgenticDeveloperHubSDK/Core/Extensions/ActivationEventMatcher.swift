//
//  ActivationEventMatcher.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// One parsed `activationEvents` entry.
///
/// VS Code extensions declare activation events as free-form strings — this
/// is what turns `"onLanguage:swift"` into something a host can actually
/// compare against a trigger, rather than re-parsing the same five prefixes
/// at every call site.
public struct ActivationEvent: Sendable, Equatable {

    public enum Kind: Sendable, Equatable {
        case any                        // "*"
        case startupFinished            // "onStartupFinished"
        case language(String)           // "onLanguage:swift"      -> "swift"
        case command(String)            // "onCommand:foo.bar"     -> "foo.bar"
        case workspaceContains(String)  // "workspaceContains:**/*.csproj" -> the glob
        case webviewPanel(String)       // "onWebviewPanel:markdown.preview" -> the view type
        case view(String)               // "onView:package-explorer" -> the view id
    }

    public let kind: Kind

    /// The entry exactly as the manifest spelled it, so a diagnostic can quote
    /// what the author wrote rather than what we understood.
    public let rawValue: String

    /// Parses one `activationEvents` entry.
    ///
    /// Leading and trailing whitespace is trimmed before recognising the
    /// shape — a manifest with `"  onStartupFinished  "` is not unusual, and
    /// there is nothing for the trailing space to mean once it is not part of
    /// a payload. What follows a colon is taken verbatim and is
    /// case-sensitive: VS Code language and command ids are lowercase by
    /// convention but the editor never normalises them, so normalising here
    /// would accept manifests VS Code itself would not activate.
    ///
    /// An entry with an empty payload after the colon (`"onLanguage:"`) is
    /// unrecognized rather than read as matching the empty string — an author
    /// who wrote that made a mistake, and there is no trigger this host could
    /// ever produce that such an entry should fire on.
    public init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if trimmed == "*" {
            kind = .any
        } else if trimmed == "onStartupFinished" {
            kind = .startupFinished
        } else if let payload = Self.payload(afterPrefix: "onLanguage:", in: trimmed) {
            kind = .language(payload)
        } else if let payload = Self.payload(afterPrefix: "onCommand:", in: trimmed) {
            kind = .command(payload)
        } else if let payload = Self.payload(afterPrefix: "workspaceContains:", in: trimmed) {
            kind = .workspaceContains(payload)
        } else if let payload = Self.payload(afterPrefix: "onWebviewPanel:", in: trimmed) {
            kind = .webviewPanel(payload)
        } else if let payload = Self.payload(afterPrefix: "onView:", in: trimmed) {
            kind = .view(payload)
        } else {
            return nil
        }

        self.rawValue = rawValue
    }

    /// `nil` when `value` does not start with `prefix`, or when everything
    /// after it is empty — the shared rule that makes `"onLanguage:"` and
    /// friends unrecognized rather than a match on `""`.
    private static func payload(afterPrefix prefix: String, in value: String) -> String? {
        guard value.hasPrefix(prefix) else { return nil }
        let payload = String(value.dropFirst(prefix.count))
        return payload.isEmpty ? nil : payload
    }
}

/// A thing that just happened, which may or may not wake an extension.
public enum ActivationTrigger: Sendable, Equatable {
    case startupFinished
    case documentOpened(languageID: String)
    case commandInvoked(String)

    /// A webview panel of this view type is being restored from a persisted
    /// layout, and the extension that owns it has to be awake before it can be
    /// handed back — the trigger `onWebviewPanel:<viewType>` exists for.
    ///
    /// Unlike every other trigger here, the restore is *waiting* on the
    /// activation: the panel is already on screen, blank, until its extension
    /// deserializes it.
    case webviewPanelRestored(viewType: String)

    /// A pane showing a contributed view of this id has just been built,
    /// and the extension that draws it has to be awake before it can —
    /// the trigger `onView:<viewID>` exists for.
    ///
    /// `webviewPanelRestored`'s sibling, and waiting in the same way: the
    /// pane is on screen, empty, until its provider resolves it. The
    /// difference is who is asked. A restored panel is *claimed* — nothing
    /// says whose it is but the claim — whereas a contributed view names
    /// its extension in the manifest that declared it, so this trigger is
    /// a broadcast: it exists for the extension that declares
    /// `onView:` against **someone else's** view, which VS Code permits
    /// and which no ownership lookup would ever wake.
    case viewShown(viewID: String)

    /// The workspace's contents, as paths relative to the workspace root, with
    /// `/` separators and no leading slash. The caller does the directory walk;
    /// this type does pure pattern matching and touches no filesystem.
    case workspaceScanned(WorkspaceScan)

    /// The same trigger from the paths themselves, for a caller with one
    /// matcher to ask — a test, or a replay for a single extension that has
    /// no prepared scan to hand.
    ///
    /// **A caller with more than one matcher to ask must not use this.** It
    /// builds a `WorkspaceScan`, and the whole point of that type is that the
    /// work it does happens once for the whole workspace rather than once per
    /// extension; see its own doc.
    public static func workspaceScanned(relativePaths: [String]) -> ActivationTrigger {
        .workspaceScanned(WorkspaceScan(relativePaths: relativePaths))
    }
}

/// One directory walk's answer, prepared once for every matcher that will be
/// asked about it.
///
/// `GlobPattern` matches over `[Character]`, so a `String` path has to be
/// decomposed before it can be matched against anything. That decomposition
/// is the expensive half of a `workspaceContains:` check — a real workspace
/// carries tens of thousands of paths — and it depends only on the path, not
/// on the pattern or the extension. Held here, it happens once per scan.
/// Held inside `matches(_:)`, as it was, it happened once per *extension*:
/// the installer replays one completed scan at every installed extension in
/// turn, so a 20,000-path workspace with 30 extensions installed decomposed
/// 600,000 paths, all of it on the main actor, to answer a question whose
/// input never changed between the calls.
///
/// `relativePaths` is kept alongside because it is what the scan *is*; the
/// decomposition is a derived index, which is why equality is defined on the
/// paths alone.
public struct WorkspaceScan: Sendable, Equatable {

    /// Paths relative to the workspace root, with `/` separators and no
    /// leading slash — the vocabulary `workspaceContains:` globs are written
    /// in.
    public let relativePaths: [String]

    /// `relativePaths`, decomposed for `GlobPattern.matches(_:)`, at matching
    /// indices.
    ///
    /// Eager rather than lazy: a lazily filled cache would need either
    /// `mutating` access from a `matches(_:)` that is deliberately
    /// non-mutating, or a lock, and the scan is built exactly once on the
    /// path that already walked the filesystem to produce it.
    let decomposedPaths: [[Character]]

    public init(relativePaths: [String]) {
        self.relativePaths = relativePaths
        self.decomposedPaths = relativePaths.map(Array.init)
    }

    public static func == (lhs: WorkspaceScan, rhs: WorkspaceScan) -> Bool {
        lhs.relativePaths == rhs.relativePaths
    }
}

/// Decides whether a manifest's `activationEvents` (and, from VS Code 1.74,
/// its declared commands) wake it for a given trigger.
///
/// Built once from a manifest and then queried repeatedly — `events` and the
/// `workspaceContains:` glob patterns are both captured at `init` rather than
/// re-parsed on every `matches(_:)` call, since a host may check the same
/// extension against many triggers over its lifetime (each document opened,
/// each command invoked).
public struct ActivationEventMatcher: Sendable, Equatable {

    /// Every entry we understood, in manifest order.
    public let events: [ActivationEvent]

    /// Entries we did not understand, raw, in manifest order. Never dropped
    /// silently — a later task reports them.
    public let unrecognizedEvents: [String]

    /// `workspaceContains:` globs whose syntax this matcher does not support.
    /// They never match; they are surfaced here so a report can say so rather
    /// than leaving an author wondering why their extension never woke.
    public let unsupportedPatterns: [String]

    /// Every `workspaceContains:` glob that parsed, in manifest order, as the
    /// `GlobPattern` a `.workspaceScanned` trigger is matched against. The
    /// globs that did *not* parse are in `unsupportedPatterns` and are absent
    /// from here, which is the whole of how they never match.
    ///
    /// Parsed in `init` and kept, rather than rebuilt per `matches(_:)` call:
    /// parsing is the only part of matching that does real work up front, and
    /// `init` had to do it anyway to fill `unsupportedPatterns`.
    private let workspaceContainsPatterns: [GlobPattern]

    /// Command ids that wake this extension *without* an `onCommand:` entry,
    /// because it declares an engine of 1.74.0 or later. Empty otherwise.
    public let implicitlyActivatingCommands: Set<String>

    /// True when the manifest declares `"*"`. Such an extension activates as
    /// soon as the host is ready, without waiting for a specific trigger.
    public var activatesEagerly: Bool {
        events.contains { $0.kind == .any }
    }

    /// Whether this manifest declares `onWebviewPanel:<viewType>`.
    ///
    /// Deliberately *not* `matches(.webviewPanelRestored(viewType:))`: that
    /// question is "does this wake the extension," and `"*"` answers yes to
    /// all of them. Restoring a panel asks a different question — "whose panel
    /// is this" — and an extension that merely activates eagerly has made no
    /// claim on any view type. Handing it someone else's panel would be a
    /// silent mis-delivery, so the claim reads the declaration itself.
    public func declaresWebviewPanel(viewType: String) -> Bool {
        events.contains {
            if case .webviewPanel(let declared) = $0.kind { return declared == viewType }
            return false
        }
    }

    /// The VS Code version, as a `SemanticVersion`, from which a declared
    /// command activates its extension without an explicit `onCommand:`
    /// entry — see the "Implicit activation from contributions.commands"
    /// note on `matches(_:)`.
    private static let implicitCommandActivationFloor = SemanticVersion(major: 1, minor: 74, patch: 0)

    /// Builds a matcher from a manifest's `activationEvents` and declared
    /// commands.
    ///
    /// Parses every `activationEvents` entry once, up front, sorting them
    /// into `events` (recognised) and `unrecognizedEvents` (not); does the
    /// same triage for `workspaceContains:` globs, keeping the ones that
    /// parsed in `workspaceContainsPatterns` and the raw text of the ones
    /// that did not in `unsupportedPatterns`, so nothing re-derives "did
    /// this glob parse" — or re-parses it — later.
    /// It also computes `implicitlyActivatingCommands`: from VS Code 1.74, a
    /// command already declared in `contributes.commands` activates its
    /// extension without a matching `onCommand:` entry.
    ///
    /// The version test is the extension's own declared engine, not the
    /// host's: an extension that still targets an older VS Code cannot rely
    /// on behaviour its stated minimum predates. A manifest whose
    /// `engines.vscode` does not parse gets no implicit activation — an
    /// engine string this host cannot evaluate is not evidence the extension
    /// supports the newer inference.
    ///
    /// **`*` is not a declared minimum of 0.0.0.** It parses to three zero
    /// bases, so a test written on `minimumVersion` alone puts every
    /// `"vscode": "*"` manifest below the floor and hands it an empty set —
    /// every command it declares becomes inert, and the symptom is a palette
    /// entry that does nothing rather than an error anywhere. An engine of
    /// `*` is the absence of a version claim, which is the opposite of a
    /// claim to predate 1.74, so `isUnconstrained` takes the same branch as
    /// a modern floor.
    public init(manifest: ExtensionManifest) {
        var parsed: [ActivationEvent] = []
        var unrecognized: [String] = []
        for raw in manifest.activationEvents {
            if let event = ActivationEvent(rawValue: raw) {
                parsed.append(event)
            } else {
                unrecognized.append(raw)
            }
        }
        events = parsed
        unrecognizedEvents = unrecognized

        var unsupported: [String] = []
        var patterns: [GlobPattern] = []
        for event in parsed {
            guard case .workspaceContains(let glob) = event.kind else { continue }
            if let pattern = GlobPattern(glob) {
                patterns.append(pattern)
            } else {
                unsupported.append(glob)
            }
        }
        unsupportedPatterns = unsupported
        workspaceContainsPatterns = patterns

        if let range = VSCodeEngineRange(manifest.engines.vscode),
           range.isUnconstrained
               || range.minimumVersion >= Self.implicitCommandActivationFloor {
            let commandIDs = manifest.contributes?.commands.map(\.command) ?? []
            implicitlyActivatingCommands = Set(commandIDs)
        } else {
            implicitlyActivatingCommands = []
        }
    }

    /// Whether `trigger` wakes this extension.
    ///
    /// An extension with no recognised events and no implicitly activating
    /// commands never matches anything here — it does not fall back to
    /// eager activation. `"*"` is the only entry that means "activate
    /// unconditionally," and it is handled explicitly rather than by
    /// treating an empty `events` as a wildcard.
    public func matches(_ trigger: ActivationTrigger) -> Bool {
        if activatesEagerly { return true }

        switch trigger {
        case .startupFinished:
            return events.contains { $0.kind == .startupFinished }

        case .documentOpened(let languageID):
            return events.contains {
                if case .language(let declared) = $0.kind { return declared == languageID }
                return false
            }

        case .commandInvoked(let commandID):
            if implicitlyActivatingCommands.contains(commandID) { return true }
            return events.contains {
                if case .command(let declared) = $0.kind { return declared == commandID }
                return false
            }

        case .webviewPanelRestored(let viewType):
            return events.contains {
                if case .webviewPanel(let declared) = $0.kind { return declared == viewType }
                return false
            }

        case .viewShown(let viewID):
            return events.contains {
                if case .view(let declared) = $0.kind { return declared == viewID }
                return false
            }

        case .workspaceScanned(let scan):
            // Path outside, pattern inside — deliberately, because the path
            // is what costs anything to prepare. `GlobPattern` indexes
            // characters, so a `String` has to be decomposed before it can
            // be matched; with the patterns outside, every pattern would
            // decompose the same path again, which is the whole workspace
            // re-decomposed per glob. The decomposition itself is no longer
            // done here at all: `WorkspaceScan` carries it, so it happens
            // once per scan rather than once per extension asked. Both
            // `contains` still short-circuit.
            guard !workspaceContainsPatterns.isEmpty else { return false }
            return scan.decomposedPaths.contains { path in
                workspaceContainsPatterns.contains { $0.matches(path) }
            }
        }
    }
}
