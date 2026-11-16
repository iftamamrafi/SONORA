
import XCTest
@testable import SONORA

final class QueueTests: XCTestCase {
    private func track(_ n: Int) -> TrackSnapshot {
        TrackSnapshot(id: UUID(), title: "T\(n)", artistName: "A", albumTitle: "AL", duration: 100, source: .local)
    }
    func testSetQueueAndCurrent() {
        var q = PlaybackQueue()
        let tracks = (0..<5).map { track($0) }
        q.setQueue(tracks, startAt: 2)
        XCTAssertEqual(q.current?.title, "T2")
        XCTAssertEqual(q.upcoming.map { $0.title }, ["T3", "T4"])
    }
    func testAppendAndInsertNext() {
        var q = PlaybackQueue()
        q.setQueue([track(0), track(1)])
        q.append(track(2))
        XCTAssertEqual(q.items.count, 3)
        q.insertNext(track(9))
        XCTAssertEqual(q.items[1].title, "T9")
    }
    func testRemove() {
        var q = PlaybackQueue()
        let tracks = (0..<4).map { track($0) }
        q.setQueue(tracks, startAt: 0)
        q.remove(trackID: tracks[2].id)
        XCTAssertEqual(q.items.count, 3)
        XCTAssertFalse(q.items.contains { $0.id == tracks[2].id })
    }
    func testMove() {
        var q = PlaybackQueue()
        q.setQueue((0..<4).map { track($0) }, startAt: 0)
        q.moveItem(from: 3, to: 1)
        XCTAssertEqual(q.items.map { $0.title }, ["T0", "T3", "T1", "T2"])
        XCTAssertEqual(q.current?.title, "T0")
    }
    func testClearUpcoming() {
        var q = PlaybackQueue()
        q.setQueue((0..<4).map { track($0) }, startAt: 1)
        q.clearUpcoming()
        XCTAssertEqual(q.items.count, 1)
        XCTAssertEqual(q.current?.title, "T1")
    }
    func testJump() {
        var q = PlaybackQueue()
        let tracks = (0..<3).map { track($0) }
        q.setQueue(tracks)
        let t = q.jump(to: tracks[2].id)
        XCTAssertEqual(t?.title, "T2")
    }
}
