#if canImport(AgenticDeveloperHubSDKCore)

import Foundation

/// Every branch's notation, wherever it is kept: `NotationsStore` on this
/// app's own `Notations.db`, or adhd's copy through the client library.
///
/// Every requirement is `async throws` so a store across a socket fits the
/// same shape as the local file; `NotationsStore`'s synchronous methods
/// witness them. Consumers (the Notations feature, pane, window, tools and
/// reconciler) take `any NotationsStoring` (`dependency-injection`).
///
/// The semantics are `NotationsStore`'s, and a conformer keeps them:
/// - at most one active notation per `(project, branch, fork point)`;
/// - `save` writes to the active notation `id` names, else to the active one
///   of `key`, else creates one;
/// - `deleteArchived` throws `NotationsStoreError.notArchived` for an active
///   notation and answers false for a missing one;
/// - `changes` yields after every committed write, coalesced: a consumer
///   re-reads rather than trusting a count.
public protocol NotationsStoring: Sendable {

    /// Every notation, or every one in `state`, by project then branch.
    func all(state: Notation.State?) async throws -> [Notation]

    func notation(id: UUID) async throws -> Notation?

    /// The active notations of one branch of one project, newest first.
    func activeNotations(projectID: UUID, branch: String) async throws -> [Notation]

    func activeNotation(for key: NotationKey) async throws -> Notation?

    /// Writes `content` and returns the row as stored.
    @discardableResult
    func save(id: UUID?, key: NotationKey, content: String, at now: Date) async throws -> Notation

    /// False when there is no such notation.
    @discardableResult
    func updateContent(id: UUID, content: String, at now: Date) async throws -> Bool

    /// Records the branch tip a reconcile saw; not a user edit.
    func recordTip(id: UUID, tip: String?) async throws

    /// False when the notation is not active.
    @discardableResult
    func archive(id: UUID, at now: Date) async throws -> Bool

    /// False when there is no such notation; throws `.notArchived` for an
    /// active one.
    @discardableResult
    func deleteArchived(id: UUID) async throws -> Bool

    /// One element after each committed write. Each access is a new stream,
    /// ended when its consumer stops iterating.
    var changes: AsyncStream<Void> { get }
}

extension NotationsStoring {

    /// Every notation, active and archived.
    public func all() async throws -> [Notation] {
        try await all(state: nil)
    }

    /// `save(id:key:content:at:)` as of now.
    @discardableResult
    public func save(id: UUID?, key: NotationKey, content: String) async throws -> Notation {
        try await save(id: id, key: key, content: content, at: Date())
    }

    /// `updateContent(id:content:at:)` as of now.
    @discardableResult
    public func updateContent(id: UUID, content: String) async throws -> Bool {
        try await updateContent(id: id, content: content, at: Date())
    }

    /// `archive(id:at:)` as of now.
    @discardableResult
    public func archive(id: UUID) async throws -> Bool {
        try await archive(id: id, at: Date())
    }
}

#endif
