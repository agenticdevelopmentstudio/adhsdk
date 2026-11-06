import Foundation

/// The crawl's bookkeeping, apart from any window: which notices run on which
/// strip, in what order, and which strips each change opens, closes or
/// redraws. Pure, so it is tested with made-up strip keys.
struct CrawlModel {

    typealias Key = CrawlPresenter.StripKey

    /// What a change did to the strips. The presenter makes a panel for each
    /// opened key, closes each closed one, and redraws opened and refreshed.
    struct Change: Equatable {
        var opened: Set<Key> = []
        var closed: Set<Key> = []
        var refreshed: Set<Key> = []
    }

    /// Shown ids, oldest first.
    private(set) var order: [String] = []
    private var keysByID: [String: [Key]] = [:]
    private var idsByStrip: [Key: [String]] = [:]

    var isEmpty: Bool { idsByStrip.isEmpty }

    func keys(of id: String) -> [Key] { keysByID[id] ?? [] }

    func ids(on key: Key) -> [String] { idsByStrip[key] ?? [] }

    /// Puts `id` at the end of `keys`' strips, and of the order. An id already
    /// shown is taken off first; no keys at all just takes it off.
    mutating func show(_ id: String, on keys: [Key]) -> Change {
        let before = Set(idsByStrip.keys)
        var touched = detach(id)
        if !keys.isEmpty {
            order.append(id)
            attach(id, on: keys, touched: &touched)
        }
        return change(from: before, touched: touched)
    }

    mutating func remove(_ id: String) -> Change {
        let before = Set(idsByStrip.keys)
        // Detach first: a call's receiver is read before its arguments, so
        // detaching inside the argument list would diff the old state.
        let touched = detach(id)
        return change(from: before, touched: touched)
    }

    /// `newID` takes `oldID`'s place: on a strip both use it stands where the
    /// old one stood; strips only the old one used lose it; strips only the
    /// new one uses get it at the end. Any earlier placement of `newID` goes.
    mutating func replace(_ oldID: String, with newID: String, on keys: [Key]) -> Change {
        guard let oldKeys = keysByID[oldID] else { return show(newID, on: keys) }
        guard !keys.isEmpty else { return remove(oldID) }
        let before = Set(idsByStrip.keys)
        var touched: Set<Key> = []
        if newID != oldID {
            touched.formUnion(detach(newID))
        }
        let position = order.firstIndex(of: oldID)
        // Off the strips it is leaving; renamed where it stays.
        for key in oldKeys {
            touched.insert(key)
            if keys.contains(key) {
                idsByStrip[key] = idsByStrip[key]?.map { $0 == oldID ? newID : $0 }
            } else {
                drop(oldID, from: key)
            }
        }
        keysByID[oldID] = nil
        order.removeAll { $0 == oldID }
        order.insert(newID, at: min(position ?? order.count, order.count))
        keysByID[newID] = keys
        for key in keys where !oldKeys.contains(key) {
            idsByStrip[key, default: []].append(newID)
            touched.insert(key)
        }
        return change(from: before, touched: touched)
    }

    // MARK: Helpers

    /// Takes `id` off every strip and out of the order; the strips it was on.
    private mutating func detach(_ id: String) -> Set<Key> {
        guard let keys = keysByID.removeValue(forKey: id) else { return [] }
        order.removeAll { $0 == id }
        for key in keys {
            drop(id, from: key)
        }
        return Set(keys)
    }

    private mutating func attach(_ id: String, on keys: [Key], touched: inout Set<Key>) {
        keysByID[id] = keys
        for key in keys {
            idsByStrip[key, default: []].append(id)
            touched.insert(key)
        }
    }

    private mutating func drop(_ id: String, from key: Key) {
        idsByStrip[key]?.removeAll { $0 == id }
        if idsByStrip[key]?.isEmpty == true {
            idsByStrip[key] = nil
        }
    }

    private func change(from before: Set<Key>, touched: Set<Key>) -> Change {
        let after = Set(idsByStrip.keys)
        let opened = after.subtracting(before)
        return Change(
            opened: opened,
            closed: before.subtracting(after),
            refreshed: touched.intersection(after).subtracting(opened))
    }
}
