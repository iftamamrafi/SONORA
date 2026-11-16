
import Foundation
import AVFoundation

struct EQPreset: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var gains: [Float]  // 10 bands
    static let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    static let all: [EQPreset] = [
        EQPreset(name: "Normal", gains: [0,0,0,0,0,0,0,0,0,0]),
        EQPreset(name: "Bass Boost", gains: [7,6,5,3,1,0,0,0,0,0]),
        EQPreset(name: "Rock", gains: [5,4,3,1,-1,1,3,4,5,5]),
        EQPreset(name: "Pop", gains: [-1,1,3,4,4,3,1,0,-1,-1]),
        EQPreset(name: "Classical", gains: [4,3,2,1,0,0,1,2,3,4]),
        EQPreset(name: "Jazz", gains: [4,3,2,1,2,2,1,2,3,3]),
        EQPreset(name: "Electronic", gains: [6,5,3,0,-1,1,2,4,5,6]),
        EQPreset(name: "Vocal", gains: [-2,-1,0,2,4,4,3,2,1,0]),
        EQPreset(name: "Custom", gains: [0,0,0,0,0,0,0,0,0,0])
    ]
    static func named(_ name: String) -> EQPreset { all.first { $0.name == name } ?? all[0] }
}

/// Real equalizer playback for LOCAL files: AVAudioPlayerNode -> AVAudioUnitEQ (10 bands) -> output.
/// Remote streams cannot pass through this engine; PlaybackManager keeps those on AVPlayer.
final class LocalEQPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let eq = AVAudioUnitEQ(numberOfBands: 10)
    private var file: AVAudioFile?
    private var scheduledDuration: Double = 0
    private var startTime: AVAudioTime?
    private var pausePosition: Double = 0
    private var segmentScheduled = false
    private var scheduleGeneration = 0
    private(set) var isPlaying = false
    var onFinished: (() -> Void)?
    var volume: Float = 1.0 { didSet { engine.mainMixerNode.outputVolume = volume } }

    init() {
        for (i, band) in eq.bands.enumerated() {
            band.frequency = EQPreset.frequencies[min(i, EQPreset.frequencies.count - 1)]
            band.bandwidth = 1.0
            band.bypass = false
            band.filterType = i == 0 ? .lowShelf : (i == eq.bands.count - 1 ? .highShelf : .parametric)
        }
        engine.attach(playerNode)
        engine.attach(eq)
    }
    func applyGains(_ gains: [Float]) {
        for (i, band) in eq.bands.enumerated() where gains.indices.contains(i) { band.gain = gains[i] }
    }
    func load(url: URL) throws {
        stopInternal()
        file = try AVAudioFile(forReading: url)
        scheduledDuration = file.map { Double($0.length) / $0.processingFormat.sampleRate } ?? 0
        pausePosition = 0
        if let file {
            engine.disconnectNodeOutput(playerNode)
            engine.connect(playerNode, to: eq, format: file.processingFormat)
            engine.connect(eq, to: engine.mainMixerNode, format: file.processingFormat)
        }
    }
    var duration: Double { scheduledDuration }
    var currentTime: Double {
        guard isPlaying, let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else { return pausePosition }
        return pausePosition + Double(playerTime.sampleTime) / playerTime.sampleRate
    }
    func play() {
        guard let file else { return }
        if !engine.isRunning { try? engine.start() }
        if segmentScheduled {
            // Resume the segment that is still scheduled (paused mid-segment) instead of
            // scheduling a second copy, which would double-play the remainder.
            playerNode.play()
            isPlaying = true
            return
        }
        scheduleFrom(pausePosition, file: file)
        playerNode.play()
        isPlaying = true
    }
    private func scheduleFrom(_ position: Double, file: AVAudioFile) {
        let startFrame = AVAudioFramePosition(position * file.processingFormat.sampleRate)
        let remaining = file.length - startFrame
        guard remaining > 0 else { return }
        scheduleGeneration += 1
        let generation = scheduleGeneration
        segmentScheduled = true
        playerNode.scheduleSegment(file, startingFrame: startFrame, frameCount: AVAudioFrameCount(remaining), at: nil) { [weak self] in
            DispatchQueue.main.async {
                // Ignore completions from superseded segments (stop/seek invalidate them
                // by bumping scheduleGeneration).
                guard let self, generation == self.scheduleGeneration, self.isPlaying else { return }
                self.segmentScheduled = false
                self.isPlaying = false; self.pausePosition = 0
                self.onFinished?()
            }
        }
    }
    func pause() {
        pausePosition = currentTime
        playerNode.pause()
        isPlaying = false
    }
    func seek(to time: Double) {
        let wasPlaying = isPlaying
        playerNode.stop()
        segmentScheduled = false; scheduleGeneration += 1
        pausePosition = min(max(time, 0), scheduledDuration)
        if wasPlaying, let file {
            if !engine.isRunning { try? engine.start() }
            scheduleFrom(pausePosition, file: file)
            playerNode.play(); isPlaying = true
        }
    }
    func setVolume(_ v: Float) { volume = v }
    func stop() { stopInternal() }
    private func stopInternal() {
        playerNode.stop()
        segmentScheduled = false; scheduleGeneration += 1
        if engine.isRunning { engine.stop() }
        isPlaying = false; pausePosition = 0; startTime = nil
    }
}
