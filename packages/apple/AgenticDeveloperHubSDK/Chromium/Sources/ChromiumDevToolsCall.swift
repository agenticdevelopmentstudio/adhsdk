//
//  ChromiumDevToolsCall.swift
//  AgenticDeveloperHubSDKChromium
//

import Foundation

/// A DevTools reply crossing from the bridge's completion block to the
/// awaiting caller. Its JSON is parsed fresh for each reply and never
/// shared, so handing it over is safe though `[String: Any]` is not
/// `Sendable`.
struct ChromiumDevToolsReply: @unchecked Sendable {
    let value: [String: Any]
}

/// Resumes its continuation once: with the reply, or with the timeout,
/// whichever comes first. Both arrive on the main thread.
@MainActor
private final class PendingDevToolsReply {
    private var continuation: CheckedContinuation<ChromiumDevToolsReply, Error>?
    init(_ continuation: CheckedContinuation<ChromiumDevToolsReply, Error>) { self.continuation = continuation }
    func finish(_ result: Result<ChromiumDevToolsReply, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

extension ChromiumBrowserView {

    /// One DevTools call, answered once. `timeout` nil waits however long the
    /// browser takes to exist; closing the view still answers it. `failure`
    /// turns the protocol's message, or the timeout's, into the caller's error.
    @MainActor
    func devToolsCall(
        _ method: String, _ params: [String: Any], timeout: TimeInterval?,
        failure: @escaping @MainActor (String) -> Error
    ) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ChromiumDevToolsReply, Error>) in
            let pending = PendingDevToolsReply(continuation)
            sendDevToolsMethod(method, params: params) { result, error in
                MainActor.assumeIsolated {
                    if let result {
                        pending.finish(.success(ChromiumDevToolsReply(value: result)))
                    } else {
                        pending.finish(.failure(failure(error?.localizedDescription ?? "\(method) failed")))
                    }
                }
            }
            guard let timeout else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                MainActor.assumeIsolated {
                    pending.finish(.failure(failure(
                        "Chrome did not answer \(method) within \(Int(timeout)) seconds")))
                }
            }
        }.value
    }
}
