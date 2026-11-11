//
//  BrowserPageLoadGate.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Holds callers until a hidden page has loaded, for a page loaded once and
/// then called into — Chrome's extensions page behind extension management.
/// Engine-free, so the waiting, the timeout and the failures are tested
/// without a browser; the engine reports the page's load and failure.
///
/// - One timeout per page load, armed when the load starts, so a caller who
///   arrives late waits for the same load as the first one and every caller
///   fails together if it never finishes.
/// - A failure counts only while the load is outstanding: a sub-frame or a
///   cancelled navigation reported after the page loaded leaves a working
///   page working.
/// - `close()` fails every caller still waiting, and every later one.
@MainActor
public final class BrowserPageLoadGate {

    /// Runs `action` after `delay` seconds, on the main actor.
    public typealias Schedule = (_ delay: TimeInterval, _ action: @escaping @MainActor @Sendable () -> Void) -> Void

    public enum State: Equatable {
        case loading
        case loaded
        case failed(String)
        case closed
    }

    public private(set) var state: State = .loading

    private let timeout: TimeInterval
    private let pageName: String
    private let schedule: Schedule
    private var waiters: [CheckedContinuation<Void, Error>] = []

    /// Starts waiting for the load that is starting now, and arms its timeout.
    /// `pageName` names the page in the failure sentences.
    public init(pageName: String, timeout: TimeInterval, schedule: @escaping Schedule = BrowserPageLoadGate.mainQueue) {
        self.pageName = pageName
        self.timeout = timeout
        self.schedule = schedule
        schedule(timeout) { [weak self] in self?.timeoutDidFire() }
    }

    /// The default schedule: the main queue.
    public static let mainQueue: Schedule = { delay, action in
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            MainActor.assumeIsolated { action() }
        }
    }

    /// The load failed or timed out: a fresh page may do better.
    public var hasFailed: Bool {
        if case .failed = state { return true }
        return false
    }

    /// Callers waiting right now.
    public var waiting: Int { waiters.count }

    /// Returns once the page has loaded; throws when it failed, timed out or
    /// the gate was closed.
    public func wait() async throws {
        switch state {
        case .loaded:
            return
        case .failed(let sentence):
            throw BrowserExtensionError.unavailable(sentence)
        case .closed:
            throw Self.closedError
        case .loading:
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                waiters.append(continuation)
            }
        }
    }

    /// The page loaded. A page that loads after it timed out recovers.
    public func pageDidLoad() {
        guard state != .closed else { return }
        state = .loaded
        finish(.success(()))
    }

    /// The page reported a failure; ignored once it has loaded.
    public func pageDidFail(_ message: String) {
        guard state == .loading else { return }
        fail("\(pageName) did not load: \(message)")
    }

    /// Fails every waiting caller and every later one.
    public func close() {
        guard state != .closed else { return }
        state = .closed
        finish(.failure(Self.closedError))
    }

    private static let closedError = BrowserExtensionError.unavailable("Extension management closed.")

    private func timeoutDidFire() {
        guard state == .loading else { return }
        fail("\(pageName) did not load within \(Int(timeout)) seconds.")
    }

    private func fail(_ sentence: String) {
        state = .failed(sentence)
        finish(.failure(BrowserExtensionError.unavailable(sentence)))
    }

    private func finish(_ result: Result<Void, Error>) {
        let waiting = waiters
        waiters = []
        waiting.forEach { $0.resume(with: result) }
    }
}
