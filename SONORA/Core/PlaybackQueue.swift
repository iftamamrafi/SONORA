
import Foundation

/// Pure, testable queue logic. Holds track snapshots in original order plus a
/// shuffled play order. PlaybackManager owns one instance.
struct PlaybackQueue: Equatable {
    private(set) var items: [TrackSnapshot] = []
    private(set) var shuffledOrder: [Int] = []   // indices into items
    private(set) var currentIndex: Int = -1      // index into items
    var isShuffled: Bool = false
    var repeatMode: RepeatMode = .off

    var isEmpty: Bool { items.isEmpty }
    var current: TrackSnapshot? {
        guard currentIndex >= 0, currentIndex < items.count else { return nil }
        return items[currentIndex]
    }
    /// Tracks in the order they will play from the current position (excluding current).
    var upcoming: [TrackSnapshot] {
        guard currentIndex >= 0 else { return items }
        if isShuffled {
            guard let pos = shuffledOrder.firstIndex(of: currentIndex) else { return [] }
            return shuffledOrder.dropFirst(pos + 1).compactMap { items.indices.contains($0) ? items[$0] : nil }
        }
        return Array(items.dropFirst(currentIndex + 1))
    }

    mutating func setQueue(_ tracks: [TrackSnapshot], startAt index: Int = 0) {
        items = tracks
        currentIndex = tracks.isEmpty ? -1 : min(max(index, 0), tracks.count - 1)
        rebuildShuffleOrder()
    }
    mutating func append(_ track: TrackSnapshot) {
        items.append(track)
        shuffledOrder.append(items.count - 1)
        if currentIndex < 0 { currentIndex = 0 }
    }
    mutating func insertNext(_ track: TrackSnapshot) {
        guard currentIndex >= 0 else { append(track); return }
        let insertAt = currentIndex + 1
        items.insert(track, at: insertAt)
        // Fix shuffle indices >= insertAt, then place new index right after current in play order.
        shuffledOrder = shuffledOrder.map { $0 >= insertAt ? $0 + 1 : $0 }
        if isShuffled, let pos = shuffledOrder.firstIndex(of: currentIndex) {
            shuffledOrder.insert(insertAt, at: pos + 1)
        } else {
            shuffledOrder.insert(insertAt, at: insertAt)
        }
    }
    mutating func remove(trackID: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == trackID }) else { return }
        remove(atItemIndex: idx)
    }
    mutating func remove(atItemIndex idx: Int) {
        guard items.indices.contains(idx) else { return }
        items.remove(at: idx)
        shuffledOrder = shuffledOrder.compactMap { $0 == idx ? nil : ($0 > idx ? $0 - 1 : $0) }
        if items.isEmpty { currentIndex = -1; return }
        if idx < currentIndex { currentIndex -= 1 }
        else if idx == currentIndex { currentIndex = min(currentIndex, items.count - 1) }
    }
    /// Reorder within the visible (play-order) upcoming list is handled by moving item indices.
    mutating func moveItem(from source: Int, to destination: Int) {
        guard items.indices.contains(source), destination >= 0, destination <= items.count else { return }
        let currentID = current?.id
        let element = items.remove(at: source)
        let dest = destination > source ? destination - 1 : destination
        items.insert(element, at: min(dest, items.count))
        rebuildShuffleOrderKeepingCurrent(currentID)
    }
    mutating func clear() { items = []; shuffledOrder = []; currentIndex = -1 }
    mutating func clearUpcoming() {
        guard let cur = current else { clear(); return }
        items = [cur]; currentIndex = 0; shuffledOrder = [0]
    }
    mutating func jump(to trackID: UUID) -> TrackSnapshot? {
        guard let idx = items.firstIndex(where: { $0.id == trackID }) else { return nil }
        currentIndex = idx
        return current
    }
    mutating func setShuffle(_ on: Bool) {
        isShuffled = on
        rebuildShuffleOrder()
    }
    private mutating func rebuildShuffleOrder() {
        if isShuffled {
            let rest = items.indices.filter { $0 != currentIndex }.shuffled()
            shuffledOrder = (currentIndex >= 0 ? [currentIndex] : []) + rest
        } else {
            shuffledOrder = Array(items.indices)
        }
    }
    private mutating func rebuildShuffleOrderKeepingCurrent(_ currentID: UUID?) {
        if let currentID, let idx = items.firstIndex(where: { $0.id == currentID }) { currentIndex = idx }
        rebuildShuffleOrder()
    }
    /// Advance respecting repeat mode. Returns the next track to play, or nil to stop.
    mutating func advance(auto: Bool) -> TrackSnapshot? {
        guard !items.isEmpty, currentIndex >= 0 else { return nil }
        if auto && repeatMode == .one { return current }
        let order: [Int] = isShuffled ? shuffledOrder : Array(items.indices)
        guard let pos = order.firstIndex(of: currentIndex) else { return nil }
        if pos + 1 < order.count {
            currentIndex = order[pos + 1]
            return current
        }
        if repeatMode == .all {
            currentIndex = order[0]
            return current
        }
        return nil
    }
    mutating func back() -> TrackSnapshot? {
        guard !items.isEmpty, currentIndex >= 0 else { return nil }
        let order: [Int] = isShuffled ? shuffledOrder : Array(items.indices)
        guard let pos = order.firstIndex(of: currentIndex) else { return current }
        if pos > 0 { currentIndex = order[pos - 1] }
        else if repeatMode == .all { currentIndex = order[order.count - 1] }
        return current
    }
}
