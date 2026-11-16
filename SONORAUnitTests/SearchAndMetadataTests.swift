
import XCTest
@testable import SONORA

final class SearchAndMetadataTests: XCTestCase {
    func testLocalSearchMatchingLogic() {
        let tracks = [
            TrackSnapshot(id: UUID(), title: "Blue Sky", artistName: "Ava", albumTitle: "Horizons", duration: 10, source: .local),
            TrackSnapshot(id: UUID(), title: "Night Rain", artistName: "Ben", albumTitle: "Storm", duration: 10, source: .local)
        ]
        let q = "blue"
        let results = tracks.filter { $0.title.lowercased().contains(q) || $0.artistName.lowercased().contains(q) || $0.albumTitle.lowercased().contains(q) }
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Blue Sky")
    }
    func testMetadataDefaults() {
        let d = MetadataService.defaults(for: "my-song.mp3")
        XCTAssertEqual(d.title, "my-song.mp3")
        XCTAssertEqual(d.artist, "Unknown Artist")
        XCTAssertEqual(d.album, "Unknown Album")
    }
    func testTimeFormatting() {
        XCTAssertEqual(DS.timeString(0), "0:00")
        XCTAssertEqual(DS.timeString(65), "1:05")
        XCTAssertEqual(DS.timeString(600), "10:00")
        XCTAssertEqual(DS.timeString(.nan), "0:00")
    }
    func testEQPresetsHaveTenBands() {
        for preset in EQPreset.all { XCTAssertEqual(preset.gains.count, 10, preset.name) }
    }
    func testDemoProviderIsLabeled() async throws {
        let provider = DemoMusicProvider()
        XCTAssertTrue(provider.isConfigured)
        XCTAssertTrue(provider.providerName.contains("Demo"))
        let tracks = try await provider.trending()
        XCTAssertFalse(tracks.isEmpty)
        XCTAssertTrue(tracks.allSatisfy { $0.isDemo && $0.source == .online })
    }
    func testUnavailableProviderThrows() async {
        let provider = UnavailableProvider()
        XCTAssertFalse(provider.isConfigured)
        do { _ = try await provider.trending(); XCTFail("should throw") }
        catch { XCTAssertTrue(error is SonoraError) }
    }
}
