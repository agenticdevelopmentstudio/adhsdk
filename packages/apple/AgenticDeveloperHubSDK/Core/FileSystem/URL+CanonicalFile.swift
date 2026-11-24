//
//  URL+CanonicalFile.swift
//  AgenticDeveloperHubSDK
//

import Foundation

extension URL {
    /// One spelling per file: standardized, with every symlink resolved, so
    /// `/tmp/x` and `/private/tmp/x`, or a symlink and the file it names,
    /// compare equal. What anything that asks "is this file already open?"
    /// compares.
    public var canonicalFileURL: URL {
        standardizedFileURL.resolvingSymlinksInPath()
    }
}
