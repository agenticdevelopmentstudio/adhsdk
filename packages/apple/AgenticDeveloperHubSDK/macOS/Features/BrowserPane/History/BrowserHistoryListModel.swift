//
//  BrowserHistoryListModel.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import os

/// The visits a History panel lists, and the edits it makes to them: the
/// store's most recent visits while the filter is empty, the visits whose
/// title or address contains the filter otherwise, newest first and never
/// more than `pageSize` of either.
///
/// It owns the rules — trimming, the page size, which reload's answer is
/// shown — so they are testable without a view and any host that shows a
/// history gets the same ones (`separation-of-concerns`). Every store call
/// runs through `BrowserHistoryStore.perform(_:)`, off the main actor, and
/// the answer is published back on it.
@MainActor
public final class BrowserHistoryListModel {

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserHistory")

    /// The visits listed now, newest first.
    public private(set) var visits: [BrowserVisit] = []

    /// What the list is narrowed to. Setting it starts a reload; it is
    /// trimmed before use, so whitespace alone lists recent visits.
    public var filter: String = "" {
        didSet {
            guard filter != oldValue else { return }
            scheduleReload()
        }
    }

    /// Called on the main actor just before `visits` is replaced, while it
    /// still holds the rows a view shows — the moment to note which visits
    /// are selected, since a row index means a different visit afterwards.
    public var onWillChange: (() -> Void)?

    /// Called on the main actor each time `visits` is replaced.
    public var onChange: (() -> Void)?

    private let pageSize: Int
    private let store: BrowserHistoryStore
    /// Advanced by every reload; an answer that comes back to a newer
    /// generation than its own is discarded, so the latest filter wins
    /// however the store's answers are ordered.
    private var generation = 0
    private var reloadTask: Task<Void, Never>?
    nonisolated(unsafe) private var storeObserver: NSObjectProtocol?

    public init(store: BrowserHistoryStore, pageSize: Int = 200) {
        self.store = store
        self.pageSize = pageSize
        // A write from anywhere — a pane recording a visit, another list's
        // removal — rereads the list, which also brings its times up to date.
        storeObserver = NotificationCenter.default.addObserver(
            forName: BrowserHistoryStore.didChangeNotification, object: store, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.scheduleReload() }
        }
    }

    deinit {
        if let storeObserver { NotificationCenter.default.removeObserver(storeObserver) }
    }

    /// Rereads the list for the current filter and returns once the latest
    /// reload — this one, or any started while it ran — has answered.
    public func reload() async {
        scheduleReload()
        await settle()
    }

    /// Forgets the visits `ids` names, then rereads the list. A store
    /// failure is logged and the reread still runs, so the list shows what
    /// the file holds rather than a removal that did not happen.
    public func remove(_ ids: [Int64]) async {
        guard !ids.isEmpty else { return }
        await write("remove visits") { store in
            for id in ids { try store.remove(visit: id) }
        }
    }

    /// Forgets every visit, then rereads the list.
    public func clearAll() async {
        await write("clear history") { try $0.removeAll() }
    }

    // MARK: - Private

    private var trimmedFilter: String {
        filter.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func write(_ what: String, _ work: @escaping @Sendable (BrowserHistoryStore) throws -> Void) async {
        do {
            try await store.perform(work)
        } catch {
            Self.logger.error("could not \(what, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
        await reload()
    }

    private func scheduleReload() {
        generation += 1
        let generation = generation
        let query = trimmedFilter
        let limit = pageSize
        let store = store
        reloadTask = Task { [weak self] in
            let answer: Result<[BrowserVisit], Error>
            do {
                answer = .success(try await store.perform { store in
                    query.isEmpty ? try store.recent(limit: limit) : try store.search(query, limit: limit)
                })
            } catch {
                answer = .failure(error)
            }
            guard let self, self.generation == generation else { return }
            switch answer {
            case .success(let visits):
                self.onWillChange?()
                self.visits = visits
                self.onChange?()
            case .failure(let error):
                // The list keeps what it showed: a failed read is no reason
                // to show an empty history.
                Self.logger.error("could not read history: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Waits until the reload in flight is the latest one and has answered.
    private func settle() async {
        while let task = reloadTask {
            await task.value
            if reloadTask == task { return }
        }
    }
}
