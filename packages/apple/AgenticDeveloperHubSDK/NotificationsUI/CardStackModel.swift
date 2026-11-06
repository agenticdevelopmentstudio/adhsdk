import AgenticDeveloperHubSDKNotifications

/// The bookkeeping under `CardStackPresenter`, with no windows in it: which
/// notice ids sit in which stack, newest first, and how a stack splits into the
/// cards it shows and the ones folded behind its "+N more" pill.
///
/// A stack is one position on one display. A notice shown on every screen sits
/// in one stack per display.
struct CardStackModel {

    struct StackKey: Hashable {
        let displayID: UInt32
        let position: NoticeProfile.Position

        /// The same position on another display, for re-homing a stack whose
        /// display went away.
        func onDisplay(_ displayID: UInt32) -> StackKey {
            StackKey(displayID: displayID, position: position)
        }
    }

    /// How one stack is drawn.
    struct Split: Equatable {
        /// Newest first; at most `limit` of them.
        var visible: [String]
        /// The rest, which must neither show nor count down.
        var hidden: [String]
        /// The count on the pill; 0 means no pill.
        var pillCount: Int { hidden.count }
    }

    /// Ids per stack, newest first.
    private var stacks: [StackKey: [String]] = [:]
    /// Stacks in the order they were first used, so every answer that lists
    /// keys is deterministic.
    private(set) var keys: [StackKey] = []
    /// When each id arrived, so a re-homed id lands where its age puts it.
    private var arrival: [String: Int] = [:]
    private var nextArrival = 0

    func ids(in key: StackKey) -> [String] {
        stacks[key] ?? []
    }

    func keys(containing id: String) -> [StackKey] {
        keys.filter { stacks[$0]?.contains(id) == true }
    }

    /// Puts `id` at the front of `key`'s stack, as the newest card.
    mutating func insert(_ id: String, in key: StackKey) {
        stacks[key, default: []].removeAll { $0 == id }
        stacks[key, default: []].insert(id, at: 0)
        if !keys.contains(key) {
            keys.append(key)
        }
        arrival[id] = nextArrival
        nextArrival += 1
    }

    /// Takes `id` out of every stack. Returns the stacks it left, which need
    /// laying out again.
    @discardableResult
    mutating func remove(_ id: String) -> [StackKey] {
        let affected = keys(containing: id)
        for key in affected {
            stacks[key]?.removeAll { $0 == id }
        }
        arrival[id] = nil
        dropEmpty()
        return affected
    }

    /// Swaps `oldID` for `newID` where it stands in every stack, so an update
    /// does not move the card. Returns the stacks it touched.
    @discardableResult
    mutating func replace(_ oldID: String, with newID: String) -> [StackKey] {
        guard oldID != newID else { return keys(containing: oldID) }
        let affected = keys(containing: oldID)
        for key in affected {
            guard var ids = stacks[key], let index = ids.firstIndex(of: oldID) else { continue }
            ids[index] = newID
            ids = ids.enumerated().filter { $0.element != newID || $0.offset == index }.map(\.element)
            stacks[key] = ids
        }
        if !affected.isEmpty {
            arrival[newID] = arrival[oldID]
            arrival[oldID] = nil
        }
        dropEmpty()
        return affected
    }

    /// Moves `id` from one stack to another, slotting it in by when it arrived
    /// rather than putting it on top.
    mutating func move(_ id: String, from source: StackKey, to target: StackKey) {
        guard source != target, stacks[source]?.contains(id) == true else { return }
        stacks[source]?.removeAll { $0 == id }
        var ids = stacks[target] ?? []
        if !ids.contains(id) {
            let age = arrival[id] ?? .min
            let index = ids.firstIndex { (arrival[$0] ?? .min) < age } ?? ids.count
            ids.insert(id, at: index)
        }
        stacks[target] = ids
        if !keys.contains(target) {
            keys.append(target)
        }
        dropEmpty()
    }

    /// The newest `limit` cards show (at least one, if any); the rest hide.
    func split(_ key: StackKey, limit: Int) -> Split {
        let ids = ids(in: key)
        let shown = max(1, limit)
        return Split(visible: Array(ids.prefix(shown)), hidden: Array(ids.dropFirst(shown)))
    }

    private mutating func dropEmpty() {
        for key in keys where stacks[key]?.isEmpty ?? true {
            stacks[key] = nil
        }
        keys.removeAll { stacks[$0] == nil }
    }
}
