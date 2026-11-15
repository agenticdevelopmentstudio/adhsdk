import Foundation

/// The toolkit's one glob matcher, in two syntaxes.
///
/// - ``init(_:)``: `workspaceContains:` patterns (`ActivationEventMatcher`),
///   VS Code's glob — `*` and `?` stop at `/`, `**` crosses it, `{a,b}`
///   alternates, and `[...]` or a leading `!` is refused.
/// - ``init(wildcard:)``: privacy site patterns (`PrivacySitePattern`), where
///   `*` matches any run of characters, `/` included, and every other
///   character is itself — `?` too, since a site pattern may hold a query.
///
/// Both run on the same tokens and the same memoized search, so a fix to the
/// matching reaches both. It lived inside `ActivationEventMatcher.swift`
/// until the site patterns became its second consumer; add a third syntax
/// here rather than a second matcher elsewhere.
///
/// Implemented as a straightforward backtracking matcher over the pattern's
/// tokens and the path's characters, not `NSRegularExpression`: translating
/// glob to regex requires escaping every regex metacharacter that is also a
/// legal filename character, and a missed one turns a literal `.` or `+` in
/// a real filename into a wildcard.
internal struct GlobPattern: Equatable, Sendable {

    private enum Token: Equatable, Sendable {
        case literal(Character)
        /// `*` — any run of characters except `/`, including empty.
        case star
        /// A trailing `**` that is a whole path segment — any run of
        /// characters *including* `/`, including empty. `tokenize` emits it
        /// only for a `**` at the end of the pattern (or of a `{...}`
        /// alternative) that is preceded by `/` or by nothing: `src/**`,
        /// `**`. Distinct from `anyDirectories` below, which is the same
        /// `**` followed by a `/` and therefore able to consume that slash
        /// too. A `**` that is *not* a whole segment — `src**/foo`,
        /// `lib/**test.js` — is tokenized as `.star` and never reaches this
        /// case. ``GlobPattern/init(wildcard:)`` emits it for every `*`,
        /// anywhere: its matching does not depend on where it sits.
        case doubleStar
        /// `?` — exactly one character, not `/`.
        case question
        /// `**/` as one unit, tokenized together rather than as `doubleStar`
        /// followed by a literal `/`, and only where the `**` begins a path
        /// segment — start of the pattern, or a `/` immediately before it.
        /// That distinction is the whole reason
        /// this case exists: a leading `**/` must also match *zero*
        /// directories, i.e. the slash itself is allowed to vanish along
        /// with everything `**` would have consumed. A plain literal `/`
        /// token after `doubleStar` could never do that — it would still
        /// demand an actual `/` character in the path even when `**` matched
        /// nothing. This token instead matches zero or more path segments,
        /// each ending in `/`.
        case anyDirectories
        /// `{a,b,c}` — each alternative's own token list is tokenized once,
        /// up front, and stored in `branches` under a stable id; this case
        /// holds only the ids for its own alternatives, not the token lists
        /// themselves. Nested `{` is rejected at parse time.
        case alternation([BranchID])
    }

    /// Identifies one `{...}` branch's own token list within `branches`.
    /// Assigned once at tokenize time and never reused for another branch —
    /// see `matchBranch` for why that makes it a sufficient memoization key
    /// on its own, without also carrying which `.alternation` token or which
    /// outer array it belongs to.
    private typealias BranchID = Int

    private let tokens: [Token]

    /// Every `{...}` branch's own token list, flattened out of the pattern's
    /// tree and indexed by `BranchID`. `tokenize` rejects a nested `{`, so a
    /// branch can only ever hold `literal`/`star`/`doubleStar`/`question`/
    /// `anyDirectories` tokens — never another `.alternation` — which is
    /// exactly what lets `matchBranch` treat every branch as belonging to
    /// exactly one `.alternation` token, at exactly one fixed index in
    /// `tokens`.
    private let branches: [[Token]]

    /// Whether a match of this pattern is worth caching its search states.
    ///
    /// The caches on `matchTokens`/`matchBranch` exist for one shape only:
    /// **two or more** backtracking tokens (`*`, `**`, `**/`), which is what
    /// makes the search re-derive the same state through every combination
    /// of how much each one consumed. With one such token there is a single
    /// loop over non-backtracking tokens, and with none there is no loop at
    /// all — in both cases every state is reached once already, and the
    /// cache can only add to the work.
    ///
    /// That is not a rounding error at this call site. A `workspaceContains:`
    /// glob is usually a bare filename (`package.json`, `.eslintrc`), and it
    /// is matched against **every** relative path of a workspace scan: with
    /// the cache unconditional, a pattern that cannot backtrack still hashed
    /// and stored one dictionary entry per character of every path it was
    /// tried against, and threw the whole table away a path later.
    ///
    /// Counted once here, over the pattern's own tokens *and* every `{...}`
    /// branch, because a branch's tokens run the same search — see
    /// `matchBranch`.
    private let needsMemoization: Bool

