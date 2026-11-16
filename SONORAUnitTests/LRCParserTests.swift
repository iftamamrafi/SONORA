
import XCTest
@testable import SONORA

final class LRCParserTests: XCTestCase {
    func testParseBasic() {
        let lrc = "[ti:Song]\n[00:01.00]First line\n[00:05.50]Second line\n[01:02.25]Third line"
        let lines = LRCParser.parse(lrc)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].text, "First line")
        XCTAssertEqual(lines[0].time, 1.0, accuracy: 0.001)
        XCTAssertEqual(lines[1].time, 5.5, accuracy: 0.001)
        XCTAssertEqual(lines[2].time, 62.25, accuracy: 0.001)
    }
    func testMultipleTimestampsOneLine() {
        let lines = LRCParser.parse("[00:01.00][00:10.00]Chorus")
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines.allSatisfy { $0.text == "Chorus" })
    }
    func testCurrentLineIndex() {
        let lines = LRCParser.parse("[00:01.00]A\n[00:05.00]B\n[00:09.00]C")
        XCTAssertEqual(LRCParser.index(ofCurrentLine: lines, at: 6), 1)
        XCTAssertEqual(LRCParser.index(ofCurrentLine: lines, at: 0.5), nil)
        XCTAssertEqual(LRCParser.index(ofCurrentLine: lines, at: 100), 2)
    }
    func testEmpty() { XCTAssertTrue(LRCParser.parse("").isEmpty) }
}
