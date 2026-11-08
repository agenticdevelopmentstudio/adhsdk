import Foundation

/// Which search a caller asked for, as the backend's `searchModeSchema`
/// (`adhbackend/src/adh/src/lib/search-mode.ts`) names them.
public enum SearchMode: String, Sendable, CaseIterable, Codable {
    /// Words only: needs no embedder.
    case keyword
    /// Vectors only.
    case semantic
    /// Both, merged by ``SearchFusion/mergeRanked(semantic:keyword:limit:key:)``.
    case combined
}

/// How two ranked lists become one.
public enum SearchFusion {

    /// The longest result list the server's rule is meant for. RRF is offered
    /// only past it.
    public static let shortListLimit = 10

    /// The rank constant of Reciprocal Rank Fusion, as in Cormack et al. 2009.
    public static let defaultRRFConstant = 60

    /// The server's combined order (`mergeRanked`): every semantic hit first,
    /// in its order, then each keyword hit whose key has not been seen, capped
    /// at `limit`. No score normalisation: bm25 is unbounded and
    /// corpus-dependent while cosine is not, so there is no honest way to
    /// weigh one against the other.
    public static func mergeRanked<Hit>(
        semantic: [Hit], keyword: [Hit], limit: Int, key: (Hit) -> String
    ) -> [Hit] {
        var out: [Hit] = []
        var seen = Set<String>()
        for hit in semantic + keyword {
            if out.count >= limit { break }
            guard seen.insert(key(hit)).inserted else { continue }
            out.append(hit)
        }
        return out
    }

    /// Reciprocal Rank Fusion: each key scores the sum of `1 / (k + rank)`
    /// over the lists it appears in (rank from 1; a key seen twice in one
    /// list counts once, at its best rank). The hit kept for a key is its
    /// first appearance, earlier lists first. Equal scores keep that
    /// first-appearance order.
    ///
    /// It earns its keep only over long lists, so it refuses a `limit` of
    /// ``shortListLimit`` or less; at that length ``mergeRanked(semantic:keyword:limit:key:)``
    /// gives the same practical order for less.
    public static func reciprocalRankFusion<Hit>(
        _ lists: [[Hit]], limit: Int, k constant: Int = defaultRRFConstant, key: (Hit) -> String
    ) throws -> [Hit] {
        guard limit > shortListLimit else { throw SearchFusionError.listTooShortForRRF(limit: limit) }
        var scores: [String: Double] = [:]
        var firstSeen: [String: (order: Int, hit: Hit)] = [:]
        var order = 0
        for list in lists {
            var seenInList = Set<String>()
            for (offset, hit) in list.enumerated() {
                let id = key(hit)
                guard seenInList.insert(id).inserted else { continue }
                scores[id, default: 0] += 1 / Double(constant + offset + 1)
                if firstSeen[id] == nil {
                    firstSeen[id] = (order, hit)
                    order += 1
                }
            }
        }
        return firstSeen
            .sorted { lhs, rhs in
                let left = scores[lhs.key] ?? 0
                let right = scores[rhs.key] ?? 0
                return left != right ? left > right : lhs.value.order < rhs.value.order
            }
            .prefix(limit)
            .map { $0.value.hit }
    }
}

public enum SearchFusionError: Error, Sendable, Equatable, CustomStringConvertible {
    case listTooShortForRRF(limit: Int)

    public var description: String {
        switch self {
        case .listTooShortForRRF(let limit):
            "RRF is offered only for lists longer than \(SearchFusion.shortListLimit); \(limit) asked"
        }
    }
}