    /// `nil` when `pattern` uses syntax this matcher does not support: a
    /// `[...]` character class, a leading `!` negation, or a nested `{`
    /// inside a `{...}` group. Those are refused rather than approximated —
    /// silently treating `[` as a literal would make a pattern match paths
    /// its author never intended it to.
    init?(_ pattern: String) {
        guard !pattern.contains("["), !pattern.hasPrefix("!") else { return nil }
        var branches: [[Token]] = []
        guard let tokens = Self.tokenize(Array(pattern), &branches) else { return nil }
        self.tokens = tokens
        self.branches = branches
        self.needsMemoization = Self.backtrackingTokenCount(tokens, branches) > 1
    }

    /// A pattern in which `*` matches any run of characters, `/` included,
    /// and every other character only itself. A run of stars means one. Never
    /// refused: there is no syntax to get wrong.
    init(wildcard pattern: String) {
        var tokens: [Token] = []
        for character in pattern {
            if character == "*" {
                if tokens.last != .doubleStar { tokens.append(.doubleStar) }
            } else {
                tokens.append(.literal(character))
            }
        }
        self.tokens = tokens
        self.branches = []
        self.needsMemoization = Self.backtrackingTokenCount(tokens, []) > 1
    }

    /// How many of `tokens` are the kind that can consume a variable amount
    /// of the path and therefore be backtracked into — counting `.alternation`
    /// itself as one.
    ///
    /// **`.alternation` is a backtracking point, not a fixed-width token.**
    /// `matchTokens`'s own `.alternation` case tries each branch in turn via
    /// `branchIDs.contains { matchBranch(...) }` and backtracks to the next
    /// branch on failure — the same shape `.star`/`.doubleStar`/
    /// `.anyDirectories` already score `+1` for. Scoring it `0` (as a
    /// `.literal` or `.question` would be) undercounts a pattern whose only
    /// real cost is trying several alternatives: `*.{js,ts,jsx,tsx,mjs,cjs}`
    /// has exactly one non-alternation backtracking token (the leading `*`),
    /// so the old count of `1` sat at, not past, `needsMemoization`'s `> 1`
    /// threshold — both `memo` and `branchMemo` stayed `nil`, and every one
    /// of a workspace scan's up to 20,000 paths re-explored the six
    /// alternatives from scratch, on the main actor, with no cache to
    /// collapse repeated `(tokenIndex, pathIndex)` states into one
    /// evaluation.
    ///
    /// Each branch's *own* contained tokens are added in too — recursively,
    /// via this same function — rather than left for a caller to add
    /// separately: `tokenize` guarantees a branch can never itself contain a
    /// nested `.alternation` (a `{` inside `{...}` is rejected at parse
    /// time), so the recursion is exactly one level deep and always
    /// terminates. A branch that is itself wildcard-heavy —
    /// `{*.test.js,*.spec.js}` — must contribute its own `*`s to the total
    /// the same way a bare `*` outside any `{...}` would.
    private static func backtrackingTokenCount(_ tokens: [Token], _ branches: [[Token]]) -> Int {
        tokens.reduce(0) { count, token in
            switch token {
            case .star, .doubleStar, .anyDirectories:
                return count + 1
            case .literal, .question:
                return count
            case .alternation(let branchIDs):
                return branchIDs.reduce(count + 1) { branchCount, branchID in
                    branchCount + Self.backtrackingTokenCount(branches[branchID], branches)
                }
            }
        }
    }

