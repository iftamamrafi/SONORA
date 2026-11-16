
import Foundation

struct LyriTimber: Identifiable, Equatable {
    var id: Double { time }
    var time: Double
    var text: String
}

enum LRCParser {
    /// Parses LRC text with [mm:ss.xx] timestamps. Lines without timestamps are kept as plain lines at time -1 sorted last-resort.
    static func parse(_ content: String) -> [LyriTimber] {
        var result: [LyriTimber] = []
        let lines = content.components(separatedBy: .newlines)
        for raw in lines {
            var line = raw
            var times: [Double] = []
            while line.hasPrefix("[") {
                guard let close = line.firstIndex(of: "]") else { break }
                let tag = String(line[line.index(after: line.startIndex)..<close])
                if let t = parseTimestamp(tag) {
                    times.append(t)
                    line = String(line[line.index(after: close)...])
                } else {
                    // metadata tag like [ti:...] — skip it
                    line = String(line[line.index(after: close)...])
                    break
                }
            }
            let text = line.trimmingCharacters(in: .whitespaces)
            for t in times { result.append(LyriTimber(time: t, text: text)) }
        }
        return result.sorted { $0.time < $1.time }
    }
    static func parseTimestamp(_ tag: String) -> Double? {
        let parts = tag.split(separator: ":")
        guard parts.count == 2, let m = Double(parts[0]) else { return nil }
        guard let s = Double(parts[1]) else { return nil }
        return m * 60 + s
    }
    static func index(ofCurrentLine lines: [LyriTimber], at time: Double) -> Int? {
        var current: Int? = nil
        for (i, line) in lines.enumerated() {
            if line.time <= time { current = i } else { break }
        }
        return current
    }
}
