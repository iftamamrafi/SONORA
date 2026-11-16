
import XCTest
@testable import SONORA

final class ShuffleRepeatTests: XCTestCase {
    private func track(_ n: Int) -> TrackSnapshot {
        TrackSnapshot(id: UUID(), title: "T\(n)", artistName: "A", albumTitle: "AL", duration: 100, source: .local)
    }
    func testAdvanceStopsAtEndWhenRepeatOff() {
        var q = PlaybackQueue()
        q.setQueue([track(0), track(1)], startAt: 1)
        XCTAssertNil(q.advance(auto: true))
    }
    func testRepeatAllWraps() {
        var q = PlaybackQueue()
        q.repeatMode = .all
        q.setQueue([track(0), track(1)], startAt: 1)
        // setQueue preserves repeatMode property on the struct copy semantics: re-apply after set.
        q.repeatMode = .all
        XCTAssertEqual(q.advance(auto: true)?.title, "T0")
    }
    func testRepeatOneReturnsCurrentOnAutoAdvance() {
        var q = PlaybackQueue()
        q.setQueue([track(0), track(1)], startAt: 0)
        q.repeatMode = .one
        XCTAssertEqual(q.advance(auto: true)?.title, "T0")
        XCTAssertEqual(q.advance(auto: false)?.title, "T1")
    }
    func testShuffleCoversAllTracks() {
        var q = PlaybackQueue()
        let tracks = (0..<10).map { track($0) }
        q.setQueue(tracks, startAt: 0)
        q.setShuffle(true)
        var seen: Set<UUID> = [q.current!.id]
        for _ in 0..<9 { if let n = q.advance(auto: false) { seen.insert(n.id) } }
        XCTAssertEqual(seen.count, 10)
        XCTAssertTrue(q.isShuffled)
    }
    func testBack() {
        var q = PlaybackQueue()
        q.setQueue((0..<3).map { track($0) }, startAt: 2)
        XCTAssertEqual(q.back()?.title, "T1")
    }
    func testRepeatModeCycle() {
        XCTAssertEqual(RepeatMode.off.next, .all)
        XCTAssertEqual(RepeatMode.all.next, .one)
        XCTAssertEqual(RepeatMode.one.next, .off)
    }
}