    /// Tokenizes `characters`, appending each `{...}` branch it discovers
    /// (its own already-tokenized contents) to the shared `branches` table
    /// and recording only that branch's index in the `.alternation` token —
    /// so every branch, anywhere in the pattern, ends up with a single
    /// stable id it keeps for the lifetime of this `GlobPattern`.
    private static func tokenize(_ characters: [Character], _ branches: inout [[Token]]) -> [Token]? {
        var tokens: [Token] = []
        var index = 0
        while index < characters.count {
            switch characters[index] {
            case "*":
                if index + 1 < characters.count, characters[index + 1] == "*" {
                    // `**` carries its directory-crossing meaning only when
                    // it is a whole path segment: start-of-pattern or a `/`
                    // before it, and a `/` or end-of-pattern after it.
                    // `src**/foo` and `lib/**test.js` each fail one half of
                    // that, and in both the `**` is an ordinary `*` that
                    // cannot cross `/` — two `*` in a row mean no more than
                    // one, so one `.star` consumes both characters.
                    //
                    // `index` is an index into `characters`, which for a
                    // `{...}` alternative is that alternative's own
                    // characters, not the whole pattern's: inside a branch,
                    // `index == 0` is the start of the branch. What precedes
                    // the `{` is not consulted.
                    let startsSegment = index == 0 || characters[index - 1] == "/"
                    if startsSegment, index + 2 < characters.count, characters[index + 2] == "/" {
                        tokens.append(.anyDirectories)
                        index += 3
                    } else if startsSegment, index + 2 == characters.count {
                        tokens.append(.doubleStar)
                        index += 2
                    } else {
                        tokens.append(.star)
                        index += 2
                    }
                } else {
                    tokens.append(.star)
                    index += 1
                }

            case "?":
                tokens.append(.question)
                index += 1

            case "{":
                guard let closeIndex = characters[(index + 1)...].firstIndex(of: "}") else { return nil }
                let inner = characters[(index + 1)..<closeIndex]
                guard !inner.contains("{") else { return nil }

                let alternatives = inner.split(separator: ",", omittingEmptySubsequences: false)
                var branchIDs: [BranchID] = []
                for alternative in alternatives {
                    guard let branchTokens = tokenize(Array(alternative), &branches) else { return nil }
                    branchIDs.append(branches.count)
                    branches.append(branchTokens)
                }
                tokens.append(.alternation(branchIDs))
                index = closeIndex + 1

            case let character:
                tokens.append(.literal(character))
                index += 1
            }
        }
        return tokens
    }

    /// A `(tokenIndex, pathIndex)` pair identifies one state in `tokens`'s
    /// backtracking search — see `matchTokens` below for why that pair alone
    /// is enough to memoize on.
    private struct MemoKey: Hashable {
        let tokenIndex: Int
        let pathIndex: Int
    }

    /// A `(branch, branchIndex, pathIndex)` triple identifies one state in a
    /// `{...}` branch's own backtracking search — see `matchBranch`.
    private struct BranchMemoKey: Hashable {
        let branch: BranchID
        let branchIndex: Int
        let pathIndex: Int
    }

    /// Whether `path` matches this pattern, anchored at both ends — the
    /// whole relative path, not a substring of it.
    ///
    /// Converts `path` to characters and hands off. A caller with several
    /// patterns to try against the same path should convert once itself and
    /// call the `[Character]` overload — see `ActivationEventMatcher`'s
    /// `.workspaceScanned` case, which is every pattern of every extension
    /// against every path of a scan.
    func matches(_ path: String) -> Bool {
        matches(Array(path))
    }

    /// Whether `path` — already decomposed into the characters the matcher
    /// indexes — matches this pattern.
    ///
    /// The caches are built here rather than held on the pattern: they are
    /// keyed on positions in *this* path, so they are worth exactly one
    /// match and nothing beyond it. `needsMemoization` decides whether they
    /// exist at all; `nil` means every state below is reached once and the
    /// bookkeeping would be pure cost.
    func matches(_ path: [Character]) -> Bool {
        var memo: [MemoKey: Bool]? = needsMemoization ? [:] : nil
        var branchMemo: [BranchMemoKey: Bool]? = needsMemoization ? [:] : nil
        return Self.matchTokens(tokens, 0, path, 0, branches, &memo, &branchMemo)
    }

