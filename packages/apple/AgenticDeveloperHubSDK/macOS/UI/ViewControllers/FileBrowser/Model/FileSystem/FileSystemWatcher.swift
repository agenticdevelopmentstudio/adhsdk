import Foundation
import CoreServices
import os
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

public final class FileSystemWatcher: @unchecked Sendable {
    public typealias ChangeHandler = @Sendable (_ changedPaths: [String]) -> Void

    private var streamRef: FSEventStreamRef?
    private let rootPaths: [String]
    private let excludedPrefixes: [String]
    private let handler: ChangeHandler
    private let queue = DispatchQueue(
        label: "com.mikefullerton.agenticdeveloperhubsdk.filebrowser.fswatcher", qos: .utility
    )

    public convenience init(rootPath: String, excludedPrefixes: [String], handler: @escaping ChangeHandler) {
        self.init(rootPaths: [rootPath], excludedPrefixes: excludedPrefixes, handler: handler)
    }

    /// Watches every one of `rootPaths` in one stream — a linked worktree's
    /// git directory and the common directory live outside its working tree.
    /// A root that repeats another, or lies inside one, is dropped, so an
    /// event is never delivered twice.
    public init(rootPaths: [String], excludedPrefixes: [String], handler: @escaping ChangeHandler) {
        self.rootPaths = Self.distinctRoots(rootPaths)
        self.excludedPrefixes = excludedPrefixes
        self.handler = handler
    }

    /// `paths` without repeats and without any path inside another, in their
    /// original order.
    static func distinctRoots(_ paths: [String]) -> [String] {
        var kept: [String] = []
        for path in paths where !kept.contains(path) {
            let covered = paths.contains { other in other != path && path.hasPrefix(other + "/") }
            if !covered { kept.append(path) }
        }
        return kept
    }

    /// Whether `path` is an excluded directory or something inside one.
    ///
    /// The separator is what makes it "inside": a bare `hasPrefix` on
    /// `<root>/.git` also swallows `<root>/.gitignore`, `.gitmodules`,
    /// `.gitattributes` and everything under `.github/` — files the tree shows
    /// and whose edits it therefore has to hear about.
    static func isExcluded(_ path: String, by prefixes: [String]) -> Bool {
        prefixes.contains { path == $0 || path.hasPrefix($0 + "/") }
    }

    public func start() {
        guard streamRef == nil, !rootPaths.isEmpty else { return }

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let callback: FSEventStreamCallback = { _, clientCallBackInfo, _, eventPaths, _, _ in
            guard let info = clientCallBackInfo else { return }
            let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(info).takeUnretainedValue()

            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String] // swiftlint:disable:this force_cast
            let filtered = paths.filter { path in
                !FileSystemWatcher.isExcluded(path, by: watcher.excludedPrefixes)
            }

            guard !filtered.isEmpty else { return }
            let handler = watcher.handler
            DispatchQueue.main.async {
                handler(filtered)
            }
        }

        let pathsToWatch = rootPaths as CFArray
        streamRef = FSEventStreamCreate(
            nil, callback, &context,
            pathsToWatch, FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        guard let stream = streamRef else {
            logger.error("Failed to create FSEvent stream for \(self.rootPaths.joined(separator: ", "))")
            return
        }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        logger.info("Started file system watcher for \(self.rootPaths.joined(separator: ", "), privacy: .public)")
    }

    public func stop() {
        guard let stream = streamRef else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
        logger.info("Stopped file system watcher")
    }

    deinit { stop() }
}

extension FileSystemWatcher: Loggable {
    public static nonisolated let logger = makeLogger()
}
