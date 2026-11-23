import Foundation
import CoreServices
import os
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

public final class FileSystemWatcher: @unchecked Sendable {
    public typealias ChangeHandler = @Sendable (_ changedPaths: [String]) -> Void

    /// FSEvents' flags meaning "events under this path were lost; rescan it":
    /// fseventsd or the kernel fell behind and dropped events
    /// (`UserDropped`/`KernelDropped`, both with `MustScanSubDirs`), coalesced a
    /// burst into one `MustScanSubDirs`, or a watched root itself moved
    /// (`RootChanged`). The path such an event names is a directory, often a
    /// watched root, and says nothing about which file inside it changed.
    static let rescanFlags = FSEventStreamEventFlags(
        kFSEventStreamEventFlagMustScanSubDirs | kFSEventStreamEventFlagUserDropped
            | kFSEventStreamEventFlagKernelDropped | kFSEventStreamEventFlagRootChanged
    )

    /// The stream's creation flags. `WatchRoot` is what makes FSEvents report a
    /// watched root that moved, was renamed or was deleted (`RootChanged`, one of
    /// ``rescanFlags``); without it that event never arrives and the watcher goes
    /// on watching a path that no longer exists.
    static let createFlags = FSEventStreamCreateFlags(
        kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
            | kFSEventStreamCreateFlagWatchRoot
    )

    private var streamRef: FSEventStreamRef?
    private let rootPaths: [String]
    private let excludedPrefixes: [String]
    private let handler: ChangeHandler
    private let rescanHandler: ChangeHandler?
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
    ///
    /// `rescanHandler`, when given, receives the paths of events that mean
    /// "rescan this directory" (`rescanFlags`) instead of `handler`, so a
    /// watcher that reads meaning into a path can treat them as "anything
    /// under here changed". Without it, those paths go to `handler` like any
    /// other.
    public init(rootPaths: [String], excludedPrefixes: [String],
                rescanHandler: ChangeHandler? = nil, handler: @escaping ChangeHandler) {
        self.rootPaths = Self.distinctRoots(rootPaths)
        self.excludedPrefixes = excludedPrefixes
        self.rescanHandler = rescanHandler
        self.handler = handler
    }

    /// Splits one callback's events into ordinary changes and rescans, dropping
    /// excluded paths from both. With no rescan handler every path is ordinary.
    static func partition(paths: [String], flags: [FSEventStreamEventFlags], excludedPrefixes: [String],
                          separatingRescans: Bool) -> (changed: [String], rescan: [String]) {
        var changed: [String] = []
        var rescan: [String] = []
        for (index, path) in paths.enumerated() where !isExcluded(path, by: excludedPrefixes) {
            let flag = index < flags.count ? flags[index] : 0
            if separatingRescans, flag & rescanFlags != 0 {
                rescan.append(path)
            } else {
                changed.append(path)
            }
        }
        return (changed, rescan)
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

        let callback: FSEventStreamCallback = { _, clientCallBackInfo, numEvents, eventPaths, eventFlags, _ in
            guard let info = clientCallBackInfo else { return }
            let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(info).takeUnretainedValue()

            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String] // swiftlint:disable:this force_cast
            let flags = Array(UnsafeBufferPointer(start: eventFlags, count: numEvents))
            let rescanHandler = watcher.rescanHandler
            let (changed, rescan) = FileSystemWatcher.partition(
                paths: paths, flags: flags, excludedPrefixes: watcher.excludedPrefixes,
                separatingRescans: rescanHandler != nil
            )
            if !rescan.isEmpty {
                // The paths are the user's (a home directory, client and
                // project names), so only their count is public.
                let joined = rescan.joined(separator: ", ")
                let count = rescan.count
                FileSystemWatcher.logger.info(
                    "FSEvents asked for a rescan of \(count, privacy: .public) path(s): \(joined, privacy: .private)"
                )
            }

            guard !changed.isEmpty || !rescan.isEmpty else { return }
            let handler = watcher.handler
            DispatchQueue.main.async {
                if !rescan.isEmpty { rescanHandler?(rescan) }
                if !changed.isEmpty { handler(changed) }
            }
        }

        let pathsToWatch = rootPaths as CFArray
        streamRef = FSEventStreamCreate(
            nil, callback, &context,
            pathsToWatch, FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            Self.createFlags
        )

        guard let stream = streamRef else {
            logger.error("Failed to create FSEvent stream for \(self.rootPaths.joined(separator: ", "))")
            return
        }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        let roots = rootPaths.joined(separator: ", ")
        let count = rootPaths.count
        logger.info(
            "Started file system watcher for \(count, privacy: .public) root(s): \(roots, privacy: .private)"
        )
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