    /// Whether `path[pathIndex...]` matches `tokens[tokenIndex...]`.
    ///
    /// Memoized on `(tokenIndex, pathIndex)`: for a fixed `tokens` array and
    /// `path`, that pair alone determines the answer — two calls with the
    /// same indices explore exactly the same remaining search space and must
    /// return the same result. Without the cache, a pattern like
    /// `a**a**a**a**a**a**a**b` matched against a long run of `a` characters
    /// re-derives the same failing `(tokenIndex, pathIndex)` state through
    /// every combination of how much each `**` consumed — the search time
    /// roughly doubles per added `**` segment. Caching collapses that to one
    /// evaluation per state: `O(tokens.count * path.count)` states, each
    /// doing at most `O(path.count)` work, rather than exponential
    /// re-exploration. Every recursive call below either advances
    /// `tokenIndex` or (for `.anyDirectories`, which can repeat the same
    /// token) strictly advances `pathIndex`, so the state space has no
    /// cycles and it is safe to cache each result only once its full value
    /// is known.
    ///
    /// `.alternation` is the one case that does not recurse into this same
    /// `tokens` array — see `matchBranch`. The same blowup this cache guards
    /// against is just as reachable through a single, comma-less `{...}`
    /// group wrapping a wildcard-heavy pattern (e.g.
    /// `{a**a**a**a**a**a**a**b}` parses to one `.alternation` with one
    /// branch holding that same adversarial token list), so `matchBranch`
    /// keeps an equivalent cache of its own rather than leaning on this one.
    ///
    /// Both caches are `nil` for a pattern that cannot reach that blowup at
    /// all — see `needsMemoization` — and every read and write below is then
    /// a no-op, rather than a table whose every entry is written once and
    /// read never.
    private static func matchTokens(
        _ tokens: [Token], _ tokenIndex: Int, _ path: [Character], _ pathIndex: Int,
        _ branches: [[Token]], _ memo: inout [MemoKey: Bool]?, _ branchMemo: inout [BranchMemoKey: Bool]?
    ) -> Bool {
        guard tokenIndex < tokens.count else { return pathIndex == path.count }

        let key = MemoKey(tokenIndex: tokenIndex, pathIndex: pathIndex)
        if let cached = memo?[key] { return cached }

        let result: Bool
        switch tokens[tokenIndex] {
        case .literal(let expected):
            if pathIndex < path.count, path[pathIndex] == expected {
                result = matchTokens(tokens, tokenIndex + 1, path, pathIndex + 1, branches, &memo, &branchMemo)
            } else {
                result = false
            }

        case .question:
            if pathIndex < path.count, path[pathIndex] != "/" {
                result = matchTokens(tokens, tokenIndex + 1, path, pathIndex + 1, branches, &memo, &branchMemo)
            } else {
                result = false
            }

        case .star:
            var matched = matchTokens(tokens, tokenIndex + 1, path, pathIndex, branches, &memo, &branchMemo)
            var cursor = pathIndex
            while !matched, cursor < path.count, path[cursor] != "/" {
                cursor += 1
                matched = matchTokens(tokens, tokenIndex + 1, path, cursor, branches, &memo, &branchMemo)
            }
            result = matched

        case .doubleStar:
            var matched = matchTokens(tokens, tokenIndex + 1, path, pathIndex, branches, &memo, &branchMemo)
            var cursor = pathIndex
            while !matched, cursor < path.count {
                cursor += 1
                matched = matchTokens(tokens, tokenIndex + 1, path, cursor, branches, &memo, &branchMemo)
            }
            result = matched

        case .anyDirectories:
            // Zero directories first — the case a plain `doubleStar` +
            // literal `/` could never express.
            var matched = matchTokens(tokens, tokenIndex + 1, path, pathIndex, branches, &memo, &branchMemo)
            var cursor = pathIndex
            while !matched, cursor < path.count {
                if path[cursor] == "/" {
                    // Consumed one segment ending at this slash; recurse on
                    // the *same* token so further segments can follow.
                    matched = matchTokens(tokens, tokenIndex, path, cursor + 1, branches, &memo, &branchMemo)
                }
                cursor += 1
            }
            result = matched

        case .alternation(let branchIDs):
            result = branchIDs.contains { branchID in
                matchBranch(
                    branchID, branches[branchID], 0, tokens, tokenIndex + 1, path, pathIndex,
                    branches, &memo, &branchMemo
                )
            }
        }

        memo?[key] = result
        return result
    }

