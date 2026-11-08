//
//  SubsequenceMatch.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// The "any" filter: does every character of a query appear in a string, in
/// order, though not necessarily side by side — and where?
///
/// Case-sensitive on purpose: the strings it filters (model ids, mostly) are
/// spelled one way, so a query typed the same way narrows exactly as typed.
///
/// It returns the matched positions, not just a yes or no, so a list can
/// underline the letters that matched and show why each row is there. When the
/// query occurs as one contiguous run that run is returned, since "opus" lit up
/// inside `claude-opus-5` reads better than the same four letters scattered;
/// otherwise each character takes its earliest position after the previous one.
///
/// It lives in `AgenticDeveloperHubSDKCore` because it needs only Foundation,
/// and the tier rule is the lowest tier that can hold it.
public enum SubsequenceMatch {

    /// The indices in `haystack` of `needle`'s characters, in order, or nil when
    /// `needle` is not a subsequence. An empty `needle` matches with no indices.
    public static func indices(of needle: String, in haystack: String) -> [String.Index]? {
        guard !needle.isEmpty else { return [] }
        if let run = haystack.range(of: needle) {
            return Array(haystack[run].indices)
        }
        var result: [String.Index] = []
        var cursor = haystack.startIndex
        for character in needle {
            guard let found = haystack[cursor...].firstIndex(of: character) else { return nil }
            result.append(found)
            cursor = haystack.index(after: found)
        }
        return result
    }

    /// `indices(of:in:)` as `NSRange`s in `haystack`'s UTF-16 view, one per
    /// matched character, ready for an attributed string.
    public static func ranges(of needle: String, in haystack: String) -> [NSRange]? {
        indices(of: needle, in: haystack)?.map {
            NSRange($0..<haystack.index(after: $0), in: haystack)
        }
    }
}
