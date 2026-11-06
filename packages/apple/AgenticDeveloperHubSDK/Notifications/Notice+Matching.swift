import Foundation

public extension Notice {

    /// Whether a subscriber's filter dictionary selects this notice.
    ///
    /// `source`, `level` and `category` match the fields of the same name;
    /// `min_level` and `min_urgency` compare by rank; every other key is
    /// matched against `metadata`. An empty dictionary matches everything,
    /// which is what makes the same shape usable as an SSE query string and
    /// an XPC subscription.
    func matches(filters: [String: String]) -> Bool {
        for (key, wanted) in filters {
            switch key {
            case "source":
                if source != wanted { return false }
            case "level":
                if level.rawValue != wanted { return false }
            case "category":
                if category != wanted { return false }
            case "min_level":
                // An unrecognised floor matches nothing, not everything: a
                // typo'd filter from an API caller must fail closed.
                guard let floor = Level(rawValue: wanted), level.rank >= floor.rank else { return false }
            case "min_urgency":
                guard let floor = Urgency(rawValue: wanted), urgency.rank >= floor.rank else { return false }
            default:
                if metadata[key] != wanted { return false }
            }
        }
        return true
    }
}