    /// Matches branch `branchID` (its token list, `branch`, is always
    /// `branches[branchID]` — passed in directly so callers don't re-look it
    /// up), starting at `branchIndex`, against `path` starting at
    /// `pathIndex`; `outerTokenIndex` in `outerTokens` is where to resume
    /// once the branch is exhausted.
    ///
    /// Memoized on `(branchID, branchIndex, pathIndex)` — a smaller version
    /// of the same problem `matchTokens` solves, and needed for the same
    /// reason: `.star`/`.doubleStar`/`.anyDirectories` inside a branch can
    /// backtrack exponentially too. `{a**a**a**a**a**a**a**b}` is exactly
    /// `matchTokens`'s adversarial pattern wrapped in one comma-less group —
    /// before this cache existed, `matchBranch` reached that same blowup
    /// with no bound at all, since its only contact with any cache was the
    /// one terminal delegation below.
    ///
    /// `branchID` alone is enough to identify which branch a state belongs
    /// to — the key does not also need `outerTokens`/`outerTokenIndex` —
    /// because `tokenize` rejects a nested `{`, so every branch belongs to
    /// exactly one `.alternation` token, which sits at exactly one index in
    /// exactly one array (always `self.tokens`, since `.alternation` can
    /// only ever appear there, never inside a branch). `outerTokenIndex` is
    /// therefore a constant function of `branchID`, not a separate degree of
    /// freedom the key would need to distinguish. For the same reason,
    /// `branch` can never itself contain `.alternation`, so there is no case
    /// for it below.
    ///
    /// Relax either of those two facts — the nested-`{` rejection, or one
    /// branch belonging to one `.alternation` — and this key stops being
    /// sufficient. It would then go on returning answers, just wrong ones,
    /// so change the key in the same edit.
    private static func matchBranch(
        _ branchID: BranchID, _ branch: [Token], _ branchIndex: Int,
        _ outerTokens: [Token], _ outerTokenIndex: Int,
        _ path: [Character], _ pathIndex: Int,
        _ branches: [[Token]], _ memo: inout [MemoKey: Bool]?, _ branchMemo: inout [BranchMemoKey: Bool]?
    ) -> Bool {
        guard branchIndex < branch.count else {
            return matchTokens(outerTokens, outerTokenIndex, path, pathIndex, branches, &memo, &branchMemo)
        }

        let key = BranchMemoKey(branch: branchID, branchIndex: branchIndex, pathIndex: pathIndex)
        if let cached = branchMemo?[key] { return cached }

        let result: Bool
        switch branch[branchIndex] {
        case .literal(let expected):
            if pathIndex < path.count, path[pathIndex] == expected {
                result = matchBranch(
                    branchID, branch, branchIndex + 1, outerTokens, outerTokenIndex, path, pathIndex + 1,
                    branches, &memo, &branchMemo
                )
            } else {
                result = false
            }

        case .question:
            if pathIndex < path.count, path[pathIndex] != "/" {
                result = matchBranch(
                    branchID, branch, branchIndex + 1, outerTokens, outerTokenIndex, path, pathIndex + 1,
                    branches, &memo, &branchMemo
                )
            } else {
                result = false
            }

        case .star:
            var matched = matchBranch(
                branchID, branch, branchIndex + 1, outerTokens, outerTokenIndex, path, pathIndex,
                branches, &memo, &branchMemo
            )
            var cursor = pathIndex
            while !matched, cursor < path.count, path[cursor] != "/" {
                cursor += 1
                matched = matchBranch(
                    branchID, branch, branchIndex + 1, outerTokens, outerTokenIndex, path, cursor,
                    branches, &memo, &branchMemo
                )
            }
            result = matched

        case .doubleStar:
            var matched = matchBranch(
                branchID, branch, branchIndex + 1, outerTokens, outerTokenIndex, path, pathIndex,
                branches, &memo, &branchMemo
            )
            var cursor = pathIndex
            while !matched, cursor < path.count {
                cursor += 1
                matched = matchBranch(
                    branchID, branch, branchIndex + 1, outerTokens, outerTokenIndex, path, cursor,
                    branches, &memo, &branchMemo
                )
            }
            result = matched

        case .anyDirectories:
            var matched = matchBranch(
                branchID, branch, branchIndex + 1, outerTokens, outerTokenIndex, path, pathIndex,
                branches, &memo, &branchMemo
            )
            var cursor = pathIndex
            while !matched, cursor < path.count {
                if path[cursor] == "/" {
                    matched = matchBranch(
                        branchID, branch, branchIndex, outerTokens, outerTokenIndex, path, cursor + 1,
                        branches, &memo, &branchMemo
                    )
                }
                cursor += 1
            }
            result = matched

        case .alternation:
            // Unreachable: `branch` came from `tokenize`, which rejects a
            // nested `{` inside a `{...}` group before this ever runs.
            preconditionFailure("a { ... } branch cannot itself contain a nested alternation")
        }

        branchMemo?[key] = result
        return result
    }
}
